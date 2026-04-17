"""Shared configuration for Bedrock demo scripts."""
import os
import boto3
from functools import lru_cache

REGION = os.environ.get("AWS_REGION", "us-east-1")
DEMO_PREFIX = "bedrock-demo"

# Clients (lazy-initialized)
_clients = {}

def client(service: str):
    if service not in _clients:
        _clients[service] = boto3.client(service, region_name=REGION)
    return _clients[service]

def bedrock():
    return client("bedrock")

def bedrock_runtime():
    return client("bedrock-runtime")

def bedrock_agent():
    return client("bedrock-agent")

def bedrock_agent_runtime():
    return client("bedrock-agent-runtime")

def s3():
    return client("s3")

def iam():
    return client("iam")

def sts():
    return client("sts")

@lru_cache()
def account_id():
    return sts().get_caller_identity()["Account"]


# ---------------------------------------------------------------------------
# Model discovery — pick the newest active model per provider automatically
# ---------------------------------------------------------------------------

@lru_cache()
def _discover_models():
    """Return (inference_profiles_by_provider, foundation_models_by_provider)."""
    # Inference profiles (required for Anthropic, etc.)
    profiles = bedrock().list_inference_profiles()["inferenceProfileSummaries"]
    # Only system-defined, US-regional, ACTIVE text profiles
    profiles = [
        p for p in profiles
        if p["status"] == "ACTIVE"
        and p["type"] == "SYSTEM_DEFINED"
        and p["inferenceProfileId"].startswith("us.")
    ]
    profiles.sort(key=lambda p: p.get("createdAt", ""), reverse=True)

    # Foundation models (for Amazon Nova, etc. that work with direct IDs)
    fms = bedrock().list_foundation_models()["modelSummaries"]
    fms = [
        m for m in fms
        if m.get("modelLifecycle", {}).get("status") == "ACTIVE"
        and "TEXT" in m.get("outputModalities", [])
        and "TEXT" in m.get("inputModalities", [])
    ]

    return profiles, fms


def _pick_profile(provider_substring: str) -> str | None:
    """Pick the newest US inference profile matching a provider substring."""
    profiles, _ = _discover_models()
    for p in profiles:
        if provider_substring.lower() in p["inferenceProfileId"].lower():
            return p["inferenceProfileId"]
    return None


def _pick_foundation_model(prefix: str) -> str | None:
    """Pick a foundation model ID by prefix (e.g. 'amazon.nova-lite').
    Skips context-window variants like ':0:300k' — only picks base IDs.
    """
    _, fms = _discover_models()
    for m in sorted(fms, key=lambda m: m["modelId"], reverse=True):
        mid = m["modelId"]
        if mid.startswith(prefix) and mid.count(":") <= 1:
            return mid
    return None


def _probe_model(model_id: str) -> bool:
    """Send a minimal request to check if a model is actually invocable."""
    try:
        bedrock_runtime().converse(
            modelId=model_id,
            messages=[{"role": "user", "content": [{"text": "hi"}]}],
            inferenceConfig={"maxTokens": 1},
        )
        return True
    except Exception:
        return False


@lru_cache()
def get_demo_models() -> list[tuple[str, str]]:
    """Return [(model_id, label), ...] for the multi-model comparison demo.

    Picks the newest available model from different providers/families,
    probing each to confirm it's actually invocable.
    """
    candidates = [
        (_pick_profile("anthropic.claude-sonnet"), "Claude Sonnet (Anthropic)"),
        (_pick_profile("anthropic.claude-opus"), "Claude Opus (Anthropic)"),
        (_pick_foundation_model("amazon.nova-lite"), "Nova Lite (Amazon)"),
        (_pick_foundation_model("amazon.nova-micro"), "Nova Micro (Amazon)"),
        (_pick_profile("anthropic.claude-haiku"), "Claude Haiku (Anthropic)"),
        (_pick_foundation_model("amazon.nova-pro"), "Nova Pro (Amazon)"),
        (_pick_profile("meta.llama"), "Llama (Meta)"),
        (_pick_profile("mistral"), "Mistral"),
    ]
    results = []
    for mid, label in candidates:
        if mid and _probe_model(mid):
            results.append((mid, label))
            if len(results) == 4:
                break
    return results


@lru_cache()
def get_smart_model() -> str:
    """Return the best available model ID for demos needing strong reasoning (agents, RAG)."""
    for finder in [
        lambda: _pick_profile("anthropic.claude-sonnet"),
        lambda: _pick_profile("anthropic.claude-opus"),
        lambda: _pick_profile("anthropic.claude-haiku"),
        lambda: _pick_foundation_model("amazon.nova-pro"),
        lambda: _pick_foundation_model("amazon.nova-lite"),
    ]:
        mid = finder()
        if mid and _probe_model(mid):
            return mid
    raise RuntimeError("No suitable text model found. Enable model access in the Bedrock console.")


@lru_cache()
def get_smart_model_arn() -> str:
    """Return the full ARN for the smart model (needed by RetrieveAndGenerate)."""
    mid = get_smart_model()
    profiles, _ = _discover_models()
    for p in profiles:
        if p["inferenceProfileId"] == mid:
            return p["inferenceProfileArn"]
    # Foundation model ARN
    return f"arn:aws:bedrock:{REGION}::foundation-model/{mid}"

def print_header(title: str):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def print_step(step: str):
    print(f"\n>>> {step}")

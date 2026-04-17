"""Demo 1: Model Invocation — Converse API multi-model comparison.

Shows the same prompt sent to multiple models via the unified Converse API.
Key point: switching models = changing one string, zero code changes.
"""
import time
import json
from config import bedrock_runtime, get_demo_models, print_header, print_step

PROMPT = "Explain what a Kubernetes pod is in exactly two sentences."


def converse(model_id: str, prompt: str) -> dict:
    """Call the Converse API — identical code for every model."""
    start = time.time()
    config = {"maxTokens": 256, "temperature": 0.3}
    try:
        resp = bedrock_runtime().converse(
            modelId=model_id,
            messages=[{"role": "user", "content": [{"text": prompt}]}],
            inferenceConfig=config,
        )
    except Exception as e:
        if "temperature" in str(e).lower():
            # Reasoning models (e.g. Opus) don't support temperature
            config.pop("temperature")
            resp = bedrock_runtime().converse(
                modelId=model_id,
                messages=[{"role": "user", "content": [{"text": prompt}]}],
                inferenceConfig=config,
            )
        else:
            raise
    elapsed = time.time() - start
    text = resp["output"]["message"]["content"][0]["text"]
    usage = resp["usage"]
    return {"text": text, "latency": elapsed, "usage": usage}


def main():
    print_header("Demo 1: Model Invocation — Converse API")
    print(f"Prompt: \"{PROMPT}\"\n")
    print("Sending the SAME prompt to multiple models via the unified Converse API...\n")

    models = get_demo_models()
    print(f"Discovered {len(models)} models:\n")
    for mid, label in models:
        print(f"  • {label}: {mid}")
    print()

    results = []
    for model_id, label in models:
        print_step(f"Calling {label} ({model_id})")
        try:
            r = converse(model_id, PROMPT)
            results.append((label, model_id, r))
            print(f"  Response: {r['text'][:200]}...")
            print(f"  Latency:  {r['latency']:.2f}s")
            print(f"  Tokens:   {r['usage']['inputTokens']} in / {r['usage']['outputTokens']} out")
        except Exception as e:
            print(f"  ERROR: {e}")
            print("  (Ensure model access is enabled in the Bedrock console)")

    # Summary table
    if results:
        print_header("Comparison Summary")
        print(f"{'Model':<25} {'Latency':>8} {'In Tokens':>10} {'Out Tokens':>11}")
        print("-" * 58)
        for label, _, r in results:
            print(f"{label:<25} {r['latency']:>7.2f}s {r['usage']['inputTokens']:>10} {r['usage']['outputTokens']:>11}")

    print("\n✅ Key takeaway: One API, many models. Switching = one string change.\n")


if __name__ == "__main__":
    main()

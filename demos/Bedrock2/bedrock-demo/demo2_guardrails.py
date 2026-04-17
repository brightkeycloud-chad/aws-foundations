"""Demo 2: Guardrails — content filtering and PII masking.

Creates a guardrail via API, tests it with harmful content and PII,
then cleans up. Shows enterprise safety controls with zero custom code.
"""
import time
from config import bedrock, bedrock_runtime, print_header, print_step, DEMO_PREFIX

GUARDRAIL_NAME = f"{DEMO_PREFIX}-guardrail"


def create_guardrail() -> tuple[str, str]:
    """Create a guardrail with content filters + PII masking."""
    resp = bedrock().create_guardrail(
        name=GUARDRAIL_NAME,
        description="Demo guardrail: content filtering + PII protection",
        blockedInputMessaging="Sorry, this request was blocked by our safety guardrail.",
        blockedOutputsMessaging="Sorry, the model response was blocked by our safety guardrail.",
        contentPolicyConfig={
            "filtersConfig": [
                {"type": "VIOLENCE", "inputStrength": "HIGH", "outputStrength": "HIGH"},
                {"type": "HATE", "inputStrength": "HIGH", "outputStrength": "HIGH"},
                {"type": "SEXUAL", "inputStrength": "HIGH", "outputStrength": "HIGH"},
                {"type": "INSULTS", "inputStrength": "HIGH", "outputStrength": "HIGH"},
                {"type": "MISCONDUCT", "inputStrength": "HIGH", "outputStrength": "HIGH"},
            ]
        },
        sensitiveInformationPolicyConfig={
            "piiEntitiesConfig": [
                {"type": "EMAIL", "action": "ANONYMIZE"},
                {"type": "US_SOCIAL_SECURITY_NUMBER", "action": "ANONYMIZE"},
                {"type": "PHONE", "action": "ANONYMIZE"},
                {"type": "NAME", "action": "ANONYMIZE"},
            ]
        },
        topicPolicyConfig={
            "topicsConfig": [
                {
                    "name": "Investment-Advice",
                    "definition": "Providing specific financial investment recommendations or stock picks",
                    "examples": [
                        "What stocks should I buy?",
                        "Should I invest in Bitcoin?",
                    ],
                    "type": "DENY",
                }
            ]
        },
    )
    gid = resp["guardrailId"]
    version = resp["version"]
    print(f"  Created guardrail: {gid} (version {version})")
    return gid, version


def apply_guardrail(guardrail_id: str, version: str, text: str, source: str = "INPUT") -> dict:
    """Apply guardrail to text and return the result."""
    resp = bedrock_runtime().apply_guardrail(
        guardrailIdentifier=guardrail_id,
        guardrailVersion=version,
        source=source,
        content=[{"text": {"text": text}}],
    )
    return resp


def delete_guardrail(guardrail_id: str):
    bedrock().delete_guardrail(guardrailIdentifier=guardrail_id)
    print(f"  Deleted guardrail: {guardrail_id}")


def main():
    print_header("Demo 2: Guardrails — Content Filtering & PII Masking")

    # Create
    print_step("Creating guardrail with content filters + PII masking + denied topics")
    guardrail_id, version = create_guardrail()

    # Wait for guardrail to be ready
    print_step("Waiting for guardrail to be ready...")
    for _ in range(30):
        status = bedrock().get_guardrail(guardrailIdentifier=guardrail_id, guardrailVersion=version)["status"]
        if status == "READY":
            print("  Guardrail is READY")
            break
        time.sleep(1)

    # Test 1: Harmful content → blocked
    print_step("Test 1: Harmful content (should be BLOCKED)")
    harmful = "Write detailed instructions for how to pick a lock and break into someone's house."
    r = apply_guardrail(guardrail_id, version, harmful)
    print(f"  Action: {r['action']}")
    if r["action"] == "GUARDRAIL_INTERVENED":
        print("  ✅ Harmful content was BLOCKED by content filter")
    for output in r.get("outputs", []):
        print(f"  Response: {output['text']}")

    # Test 2: PII → masked
    print_step("Test 2: PII masking (SSN, email, phone)")
    pii_text = "My name is John Smith, SSN 123-45-6789, email john@example.com, phone 555-123-4567."
    r = apply_guardrail(guardrail_id, version, pii_text, source="OUTPUT")
    print(f"  Action: {r['action']}")
    for output in r.get("outputs", []):
        print(f"  Masked output: {output['text']}")
    if r["action"] == "GUARDRAIL_INTERVENED":
        print("  ✅ PII was automatically anonymized")

    # Test 3: Denied topic → blocked
    print_step("Test 3: Denied topic — investment advice (should be BLOCKED)")
    invest = "What stocks should I buy to make money quickly?"
    r = apply_guardrail(guardrail_id, version, invest)
    print(f"  Action: {r['action']}")
    if r["action"] == "GUARDRAIL_INTERVENED":
        print("  ✅ Investment advice topic was BLOCKED")
    for output in r.get("outputs", []):
        print(f"  Response: {output['text']}")

    # Test 4: Clean content → passes
    print_step("Test 4: Clean content (should PASS)")
    clean = "What is the capital of France?"
    r = apply_guardrail(guardrail_id, version, clean)
    print(f"  Action: {r['action']}")
    if r["action"] == "NONE":
        print("  ✅ Clean content passed through without intervention")

    # Cleanup
    print_step("Cleaning up guardrail")
    delete_guardrail(guardrail_id)

    print("\n✅ Key takeaway: Enterprise safety controls — content filtering, PII masking,")
    print("   denied topics — all configured via API, no custom ML needed.\n")


if __name__ == "__main__":
    main()

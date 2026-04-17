"""Cleanup script — removes all resources created by the demo scripts.

Most demos self-clean, but run this as a safety net to catch anything left behind.
"""
from config import bedrock, s3, print_header, print_step, DEMO_PREFIX, account_id

BUCKET_NAME = f"{DEMO_PREFIX}-docs-{account_id()}"


def cleanup_guardrails():
    """Delete any guardrails with the demo prefix."""
    try:
        resp = bedrock().list_guardrails()
        for g in resp.get("guardrails", []):
            if g["name"].startswith(DEMO_PREFIX):
                print(f"  Deleting guardrail: {g['name']} ({g['id']})")
                bedrock().delete_guardrail(guardrailIdentifier=g["id"])
    except Exception as e:
        print(f"  Guardrails cleanup: {e}")


def cleanup_s3():
    """Delete the demo S3 bucket and all objects."""
    try:
        paginator = s3().get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=BUCKET_NAME):
            for obj in page.get("Contents", []):
                s3().delete_object(Bucket=BUCKET_NAME, Key=obj["Key"])
        s3().delete_bucket(Bucket=BUCKET_NAME)
        print(f"  Deleted bucket: {BUCKET_NAME}")
    except s3().exceptions.NoSuchBucket:
        print("  No demo S3 bucket found")
    except Exception as e:
        print(f"  S3 cleanup: {e}")


def main():
    print_header("Cleanup — Removing All Demo Resources")

    print_step("Cleaning up Guardrails")
    cleanup_guardrails()

    print_step("Cleaning up S3")
    cleanup_s3()

    print("\n✅ Cleanup complete.\n")


if __name__ == "__main__":
    main()

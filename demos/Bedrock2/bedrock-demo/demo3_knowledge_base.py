"""Demo 3: Knowledge Bases / RAG — RetrieveAndGenerate with external sources.

Shows RAG in action: the model answers questions grounded in YOUR documents,
with citations. Uses EXTERNAL_SOURCES mode for instant demo (no KB provisioning wait).

Talking point: In production, you'd use a full Knowledge Base backed by
OpenSearch Serverless, Aurora, or Neptune for persistent vector storage.
"""
import json
import os
import tempfile
from config import bedrock_agent_runtime, s3, print_header, print_step, REGION, DEMO_PREFIX, account_id, get_smart_model_arn

BUCKET_NAME = f"{DEMO_PREFIX}-docs-{account_id()}"

# Sample company document to upload
SAMPLE_DOC = """# Acme Corp Employee Handbook (Excerpt)

## Vacation Policy
All full-time employees receive 20 days of paid vacation per year. Vacation days
accrue monthly at a rate of 1.67 days per month. Unused vacation days can be
carried over to the next year, up to a maximum of 10 days. Employees must submit
vacation requests at least 2 weeks in advance through the HR portal.

## Remote Work Policy
Acme Corp supports a hybrid work model. Employees may work remotely up to 3 days
per week with manager approval. Fully remote arrangements require VP-level approval.
All remote employees must be available during core hours (10 AM - 3 PM ET).

## Expense Reimbursement
Business expenses over $25 require pre-approval. Submit expense reports within
30 days of the expense via the Finance portal. Approved categories include:
travel, meals during business travel (up to $75/day), software subscriptions,
and professional development (up to $2,000/year per employee).

## Parental Leave
Primary caregivers receive 16 weeks of paid parental leave. Secondary caregivers
receive 6 weeks of paid parental leave. Leave must begin within 12 months of the
birth or adoption of a child.
"""


def setup_s3():
    """Create bucket and upload sample document."""
    try:
        if REGION == "us-east-1":
            s3().create_bucket(Bucket=BUCKET_NAME)
        else:
            s3().create_bucket(
                Bucket=BUCKET_NAME,
                CreateBucketConfiguration={"LocationConstraint": REGION},
            )
        print(f"  Created S3 bucket: {BUCKET_NAME}")
    except s3().exceptions.BucketAlreadyOwnedByYou:
        print(f"  Bucket already exists: {BUCKET_NAME}")

    s3().put_object(
        Bucket=BUCKET_NAME,
        Key="employee-handbook.txt",
        Body=SAMPLE_DOC.encode(),
        ContentType="text/plain",
    )
    print("  Uploaded employee-handbook.txt")


def query_with_rag(question: str):
    """Use RetrieveAndGenerate with external S3 source."""
    resp = bedrock_agent_runtime().retrieve_and_generate(
        input={"text": question},
        retrieveAndGenerateConfiguration={
            "type": "EXTERNAL_SOURCES",
            "externalSourcesConfiguration": {
                "modelArn": get_smart_model_arn(),
                "sources": [
                    {
                        "sourceType": "S3",
                        "s3Location": {
                            "uri": f"s3://{BUCKET_NAME}/employee-handbook.txt"
                        },
                    }
                ],
            },
        },
    )
    answer = resp["output"]["text"]
    citations = resp.get("citations", [])
    return answer, citations


def cleanup_s3():
    """Delete the demo bucket and objects."""
    try:
        s3().delete_object(Bucket=BUCKET_NAME, Key="employee-handbook.txt")
        s3().delete_bucket(Bucket=BUCKET_NAME)
        print(f"  Deleted bucket: {BUCKET_NAME}")
    except Exception as e:
        print(f"  Cleanup note: {e}")


def main():
    print_header("Demo 3: Knowledge Bases / RAG — RetrieveAndGenerate")

    # Setup
    print_step("Uploading sample company document to S3")
    setup_s3()

    # Queries
    questions = [
        "How many vacation days do employees get per year, and can they carry over unused days?",
        "What is the remote work policy? How many days can I work from home?",
        "How much can I spend on professional development?",
    ]

    for i, q in enumerate(questions, 1):
        print_step(f"Query {i}: {q}")
        try:
            answer, citations = query_with_rag(q)
            print(f"  Answer: {answer}")
            if citations:
                print(f"  📎 Citations: {len(citations)} source reference(s)")
                for c in citations[:2]:
                    refs = c.get("retrievedReferences", [])
                    for ref in refs[:1]:
                        loc = ref.get("location", {})
                        s3_loc = loc.get("s3Location", {})
                        if s3_loc:
                            print(f"     Source: {s3_loc.get('uri', 'N/A')}")
                        snippet = ref.get("content", {}).get("text", "")
                        if snippet:
                            print(f"     Excerpt: {snippet[:150]}...")
        except Exception as e:
            print(f"  ERROR: {e}")

    # Cleanup
    print_step("Cleaning up S3 resources")
    cleanup_s3()

    print("\n✅ Key takeaway: RAG grounds model responses in YOUR data with citations.")
    print("   Production setup uses full Knowledge Bases with vector stores")
    print("   (OpenSearch Serverless, Aurora, Neptune) for persistent, scalable retrieval.\n")


if __name__ == "__main__":
    main()

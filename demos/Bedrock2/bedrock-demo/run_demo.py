"""Master demo runner — orchestrates all 5 demos in sequence.

Run: python run_demo.py
Automatically creates a venv and installs dependencies on first run.
"""
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
VENV_DIR = os.path.join(SCRIPT_DIR, ".venv")
VENV_PYTHON = os.path.join(VENV_DIR, "bin", "python")

def ensure_venv():
    """Create venv and re-exec inside it if we're not already there."""
    if os.path.realpath(sys.executable) == os.path.realpath(VENV_PYTHON):
        return
    if not os.path.isdir(VENV_DIR):
        print("Creating virtual environment...")
        subprocess.check_call([sys.executable, "-m", "venv", VENV_DIR])
    subprocess.check_call([VENV_PYTHON, "-m", "pip", "install", "-q", "boto3"])
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv)

ensure_venv()

import time
from config import print_header

DEMOS = [
    ("Demo 1: Model Invocation — Converse API", "demo1_converse"),
    ("Demo 2: Guardrails", "demo2_guardrails"),
    ("Demo 3: Knowledge Bases / RAG", "demo3_knowledge_base"),
    ("Demo 4: Bedrock Agents — Tool Use", "demo4_agents"),
]


def pause(msg: str = "Press Enter to continue to the next demo..."):
    try:
        input(f"\n⏸  {msg}")
    except (EOFError, KeyboardInterrupt):
        print("\nDemo interrupted.")
        sys.exit(0)


def main():
    print_header("Amazon Bedrock — Feature Demo (10-15 min)")
    print("This will run 4 automated demos + AgentCore talking points.\n")
    print("Prerequisites:")
    print("  - AWS credentials configured")
    print("  - Bedrock model access enabled (models auto-discovered at runtime)")
    print(f"  - Region: us-east-1 (override with AWS_REGION env var)\n")

    pause("Press Enter to start the demo...")

    for title, module_name in DEMOS:
        print(f"\n{'#'*60}")
        print(f"  STARTING: {title}")
        print(f"{'#'*60}")

        try:
            mod = __import__(module_name)
            mod.main()
        except Exception as e:
            print(f"\n❌ Error in {title}: {e}")
            print("   Continuing to next demo...\n")

        pause()

    # Demo 5 is talking points
    print_header("Demo 5: AgentCore — See demo5_agentcore.txt")
    print("AgentCore is the production platform for AI agents at scale.")
    print("Key services: Runtime, Memory, Gateway, Identity, Observability")
    print("Works with ANY framework (Strands, LangChain, etc.) and ANY model.")
    print("\nSee demo5_agentcore.txt for full talking points and optional CLI demo.\n")

    print_header("Demo Complete!")
    print("Resources to share:")
    print("  - Bedrock Console: https://console.aws.amazon.com/bedrock")
    print("  - Bedrock Docs: https://docs.aws.amazon.com/bedrock/")
    print("  - AgentCore: https://aws.amazon.com/bedrock/agentcore/")
    print("  - Bedrock Workshop: https://catalog.workshops.aws/amazon-bedrock/\n")


if __name__ == "__main__":
    main()

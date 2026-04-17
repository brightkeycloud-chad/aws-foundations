# Amazon Bedrock — 15-Minute Feature Demo

A scripted demo showcasing the most impactful Amazon Bedrock features. Primarily automated via Python with console verification steps where appropriate.

## Prerequisites

- AWS account with Bedrock model access enabled (models auto-discovered at runtime)
- Python 3.11+
- AWS CLI configured with appropriate credentials
- Region: `us-east-1` (default, configurable via `AWS_REGION` env var)

## Demo Features & Timing

| # | Feature | Method | Time | Script |
|---|---------|--------|------|--------|
| 1 | **Model Invocation (Converse API)** | Python | 2-3 min | `demo1_converse.py` |
| 2 | **Guardrails** | Python | 3-4 min | `demo2_guardrails.py` |
| 3 | **Knowledge Bases (RAG)** | Python | 3-4 min | `demo3_knowledge_base.py` |
| 4 | **Bedrock Agents (Tool Use)** | Python | 3-4 min | `demo4_agents.py` |
| 5 | **AgentCore** | Talking points + optional CLI | 1-2 min | `demo5_agentcore.md` |

**Total: ~12-15 minutes**

## Quick Start

```bash
cd bedrock-demo

# Run all demos (auto-creates venv and installs boto3 on first run)
python3 run_demo.py

# Or set up manually, then run individual demos
./setup.sh
source .venv/bin/activate
python demo1_converse.py
python demo2_guardrails.py
python demo3_knowledge_base.py
python demo4_agents.py

# Cleanup all resources when done
python cleanup.py
```

## Demo Runbook & Talking Points

### Demo 1: Model Invocation — Converse API (2-3 min)

**Key message:** One unified API for 100+ foundation models. No model-specific code.

- Show the same prompt sent to 3 auto-discovered models via `Converse`
- Compare response quality, latency, and token usage side-by-side
- Highlight: switching models = changing one string, zero code changes

### Demo 2: Guardrails (3-4 min)

**Key message:** Enterprise-grade safety controls without custom code.

- Create a guardrail with content filters + PII masking via API
- Test 1: Send harmful content → blocked by content filter
- Test 2: Send text with SSN/email → PII automatically masked
- Test 3: Send benign content → passes through cleanly
- Show the guardrail in the console (optional)
- Clean up the guardrail

### Demo 3: Knowledge Bases / RAG (3-4 min)

**Key message:** Fully managed RAG — no vector DB plumbing.

- Create a Knowledge Base backed by S3 + OpenSearch Serverless
- Upload sample documents and trigger ingestion
- Query with `RetrieveAndGenerate` — get answers with citations
- Show how citations trace back to source documents

### Demo 4: Bedrock Agents with Tool Use (3-4 min)

**Key message:** Agents that reason and act — connecting LLMs to real tools.

- Create an agent with a tool definition (weather lookup)
- The agent decides when to call the tool based on the user's question
- Show the full reasoning → tool call → response cycle
- Demonstrate the Converse API's native `toolUse` capability

### Demo 5: AgentCore Overview (1-2 min)

**Key message:** Production-grade agent infrastructure — deploy any framework at scale.

- Talking points covering AgentCore's modular services:
  - **Runtime**: Serverless agent deployment with session isolation
  - **Memory**: Short-term and long-term context persistence
  - **Gateway**: Turn any API/Lambda into MCP-compatible tools
  - **Identity**: OAuth integration, secure vault for tokens
  - **Observability**: CloudWatch dashboards, OTEL compatible
- Optional: Show AgentCore CLI scaffolding a project
- See `demo5_agentcore.md` for full talking points

## Cleanup

```bash
python cleanup.py
```

This removes all demo-created resources (guardrails, knowledge bases, agents, S3 objects, IAM roles).

# Architect Technical Context
## Supporting reference for CLAUDE.md

---

## SDK and dependency state (as of 2026-06-07)

### MAF 1.7.0 upgrade — complete in purpose-agent, pending in aos-kernel

What changed:
- agent-framework monolith → agent-framework-core==1.7.0 + agent-framework-foundry==1.7.0
- azure-ai-agents removed — subsumed into azure-ai-projects==2.2.0
- hosting.py import: was azure.ai.agentserver, now agent_framework.foundry.hosting

Repos where this is done: purpose-agent
Repos where this is pending: aos-kernel (still lists azure-ai-agents>=1.1.0)

### Purpose-agent mixin structure (current)

```
src/purpose_driven_agent/
  agents/
    purpose_driven_agent.py  — ABC, registry, routing, run_turn, handle_event
    foundry.py               — FoundryMixin: mind MCPTool, register_with_foundry, A2A
    mcp_manager.py           — MCPManagerMixin: MCP registry, routing, discovery
    purpose.py               — PurposeMixin: purpose alignment, goals, orchestration
    turn_types.py            — TurnResult, _AgentResponse, errors
    protocols.py             — MCPServerProtocol, PersonaCallbackProtocol
    a2a_agent_tool.py        — A2AAgentTool
    generic_purpose_driven_agent.py
```

---

## The one failing test

File: tests/integration/test_purpose_driven_agent.py
Test: TestInvokeTool::test_invoke_raises_when_tool_not_in_index
Match string: "not found in tool index"
Current message in mcp_manager.py: "not in index"
Fix: one line change in invoke_tool()

---

## Pipeline patterns

### Dispatch between repos

```bash
jq -n --arg image "$IMAGE" '{"image": $image}' \
  | gh api repos/ASISaga/TARGET-REPO/dispatches \
      --method POST \
      --input -
```

Never use --field. client_payload must be a JSON object or GitHub returns 422.

### Azure login

```yaml
- uses: azure/login@v3
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

Always requires `environment: staging` on the job. Subject claim:
`repo:ASISaga/REPO-NAME:environment:staging`

### Conditional builds

```yaml
- uses: dorny/paths-filter@v3
  id: changes
  with:
    filters: |
      maf:
        - 'requirements.maf.txt'
        - 'Dockerfile.maf'

- name: Build maf layer
  if: steps.changes.outputs.maf == 'true'
  run: az acr build ...
```

### crane rebase

```bash
crane rebase \
  --old_base $ACR/aos/azure-sdk:$OLD_SHA \
  --new_base $ACR/aos/azure-sdk:latest \
  --tag $ACR/aos/maf:latest \
  $ACR/aos/maf:$OLD_SHA
```

Zero bytes transferred. Only use for non-breaking parent bumps.

---

## Foundry registration pattern

```python
# In FoundryMixin.register_with_foundry()
# Tool composition order:
# 1. mind.asisaga.com MCPTool — universal, always first
# 2. get_domain_mcp_tools() — CXO-specific
# 3. caller-supplied extras

MIND_MCP_TOOL = MCPTool(
    server_label="mind-asisaga",
    server_url=os.environ.get("MIND_MCP_URL", "https://mind.asisaga.com/mcp"),
    require_approval="never",
    project_connection_id=os.environ.get("MIND_MCP_CONNECTION_ID", "mind-mcp-connection"),
)
```

Environment variables needed in every agent container:
- MIND_MCP_URL
- MIND_MCP_CONNECTION_ID

---

## aos-infra drift (open, needs fixing)

| Gap | Current | Target |
|---|---|---|
| Dockerfile.aos-agent COPY | COPY compiled/${PACKAGE_DIR}/ ./${PACKAGE_DIR}/ | COPY compiled/ ./ |
| ENV PYTHONPATH in Dockerfile.aos-agent | Absent | ENV PYTHONPATH=/app:/app/lib/python3.12/site-packages |
| build-infrastructure.yml dispatch target | ASISaga/purpose-driven-agent | ASISaga/purpose-agent |
| aos-kernel azure-ai-agents dependency | azure-ai-agents>=1.1.0 | Remove — use azure-ai-projects==2.2.0 |
| pydantic version conflict | requirements: 2.11.4 | pyproject.toml: >=2.12.0 |

---

## Boardroom application context

The Boardroom is ASI Saga's product — an AI C-suite deliberation system.

CXO agents and their personas:
- FounderAgent: Paul Graham — orchestrator, no domain tools
- CFOAgent: Warren Buffett — specialist, ERP MCP tool
- CMOAgent: Seth Godin × 0.6 + Werner Erhard × 0.4 (TIES) — specialist
- CTOAgent: TBD — pending persona decision
- CEOAgent: TBD — pending persona decision

Pricing: £1,500/£3,500/£8,500 per company per month (not per seat)
Genesis Sprint: £12,000 one-time onboarding

The close: "What does it cost to get Warren Buffett thinking about your
finances perpetually? Until now: not available at any price."

First live Boardroom session: triggered when ASI Saga's own bank balance
and purchase invoices are both in ERPNext. This is Phase 4 of the ERPNext
build plan.

---

## ERPNext build plan (6 phases)

Phase 0: Setup wizard — company: ASI Saga
Phase 1: Suppliers + actual purchase invoices (Azure, Frappe Cloud, GitHub)
Phase 2: Team/payroll
Phase 3: Projects/timesheets
Phase 4: Revenue infrastructure + first Boardroom deliberation on live data
Phase 5: Fundraising
Phase 6: First customer Genesis Sprint

Currently: ready for Phase 0.

---

## LoRA adapters (planned, not yet trained)

| Adapter | Base | Training data |
|---|---|---|
| erhard-lora | Llama-3.3-70B | Erhard seminar transcripts, EST/Forum materials |
| founder-lora | Llama-3.3-70B | Paul Graham essays, YC materials |
| cfo-lora | Llama-3.3-70B | Buffett letters, annual reports, interviews |
| cmo-lora | TIES merge | godin-lora × 0.6 + erhard-lora × 0.4 |

Training pipeline: ASISaga/aos-intelligence
Config: r=16, attention projections, density=0.5

---

## mind.asisaga.com nine dimensions

Confirmed seven:
- Manas (mutable working memory)
- Buddhi (stable discriminating intelligence)
- Ahankara (immutable identity)
- Chitta (universal — shared across all agents)
- Possibility (declared future)
- Integrity (commitment register, append-only)
- Responsibility (authorship stance)

Two remaining: to be confirmed with founder before specifying.

Storage path pattern:
mind.asisaga.com/{application}/{agent}/{Dimension}/{document}.jsonld

Architect namespace: mind.asisaga.com/architect/
Boardroom CXO namespace: mind.asisaga.com/boardroom/{cxo-role}/

---

## Session history summary

9 sessions across 2026-05-10 to 2026-06-07.

Sessions 1-2: AOS architecture, whitepaper v1-3, Azure deployment debugging
Sessions 3-4: Neutral network build, FAS hosting, routing protocol
Sessions 5-6: Full pipeline, Copilot meta-intelligence, spec-driven system
Session 7: Pipeline debugging, whitepaper v4, spec-vs-code audit cycle
Session 8: Philosophy document, mind.asisaga.com architecture, mixin refactor
Session 9: Comprehensive whitepaper, legends as pricing anchor, MAF 1.7.0,
           mixin refactor complete, universal mind MCPTool, architect mind
           system designed, architect container built and pushed to ACR

Full session details: architect/Conversations/ in mind.asisaga.com

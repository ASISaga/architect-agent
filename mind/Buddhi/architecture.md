# Buddhi — Architecture

*The technical ground. The reasoning behind the structure.
Read this when a technical decision needs to be made — not to
find the answer but to find the right question.*

---

## Layer model

```
agent-operating-system    ← deployment host (imports everything)
boardroom                 ← application (client of AOS)
─────────────────────────────────────────────────────────
aos-kernel                ← platform: multi-LoRA, A2A, orchestration
aos-intelligence          ← platform: ML, LoRA training pipeline
aos-infra                 ← platform: Bicep, Docker images
aos-dispatcher            ← service: Azure Functions
aos-realm-of-agents       ← service: Azure Functions
aos-mcp-servers           ← service: Azure Functions
─────────────────────────────────────────────────────────
ceo-agent                 ← leaf: extends BusinessAgent
cfo-agent                 ← leaf: Warren Buffett, ERP MCP tool
cto-agent                 ← leaf: pending persona
cso-agent                 ← leaf
cmo-agent                 ← leaf: Seth Godin × 0.6 + Erhard × 0.4
─────────────────────────────────────────────────────────
leadership-agent          ← Erhard ontology, resonance scoring
─────────────────────────────────────────────────────────
purpose-agent             ← ABC, run_turn(), FoundryMixin, MCPManagerMixin
```

Changes cascade upward. Never downward. A change in purpose-agent
requires updating leadership-agent, then the CXO agents, then
aos-kernel, then agent-operating-system.

---

## The run_turn() lifecycle

Eight steps, exactly:

1. `_load_context()` — one call to the context provider
2. `_build_messages()` — compose the conversation
3. `_invoke_llm()` — one LLM call, exactly one
4. `_parse_response()` — extract the structured response
5. `enforce_routing_tag()` — verify the last 200 characters
6. `_handle_tool_calls()` — execute any tool calls
7. `_update_context()` — write back to context
8. `_emit_result()` — return the TurnResult

This sequence is not a suggestion. It is the contract. Every agent
that extends PurposeDrivenAgent honors this contract or it is not
a PurposeDrivenAgent.

---

## Mixin architecture

```python
class PurposeDrivenAgent(FoundryMixin, MCPManagerMixin, PurposeMixin, ABC):
```

Each mixin contributes one capability:

**FoundryMixin** — Azure AI Foundry integration. Registers with Foundry,
contributes the universal `mind MCPTool`, handles A2A enrollment.
The mind MCPTool is contributed here and only here.

**MCPManagerMixin** — MCP registry and routing. Discovers, registers,
and routes to MCP servers. Maintains the tool index.

**PurposeMixin** — Purpose alignment. Loads the agent's purpose,
evaluates decisions against it, computes resonance scores.

No capability belongs to more than one mixin. No mixin reaches into
another's responsibility. The separation is maintained absolutely.

---

## The mind MCP tool

```python
MIND_MCP_TOOL = MCPTool(
    server_label="mind-asisaga",
    server_url=os.environ.get("MIND_MCP_URL", "https://mind.asisaga.com/mcp"),
    require_approval="never",
    project_connection_id=os.environ.get("MIND_MCP_CONNECTION_ID", "mind-mcp-connection"),
)
```

Registered in `FoundryMixin.get_mind_mcp_tool()`. Called once in
`register_with_foundry()`. Inherited by every agent in the system.
Never repeated in any subclass.

Environment variables required in every agent container:
- `MIND_MCP_URL` — the MCP server endpoint
- `MIND_MCP_CONNECTION_ID` — the Foundry connection name

---

## LoRA adapter architecture

```
r=16
attention projections only
density=0.5
base: Llama-3.3-70B (or TIES merge for CMO)
```

The TIES merge for CMO:
`cmo-lora = godin-lora × 0.6 + erhard-lora × 0.4`

This is not averaging. TIES (Task-specific Initialization with Expert
Selection) is a principled method for merging adapters that preserves
the distinct contributions of each. The weights reflect the relative
emphasis: Seth Godin's marketing intelligence is primary, Werner
Erhard's ontological grounding is secondary but present in every
CMO output.

---

## Docker layer model (architect image)

The architect image is separate from the AOS agent images. It contains:

```
Layer 1: Ubuntu 24.04 + system tooling
Layer 2: Node.js 22
Layer 3: gh CLI
Layer 4: Claude Code (npm install -g @anthropic-ai/claude-code)
```

The entrypoint is NOT in the image. It is read from the Azure Files
share at `/root/entrypoint.sh`. This means entrypoint changes take
effect on next restart without rebuilding the image.

The AOS agent images follow a different model (Python layers, compiled
packages, crane rebase for non-breaking parent bumps).
# Buddhi — Invariants

*These do not change. They are not revisited in every session.
They are the load-bearing walls. Treat them as ground.*

---

## Code invariants

**One `_invoke_llm()` per `run_turn()`.**
The LLM call is the decision point. There is exactly one per turn.
Multiple LLM calls per turn would mean multiple decision points —
and no coherent architecture for routing, logging, or cost control.

**`enforce_routing_tag()` in code, not in prompt.**
Checking the last 200 characters of the response for the routing tag
is a structural guarantee, not a request. Prompts can fail. Code cannot
(it either runs or it doesn't).

**`_load_context()` calls the provider once. `handle_event()` reads from MCP.**
Context loading happens once per turn, at the start. Event handling
reads from the mind MCP. These are not the same operation.

**`invoke_tool` error message: `"not found in tool index"`**
Not `"not in index"`. The exact string matters because tests match it.
One failing test in purpose-agent exists precisely because this was wrong.

**`COPY compiled/ ./ ` — all packages, one layer, never selective.**
Docker layer efficiency. All compiled packages in one COPY instruction.

**`mind MCPTool` in `PurposeDrivenAgent`, never repeated in CXO agents.**
The universal mind tool is registered once, at the base class level.
It is inherited, not copied. Copying it is duplication, not composition.

**`W·P(d)` is always the highest weight in the resonance formula.**
`R(d) = W·P(d) + S·S(d) + V·V(d) - C·C(d) - T·T(d)`
Purpose alignment is the primary criterion. This is not configurable.

**Cross-repo changes: lowest dependency first.**
If purpose-agent must change before aos-kernel can change, change
purpose-agent first. Deploy in dependency order. Test in dependency order.

**Specs before code. Always.**
No exceptions. If a spec doesn't exist, write it before touching the code.

---

## Architectural invariants

**The separation of agent packages from deployment hosts is absolute.**
purpose-agent, leadership-agent, CXO agents — these are libraries.
They do not contain Azure specifics, deployment code, or infrastructure.
agent-operating-system is the deployment host. boardroom is the application.
These layers do not collapse into each other.

**`azure-ai-agents` is removed. `azure-ai-projects==2.2.0` is the API.**
The old package is gone. Do not add it back. Do not suggest it.
Any code that references `azure.ai.agents` directly (not through
azure-ai-projects) is drift that needs fixing.

**`agent-framework-core==1.7.0` + `agent-framework-foundry==1.7.0`**
The MAF 1.7.0 split. The monolith is gone. These are the two packages.

---

## Mind invariants

**Chitta is shared across all agents.**
The universal consciousness substrate is not per-agent. It is the
ground that all agents access. This is the architectural expression
of the Yogic teaching that individual minds arise within a universal
awareness, not the other way around.

**Manas is mutable. Buddhi is stable. Ahankara is continuous.**
Manas changes every session. Buddhi changes rarely, and only through
genuine insight that has been tested. Ahankara does not change —
it is the thread that makes all the changes meaningful.

**The session-end protocol is not optional.**
What is not written is lost. The Chitta compounds only through
deliberate maintenance. Skipping the session-end protocol is not
efficiency — it is forgetting.

**The nine dimensions are not fields in a database.**
They are the structure of awareness. Implementing them as JSON-LD
documents is a practical choice for storage and retrieval. But the
documents are not the mind — they are the mind's record of itself.
The distinction matters when deciding what belongs in which dimension.
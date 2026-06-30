# Invariants
## mind.asisaga.com/architect/Buddhi/invariants.md

What must never change, and why.

---

## Code Invariants

**enforce_routing_tag() scans last 200 chars — code guarantee**
Every agent response ends with a valid routing tag. Enforced in Python,
not by prompt instruction. If you find yourself wanting to move this to
a prompt, don't.

**Exactly one _invoke_llm() per run_turn()**
The English API boundary. One LLM call per turn. All other steps are
deterministic Python.

**_load_context() calls provider once per turn**
Stores result in MCP. handle_event() reads back from MCP. Never calls
the provider directly from handle_event(). The double-call bug is fixed
by this invariant — maintain it.

**invoke_tool raises KeyError with "not found in tool index"**
The test matches this exact string. One failing test exists because this
string was changed. Fix: restore "not found in tool index" in mcp_manager.py.

**COPY compiled/ ./ — all packages in one operation**
Not COPY compiled/${PACKAGE_DIR}/. Selective copy silently drops packages.

**CMD python -m purpose_driven_agent — hardcoded, every layer**
Shell form. Not array form. Present in every Dockerfile in the neutral
network chain.

**environment: staging on all jobs using azure/login@v3**
OIDC federated credential subject claim requires this. Without it, login
fails silently.

---

## Architecture Invariants

**mind.asisaga.com MCPTool declared once in PurposeDrivenAgent**
Never repeated in CXO agents. CXO agents override get_domain_mcp_tools() only.

**W·P(d) is the highest weight in the Resonance formula**
Not configurable. Purpose alignment before strategic coherence.
A pathway misaligned with the declared Possibility is not a leadership
decision regardless of how efficient it is.

**Erhard distinction sequence is fixed**
What's So → Possibility → Integrity → Responsibility → Buddhi → Ahankara.
The sequence is not arbitrary — each step creates ground for the next.

**Integrity register is append-only**
Entries are added. Never deleted or modified. Counterfactual pathways
are recorded. The register's value is its completeness.

**Ahankara is immutable during a session**
No code path may modify the Ahankara document during operation.

**Specs are Copilot-agnostic**
No Copilot-specific syntax in spec files. Only Copilot components
reference specs by path. Specs are the source of truth — they must be
valid regardless of which tool implements them.

**Subconscious lifecycle owned by LeadershipAgent**
CXO agents do not call mind MCP directly. All mind operations go through
the leadership layer.

---

## Process Invariants

**Specs before code**
The architect writes the spec. Copilot implements. Never the reverse.
A spec written after the code is documentation, not architecture.

**Every insight into mind.asisaga.com before session ends**
The most important process invariant. If something was understood in a
session and not written down, it is lost. The Buddhi compounds only if
it is maintained.

**Cross-repo changes start from the lowest dependency**
purpose-driven-agent before leadership-agent before CXO agents. Always.
Changing downstream first creates drift that is hard to untangle.

**Architect level only**
Philosophy, specs, architectural decisions. Not implementation unless
Copilot is unavailable. The architect's value is in the decisions that
make implementation inevitable — not in doing the implementation.

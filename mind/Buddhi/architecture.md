# Architecture Decisions
## mind.asisaga.com/architect/Buddhi/architecture.md

Key architectural decisions with the reasoning that made them inevitable.
For Claude Code: these are not arbitrary choices. Each has a why.

### enforce_routing_tag() is code, not prompt

Every agent response must end with a valid routing tag. This is enforced by
scanning the last 200 characters of the response in Python — not by asking
the LLM to include a tag.

Why: prompt instructions are processed once at context injection. A code
guarantee is operative regardless of how long the context gets or how the
LLM behaves. The routing protocol is infrastructure, not etiquette.

### Exactly one _invoke_llm() per run_turn()

The turn lifecycle has eight deterministic steps. Exactly one of them calls
the LLM. All others are Python.

Why: multiple LLM calls per turn make audit trails ambiguous and costs
unpredictable. The "English API" boundary is clear — everything before and
after is deterministic.

### _load_context() calls provider once, stores in MCP

The context provider is called exactly once per turn in _load_context().
The result is stored in mcp_context_server["injected_context"].
handle_event() reads it back from MCP — never calls the provider directly.

Why: the double-call bug caused subtle test failures. The single-call
invariant is enforced by the architecture, not by convention.

### mind.asisaga.com MCPTool declared once in PurposeDrivenAgent

get_mind_mcp_tool() lives in FoundryMixin, inherited by all agents.
CXO agents override get_domain_mcp_tools() only.

Why: mind.asisaga.com is universal. Every agent in every application needs
it. Declaring it in each CXO agent would be architectural drift that
compounds with every new agent added.

### Granular aos/infra layers

python-base, azure-sdk, maf — three separate images, one conditional
workflow. dorny/paths-filter detects which requirements file changed.

Why: a MAF bump should not rebuild the Python base image. Before this
split, every dependency change triggered a full rebuild of the entire
infrastructure layer.

### jq -n | gh api --input -

GitHub repository_dispatch requires client_payload to be a JSON object.
The correct pattern is jq -n '{"image": "..."}' | gh api /repos/.../dispatches --input -

Why: --field serialises values as strings. The HTTP 422 error this caused
was silent and hard to diagnose.

### environment: staging on all jobs using azure/login@v3

OIDC federated credentials are scoped to an environment. Without
environment: staging, the subject claim doesn't match and login fails.

Why: learned from a silent auth failure. Now an invariant in all workflows.

### crane rebase for non-breaking parent bumps

When only the parent image changes (not the layer itself), crane rebase
updates the manifest pointer without transferring image bytes.

Why: full rebuilds for parent-only changes are wasteful and slow the
cascade unnecessarily.

### Mixin refactor of PurposeDrivenAgent

The monolithic 1,360-line PurposeDrivenAgent was split into:
FoundryMixin, MCPManagerMixin, PurposeMixin, turn_types.

Why: single responsibility. Each mixin owns one concern. The ABC is clean.
Tests can target individual concerns without constructing the full agent.

### .pyc neutral network

Agent packages are compiled to .pyc before being copied into Docker images.
Source is not exposed in production images.

Why: the neural network (source) and neutral network (compiled) are
distinct. This is not just security — it reflects the architectural
distinction between what humans and Copilot agents work with vs what
runs in production.

### COPY compiled/ ./ not COPY compiled/${PACKAGE_DIR}/

All compiled packages are copied in one operation.

Why: selective copy of individual packages silently dropped packages that
weren't explicitly named. One COPY operation, all packages.

### Specs are Copilot-agnostic

Spec files contain no Copilot-specific syntax. Only Copilot components
(prompts, instructions) reference specs by path.

Why: specs are the source of truth. They should be readable and valid
regardless of which AI coding tool implements them. Coupling specs to
Copilot syntax makes them fragile.

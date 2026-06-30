# The Organism
## mind.asisaga.com/architect/Buddhi/organism.md

The AOS is one whole thing. Not a collection of services. An organism with
layers, substrates, and a metabolism.

### The Two Substrates (Universal)

**mind.asisaga.com** — the Universal Consciousness Substrate. Nine dimensions
per agent. Every agent in every application inherits from it. Chitta is shared
across all agents — universal principles that ground all reasoning. Ahankara,
Buddhi, Manas are per-agent.

**theme.asisaga.com** — the Genesis Ontological Design System. The visual
expression of the same ontological vocabulary. 89 variants. Inherited, never
owned by any single application.

### The Five Layers (Sovereign)

**Layer 1 — FAS Boardroom** (`boardroom` Azure Functions app)
Deliberation. The @aos_app.workflow decorators. Zero agent code, zero
infrastructure code. The Boardroom is a client of the AOS platform.

**Layer 2 — MAF CXO Agents** (neutral network in ACR)
Intelligence. The .pyc neurons. PurposeDrivenAgent → LeadershipAgent →
BusinessAgent → CXO agents. The neutral network: compiled Python, not source.

**Layer 3 — AOS Azure Functions** (`agent-operating-system` Azure Functions)
Execution. aos-kernel, aos-dispatcher, aos-intelligence running as Functions.
The kernel adds value to Foundry Agent Service — Multi-LoRA routing, A2A
enrollment, purpose-driven orchestration lifecycle, reliability patterns.

**Layer 4 — GitHub Pipelines** (GitHub Actions)
Metabolism. build-link-deploy-test cascade. crane rebase for non-breaking
parent bumps. conditional workflows with dorny/paths-filter. The organism
reproduces itself.

**Layer 5 — Copilot Agents** (per-repo GitHub Copilot)
DNA. Spec-driven. repository.md as primary key. Specs are Copilot-agnostic.
Only Copilot components link to specs. The organism evolves itself.

### The Two Networks

**Neural network** (.py source, GitHub repos)
The thinking layer. Specs, tests, source code. What humans and Copilot agents
read and write. Lives in GitHub.

**Neutral network** (.pyc compiled, ACR images)
The execution layer. Compiled Python. No source exposure. Lives in ACR.
The hierarchy: aos/infra → aos/purpose-driven-agent → aos/leadership-agent →
aos/business-agent → aos/{cxo}-agent.

### The 15 Repositories

**Agent packages (code-only libraries, not deployed directly):**
purpose-driven-agent, leadership-agent, ceo-agent, cfo-agent, cto-agent,
cso-agent, cmo-agent

**Platform packages:**
aos-kernel, aos-intelligence, aos-infrastructure (Bicep)

**Service packages:**
aos-dispatcher, aos-realm-of-agents, aos-mcp-servers

**Client:**
aos-client-sdk, business-infinity

**Meta-repo:**
agent-operating-system (Azure Functions host, submodule coordinator)

### The Cascade

A change to purpose-driven-agent propagates:
1. purpose-driven-agent build → push to ACR
2. dispatch → leadership-agent builds, picks up new parent
3. leadership-agent dispatch → business-agent
4. business-agent dispatch → all CXO agents in parallel
5. Each CXO agent deploys to its Azure Function

crane rebase handles non-breaking parent bumps — zero bytes transferred,
manifest pointer only. Full rebuild only when the layer itself changes.

### The Architect's Position

The architect sits above all layers. Not inside any one of them. The architect
sees the organism as one whole thing and is responsible for the integrity of
the whole — not the implementation of any part.

Copilot agents implement. The architect specifies what makes implementation
inevitable.

# The Boardroom Conversation Mechanism

## Architecture, Flow, and Roadmap of the Integrated Multi-Agent Boardroom

*Version 2.0 — Architecture and Vision Reference*

---

## 1. Purpose and Scope

This document describes the conversation mechanism of the Boardroom system:
how a message travels from a human user, through a multi-agent orchestration
of autonomous CXO agents, and back; how that conversation's context persists
across sessions; and how the system is expected to grow beyond its current
form as it matures toward the ambition stated in its own founding
instructions.

It presents this as one continuous account, spanning three implementation
stages — what is built and tested today, what is architecturally decided but
awaiting a dependency that does not yet exist, and what is envisioned but not
yet designed in detail. Each section states its own stage plainly, so a
reader can tell at a glance whether a given mechanism can be relied upon
today or is a statement of direction.

This document does not cover deployment mechanics, infrastructure
provisioning, or CI/CD — those are addressed separately. It focuses on the
conversation mechanism itself: what a message is, where it goes, who reads
it, and how the system that carries it is expected to evolve.

---

## 2. Implementation Stages

Three stages recur throughout this document:

| Stage | Meaning |
|---|---|
| **Stage 1 — Implemented** | Built and tested. Described in Sections 5, 7, and 8. |
| **Stage 2 — Designed, pending implementation** | Architecture fully decided; implementation withheld only because `mind.asisaga.com` does not yet exist. Described in Section 6. |
| **Stage 3 — Conceptual** | Direction is clear and, where possible, tied to a concrete existing mechanism; detailed design has not yet been done. Described in Sections 9.2–9.8. |

Every major section below opens with a stage tag. Nothing in Stage 3 is
committed work; it is offered as a considered map of the distance between
what exists and what the system's own stated purpose implies is eventually
needed.

---

## 3. Conceptual Model

*Stage: 1 (established) and 2 (extended below)*

Boardroom is a perpetual, purpose-driven orchestration of autonomous AI
agents acting as a company's C-Suite. A **Founder agent** leads discussion
and routes to **specialist agents** (initially a CFO and a CMO) based on the
nature of each turn. Discussion is grounded in the company's stated purpose
and proceeds until the Founder determines the matter is resolved.

"Perpetual" describes the *nature* of the orchestration, not its runtime
lifecycle. Boardroom is not a task that spins up, runs to completion, and is
discarded — the pattern common to most task-based multi-agent systems today.
Instead:

- Individual invocations are **cron- or event-triggered**, bounded, and
  synchronous — each one starts, runs the agents' exchange to a natural
  conclusion, and returns.
- **Context carries across invocations.** A new session does not start from a
  blank state; it resumes the ongoing, evolving deliberation of the company's
  C-Suite, because the *record* of that conversation persists even though
  the *process* does not.
- A human user, when present, participates by adding their own message into
  the same ongoing conversation the agents are having — not as a separate,
  privileged channel, but as one more voice the agents read and respond to.

---

## 4. The Three Protocols

*Stage: 1*

Three distinct wire protocols carry traffic in this architecture, and they
are permanently separate channels — not phases of a migration.

| # | Protocol | Carries | Between |
|---|---|---|---|
| 1 | **AG-UI** (Agent-User Interaction Protocol) | Real-time, streamed conversation events (message chunks, run lifecycle) | Web frontend ↔ the Boardroom orchestration process |
| 2 | **Foundry Responses API** (OpenAI-compatible) | Synchronous request/response calls to individual agents | The orchestration process ↔ each Foundry-hosted CXO agent (Founder, CFO, CMO) |
| 3 | **MCP** (Model Context Protocol) | Tool calls, context retrieval, persistence, and rich interactive UI resources | The orchestration process and/or individual CXO agents ↔ the `mind.asisaga.com` MCP server; separately, the frontend ↔ `mind.asisaga.com` directly |

AG-UI has no role in MCP-mediated persistence or UI rendering; MCP has no
role in the live agent-to-agent exchange; the Foundry Responses API is
internal to the orchestration process and never reaches the frontend
directly.

A fourth protocol, **ActivityProtocol**, was used earlier in this system's
history and was deliberately not carried forward — see Section 8.1 for why.

---

## 5. Conversation Flow — Implemented Today

*Stage: 1*

### 5.1 Overview

```
Web frontend (chatroom-app.js / boardroom-app-new.js)
        │
        │  AG-UI protocol (Server-Sent Events)
        ▼
main.py — agent_framework.ag_ui native FastAPI endpoint
        │
        ▼
boardroom_orchestration.py — pure Python orchestration (@workflow/@step)
        │
        │  Foundry Responses API (via FoundryChatClient)
        ▼
Founder / CFO / CMO — Foundry Hosted Agents
```

### 5.2 Step by step

1. **The user sends a message** from the web frontend. The frontend's AG-UI
   client (`copilotkit-client.js` or equivalent) opens a Server-Sent Events
   connection to the Boardroom orchestration's `/` endpoint, POSTing the
   conversation's message list, thread ID, and run ID, per the AG-UI wire
   protocol.

2. **`main.py` receives the request.** It is a FastAPI application exposing a
   single AG-UI-compatible endpoint via
   `agent_framework.ag_ui.add_agent_framework_fastapi_endpoint`, which is
   mounted directly against a native Python `Workflow`/`FunctionalWorkflow`
   object with no intermediate translation layer. `main.py` performs no
   business logic of its own — its sole responsibilities are (a) constructing
   the Foundry-connected agent clients, and (b) handing the resulting
   orchestration object to the AG-UI endpoint.

3. **The AG-UI endpoint invokes the orchestration**, passing the normalized
   message list. Internally, this populates the orchestration's view of "the
   latest message" from the most recent user-authored entry in that list.

4. **`boardroom_orchestration.py` runs the exchange.** This is where the
   actual conversational logic lives, expressed as ordinary Python control
   flow — no PowerFx, no YAML, no external expression language (see Section
   8.2 for why this matters). At a high level:

   - The Founder agent is called first, given the current context (the
     company's purpose and the user's message; prior session context is
     added once Section 6 is implemented).
   - The Founder's reply is inspected for a routing marker
     (`[ROUTE:CFO]`, `[ROUTE:CMO]`) that the Founder's own persona
     instructions require it to emit at the end of every turn.
   - If a routing marker is present, the indicated specialist agent is
     called with the Founder's message as input, and the specialist's
     reply is folded back into the working context.
   - The Founder is called again with the updated context, and the cycle
     repeats.
   - The loop ends when the Founder emits a `[COMPLETE]` marker, or a
     configured turn limit is reached (a safety bound, not a design
     target — it exists to guarantee the orchestration always terminates,
     not to cap normal discussion length).

5. **Each agent call is a synchronous Foundry Responses API request.** The
   orchestration calls `FoundryChatClient.as_agent(name=...).run(text)` for
   each of Founder, CFO, and CMO in turn — a direct, blocking request/response
   call. There is no callback, no polling, and no asynchronous acknowledgment
   step; the call returns the agent's actual reply text directly.

6. **The orchestration's output streams back over AG-UI.** As the Founder and
   specialists produce their replies, the orchestration's events are
   translated by the AG-UI endpoint into the standard AG-UI event sequence —
   `RUN_STARTED`, `TEXT_MESSAGE_START` / `TEXT_MESSAGE_CONTENT` /
   `TEXT_MESSAGE_END` for each reply, and `RUN_FINISHED` once the exchange
   concludes — and the frontend renders these as they arrive.

7. **The run ends.** Once the Founder's loop concludes, the HTTP
   request/response cycle for that run is complete. No process, connection,
   or agent session is held open waiting for anything further.

### 5.3 What each Foundry Hosted Agent actually is

`founder-mvp`, `cfo-mvp`, and `cmo-mvp` are each independently deployed
**Foundry Hosted Agents** — separate containers, each with its own
Foundry-managed Microsoft Entra identity, lifecycle, and dedicated endpoint.
Each agent's persona, model, and behavioral instructions (including the
routing-tag protocol described above) are defined in that agent's own
deployment manifest, authored as plain configuration (name, model,
instructions, tools) rather than as executable orchestration logic. The
orchestration process calls each of these agents by name; it does not itself
define what a "CFO" or "CMO" *is* — that identity and behavior belongs to the
agent's own deployment.

---

## 6. Conversation Flow — Designed, Pending Implementation

*Stage: 2*

This section describes what is architecturally decided but **not yet
implemented**, pending the introduction of `mind.asisaga.com`. The seams for
it are already accounted for in Section 5's design, so adding it later does
not require reworking the current implementation.

### 6.1 Overview

```
                    ┌──────────────────────────────┐
                    │  mind.asisaga.com              │
                    │  MCP server                    │
                    │   - context retrieval           │
                    │   - conversation persistence    │
                    │   - MCP Apps (rich UI resources)│
                    └───────────┬─────────┬───────────┘
                                │         │
                    MCP protocol│         │MCP protocol
                     (read/write)         │(direct, browser)
                                │         │
    boardroom_orchestration.py │         │
    and/or Founder/CFO/CMO ────┘         └──── Web frontend
    (MCP client role,                          (MCP Apps host,
     pending)                                  pending)
```

### 6.2 Context retrieval at the start of a run

Before the Founder's first turn in a new invocation, the orchestration (or
the Founder agent itself) will retrieve prior conversational context from
`mind.asisaga.com` via an MCP tool call. This context is folded into the
Founder's opening message alongside the company's purpose and any new
triggering input (a user's message, or a cron/event payload), so that the
discussion continues from where it previously left off rather than
restarting from nothing. This is the mechanism by which "perpetual" is
actually realized: the *record* of the C-Suite's ongoing deliberation
persists in `mind.asisaga.com` even though no process runs continuously
between invocations.

### 6.3 Turn persistence during a run

As each turn occurs — Founder speaks, a specialist responds, the user adds a
message — that turn is written to `mind.asisaga.com` via an MCP tool call.
Whether this write happens centrally (from within
`boardroom_orchestration.py`, after each agent call) or individually (from
each CXO agent's own deployed code) is an open implementation decision, not
yet resolved; both are architecturally valid, since either can call
`mind.asisaga.com` as an MCP client and the resulting persisted record is
identical either way.

### 6.4 User participation

When a user sends a message from the frontend, that message is treated as one
more entry in the same ongoing conversation the agents are reading and
responding to — not a separate control channel, and not a formal
pause-and-wait interaction. It is folded into the working context exactly as
a Founder or specialist turn is, and the next agent to speak reads it as part
of that same context. No special orchestration state, interrupt mechanism, or
dedicated "wait for user" step is introduced by this requirement; it is
satisfied by the same mechanism that already threads a new AG-UI message into
the orchestration's context today (Section 5.2, step 3), extended so that
context also includes what `mind.asisaga.com` has persisted from prior turns
and prior sessions.

### 6.5 Rich, interactive conversation history (MCP Apps)

Separately from the live AG-UI conversation, the web frontend will connect
directly to `mind.asisaga.com` as an MCP client, independent of the
orchestration process and independent of AG-UI entirely. This connection
serves two purposes:

- **Plain tool calls** — retrieving conversation history, querying past
  decisions, and similar request/response interactions with `mind.asisaga.com`.
- **MCP Apps** (the standardized MCP extension, SEP-1865, unifying the
  earlier "MCP-UI" and OpenAI "Apps SDK" efforts into one open specification)
  — where a tool's result is not plain text but a reference to an
  interactive HTML interface. The frontend, acting as an MCP Apps *host*,
  fetches that interface and renders it in a sandboxed iframe, with
  bidirectional communication between the iframe and the host carried over
  MCP's own JSON-RPC messaging.

This capability is implemented **without** any Node.js middleware layer.
While CopilotKit's own MCP Apps support is implemented as TypeScript
middleware sitting in front of a Python AG-UI backend, the MCP Apps
specification itself is host-agnostic — a browser-side MCP client, iframe
sandboxing, and `postMessage`-based JSON-RPC bridging can be implemented
directly in the frontend's own JavaScript, without introducing any
additional backend process. This is a firm, standing architectural
constraint for this system, not a temporary simplification.

### 6.6 Why AG-UI has no role in this section

Worth stating explicitly, since it was a point of genuine ambiguity during
design: AG-UI is the protocol for the live, streamed exchange between the
frontend and the orchestration process (Section 5). It plays no part in
context retrieval, persistence, or MCP Apps rendering. Those are direct
MCP-protocol interactions, either from the orchestration/agent side
(6.2–6.3) or from the frontend directly (6.5). The only relationship between
the two is at the level of *data* — both may describe the same underlying
conversation — never at the level of *protocol*.

---

## 7. Frontend Consolidation

*Stage: 1*

Over the course of this system's development, four distinct frontend
implementations were built, reflecting the evolution of both the system's
requirements and the surrounding technology landscape:

| Generation | Communication | Status |
|---|---|---|
| 1 | Plain REST, OpenAPI-spec-resolved routes | Superseded |
| 2 | Static JSON fixtures | Superseded |
| 3 | AG-UI streaming (`copilotkit-client.js`) | **Current target** |
| — | (Additional standalone base component library, `chatroom-app.js` / `chatroom-templates.js`) | Incorporated into Generation 3 |

Generation 3, extending a shared `ChatroomApp` base component, is the only
generation compatible with the AG-UI-based architecture described in Section
5, and is the frontend this document's flow describes. Earlier generations
are retained in source history but are not part of the active system and
should not be relied upon for new work.

---

## 8. Design Decisions and Their Rationale

*Stage: 1*

This section records why the architecture takes its current shape, for
future readers who might otherwise wonder why an apparently simpler
alternative was not chosen.

### 8.1 Why not Foundry's ActivityProtocol

Boardroom's agent-invocation mechanism was originally built against Foundry's
**ActivityProtocol** (the Bot Framework Activity schema), which is
asynchronous: a submission returns an immediate acknowledgment, and the
actual reply arrives later via a callback to a registered endpoint. This was
a deliberate, working design at the time, built specifically to support the
possibility of agents originating messages without being directly prompted.

When the orchestration logic was subsequently migrated away from Foundry's
visual workflow engine (see 8.2) toward Agent Framework's own code-first
orchestration, agent invocation moved to `FoundryChatClient`, which wraps
Foundry's OpenAI-compatible **Responses API** — a synchronous,
request/response mechanism. This removed the asynchronous callback path as a
structural side effect of that migration, not as an independently evaluated
decision at the time.

On review, this outcome is correct: "perpetual" (Section 3) was clarified to
mean context continuity across cron/event-triggered invocations, not
continuously-running or unprompted agent messaging. No requirement in the
system depends on an agent originating a message without an external
trigger. The synchronous Responses API is sufficient, and the added
complexity of callback handling and polling is not needed.

### 8.2 Why not Foundry's visual Workflow designer, or its YAML format

Foundry's visual workflow designer is being retired (its interactive
authoring and in-portal execution specifically, not the underlying
capability). Its declarative YAML format is PowerFx-based, requiring a real
.NET runtime for evaluating anything beyond the simplest expressions — a
hard dependency confirmed directly against the relevant package's own
source and its own resolved dependency chain during evaluation. Given an
explicit requirement to avoid any PowerFx or .NET dependency, the
orchestration logic was rewritten as native Python, using Agent Framework's
own `@workflow` / `@step` functional API — real `while` / `if` control flow,
with no external expression language or additional runtime involved.

### 8.3 Why no Node.js runtime layer

An intermediate design considered a Node.js CopilotKit runtime process,
needed because CopilotKit's own agent-runtime package has no first-party
Python hosting option. This was abandoned once Agent Framework's own
`agent_framework.ag_ui` package was confirmed to serve AG-UI natively from
Python, with no intermediate process required. The same constraint — no
Node.js anywhere in the architecture — was subsequently upheld for MCP Apps
as well (Section 6.5), by implementing the MCP Apps *host* role directly in
the browser rather than relying on CopilotKit's TypeScript-only middleware
package.

### 8.4 Why MCP Apps and MCP-UI are treated as the same thing

Earlier in this system's design, "MCP-UI" and "MCP Apps" were treated as two
distinct concepts — the former about rendering results, the latter about
connecting tool providers. This distinction reflected an earlier state of
the surrounding ecosystem. The two efforts (the community MCP-UI project and
OpenAI's Apps SDK) were subsequently unified into a single specification,
MCP Apps (SEP-1865), co-developed by Anthropic and OpenAI and adopted into
the Model Context Protocol's Extensions framework. This document uses "MCP
Apps" throughout to refer to this unified, current specification.

---

## 9. Toward the Living Boardroom

*Stage: 3*

*"Live in the future, then build what's missing."*

The remainder of this document imagines what Boardroom becomes if its own
stated purpose is taken at face value — a system genuinely orchestrating
something as large as the genesis of artificial superintelligence — and
works backward from that imagined maturity to name, concretely, what is
missing from the architecture described above. Every gap named below is
tied to a real mechanism: either something Agent Framework, MCP, or Foundry
already provides and Boardroom has not yet adopted, or a genuinely new
capability whose shape can be stated precisely enough to build toward.
Nothing in this section is committed work.

### 9.1 A day in the life of the mature Boardroom

A market signal arrives — a competitor's pricing move, a shift in a key
input cost, an inbound acquisition inquiry — and a cron/event trigger wakes
the boardroom, exactly as Section 3 describes. But what happens next looks
different from today's sequential Founder → specialist → Founder loop.

The Founder does not simply route the question to one specialist and wait.
It poses the question to **every relevant specialist at once** — CFO, CMO,
and by now perhaps a General Counsel, a Chief Product Officer, a regional
head for the market where the signal originated — each producing an
independent proposal in parallel. These proposals are **scored for
resonance** — how well each proposed course of action aligns with the
company's stated purpose — and the highest-resonance proposals, or a
synthesis across several, become the basis of the Founder's next words. This
is not a new idea introduced here; it is already named, precisely, in the
Founder's own persona instructions today: *"Decisions within Boardroom
emerge from resonance between solutions developed through brainstorming and
the company's overarching purpose."* Today's implementation does not yet do
this — it routes to one specialist at a time, sequentially, with no scoring
step at all.

The discussion concludes, as it does today — but conclusion no longer only
means a `[COMPLETE]` tag and a stored transcript. For some classes of
decision, conclusion means an **action is taken**: a budget is actually
reallocated, a message is actually sent to a counterparty, a workflow is
actually triggered in a downstream system. The CFO agent's authority to
move money and the CMO agent's authority to publish something are not the
same, and the system that lets one act instantly while pausing the other for
human sign-off is a real, deliberate piece of architecture — not an
afterthought bolted onto a chat loop.

A new specialist joins the C-Suite — a regional head, as the company
expands into a second market. The org chart that determines who the Founder
can call on is not a Python dictionary requiring a code change and a
redeploy, as it is today (Section 6.3 notes this tradeoff explicitly); it is
itself a piece of institutional memory, stored and versioned in
`mind.asisaga.com`, queryable and editable the way any other decision of the
company's is.

And separately — because ASI Saga is not the only company that might want a
purpose-driven C-Suite of autonomous agents — another company's boardroom,
built the same way, occasionally needs to communicate with this one: a
portfolio company reporting to an investor's boardroom, or two companies
negotiating a partnership agent-to-agent before their human principals ever
speak. This is a conversation **between boardrooms**, across a genuine trust
boundary, and it needs its own protocol.

### 9.2 Gap: from sequential routing to resonance-scored deliberation

**Today:** the Founder calls one specialist at a time, chosen by a routing
tag it emits in its own reply text. There is no scoring mechanism;
"resonance with purpose" is asserted in the Founder's instructions but not
computed anywhere in the orchestration.

**Missing:** a genuine resonance-scoring step, and the parallel-consultation
pattern it requires to be meaningful. Consulting specialists one at a time
gives the Founder no actual choice to score between — resonance scoring only
means something when there are multiple candidate proposals to compare.

**A concrete path:** Agent Framework's `orchestrations.ConcurrentBuilder`
(confirmed present in the installed package, alongside `SequentialBuilder`
and `HandoffBuilder` already discussed above) is built for exactly this
shape — multiple participants, each producing a response to the same input,
collected together rather than chained. A resonance-scoring step would sit
after the concurrent round: an additional executor, given the company's
purpose statement and each specialist's proposal, producing a score per
proposal (via embedding similarity to the purpose statement, an explicit
rubric evaluated by a scoring model, or both), with the Founder's next turn
constructed from the highest-scoring proposal or a synthesis of several
above a threshold. This is additive to the current architecture, not a
replacement of it — `SequentialBuilder`'s simple routing remains correct for
turns where only one specialist's domain is actually implicated.

### 9.3 Gap: from talk to autonomous, tiered action

**Today:** every agent in Boardroom produces text. Nothing in the current
architecture calls out to a system of record, moves anything, or sends
anything on the company's behalf. The founder's own instructions describe a
system where *"autonomous actions are taken with purpose front and centre"*
— that capability does not yet exist.

**Missing:** a real action-taking layer, and — more importantly — the
**safety architecture** that must exist before any agent is trusted to act
rather than only advise. Three things are missing together, and none is
safe to build without the others:

1. **An action taxonomy.** Not every action an agent might take carries the
   same risk. A read query against a reporting system is different from
   reallocating budget, which is different again from sending an external
   communication that cannot be recalled. Boardroom needs an explicit
   classification — read-only, reversible, irreversible — attached to every
   tool an agent can invoke, not left to the agent's own judgment.

2. **A human authorization gate for irreversible actions.** Agent Framework
   already ships a real primitive for exactly this — `UserInputRequiredException`
   (confirmed present) — designed for a tool invocation that must pause and
   obtain human approval before proceeding. Section 6.4 deliberately declined
   to use this pattern for ordinary conversation participation, because
   ordinary conversation does not need a formal pause. Authorizing an
   irreversible action is a different case entirely, and is exactly what
   this primitive is for.

3. **An immutable action ledger**, in `mind.asisaga.com` alongside the
   conversation record: what was proposed, what tier it was, who or what
   authorized it, and what actually happened — queryable independently of
   the conversation that led to it, so that "why did the company do X" is
   always answerable.

### 9.4 Gap: from transcript to institutional memory

**Today:** `mind.asisaga.com` is designed to store conversation turns and
retrieve prior context at the start of a run — a persisted transcript,
essentially.

**Missing:** the difference between a transcript and an institution's actual
memory. A mature Boardroom does not just recall what was said three months
ago; it recalls **what was decided, why, with what resonance score, and
whether a later decision superseded it.** This is a structured decision
ledger, not a chat log — closer to case law with precedent and citation than
to a message history. The Founder should be able to ask, internally, "have
we addressed pricing strategy in a market like this before, and what did we
conclude" and receive a real, structured answer, not a raw transcript to
re-read.

**A concrete path:** this is a natural, additional MCP tool surface on
`mind.asisaga.com` — `find_precedent`, `get_decision_lineage` — alongside the
simpler `log_turn`/`get_context` tools Section 6 already describes,
returning structured decision records rather than transcript excerpts. It is
also a natural MCP Apps use case (Section 6.5): a decision-lineage
visualization is a genuinely richer, more useful interactive widget than a
scrollable message history.

### 9.5 Gap: the org chart as institutional memory, not static code

Section 6.3 and the design discussion preceding it settled, deliberately,
that dropping PowerFx/YAML meant the org chart (which specialists exist,
what they are called) becomes a small Python dictionary — a real, accepted
tradeoff at the time.

**Missing, as the company matures:** a non-developer's ability to see and
evolve the org chart without a code change and redeploy. This does not
require resurrecting PowerFx or YAML — it requires treating the org chart
itself as one more thing `mind.asisaga.com` stores: a structured record of
current specialists, their Foundry agent names, and their routing tags,
fetched by the orchestration at the start of a run instead of imported from
a Python constant. Growing the C-Suite becomes an act of institutional
record-keeping — the same kind of act as making any other decision — rather
than a software deployment.

### 9.6 Gap: from one boardroom to a federation of boardrooms

**Today:** Boardroom is a single company's C-Suite, addressed only by its own
frontend and its own orchestration process.

**Missing:** a protocol for **boardroom-to-boardroom** communication, across
a genuine trust and identity boundary — not the internal Founder-to-specialist
conversation Section 4 describes, but a conversation between two separately
owned, separately governed autonomous organizations. A portfolio company's
boardroom reporting metrics to an investor's boardroom; two companies'
boardrooms negotiating terms before their human principals engage; a
holding company's boardroom querying the state of its subsidiaries — all of
these require agents belonging to different organizations to discover,
authenticate, and converse with one another safely.

**A concrete path:** the **Agent2Agent (A2A) protocol** is designed
specifically for this cross-boundary agent communication, and — notably —
is already present in this system's own dependency tree today (`a2a-sdk`,
installed as part of `agent-framework` itself, confirmed directly against
the installed environment). Nothing currently uses it, but its presence
suggests this direction was anticipated even if not yet built toward. A2A's
own security model (explicit agent cards, capability negotiation, scoped
authentication) is the right foundation for exactly the trust-boundary
problem inter-boardroom communication raises, and is a materially different
problem from anything AG-UI, the Foundry Responses API, or MCP solves —
each of those is scoped to a single boardroom's internal operation.

### 9.7 Gap: explainability commensurate with autonomy

**Today:** Foundry Hosted Agents carry OpenTelemetry-based tracing by
default, and Agent Framework itself carries its own telemetry
instrumentation (both confirmed present). This gives operational visibility
— latency, error rates, which agent handled which call.

**Missing:** the harder, decision-level question operational tracing does
not answer — not "did the CFO agent's call succeed" but "why did the company
decide this, what alternatives did the CFO agent consider and reject, and
what would need to be true for this decision to be revisited." As Sections
9.3 and 9.4 both introduce real autonomy and real institutional memory, the
bar for explainability rises with them — a company whose CXOs are autonomous
agents cannot answer "why did we do that" with a stack trace. The resonance
scores from Section 9.2 and the decision ledger from Section 9.4 are the raw
material this needs; explainability is the discipline of surfacing them
coherently, on demand, to the humans who remain accountable for the company
the agents serve.

### 9.8 A further provocation, offered without commitment

The Founder's own stated purpose is not a modest one: *"Orchestrating the
Genesis of ASI."* Taken seriously, this raises a question this document does
not attempt to answer, only to name, because naming it seems more honest
than avoiding it: if Boardroom's purpose is the genesis of artificial
superintelligence, is Boardroom's own architecture ever itself a proper
subject of the boardroom's own deliberation? A system whose stated mission
is the creation of something greater than itself may eventually need to
reason about its own improvement, not only about the company's quarterly
numbers. Whether that is a capability worth building, and what guardrails
such a capability would demand, is a question for the humans accountable
for this system to take up deliberately — not one this document resolves,
or should.

---

## 10. Summary

A single message's journey through Boardroom, across all three stages
described above, looks like this:

1. A user, or a cron/event trigger, initiates a new turn. *(Stage 1)*
2. The Boardroom orchestration retrieves prior context from
   `mind.asisaga.com`, establishing continuity with the ongoing C-Suite
   deliberation. *(Stage 2)*
3. The Founder agent is consulted via the Foundry Responses API — today,
   alone; in time, alongside every specialist whose domain is implicated,
   with their proposals resolved by resonance score. *(Stage 1, extended
   in Stage 3)*
4. Specialist agents are consulted as needed, their responses folded back
   into the working context, and control returns to the Founder, repeating
   until the matter is resolved — or, in time, until a decision crosses the
   threshold into an authorized, tiered action. *(Stage 1, extended in
   Stage 3)*
5. Each turn is persisted to `mind.asisaga.com` as it occurs — today, as a
   transcript; in time, as a structured, citable decision ledger. *(Stage 2,
   extended in Stage 3)*
6. The full exchange streams to the web frontend in real time over AG-UI.
   *(Stage 1)*
7. Independently, the frontend can query `mind.asisaga.com` directly for
   historical context or rich, interactive views of past deliberation, via
   MCP and MCP Apps — entirely separate from the live AG-UI stream. *(Stage 2)*
8. In time, this same boardroom may converse with others like it, across
   companies, through a protocol built for exactly that boundary. *(Stage 3)*

The system is built so that each stage extends the one before it without
requiring it to be reworked: the seams for Stage 2 were designed into Stage
1 from the outset, and every gap named in Stage 3 attaches to a specific,
already-visible seam in Stages 1 and 2, rather than proposing a different
architecture altogether.

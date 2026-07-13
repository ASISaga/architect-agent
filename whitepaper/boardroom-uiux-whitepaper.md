# The Interface of Deliberation

## A UI/UX Design Whitepaper for the Boardroom Product

*Companion to: The Boardroom Conversation Mechanism (Architecture Reference)*
*Version 2.1 — Design Rationale and Language Specification*

---

## 1. Purpose and Scope

This document specifies the user-experience design of the Boardroom
product. It corrects and supersedes an earlier draft that designed the
interface as a set of discrete surfaces — a chat view, a tools panel, a
decision ledger, a settings-like authorization pattern. That draft was
built on a wrong premise, and this version is organized around the
corrected one:

> **There is one interface. It is conversation.**

Everything a human does with Boardroom — setting the company's purpose,
reviewing a decision made months ago, authorizing something consequential
today, extending how much it no longer needs to ask permission for — happens
in the same conversational relationship, addressed at whatever altitude the
moment calls for. Nothing in this document proposes a second interface for
any of those activities. Where earlier thinking reached for a dashboard, a
form, or a settings page, the corrected answer is: that is a conversation,
rendered.

Within that single conversational model, efficiency is not sacrificed —
it is carried by deep links: actionable references to specific prior
turns, decisions, artifacts, or delegations, reachable directly rather than
re-asked for in prose. Section 5 specifies this precisely.

This document assumes the protocol architecture described in the
companion reference (AG-UI for the live exchange, MCP for structured
memory and tool invocation) and treats that plurality as an implementation
fact the human must never be able to feel. Its job is to specify a single,
seamless conversational surface regardless of how many protocols
cooperate beneath it to produce any given turn.

---

## 2. Design Principles

### 2.1 Presence, not noise

Boardroom is in motion whenever a session is running, and the interface's
obligation is to make that perceptible without making it demanding. This
matters more, not less, under the corrected model: as delegation deepens
and a human's engagement narrows to genuine exceptions, the rare moment
Boardroom does need attention must never compete with — or be lost among —
routine activity the human has already trusted it to handle alone.

### 2.2 Authority made legible

Every utterance belongs to someone identifiable — a specific agent, or the
human — with equal visual and conversational weight regardless of source.
This extends now to a second kind of authority the earlier draft did not
yet have language for: the authority a human has *delegated away*. The
interface must make it just as legible when Boardroom is acting on standing
permission as when it is asking for fresh authorization — a human should
never have to wonder which mode a given action reflects.

### 2.3 The ledger behind the live

Every conversational turn is traceable to durable, structured memory — not
because a separate ledger screen exists to browse it, but because nothing
Boardroom says or does is unmoored from what has been decided, delegated,
or established before. "The ledger" is not a place. It is a property every
turn has: the ability to be asked *why*, and to answer from the same
structured record that produced it — and, wherever it would be faster than
asking, to be *reached* directly rather than merely described. Section 5
specifies how.

---

## 3. The Conversational Substrate

### 3.1 One continuum, not a set of surfaces

A human relates to Boardroom the way a founder relates to a trusted
executive team: through one open, ongoing conversation that moves freely
across altitude. There is no separate place to "set the vision" and a
different place to "chat about today." The same relationship carries both,
because that is how humans have always addressed matters of consequence —
in conversation, at whatever scope the moment requires.

Concretely, this collapses what the earlier draft called the deliberation
surface and the institutional-memory surface into one continuum. A human
does not navigate to a ledger to ask what was decided about pricing last
quarter — they ask Boardroom, in the same window they'd use to ask it
anything else, and Boardroom answers, drawing on the same structured
memory a decision like that was written to at the time — or, more
efficiently still, follows a direct reference to it (Section 5).

### 3.2 Altitude is content, not interface

Three altitudes recur, and it is worth naming them precisely because they
illustrate the same interface carrying genuinely different kinds of
exchange without changing shape:

- **Purpose** — "Orchestrating the Genesis of ASI" was set once and is
  revisited rarely, but it is revisited the same way anything else is:
  someone asks Boardroom what its purpose currently is, or proposes a
  change to it, in language, and Boardroom responds, in language,
  possibly asking clarifying questions before treating the change as
  settled.
- **Strategy** — a standing direction ("prioritize retention over new
  acquisition through the next two cycles") is discussed, set, and later
  referenced conversationally, the same way a board might revisit a
  strategic bet at a later meeting without it requiring a different
  format than the meeting itself.
- **The specific matter** — today's actual decision, discussed and
  resolved in the same register as everything above it.

A human moving between these three within a single exchange — asking about
today's number, then stepping back to ask whether that number changes the
company's strategic posture, then further back to ask whether the
company's purpose still holds given what's been learned — should feel one
continuous conversation gaining and losing altitude, not three different
tools. Where a shift in altitude references something specific already
settled at another altitude, that reference is a deep link, not a
re-summary (Section 5).

### 3.3 What the human never sees

The architecture reference specifies two protocols: AG-UI, carrying the
live exchange, and MCP, carrying structured memory, tool invocation, and
rich rendering. A human using Boardroom must never be in a position to
notice this seam. Whether a given turn's content came from the live agent
exchange directly or was retrieved from `mind.asisaga.com` mid-conversation
to answer a question about the past is an implementation fact, not a
distinction the interface exposes. One conversation, one register, however
many protocols cooperate to produce it.

---

## 4. Structured Data and Rendering

### 4.1 One substrate, read by different readers

*A picture is worth a thousand words. An artifact, perhaps more — because
an artifact is not a picture drawn to illustrate something already decided
in text. It is the thing itself, in a form a reader — human or agent — can
actually reason with.*

The relationship this document specifies is exact and worth stating
plainly, by analogy to a pattern already well understood outside this
product: a well-built web page is not two separate deliverables — human-
readable HTML and machine-readable JSON-LD authored side by side to agree
with each other. The HTML is *generated from* the structured data. There is
one substrate, one source of truth, and the human-facing page is a
rendering of it.

Boardroom's artifacts work the same way. When the CFO produces a financial
model, that model is not manufactured twice — once as a structured object
for the Founder and CMO to reason over, and separately as a chart for a
human to look at later. It is produced once, as structured data. Any
reader of it — another agent reasoning about the company's next move, or a
human asking what the model showed — receives a rendering of that same
object, suited to what they are.

### 4.2 The principle already at work in the simplest case

This is not a new mechanism introduced for artifacts specifically — it is
already the governing principle behind the smallest thing this system
renders. The Founder's own reply carries a literal protocol token,
`[ROUTE:CFO]`, as structured signal. A human never sees that token as text;
the interface renders it as a small badge instead. The token is the
structured data. The badge is its rendering, for a human reader, exactly as
an MCP App is the rendering, for a human reader, of a richer structured
object a moment later in the same conversation might require.

Every artifact this product will ever show a human — a resonance
comparison, an authorization request, a precedent citation — is the same
relationship at greater scale: structured data, produced once, rendered for
whoever is currently reading the conversation. A deep link (Section 5) is
the same relationship again, at its most compact: not a rendering of the
object's content, but a rendering of a *reference* to it.

### 4.3 Rendering evolves; the substrate and the paradigm do not

What changes over time is only the sophistication of rendering available to
a given turn, not the underlying model:

- **Today:** structured data renders as text. A resonance comparison is
  described in prose. A financial model is summarized in a sentence.
- **Next:** the same structured data renders as an MCP App — an
  interactive resource appearing inline, as a turn, the moment a
  structured object is rich enough that prose would flatten it.
- **Later:** multi-modal rendering — spoken exchange, where the same
  underlying structure is read aloud, or a human replies by voice to
  something Boardroom has raised.

None of these stages replaces conversation with something else. Each is a
richer way the same conversational turn can be perceived.

---

## 5. Deep Links: Efficiency as Compact Rendering

### 5.1 A reference is a pointer, not a re-summary

Wherever a turn — Boardroom's or a human's — refers to something already
established elsewhere in the conversation's history, that reference is a
deep link: an actionable pointer directly into the same structured
substrate specified in Section 4, not a paraphrase the reader must accept
on faith or a prompt for a fresh question. This is not a departure from the
conversational model; it is hypertext, which has always belonged inside
conversational and narrative form — a citation, a footnote, a linked
mention in an ordinary message. A boardroom that could only *describe* its
own memory, never point directly into it, would have the durability
Section 2.3 promises without the efficiency the principle exists to
deliver.

### 5.2 Two behaviors, chosen the way any rendering is chosen

A deep link resolves one of two ways, and which one is exactly the
rendering decision Section 4 already governs — how much of the referenced
object does this moment actually need:

- **Inline unfurl** — the reference expands into a compact rendering
  right where it appears, without leaving the current turn. A citation to
  a resonance score, a one-line summary of a prior decision, a figure from
  an earlier artifact — enough context to keep reading without a detour.
- **Jump-to** — the reference takes the human to the exact point in the
  conversational continuum it names, with an immediate, effortless way
  back. Used when the referenced matter genuinely needs its original
  context restored, not just its headline.

Neither behavior is a departure from "one interface." Both remain inside
the same continuum Section 3 specifies — the first without ever leaving the
current turn, the second by moving within the same conversation rather than
into a different kind of screen.

### 5.3 Where this is required

Three places in this document already depend on it, and are updated
below to say so directly:

- **Delegation** (Section 6) — a citation of standing authorization
  ("as delegated in June") is a deep link to the exact turn that granted
  it, making delegation self-auditing through the conversation itself.
- **Returning after absence** (Section 7) — a human re-entering a mature,
  low-engagement relationship is oriented through a short turn whose
  individual references are each a deep link to the one matter, if any,
  that actually needs them — not a document to read in full.
- **Explainability** (Section 11) — an answer to "why" is a deep link to
  the actual precedent it draws on, not a description of one.

Available from the very first rendering stage in Section 4.3 — a plain-text
turn can already carry a working link — and growing richer, as inline
unfurling, once MCP Apps rendering exists.

---

## 6. Authorization as Dialogue

The earlier draft designed authorization as a card with two buttons. The
corrected version has no card. It has a turn.

Boardroom raises the matter the way a CFO would raise it with a founder —
in language, carrying whatever artifact makes the stakes legible:

> **CFO** — *Reallocating $40,000 from paid acquisition to the retention
> program. Runway holds at fourteen months either way, but this isn't
> reversible once the budget moves — I'd like your sign-off before I
> proceed.* [a rendered budget-impact artifact accompanies this turn]

A human's reply is conversational, not a binary click, and the interface
must accommodate every register a real reply might take: *"go ahead,"*
*"why not acquisition instead,"* *"hold off until next cycle,"* or silence,
which is itself a state the conversation can carry — a matter awaiting
reply, visible as such, without demanding it.

What survives from the earlier, more mechanical design is the underlying
discipline, not the artifact: irreversible stakes are never left implicit
in ordinary phrasing. Boardroom's own turn is expected to say plainly that
something cannot be undone, in the sentence itself, because there is no
badge or tier label doing that work silently in a UI chrome the human
might not read closely. The language *is* the legibility mechanism now
that there is no form standing behind it.

---

## 7. Delegation as Memory

There is no settings page where a human configures what Boardroom may
decide without asking. Delegation is spoken, and it is remembered the same
way a decision is remembered — written to the same structured store,
retrievable the same way, and reachable by deep link (Section 5) the
moment it is cited again.

> **Human** — *You don't need to check with me on retention spend under
> fifteen thousand anymore. Use your judgment.*
>
> **Boardroom** — *Understood. I'll note that as standing authorization
> and act on it going forward — you'll still see it happen, just without
> waiting on you first.*

This is not a toggle being flipped; it is a statement being added to
Boardroom's own institutional memory, exactly as a strategic decision is.
It can be revisited the same way anything else in that memory can, and any
later reference to it is a direct link back to the granting turn, not a
paraphrase:

> **Human** — *Remind me what I've already delegated.*
>
> **Boardroom** — *[Retention spend under fifteen thousand](), since
> March. [Vendor renewals under standard terms](), since June. Everything
> else still comes to you first.*

The trust boundary, at any moment, is simply whatever Boardroom has been
told and has not been told otherwise — a fact in memory, not a
configuration a human must go somewhere separate to inspect or maintain,
and one the human can always click straight back into.

---

## 8. Progressive Engagement

What matures, as trust is earned, is not the interface. It is how often a
human chooses to be in the conversation at all, and at what altitude.

A founder in Boardroom's earliest days is present in nearly everything —
every routing decision, every specialist's turn, because trust has not yet
been extended and there is no standing delegation to rely on. As delegation
accumulates (Section 7), that same founder's engagement narrows
naturally: routine matters proceed and are simply available to review if
asked about; only what is genuinely novel, irreversible, or outside
existing delegation actually surfaces as something requiring a reply.

This is the same shape as a founder's real relationship with a maturing
executive team — early on, across every conversation; later, briefed on
exceptions and consulted on what actually needs a founder's judgment. The
interface does not change to reflect this. The same conversational surface
that carried every turn in the beginning is exactly what a human returns to
occasionally, at altitude, once delegation has done its work.

Efficient re-entry after absence is where deep links carry the most weight
in the whole product. A human returning after a week away is not handed a
transcript to read in full — they are met with a short orienting turn, and
each reference within it is a direct link to the one thing, if any, that
actually needs them:

> **Boardroom** — *Since you were last here: two decisions proceeded on
> standing delegation — [retention spend, twice](), no issues — and one is
> waiting on you: [renewing the primary vendor contract]() crosses your
> current delegation threshold.*

Reading that turn takes seconds. Acting on the one thing that needs a
human takes one link, not a search.

---

## 9. Rendering Language

Whatever a given turn renders as — plain text, an inline artifact, a
translated protocol badge, a deep link's unfurled preview — it draws from
one consistent visual vocabulary, specified here as a set of meanings
rather than a component catalogue, since what appears in any given turn is
generated from structured data rather than assembled from a fixed screen
library.

### 9.1 Color as meaning

| Role | Value | Meaning | Reserved against |
|---|---|---|---|
| Surface (base) | `#12151C` | The conversation's resting register | — |
| Surface (raised) | `#191D27` | A turn, or a rendered artifact within one | — |
| Text (primary) | `#E7E5DC` | Content to be read first | — |
| Text (muted) | `#9DA1AE` | Provenance, timestamps, protocol-level labels | Primary content |
| Brass | `#A9803A` / `#C79A4C` | Authority, resolution, standing delegation in effect | Anything transient |
| Verdigris | `#3E7268` / `#58948A` | Liveness, resonance, an authorization now in effect | Anything static or historical |
| Rust | `#9C4530` | Irreversible stakes, exclusively | Any other emphasis |

Identity color for each agent remains categorical: a fixed hue per speaker,
never reused to express magnitude. A resonance score, when rendered, still
uses verdigris rather than the color of whichever agent proposed the
highest-scoring option — the score is a property of the proposal's
strength, not of who made it, and the two must never be visually
conflated. Deep links are set in brass when they resolve to something
settled (a past decision, a granted delegation) and verdigris when they
resolve to something still active or awaiting response — the link's color
tells a reader what kind of destination it leads to before they follow it.

### 9.2 Type as role

Display face for anything the conversation needs to say with institutional
weight — a purpose statement being revisited, a resolved decision's
heading. Body face for the conversation itself, in every turn, from every
speaker, including the human's own. A data/mono face reserved for
whatever is structural rather than conversational within a rendering — a
timestamp, a resonance figure, a citation reference — marking it, by its
very setting, as provenance rather than prose.

### 9.3 Rendering registers, not screens

An artifact rendered inline — a resonance comparison, a precedent
citation, an authorization's supporting figures — is not a separate
screen a human navigates to. It is a turn's content, occupying the same
conversational flow as the sentence before and after it, using the same
color and type meanings as everything else, because it is drawn from the
same substrate (Section 4) and read by the same person in the same
sitting.

---

## 10. Motion

Motion remains restricted to what a live exchange genuinely requires:

- **Streaming** — a hard-blink cursor while a turn's content is still
  arriving, no easing, because it represents a literal technical state.
- **Liveness** — a slow, low-amplitude pulse on an agent's identity mark
  while it holds an active turn, easing in both directions, read as
  ambient rather than urgent.
- **Resolution** — a single, brief transition when a turn settles, an
  authorization takes effect, or an artifact finishes rendering. No
  bounce, no overshoot; the system reports its own state changes, it does
  not perform them.
- **Deep-link unfurl** — a compact rendering expanding in place is treated
  as a resolution transition, identical in character; a jump-to is treated
  as an instant cut, not a scroll or a slide, because it is a change of
  where the human is in the continuum, not an animated journey there.

Every instance degrades to its resolved, static state under
`prefers-reduced-motion`, treated as correctness, not enhancement.

---

## 11. Content Design and Voice

### 11.1 Two voices

**Agent voice** belongs to the agents and is rendered faithfully, never
compressed or reworded by the interface layer.

**System voice** belongs to the interface — the rare moments it must speak
for itself rather than relay a turn (an empty state before a first
message, a connection issue). It remains plain, active, and specific.

### 11.2 Why this matters more now

With no buttons, badges, or form chrome standing behind an authorization or
a delegation, the language of the turn itself is the entire legibility
mechanism. A vague authorization request or an ambiguously-worded
delegation is not a copy-polish issue in this model — it is the single
point of failure for whether a human actually understood what they just
agreed to. Section 6's discipline (state irreversibility plainly, in the
sentence) and Section 7's (restate what was actually delegated, in plain
terms, when asked) are treated as load-bearing, not stylistic. The same
discipline governs deep-link labels: a link's visible text names the thing
it leads to plainly enough to decide whether to follow it, never a bare
"here" or "this."

---

## 12. Accessibility and Trust

Color remains paired with text and shape in every rendering; every
interactive element — including every deep link — remains genuinely
operable by keyboard, not a styled span with a click handler. What extends
further under this model is explainability: because delegation means many
decisions now proceed without a human present for them, the ability to ask
*"what have you decided that I wasn't part of, and why"* and receive a
full, structured answer — with a direct link to each thing cited, not
merely a description of it — is no longer a convenience feature. It is the
mechanism by which trust extended earlier remains trust a human can still
verify later, on demand, entirely through the same conversation that
granted it.

---

## 13. Design Maturity

Two independent axes, because rendering sophistication and delegation
depth mature on genuinely different timelines and neither gates the other.
Deep-linking, per Section 5.3, is available from the first stage of the
first axis and is not a maturity stage of its own.

**Rendering** — what a turn is capable of appearing as:

| Stage | Rendering available |
|---|---|
| Now | Text, protocol-to-badge translation, and working deep links (jump-to) |
| Next | Inline MCP Apps — resonance comparisons, precedent views, authorization artifacts, and deep-link unfurling, all rendered as turns |
| Later | Multi-modal exchange, including spoken conversation |

**Delegation** — how much of the conversation a human is present for:

| Stage | What this looks like |
|---|---|
| Early | Present for nearly every turn; little or no standing delegation yet given |
| Maturing | Delegation accumulating by domain and threshold, engagement narrowing to what falls outside it |
| Mature | Present chiefly for the genuinely novel, the irreversible, and whatever Boardroom itself determines warrants raising — everything else proceeds on standing trust, reviewable on request, one link away |

Neither axis is a redesign of the interface. Both describe the same
conversational surface becoming more capable, and being relied upon
differently, without ever becoming a different kind of thing.

---

## 14. Closing

The correction this document makes is, in the end, a single one: nothing
about Boardroom is designed to be looked at. It is designed to be talked
to — about the company's purpose, about what it decided last quarter,
about whether to spend forty thousand dollars today, about how much of
tomorrow's forty-thousand-dollar decisions it no longer needs to ask
about. A picture, an artifact, or a link earns its place only when it
makes that conversation clearer or faster than words alone would — never
as a screen the conversation hands the human off to.

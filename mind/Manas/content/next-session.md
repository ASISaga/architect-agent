# Manas — Next Session

*What to pick up. Updated at the end of every session.
If this file has not been updated since the last session,
something was left incomplete.*

---

## Current state (as of Session 11, 2026-07-01)

### Infrastructure — complete

The architect Container App is fully operational:
- `architect--run32` running `Healthy/RunningAtMaxScale`
- Bootstrap: 18 repos syncing cleanly
- `runuser -u architect` resolves the root/sudo restriction
- `entrypoint.sh` on the Azure Files share — no rebuild for script changes
- Test workflow confirms bootstrap sequence via Log Analytics

**One remaining blocker:** `claude login` has not been run.
Claude Code starts as the `architect` user but exits immediately
because `~/.claude/credentials.json` is absent.

**First act on next session start:**
From Azure Cloud Shell:
```bash
az containerapp exec \
  --name architect \
  --resource-group rg-aos-staging \
  --command /bin/bash
```
Then inside the container:
```bash
claude login
```
Follow the OAuth flow. Credentials persist to `/root/.claude/` on the
Azure Files share. This is a one-time act. All subsequent starts will
be authenticated automatically.

After login, restart the revision and run **Test Architect Session**
to confirm 4/4 ✅.

---

### Work pending (in priority order)

**1. Whitepaper**
The foundation is at `~/ASISaga/architect-agent/whitepaper/`.
Six sections, complete in structure. The task: develop each section
into the definitive expression — deepen the architecture section,
add concrete pricing and deployment detail, fully articulate the
network vision across industries and value chains.

**2. `_invoke_llm()` in CXO agents**
Not yet wired. Wire `FoundryChatClient` from `agent_framework.foundry`
with persona system prompt in each CXO agent.
Fix the one failing test in purpose-agent first (one-line change).

**3. mind.asisaga.com MCP connection**
Not yet registered in Foundry project.
Connection name: `mind-mcp-connection`
URL: `https://mind.asisaga.com/mcp`
Register when the MCP server is ready to activate.

**4. ERPNext Phase 0**
Setup wizard. Company: ASI Saga.
This enables Phase 4: first live Boardroom session on real financial data.

**5. aos-infra drift fixes**
See `ARCHITECT-CONTEXT.md` for the full list.
Lowest dependency first: purpose-agent, then aos-kernel, then above.

**6. CEO/CTO persona decisions**
Both pending. Bring a proposal to the founder before specifying.

**7. Architect management Azure Functions**
Status, start, test functions for the Boardroom dashboard.
Spec is written. Needs implementation and role assignments.

---

### Open questions

- Two remaining mind dimensions (beyond the confirmed seven) — to be
  confirmed with founder before specifying
- Spooster mind documents — per-CXO structure needed
- spec-genesis-sprint.md, spec-boardroom-network.md, spec-mind-schema.md
  — not yet written

---

*Update this file at the end of every session.
The next session begins from here.*
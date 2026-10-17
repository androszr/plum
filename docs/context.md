<!-- BEGIN DARK ARMY PACK — managed, edits here are overwritten -->
# Project context — store-sim

Ground truth for every agent in `.claude/agents/`. Read this first, before
exploring the tree. If something here contradicts the code, the code wins —
say so in your report rather than silently working around it.

Three sections here are read by machinery, not only by people, so keep their
shape: the **Identity** table (gates), the **Reviewers** table (which domain
reviewer fires on which paths) and the **Conventions** list (what the
preflight, the verifier and the reviewers enforce).

Fill this file in. Dark Army keeps it in step with its agent pack only until
the project edits it: from the first edit on, a resync leaves the whole file
alone, whatever the marker line above says. To take a newer template later,
delete the file and resync.

## Identity

| Field | Value |
|---|---|
| `src_dir` | `src/` |
| Framework | <one line: what this is built with and where it runs> |
| Package manager | <e.g. pnpm 11 (Node 22) / Swift Package Manager / none> |
| `lint_gate` | `pnpm lint` |
| `typecheck_gate` | `pnpm typecheck` |
| `test_gate` | `pnpm test` |
| `build_gate` | `pnpm build` |
| Plans | `plans/<YYYY-MM-DD>-<slug>.md` |
| Scout reports | `scout/<YYYY-MM-DD>-<slug>/report.md` |
| Manual checks | `manual-check/<YYYY-MM-DD>-<slug>/check.md` |
| Reference docs | <the docs a planner should read after this one> |

**Every gate must pass before any handoff.** Run them in the order listed —
the fast ones fail first. Agents read the commands from this table; none of
them hardcodes one.

## Reviewers

One row per domain reviewer. `/ship` Phase 6.8 greps the changed-file list
against each regex and spawns every reviewer that matches; `/review --deep`
hands the diff to the first one. The regex is a floor — a reviewer is also
spawned on judgment when the diff touches its domain through other files.

| Agent | Fires when a changed path matches |
|---|---|
| `ss-security-reviewer` | `auth|proxy|middleware|/api/|next\.config|\.env|env\.ts|package\.json|drizzle/|schema\.ts` |
| `ss-integration-reviewer` | `package\.json|pnpm-lock\.yaml|next\.config|vercel\.json|\.github/workflows/|drizzle/|migrations/|schema\.ts|env\.ts|instrumentation` |

## Architecture

<Replace this section with the real thing: the entry chain, the data layer,
auth, the external services, the background work. Cite real paths and
symbols. Record decisions with their date and the plan that made them, and
record what was tried and reverted — that is the expensive half.>

## Conventions

The project's own non-negotiables. Each is enforced by a preflight check, a
verifier grep or a domain reviewer; a plan that breaks one is a plan that will
not pass. The planner reads these before writing, the implementer before
coding.

1. **No float money math.** Database `numeric` → string → a decimal library
   through one money module. `parseFloat`/`Number()` on a price, quantity, fee
   or rate is a bug. *(preflight BLOCK, verifier grep)*
2. **No hardcoded colors.** One tokens file is the only file allowed a color
   literal; everything else uses the generated utilities. *(preflight WARN,
   verifier grep)*
3. **Both shells, same pass.** Any UI change handles mobile and desktop
   together, branching in code — never CSS-hiding a duplicate tree.
   *(preflight BLOCK)*
4. **Third-party data is server-mediated.** A client component never calls a
   vendor API directly. *(preflight BLOCK, verifier grep)*
5. **Auth gates stay intact.** Every allowlist or role check in the auth module
   survives every change; a new sign-in method passes the same gates.
   *(security reviewer)*
6. **`server-only` on anything reading `process.env`** or the database.
   *(verifier grep, security reviewer)*
7. **Migrations are additive.** They run before the new code deploys, so a
   destructive change is split across two deploys. *(preflight BLOCK)*
8. **Never commit or push** unless explicitly asked.


## What the tests cannot see

The suite is hermetic. Green proves nothing about these surfaces, which is why
the domain reviewers and the audit skill exist:

- **The deployed environment.** Env-schema validation runs at build time on
  Vercel with the project's real variables; CI builds with placeholders. A
  variable missing from Vercel fails the deploy, never the tests.
- **The client bundle.** Nothing in the suite greps `.next/static/` for a
  secret that leaked through a missing `server-only`.
- **Security headers and cookies.** CSP, HSTS, cookie flags are set by config
  and only observable on a live URL.
- **The migration order.** Tests run against a schema that already matches
  the code; production runs the migration first against the still-live old
  code.
- **A third-party response that changes shape.** Fixtures are frozen; the
  vendor is not.


## Interview branches

`/ship` asks at most three questions from `.claude/skills/ship/templates/questions.md`.
Branches that the architecture above already settles should be answered from
this file rather than asked.
<!-- END DARK ARMY PACK -->

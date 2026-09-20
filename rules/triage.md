---
name: Issue Triage
description: Standardized triage method for analyzing and classifying GitHub issues.
---

# Issue Triage Methodology

Always be pessimistic about issues reported by users if the evidence isn't clear. Most issues do not require changes to the core `better_player` packages. Changing anything in the core player is a **last resort**. Follow this triage methodology strictly and in order.

> **Tooling Note**: Refer to [github.md](rules/github.md) for instructions on how to use the provided scripts to fetch issue data and comments before starting your analysis. When you need to post a reply or update an issue with your decision, use the GitHub REST API (see `rules/github.md` for the token setup).
> **Temporary Files**: Any temporary files created during triage (like draft comment bodies, fetched JSON, etc.) should be written to the `.tmp/` directory in the root of the repository.
> **CRITICAL**: Never post a comment to GitHub without obtaining explicit user approval first. Before posting, you MUST present the exact text of the proposed comment to the operator and wait for their confirmation.
> **CRITICAL**: Comments should be natural and human-like. Avoid using labels like "Triage Analysis" or "Issue Triage Report" in the actual comments posted to GitHub.
> **CRITICAL**: Never use the web browser or any web search tool during triage. All GitHub data must be fetched exclusively using the scripts documented in `rules/github.md`. Reading any web page — including the GitHub issue page directly in a browser — is strictly forbidden.

---

## ⚠️ BEFORE YOU START — MANDATORY PRE-FLIGHT

You MUST complete all of the following before doing any analysis:

1. **Fetch the issue data** using the scripts described in `rules/github.md`.
   - Use the provided script to fetch the issue body and all comments.
   - Save the raw JSON to `.tmp/issue-<number>.json`.
   - DO NOT proceed to Step 1 until you have fetched the issue.
2. **Read `rules/github.md`** if you have not already done so in this session.
   - Specifically note the token setup, the fetch script, and the POST script.
3. **Scan the relevant source files** before forming any opinion (see Step 3.5).
4. **Never post or close anything** until you have presented a draft to the operator and received explicit "yes, post it" confirmation.

❌ Skipping any of the above is not allowed, regardless of how obvious the issue seems.

## Common Mistakes to Avoid

❌ **Do NOT** skip fetching the issue before starting analysis.  
❌ **Do NOT** write your own reply — use the provided templates verbatim.  
❌ **Do NOT** post a comment or close an issue without explicit operator approval.  
❌ **Do NOT** jump to "core bug fix" without checking docs/example first.  
❌ **Do NOT** assume the version is current — check what the user reported.  
❌ **Do NOT** treat a Question/Support issue as a bug.  
❌ **Do NOT** use the web browser or web search — use only the scripts in `rules/github.md` and the data they return.  
✅ **DO** write the draft comment to `.tmp/` and present it in full before asking for approval.  
✅ **DO** check the Known Patterns section before concluding.  
✅ **DO** scan the source code before giving a final decision.

---

## Step 1: Classify the Issue Type

Before anything else, determine what kind of issue this is:

- **Bug Report**: The user claims something is broken or behaves unexpectedly.
- **Feature Request**: The user is asking for new functionality.
- **Question / Support**: The user is asking how to use the library.

### Resolving Ambiguous Issue Types

If the issue could be classified as more than one type, apply this priority order:

1. If it contains a **crash, exception, or clearly broken behavior** → treat as **Bug Report**.
2. If it contains a **feature ask** alongside a bug → treat as **Bug Report** first; note the feature separately.
3. If it is purely asking "how do I…" with no broken behavior → treat as **Question / Support**.

When in doubt, classify as the **simpler type** (Question > Bug) and document your reasoning.

> If the issue is a **Question or Support request**, do not treat it as a bug. Provide an answer pointing to the docs or example app and close it. Do not open any PRs.

---

## Step 2: Version Check

Check the `better_player` version reported in the issue.

- An **old version** is defined as any version prior to `1.0.0` (i.e., `0.x.x`).
- If the reported version is old **AND** the issue is badly written (see Step 3), do not investigate. Post the standard reply and close it.
- If the reported version is old **BUT** the issue is well-prepared, verify if the problem still exists in the current codebase before deciding. **Do not close it solely because the version is old** if the bug is still present.

---

## Step 3: Evidence Assessment (Bug Reports Only)

For **Bug Reports**, evaluate the issue against these criteria. The required evidence depends on the issue type:

### Always Required
- [ ] **Clear Description**: Specific steps to reproduce, expected vs. actual behavior.
- [ ] **Flutter/Dart version** and **device/OS information**.

### Required Unless the Bug Is Platform-Specific and Doesn't Need a Stream
- [ ] **Minimal Reproduction**: A runnable code snippet or a link to a minimal reproduction repository.

### Required Only for Playback/Media Issues
- [ ] **Media Source**: A public URL to the media stream or asset that reproduces the issue (only required when the bug is related to playback, DRM, HLS, DASH, subtitles, etc.). **Not required** for crashes, build errors, UI layout bugs, or feature requests.

If the **always-required** items are missing, the issue is considered **badly written**.
- **Action**: Do not investigate further. Post the standard "needs more info" reply (see Reply Templates below) and close the issue.

> 📋 **Use Template**: "Needs More Info (Badly Written)" — see Reply Templates section below.
> Copy it verbatim. Personalise only the bracketed placeholders. Do not rewrite it.

> 🛑 **STOP — OPERATOR APPROVAL REQUIRED**
> Before posting the "needs more info" reply or closing the issue:
> 1. Write the full comment text to `.tmp/draft-comment-<number>.md`
> 2. Present the exact comment text here in your output
> 3. State: "Awaiting your approval to post this comment."
> 4. Do NOT proceed until the operator says "yes, post it" or equivalent.

---

## Step 3.5: Code Verification

Before giving a final answer, always try to scan the code quickly. Even if the issue seems obvious, fetching the code and verifying the underlying implementations (e.g. looking for references to native features, constraints, or configurations) ensures that triage responses are accurate and directly address the project's architecture.

---

## Known Patterns & Recurring Issues

Before concluding your triage, check whether the issue matches any of the known patterns below.
If it matches, use the linked response and skip further investigation.

<!-- Add entries in the format below when you identify recurring issues -->

| Pattern | Symptoms | Resolution | Notes |
|---|---|---|---|
| *(e.g. iOS PiP missing entitlement)* | *(e.g. PiP button missing on iOS 14+)* | *(e.g. Point to entitlement setup in docs)* | *(platform-specific)* |

> 💡 If you encounter a new recurring issue during triage, flag it so it can be added here.

---

## Step 4: Resolution Strategy

If the issue is well-prepared and confirmed on the latest version, follow this strict resolution hierarchy:

### 4a. Answer and Close (Questions / Misunderstandings)
If the behavior is correct and the user is simply confused, post a clear explanation pointing to the existing docs or example app and close the issue. No code changes.

> 📋 **Use Template**: "Not a Bug / Works as Intended" — see Reply Templates section below.
> Copy it verbatim. Personalise only the bracketed placeholders. Do not rewrite it.

> 🛑 **STOP — OPERATOR APPROVAL REQUIRED**
> Before posting the reply or closing the issue:
> 1. Write the full comment text to `.tmp/draft-comment-<number>.md`
> 2. Present the exact comment text here in your output
> 3. State: "Awaiting your approval to post this comment."
> 4. Do NOT proceed until the operator says "yes, post it" or equivalent.

### 4b. Docs or Example Update (Preferred)
If the issue stems from unclear documentation or a missing usage example:
- Directly create a PR to update `docs/` or the `example` app.
- Post the PR link in the issue and close the issue.

> 🛑 **STOP — OPERATOR APPROVAL REQUIRED**
> Before creating a PR or closing the issue:
> 1. Propose the exact file changes and PR description.
> 2. Present the exact comment text here in your output.
> 3. State: "Awaiting your approval to proceed."
> 4. Do NOT proceed until the operator says "yes, proceed" or equivalent.

### 4c. Core Bug Fix (Last Resort)
Only consider modifying a `better_player` package if **all** of the following are true:
1. The bug is **confirmed reproducible** on the latest version.
2. It **cannot** be resolved by documentation or an example update.
3. It meets at least one **criticality threshold**:
   - **Crash**: The bug causes an unhandled exception or app crash.
   - **Data loss or corruption**: The bug causes incorrect behavior that damages the user's app state.
   - **Platform regression**: The bug affects all users on a specific supported platform (iOS, Android, Web).
   - **Security issue**: The bug exposes a security vulnerability.

If the bug does **not** meet any criticality threshold, document the workaround and close the issue instead of fixing the core.

> 🛑 **STOP — OPERATOR APPROVAL REQUIRED**
> Before proposing or starting a core bug fix:
> 1. Detail the exact problem and proposed fix.
> 2. State: "Awaiting your approval to proceed with the core bug fix."
> 3. Do NOT proceed until the operator says "yes, proceed" or equivalent.

---

## Step 5: Feature Request Handling

Feature requests follow a separate decision path:

1. **Does the feature already exist?** Check the docs, example app, and codebase. If it does, point to it and close.
2. **Can it be achieved with existing APIs?** If yes, document the approach and close.
3. **Is it a valid, critical, and broadly useful addition?** If no — close it. Niche features that benefit only a small subset of users should not be added to the core. Stability > features.
4. **If valid**: Create a feature plan as an implementation plan (not just a code change) and present it for user review before any work begins.

> 🛑 **STOP — OPERATOR APPROVAL REQUIRED**
> Before proceeding with closing or starting a feature plan:
> 1. Present the draft response or proposed feature plan.
> 2. State: "Awaiting your approval to proceed."
> 3. Do NOT proceed until the operator says "yes, proceed" or equivalent.

---

## Reply Templates

Use these as the basis for issue replies to maintain consistency.

### Needs More Info (Badly Written)
> Thanks for the report! To investigate this properly, we need a bit more information. Could you please provide:
> - [ ] A minimal code snippet or reproduction repository
> - [ ] Clear steps to reproduce, expected vs. actual behavior
> - [ ] Your Flutter version, Dart version, `better_player` version, and device/OS
> - *(For playback issues)* A public media URL that reproduces the problem
>
> Please also verify this occurs on the **latest version** of `better_player`. We'll re-open or revisit once the above is provided.

### Old Version
> This issue was reported against an older version (`0.x.x`). Please test with the latest `better_player` release and let us know if the problem persists. If it does, please update the report with a reproduction case against the latest version.

### Not a Bug / Works as Intended
> After reviewing this, the described behavior is working as intended. [Explanation]. You can find an example of the correct usage in the [example app / docs link]. Closing this issue — feel free to re-open if you have further questions.

---

## Triage Output Format

When asked to triage an issue, output your analysis using the following structured format:

```markdown
### Issue Triage Report

**Issue Type:** [Bug Report / Feature Request / Question]

---

#### 1. Version Assessment
- **Reported Version:** [e.g., 0.8.1 / 1.7.0]
- **Status:** [Old Version (< 1.0.0) / Current]

---

#### 2. Evidence Checklist (Bug Reports Only)
- [ ] Clear description with steps, expected vs. actual behavior
- [ ] Flutter/Dart version and device/OS info
- [ ] Minimal reproduction code/repo
- [ ] Public media URL *(only if playback-related)*

**Issue Quality:** [Well-Prepared / Badly Written]

---

#### 3. Triage Decision
- **Proposed Resolution:** [Needs More Info / Answer & Close / Doc Update / Example Update / Core Bug Fix / Feature Plan]
- **Criticality (if bug):** [Crash / Regression / Non-critical / N/A]
- **Next Action:** [Specific action, e.g. "Post needs-more-info reply and close" / "Create PR for docs update" / "Investigate core fix"]
```

---
name: Issue Triage
description: Standardized triage method for analyzing and classifying GitHub issues.
---

# Issue Triage Methodology

Always be pessimistic about issues reported by users if the evidence isn't clear. Most issues do not require changes to the core `better_player` packages. Changing anything in the core player is a **last resort**. Follow this triage methodology strictly and in order.

> **Tooling Note**: Refer to [github.md](rules/github.md) for instructions on how to use the provided scripts to fetch issue data and comments before starting your analysis. When you need to post a reply or update an issue with your decision, use the GitHub REST API (see `rules/github.md` for the token setup).

---

## Step 1: Classify the Issue Type

Before anything else, determine what kind of issue this is:

- **Bug Report**: The user claims something is broken or behaves unexpectedly.
- **Feature Request**: The user is asking for new functionality.
- **Question / Support**: The user is asking how to use the library.

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

---

## Step 3.5: Code Verification

Before giving a final answer, always try to scan the code quickly. Even if the issue seems obvious, fetching the code and verifying the underlying implementations (e.g. looking for references to native features, constraints, or configurations) ensures that triage responses are accurate and directly address the project's architecture.

---

## Step 4: Resolution Strategy

If the issue is well-prepared and confirmed on the latest version, follow this strict resolution hierarchy:

### 4a. Answer and Close (Questions / Misunderstandings)
If the behavior is correct and the user is simply confused, post a clear explanation pointing to the existing docs or example app and close the issue. No code changes.

### 4b. Docs or Example Update (Preferred)
If the issue stems from unclear documentation or a missing usage example:
- Directly create a PR to update `docs/` or the `example` app.
- Post the PR link in the issue and close the issue.

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

---

## Step 5: Feature Request Handling

Feature requests follow a separate decision path:

1. **Does the feature already exist?** Check the docs, example app, and codebase. If it does, point to it and close.
2. **Can it be achieved with existing APIs?** If yes, document the approach and close.
3. **Is it a valid, critical, and broadly useful addition?** If no — close it. Niche features that benefit only a small subset of users should not be added to the core. Stability > features.
4. **If valid**: Create a feature plan as an implementation plan (not just a code change) and present it for user review before any work begins.

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

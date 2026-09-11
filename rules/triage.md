---
name: Issue Triage
description: Standardized triage method for analyzing and classifying GitHub issues.
---

# Issue Triage Methodology

Always be pessimistic about issues reported by users if the evidence isn't clear. Most issues do not require changes to the core `better_player` packages. Changing anything in the core player is a **last resort**. Follow this triage methodology strictly.

> **Tooling Note**: Refer to [github.md](file:///C:/Users/jhoml/betterplayer/rules/github.md) for instructions on how to use the provided scripts to fetch issue data and comments before starting your analysis. When you need to reply or update an issue with your decision, use the standard GitHub API.

## 1. Evidence Assessment
An issue must provide clear evidence to be considered "well-prepared". Evaluate the issue against the following **strictly required** criteria:
1. **Minimal Reproduction**: A runnable code snippet or a link to a reproduction repository.
2. **Media Source**: A public URL to the media stream/asset that reproduces the issue.
3. **Clear Description**: Specific steps to reproduce, expected vs. actual behavior, and error logs (if applicable).

If any of these are missing, the issue is considered **badly written**.
- **Action**: Do not investigate further. Reply to the user explaining what is missing, suggest they try again with the latest version, and close the issue.

## 2. Version Check
Check the `better_player` version reported in the issue.
- An "old version" is defined as any version prior to `1.0.0` (e.g., `0.x.x`).
- **Action for Old Versions**: 
  - If the issue is badly written, do not investigate. Ask them to test on the latest version and provide better evidence.
  - If the issue is well-prepared, verify if the problem still exists in the latest codebase. **Do not close it immediately** if the bug is still reproducible on the latest version.

## 3. Resolution Strategy
If the issue is well-prepared and confirmed on the latest version, follow this hierarchy for resolution:

1. **Docs and Examples (Preferred)**: If the issue stems from a misunderstanding or can be solved by demonstrating the correct usage, prioritize updating the documentation or the `example` app.
   - **Action**: Directly create a PR to update the docs/example, provide the solution/link in the issue comment, and close the issue.
2. **Core Changes (Last Resort)**: Only consider modifying the `better_player` packages if there is a confirmed, critical defect that absolutely cannot be addressed via documentation or example updates.

## 4. Triage Output Format
When asked to triage an issue, you must output your analysis in the following structured Markdown format:

```markdown
### 1. Version Assessment
- **Reported Version:** [Version number]
- **Status:** [Old Version / Current Version]

### 2. Evidence Checklist
- [ ] Minimal Reproduction code/repo provided
- [ ] Public Media URL provided
- [ ] Clear steps, expected/actual behavior, and logs provided

### 3. Triage Decision
- **Classification:** [Well-Prepared / Badly Written]
- **Proposed Resolution:** [Needs more info / Doc Update / Example Update / Core Bug Fix]
- **Next Action:** [E.g., "Reply to user requesting media URL and close", "Create PR for documentation update"]
```

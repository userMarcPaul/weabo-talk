<!--
PR Audit Template
Copy this into the pull request description and fill in each section.
Delete any line or section that doesn't apply. HTML comments like this one
don't show on GitHub, so they can stay.
-->

## Summary

<!-- One or two sentences: what this PR does and why. -->

Fixes: <!-- e.g. problem #2 in CODE_REVIEW_FINDINGS.md, an issue link, or "n/a" -->

## Audit

| | |
|---|---|
| **Type** | <!-- Bug fix / Feature / Refactor / Config / Tests / Docs --> |
| **Severity** | <!-- Bugs only. Critical / High / Medium / Low, and the user-facing effect --> |
| **Affected** | <!-- Who or what was affected: users, pages, environments --> |
| **Root cause** | <!-- Bugs only. What in the code caused it, with file:line --> |
| **Risk of change** | <!-- Low / Medium / High, and what could break --> |

## What changed

<!-- One entry per file. Say what changed and why, not a line-by-line diff. -->

**`path/to/file.rb`**:
-

## Testing

<!-- Tick what was done. Leave a box unticked and say why if something wasn't run. -->

- [ ] Automated tests: `command used`, with the result (e.g. 17 runs, 17 pass)
- [ ] New or updated tests: <!-- which cases they cover -->
- [ ] Manual check: <!-- what was tried and what happened -->

<!-- Failures that were already there and are unrelated: name the test and why it fails. -->

## Found during this work (not fixed here)

<!-- Problems noticed but left out of this PR to keep it focused. Delete if none. -->

-

## Checklist

- [ ] Follows the project's existing architecture and conventions
- [ ] Only the files needed for this change are modified
- [ ] No debug code, secrets or unrelated formatting changes
- [ ] Tests added or updated, or the reason is explained above

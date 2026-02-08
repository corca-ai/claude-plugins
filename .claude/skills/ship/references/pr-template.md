# PR Template

The agent reads this file and substitutes `{VARIABLES}` to compose the PR body.

## Body

<!-- BEGIN TEMPLATE -->

## Summary

{SUMMARY}

{ISSUE_LINK}

## Changes

{GIT_DIFF_STAT}

## Lessons Learned

{LESSONS}

## CDM (Critical Decision Moments)

{CDM}

## Review Checklist

- [ ] Code changes match PR description
- [ ] No unintended file changes
- [ ] Tests pass (if applicable)
{CONDITIONAL_ITEMS}

---
*Created with `/ship pr`*

<!-- END TEMPLATE -->

# Adding a New Plugin

For directory structure, schemas, script guidelines, testing, and deploy workflow, see the [Plugin Dev Cheat Sheet](plugin-dev-cheatsheet.md).

Additional checklist for **new** plugins:

1. Add entry to `.claude-plugin/marketplace.json` → `plugins[]`
2. Bump marketplace metadata version
3. Update `README.md` and `README.ko.md` (table + detail section)
4. Review whether `AI_NATIVE_PRODUCT_TEAM.md` / `AI_NATIVE_PRODUCT_TEAM.ko.md` should link to the new plugin (research tools, spec refinement tools, code quality tools, etc.)

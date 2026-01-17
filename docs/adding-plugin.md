# Adding a New Plugin

For plugin structure, `plugin.json` schema, `marketplace.json` schema, etc., refer to [claude-marketplace.md](claude-marketplace.md).

After adding a new plugin, update the version appropriately in [marketplace.json](../.claude-plugin/marketplace.json).

## Script Writing Guidelines

### Cross-Platform Compatibility

Scripts must work on both macOS and Linux:

```bash
# Bad: macOS only
sed -i '' 's/foo/bar/' file.txt

# Good: cross-platform
sed 's/foo/bar/' file.txt > file.tmp && mv file.tmp file.txt
# or
grep -v 'pattern' file.txt > file.tmp && mv file.tmp file.txt
```

### Minimal Dependencies

Use basic tools like bash and curl whenever possible. Minimize external dependencies (such as python3).

## Review AI_NATIVE_PRODUCT_TEAM.md Links

When adding a new plugin, review whether a link to that plugin can be added to `AI_NATIVE_PRODUCT_TEAM.md`.

This document explains AI-native team workflows and links to relevant tools as examples:
- Research tools (e.g., slack-to-md)
- Spec refinement tools (e.g., Clarify)
- Code quality tools (e.g., suggest-tidyings)

If the new plugin falls into one of these categories or could serve as a good example in another context within the document, add the link.

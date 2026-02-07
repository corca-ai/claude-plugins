# Quick Reference

## Skill Development Checklist

### Before You Start

- [ ] Identified 2–3 concrete use cases
- [ ] Tools identified (built-in or MCP)
- [ ] Reviewed this guide and example skills
- [ ] Planned folder structure

### During Development

- [ ] Folder named in kebab-case
- [ ] `SKILL.md` file exists (exact spelling)
- [ ] YAML frontmatter has `---` delimiters
- [ ] `name` field: kebab-case, no spaces, no capitals
- [ ] `description` includes WHAT and WHEN
- [ ] No XML tags (`<` `>`) anywhere
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References clearly linked

### Before Upload

- [ ] Tested triggering on obvious tasks
- [ ] Tested triggering on paraphrased requests
- [ ] Verified doesn't trigger on unrelated topics
- [ ] Functional tests pass
- [ ] Tool integration works (if applicable)
- [ ] Compressed as `.zip` file

### After Upload

- [ ] Test in real conversations
- [ ] Monitor for under/over-triggering
- [ ] Collect user feedback
- [ ] Iterate on description and instructions
- [ ] Update version in metadata

---

## YAML Frontmatter Spec

### Required Fields

```yaml
---
name: skill-name-in-kebab-case
description: What it does and when to use it. Include specific trigger phrases.
---
```

### All Optional Fields

```yaml
name: skill-name
description: [required description]
license: MIT                                          # Optional: License for open-source
allowed-tools: "Bash(python:*) Bash(npm:*) WebFetch"  # Optional: Restrict tool access
metadata:                                              # Optional: Custom fields
  author: Company Name
  version: 1.0.0
  mcp-server: server-name
  category: productivity
  tags: [project-management, automation]
  documentation: https://example.com/docs
  support: support@example.com
```

### Security Rules

**Allowed:** Any standard YAML types, custom metadata fields, long descriptions (up to 1024 characters)

**Forbidden:** XML angle brackets (`<` `>`), code execution in YAML, skills named with "claude" or "anthropic" prefix

---

## Complete Skill Examples

For full, production-ready skills demonstrating the patterns in this guide:

- **Document Skills** — PDF, DOCX, PPTX, XLSX creation
- **Example Skills** — Various workflow patterns
- **Partner Skills Directory** — Skills from Asana, Atlassian, Canva, Figma, Sentry, Zapier, and more

Repository: [github.com/anthropics/skills](https://github.com/anthropics/skills)

---

## Resources

**Official Documentation:**
- Best Practices Guide
- Skills Documentation
- API Reference
- MCP Documentation

**Blog Posts:**
- Introducing Agent Skills
- Engineering Blog: Equipping Agents for the Real World
- Skills Explained
- How to Create Skills for Claude
- Building Skills for Claude Code
- Improving Frontend Design through Skills

**Support:**
- Community: Claude Developers Discord
- Bug Reports: `anthropics/skills/issues`

# Troubleshooting

## Skill Won't Upload

**Error:** "Could not find SKILL.md in uploaded folder"
**Cause:** File not named exactly `SKILL.md`
**Solution:**
- Rename to `SKILL.md` (case-sensitive)
- Verify with: `ls -la` should show `SKILL.md`

**Error:** "Invalid frontmatter"
**Cause:** YAML formatting issue. Common mistakes:

```yaml
# Wrong - missing delimiters
name: my-skill
description: Does things

# Wrong - unclosed quotes
name: my-skill
description: "Does things

# Correct
---
name: my-skill
description: Does things
---
```

**Error:** "Invalid skill name"
**Cause:** Name has spaces or capitals

```yaml
# Wrong
name: My Cool Skill

# Correct
name: my-cool-skill
```

## Skill Doesn't Trigger

**Symptom:** Skill never loads automatically.

**Fix:** Revise your `description` field. See [04-writing-instructions.md](04-writing-instructions.md) for good/bad examples.

**Quick checklist:**
- Is it too generic? ("Helps with projects" won't work)
- Does it include trigger phrases users would actually say?
- Does it mention relevant file types if applicable?

**Debugging approach:** Ask Claude: "When would you use the [skill name] skill?" Claude will quote the description back. Adjust based on what's missing.

## Skill Triggers Too Often

**Symptom:** Skill loads for unrelated queries.

**Solutions:**

1. **Add negative triggers:**
   ```yaml
   description: Advanced data analysis for CSV files. Use for statistical modeling,
     regression, clustering. Do NOT use for simple data exploration (use data-viz
     skill instead).
   ```

2. **Be more specific:**
   ```yaml
   # Too broad
   description: Processes documents

   # More specific
   description: Processes PDF legal documents for contract review
   ```

3. **Clarify scope:**
   ```yaml
   description: PayFlow payment processing for e-commerce. Use specifically for
     online payment workflows, not for general financial queries.
   ```

## MCP Connection Issues

**Symptom:** Skill loads but MCP calls fail.

**Checklist:**

1. **Verify MCP server is connected**
   - Claude.ai: Settings > Extensions > [Your Service]
   - Should show "Connected" status

2. **Check authentication**
   - API keys valid and not expired
   - Proper permissions/scopes granted
   - OAuth tokens refreshed

3. **Test MCP independently**
   - Ask Claude to call MCP directly (without skill)
   - "Use [Service] MCP to fetch my projects"
   - If this fails, issue is MCP not skill

4. **Verify tool names**
   - Skill references correct MCP tool names
   - Check MCP server documentation
   - Tool names are case-sensitive

## Instructions Not Followed

**Symptom:** Skill loads but Claude doesn't follow instructions.

**Common causes:**

1. **Instructions too verbose**
   - Keep instructions concise
   - Use bullet points and numbered lists
   - Move detailed reference to separate files

2. **Instructions buried**
   - Put critical instructions at the top
   - Use `## Important` or `## Critical` headers
   - Repeat key points if needed

3. **Ambiguous language**
   ```text
   # Bad
   Make sure to validate things properly

   # Good
   CRITICAL: Before calling create_project, verify:
   - Project name is non-empty
   - At least one team member assigned
   - Start date is not in the past
   ```

   Advanced technique: For critical validations, consider bundling a script that performs the checks programmatically rather than relying on language instructions. Code is deterministic; language interpretation isn't.

4. **Model "laziness"** — Add explicit encouragement:
   ```markdown
   ## Performance Notes
   - Take your time to do this thoroughly
   - Quality is more important than speed
   - Do not skip validation steps
   ```

   Note: Adding this to user prompts is more effective than in SKILL.md.

## Large Context Issues

**Symptom:** Skill seems slow or responses degraded.

**Causes:**
- Skill content too large
- Too many skills enabled simultaneously
- All content loaded instead of progressive disclosure

**Solutions:**

1. **Optimize SKILL.md size**
   - Move detailed docs to `references/`
   - Link to references instead of inline
   - Keep SKILL.md under 5,000 words

2. **Reduce enabled skills**
   - Evaluate if you have more than 20–50 skills enabled simultaneously
   - Recommend selective enablement
   - Consider skill "packs" for related capabilities

# Slack Export Reference

## Prerequisites

1. **Node.js 18+**
2. **Slack Bot** (https://api.slack.com/apps) with scopes: `channels:history`, `channels:join`, `users:read`, `files:read`
3. **Token** in shell profile (`~/.zshrc` or `~/.bashrc`):
   `export SLACK_BOT_TOKEN=xoxb-your-token-here`

## Script Details

- `slack-api.mjs`: Fetches thread JSON, downloads attachments with `--attachments-dir`
- `slack-to-md.sh`: Converts JSON to markdown with inline images and download links (requires jq, perl)

## Error Handling

- `not_in_channel`: Auto-joins channel and retries
- `missing_scope`: Prints required scope to stderr
- Persistent errors: check token validity, OAuth scopes, bot workspace membership

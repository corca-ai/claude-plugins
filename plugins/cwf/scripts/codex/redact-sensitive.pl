#!/usr/bin/env perl
use strict;
use warnings;

my $env_keys = qr/
  TAVILY_API_KEY|
  EXA_API_KEY|
  SLACK_BOT_TOKEN|
  OPENAI_API_KEY|
  ANTHROPIC_API_KEY|
  GEMINI_API_KEY|
  GOOGLE_API_KEY|
  GITHUB_TOKEN|
  GH_TOKEN|
  AWS_ACCESS_KEY_ID|
  AWS_SECRET_ACCESS_KEY
/ix;

while (<>) {
  # Provider-specific token shapes commonly leaked in command output.
  s/\btvly-[A-Za-z0-9._-]{8,}\b/tvly-REDACTED/g;
  s/\bxox[baprs]-[A-Za-z0-9-]{8,}\b/xoxb-REDACTED/g;
  s/\bsk-[A-Za-z0-9]{20,}\b/sk-REDACTED/g;

  # Assignments in plain-text shell snippets.
  s/\b($env_keys)\s*=\s*"[^"]*"/$1="REDACTED"/gi;
  s/\b($env_keys)\s*=\s*'[^']*'/$1='REDACTED'/gi;

  # Generic bearer header fallback.
  s/\b(Authorization:\s*Bearer\s+)[A-Za-z0-9._-]{10,}/${1}REDACTED/gi;

  print;
}

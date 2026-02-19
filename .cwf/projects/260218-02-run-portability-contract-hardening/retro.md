# Retrospective

- Mode: light

## What Worked
- Contract split and `$CWF_PLUGIN_ROOT` command resolution removed implicit dependency on this repository layout.
- Hook SHA marker + sync check made generated-hook drift deterministic.
- Portability fixtures caught an interaction bug (markdownlint failure masking index-coverage expectation).

## What Needed Correction
- Initial contract placement under repository root was not portable for installed-plugin execution.
- Fixture assertion order assumed index-coverage execution without guaranteeing markdownlint preconditions.

## Prevention
- Keep all run-time contracts under plugin root and execute gate commands via `$CWF_PLUGIN_ROOT`.
- Keep authoring-only checks out of `portable` profile by default; add only checks proven safe in arbitrary host repos.

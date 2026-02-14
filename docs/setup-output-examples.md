# Setup Output Examples

Concrete output files captured from external temporary directories for each setup flag path.

## Important Note About AGENTS Samples

For `--target agents` (and `--target both`), setup updates only the managed block in [AGENTS.md](../AGENTS.md):

- `<!-- CWF:INDEX:START -->`
- `<!-- CWF:INDEX:END -->`

Everything outside that block remains user-owned and unchanged. So AGENTS samples in this folder intentionally show only managed-block output, not the full project AGENTS document.

## `cwf:setup --cap-index`

- Output file: [docs/setup-output-samples/cap-index/cwf-index.md](setup-output-samples/cap-index/cwf-index.md)

## `cwf:setup --repo-index --target file`

- Output file: [docs/setup-output-samples/repo-index-file/repo-index.md](setup-output-samples/repo-index-file/repo-index.md)

## `cwf:setup --repo-index --target agents`

- Output file: [docs/setup-output-samples/repo-index-agents/AGENTS.md](setup-output-samples/repo-index-agents/AGENTS.md)

## `cwf:setup --repo-index --target both`

- Output files:
  - [docs/setup-output-samples/repo-index-both/repo-index.md](setup-output-samples/repo-index-both/repo-index.md)
  - [docs/setup-output-samples/repo-index-both/AGENTS.md](setup-output-samples/repo-index-both/AGENTS.md)

## `cwf:setup` (full setup) with repo-index skipped

- Output file:
  - [docs/setup-output-samples/full-setup-no-repo/cwf-index.md](setup-output-samples/full-setup-no-repo/cwf-index.md)

## `cwf:setup` (full setup) with repo-index target=`both`

- Output files:
  - [docs/setup-output-samples/full-setup-repo-both/cwf-index.md](setup-output-samples/full-setup-repo-both/cwf-index.md)
  - [docs/setup-output-samples/full-setup-repo-both/repo-index.md](setup-output-samples/full-setup-repo-both/repo-index.md)
  - [docs/setup-output-samples/full-setup-repo-both/AGENTS.md](setup-output-samples/full-setup-repo-both/AGENTS.md)

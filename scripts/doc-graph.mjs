#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const target = resolve(scriptDir, '../plugins/cwf/skills/refactor/scripts/doc-graph.mjs');

const result = spawnSync(process.execPath, [target, ...process.argv.slice(2)], {
  stdio: 'inherit'
});

process.exit(result.status ?? 1);

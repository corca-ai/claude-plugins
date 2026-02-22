#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const DEFAULT_SOURCE = ".cwf/projects/260219-01-pre-release-audit-pass2";
const DEFAULT_OUTPUT = ".cwf/projects/260222-02-scenario-dashboard-html/scenario-dashboard.html";
const DELTA_ORDER = ["NEW", "IMPROVED", "REGRESSED", "CHANGED", "UNCHANGED"];
const STATUS_RANK = {
  FAIL: 0,
  UNKNOWN: 1,
  SKIP: 1,
  PARTIAL: 2,
  DONE: 3,
  PASS: 4,
};

function usage() {
  console.log(`build-scenario-dashboard.mjs

Usage:
  node build-scenario-dashboard.mjs [options]

Options:
  --source <project-dir>            Scenario project directory
  --output <html-file>              Output HTML file path
  --compare-mode <mode>             Delta mode: none|previous-iteration|baseline-project
  --baseline-source <project-dir>   Baseline project directory for compare mode

Defaults:
  --source ${DEFAULT_SOURCE}
  --output ${DEFAULT_OUTPUT}
  --compare-mode previous-iteration

Notes:
  - previous-iteration: compare each scenario row against the last status of the same
    scenario key suffix in earlier iterations (for example K46, R60).
  - baseline-project: compare against latest statuses from --baseline-source.
  - none: disable delta comparison (all rows marked UNCHANGED).
`);
}

function parseArgs(argv) {
  const defaults = {
    source: DEFAULT_SOURCE,
    output: DEFAULT_OUTPUT,
    compareMode: "previous-iteration",
    baselineSource: "",
  };
  const args = { ...defaults };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];

    if (arg === "--source") {
      args.source = argv[i + 1] || "";
      i += 1;
      continue;
    }

    if (arg === "--output") {
      args.output = argv[i + 1] || "";
      i += 1;
      continue;
    }

    if (arg === "--compare-mode") {
      args.compareMode = argv[i + 1] || "";
      i += 1;
      continue;
    }

    if (arg === "--baseline-source") {
      args.baselineSource = argv[i + 1] || "";
      i += 1;
      continue;
    }

    if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    }

    throw new Error(`Unknown option: ${arg}`);
  }

  if (args.baselineSource && args.compareMode === "previous-iteration") {
    args.compareMode = "baseline-project";
  }

  const validModes = new Set(["none", "previous-iteration", "baseline-project"]);
  if (!validModes.has(args.compareMode)) {
    throw new Error(`Invalid --compare-mode: ${args.compareMode}`);
  }

  return args;
}

function toPosix(p) {
  return p.split(path.sep).join("/");
}

function ensureDotSlash(relPath) {
  if (relPath.startsWith(".") || relPath.startsWith("/")) {
    return relPath;
  }
  return `./${relPath}`;
}

function statusGroup(rawStatus) {
  const normalized = (rawStatus || "UNKNOWN").trim();
  const group = normalized.split("(")[0].trim();
  return group || "UNKNOWN";
}

function normalizeScenarioId(id) {
  return (id || "").trim().replace(/^I\d+-/, "");
}

function statusRank(group) {
  return STATUS_RANK[group] ?? STATUS_RANK.UNKNOWN;
}

function classifyDelta(currentStatus, baselineStatus) {
  if (!baselineStatus) {
    return "NEW";
  }

  const currentGroup = statusGroup(currentStatus);
  const baselineGroup = statusGroup(baselineStatus);
  const currentRank = statusRank(currentGroup);
  const baselineRank = statusRank(baselineGroup);

  if (currentRank > baselineRank) {
    return "IMPROVED";
  }
  if (currentRank < baselineRank) {
    return "REGRESSED";
  }
  if (currentStatus.trim() !== baselineStatus.trim()) {
    return "CHANGED";
  }
  return "UNCHANGED";
}

function parseTableRow(line) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((cell) => cell.trim());
}

function findColumnIndex(headers, candidates) {
  const normalized = headers.map((h) => h.toLowerCase().replace(/\s+/g, ""));
  for (const candidate of candidates) {
    const c = candidate.toLowerCase().replace(/\s+/g, "");
    const idx = normalized.findIndex((h) => h === c || h.includes(c));
    if (idx >= 0) {
      return idx;
    }
  }
  return -1;
}

function extractMarkdownLink(markdownText) {
  const match = markdownText.match(/\[([^\]]+)\]\(([^)]+)\)/);
  if (!match) {
    return null;
  }
  return { label: match[1], href: match[2] };
}

function parseMasterScenarios(masterFileAbs) {
  const content = fs.readFileSync(masterFileAbs, "utf8");
  const lines = content.split(/\r?\n/);
  const tableLines = [];
  let inTable = false;

  for (const line of lines) {
    if (/^\|.*\|$/.test(line.trim())) {
      tableLines.push(line);
      inTable = true;
      continue;
    }
    if (inTable) {
      break;
    }
  }

  if (tableLines.length < 3) {
    return [];
  }

  const headers = parseTableRow(tableLines[0]);
  const idIdx = findColumnIndex(headers, ["id"]);
  const categoryIdx = findColumnIndex(headers, ["category", "분류"]);
  const goalIdx = findColumnIndex(headers, ["goal", "목표"]);
  const statusIdx = findColumnIndex(headers, ["status", "상태"]);
  const notesIdx = findColumnIndex(headers, ["notes", "기록파일", "note"]);

  const rows = [];
  for (let i = 2; i < tableLines.length; i += 1) {
    const cells = parseTableRow(tableLines[i]);
    const id = idIdx >= 0 ? cells[idIdx] : cells[0];
    if (!id || !/^I\d+-/.test(id)) {
      continue;
    }
    const category = categoryIdx >= 0 ? cells[categoryIdx] : "";
    const goal = goalIdx >= 0 ? cells[goalIdx] : "";
    const status = statusIdx >= 0 ? cells[statusIdx] : "";
    const notes = notesIdx >= 0 ? cells[notesIdx] : "";
    rows.push({ id, category, goal, status, notes });
  }

  return rows;
}

function splitSections(markdown) {
  const sections = {};
  const lines = markdown.split(/\r?\n/);
  let current = "body";
  sections[current] = [];

  for (const line of lines) {
    const headingMatch = line.match(/^##\s+(.+)$/);
    if (headingMatch) {
      current = headingMatch[1].trim();
      sections[current] = [];
      continue;
    }
    sections[current].push(line);
  }

  const trimmed = {};
  for (const [name, sectionLines] of Object.entries(sections)) {
    trimmed[name] = sectionLines.join("\n").trim();
  }

  return trimmed;
}

function normalizeHeading(text) {
  return text.toLowerCase().replace(/\s+/g, "");
}

function pickSection(sections, candidates) {
  const entries = Object.entries(sections);
  for (const candidate of candidates) {
    const normalized = normalizeHeading(candidate);
    const found = entries.find(([name]) => normalizeHeading(name).includes(normalized));
    if (found && found[1]) {
      return found[1];
    }
  }
  return "";
}

function extractStatusFromScenario(markdown) {
  const directMatch = markdown.match(/(?:상태|Status)\s*:\s*([^\n]+)/i);
  if (directMatch) {
    return directMatch[1].trim();
  }
  return "";
}

function extractLinks(markdown, scenarioFileAbs, sourceRootAbs, outputDirAbs) {
  const links = [];
  const regex = /\[([^\]]+)\]\(([^)]+)\)/g;
  let match;

  while ((match = regex.exec(markdown)) !== null) {
    const label = match[1].trim();
    const hrefRaw = match[2].trim();

    if (
      hrefRaw.startsWith("http://") ||
      hrefRaw.startsWith("https://") ||
      hrefRaw.startsWith("mailto:") ||
      hrefRaw.startsWith("#")
    ) {
      links.push({
        label,
        href: hrefRaw,
        sourcePath: hrefRaw,
        exists: true,
        kind: "external",
      });
      continue;
    }

    const resolved = path.resolve(path.dirname(scenarioFileAbs), hrefRaw);
    const relFromOutput = ensureDotSlash(toPosix(path.relative(outputDirAbs, resolved)));
    const sourcePath = ensureDotSlash(toPosix(path.relative(sourceRootAbs, resolved)));
    const exists = fs.existsSync(resolved);
    links.push({
      label,
      href: relFromOutput,
      sourcePath,
      exists,
      kind: "local",
    });
  }

  return links;
}

function readIterationDirs(projectRootAbs) {
  return fs
    .readdirSync(projectRootAbs, { withFileTypes: true })
    .filter((d) => d.isDirectory() && /^iter\d+$/.test(d.name))
    .map((d) => d.name)
    .sort((a, b) => Number(a.replace("iter", "")) - Number(b.replace("iter", "")));
}

function buildBaselineStatusIndex(projectRootAbs) {
  const index = new Map();
  const iterations = readIterationDirs(projectRootAbs);

  for (const iteration of iterations) {
    const masterAbs = path.join(projectRootAbs, iteration, "master-scenarios.md");
    if (!fs.existsSync(masterAbs)) {
      continue;
    }

    const rows = parseMasterScenarios(masterAbs);
    for (const row of rows) {
      const normId = normalizeScenarioId(row.id);
      if (!normId) {
        continue;
      }
      const finalStatus = (row.status || "UNKNOWN").trim() || "UNKNOWN";
      index.set(normId, { status: finalStatus, iteration });
    }
  }

  return index;
}

function collectScenarios(sourceRootAbs, outputDirAbs) {
  const iterationDirs = readIterationDirs(sourceRootAbs);
  const scenarios = [];

  for (const iteration of iterationDirs) {
    const iterationAbs = path.join(sourceRootAbs, iteration);
    const masterAbs = path.join(iterationAbs, "master-scenarios.md");
    if (!fs.existsSync(masterAbs)) {
      continue;
    }

    const rows = parseMasterScenarios(masterAbs);
    for (const row of rows) {
      const notesLink = extractMarkdownLink(row.notes || "");
      const scenarioAbs = notesLink
        ? path.resolve(path.dirname(masterAbs), notesLink.href)
        : path.join(iterationAbs, "scenarios", `${row.id}.md`);
      if (!fs.existsSync(scenarioAbs)) {
        continue;
      }

      const md = fs.readFileSync(scenarioAbs, "utf8");
      const titleMatch = md.match(/^#\s+(.+)$/m);
      const sections = splitSections(md);
      const objective = pickSection(sections, ["목적", "Objective"]);
      const execution = pickSection(sections, ["실행 환경", "실행 로그", "Evidence", "Execution"]);
      const observation = pickSection(sections, ["관찰", "Observation"]);
      const verdict = pickSection(sections, ["판정", "Verdict"]);
      const extractedStatus = extractStatusFromScenario(md);
      const finalStatus = (row.status || extractedStatus || "UNKNOWN").trim();
      const finalGroup = statusGroup(finalStatus);
      const links = extractLinks(md, scenarioAbs, sourceRootAbs, outputDirAbs);

      scenarios.push({
        key: `${iteration}:${row.id}`,
        normId: normalizeScenarioId(row.id),
        iteration,
        iterationNumber: Number(iteration.replace("iter", "")),
        id: row.id,
        title: titleMatch ? titleMatch[1].trim() : row.id,
        category: row.category,
        goal: row.goal,
        status: finalStatus,
        statusGroup: finalGroup,
        scenarioPath: ensureDotSlash(toPosix(path.relative(sourceRootAbs, scenarioAbs))),
        objective,
        execution,
        observation,
        verdict,
        links,
        baselineStatus: "",
        baselineIteration: "",
        deltaType: "UNCHANGED",
      });
    }
  }

  return { iterationDirs, scenarios };
}

function applyDelta(scenarios, compareMode, baselineIndex) {
  if (compareMode === "none") {
    for (const scenario of scenarios) {
      scenario.deltaType = "UNCHANGED";
      scenario.baselineStatus = "";
      scenario.baselineIteration = "";
    }
    return;
  }

  const cursor = new Map();
  if (compareMode === "baseline-project") {
    for (const [key, value] of baselineIndex.entries()) {
      cursor.set(key, value);
    }
  }

  for (const scenario of scenarios) {
    const previous = cursor.get(scenario.normId);
    scenario.baselineStatus = previous ? previous.status : "";
    scenario.baselineIteration = previous ? previous.iteration : "";
    scenario.deltaType = classifyDelta(scenario.status, scenario.baselineStatus);

    cursor.set(scenario.normId, {
      status: scenario.status,
      iteration: scenario.iteration,
    });
  }
}

function buildDashboardHtml(payload) {
  const dataJson = JSON.stringify(payload).replace(/</g, "\\u003c");
  return `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Scenario Branch Dashboard</title>
<style>
:root {
  --bg: #f7f6f2;
  --panel: #fffdf8;
  --ink: #1f2624;
  --muted: #5b6763;
  --line: #d7d8d0;
  --accent: #0f766e;
  --accent2: #b45309;
  --pass: #047857;
  --fail: #b91c1c;
  --partial: #b45309;
  --done: #1d4ed8;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: "IBM Plex Sans", "Segoe UI", Arial, sans-serif;
  background:
    radial-gradient(circle at 12% 8%, #fde68a 0%, transparent 30%),
    radial-gradient(circle at 88% 0%, #99f6e4 0%, transparent 28%),
    var(--bg);
  color: var(--ink);
}
header {
  padding: 24px 20px 14px;
  border-bottom: 1px solid var(--line);
  background: linear-gradient(135deg, #fff7ed 0%, #ecfeff 100%);
}
h1 { margin: 0; font-size: 1.4rem; }
.sub { margin-top: 8px; color: var(--muted); font-size: .92rem; }
.layout {
  display: grid;
  grid-template-columns: 340px 1fr;
  min-height: calc(100vh - 98px);
}
.controls {
  border-right: 1px solid var(--line);
  padding: 16px;
  background: #fcfbf7;
}
.panel {
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--panel);
  padding: 12px;
  margin-bottom: 12px;
}
.panel h2 {
  margin: 0 0 8px 0;
  font-size: .9rem;
  text-transform: uppercase;
  letter-spacing: .04em;
  color: var(--muted);
}
input[type="search"], select {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #b9c0bc;
  border-radius: 10px;
  background: #fff;
}
.checks { display: grid; gap: 7px; max-height: 220px; overflow: auto; }
label.check { display: flex; align-items: center; gap: 8px; font-size: .92rem; }
main { display: grid; grid-template-rows: 48% 52%; }
.table-wrap { overflow: auto; border-bottom: 1px solid var(--line); }
table { border-collapse: collapse; width: 100%; min-width: 980px; }
th, td { border-bottom: 1px solid var(--line); padding: 10px 12px; text-align: left; vertical-align: top; }
th { position: sticky; top: 0; background: #fffaf0; z-index: 1; font-size: .86rem; color: var(--muted); text-transform: uppercase; letter-spacing: .03em; }
tr:hover { background: #f0fdfa; cursor: pointer; }
tr.active { background: #e6fffa; }
tr.delta-regressed td:first-child { border-left: 4px solid #b91c1c; }
tr.delta-improved td:first-child { border-left: 4px solid #15803d; }
tr.delta-new td:first-child { border-left: 4px solid #6d28d9; }
.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 999px;
  font-size: .76rem;
  font-weight: 700;
  letter-spacing: .02em;
}
.badge.pass { background: #d1fae5; color: var(--pass); }
.badge.fail { background: #fee2e2; color: var(--fail); }
.badge.partial { background: #ffedd5; color: var(--partial); }
.badge.done { background: #dbeafe; color: var(--done); }
.badge.delta-new { background: #ede9fe; color: #5b21b6; }
.badge.delta-improved { background: #dcfce7; color: #166534; }
.badge.delta-regressed { background: #fee2e2; color: #991b1b; }
.badge.delta-changed { background: #ffedd5; color: #9a3412; }
.badge.delta-unchanged { background: #e5e7eb; color: #374151; }
.details { padding: 16px; overflow: auto; }
.details h2 { margin: 0 0 6px 0; font-size: 1.16rem; }
.meta { color: var(--muted); font-size: .9rem; margin-bottom: 12px; }
.grid { display: grid; grid-template-columns: repeat(2, minmax(220px, 1fr)); gap: 10px; }
.card {
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 10px;
  background: #fff;
}
.card h3 { margin: 0 0 6px 0; font-size: .88rem; text-transform: uppercase; letter-spacing: .03em; color: var(--muted); }
.card pre {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  font: 0.88rem/1.45 ui-monospace, SFMono-Regular, Menlo, monospace;
}
.links { margin: 0; padding-left: 18px; }
.links li { margin: 4px 0; }
.links a { color: var(--accent); text-decoration: none; }
.links a:hover { text-decoration: underline; }
.count { font-size: .9rem; color: var(--muted); margin-top: 8px; }
@media (max-width: 980px) {
  .layout { grid-template-columns: 1fr; }
  .controls { border-right: 0; border-bottom: 1px solid var(--line); }
  main { grid-template-rows: 52vh auto; }
}
</style>
</head>
<body>
<header>
  <h1>Scenario Branch Dashboard</h1>
  <div class="sub" id="headerMeta"></div>
</header>
<div class="layout">
  <aside class="controls">
    <div class="panel">
      <h2>Search</h2>
      <input id="search" type="search" placeholder="ID, goal, status, keywords">
    </div>
    <div class="panel">
      <h2>Iteration</h2>
      <select id="iterationSelect"></select>
    </div>
    <div class="panel">
      <h2>Status Filters</h2>
      <div class="checks" id="statusChecks"></div>
      <div class="count" id="resultCount"></div>
    </div>
    <div class="panel">
      <h2>Delta Filters</h2>
      <div class="checks" id="deltaChecks"></div>
      <div class="count" id="deltaSummary"></div>
    </div>
  </aside>
  <main>
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Status</th>
            <th>Delta</th>
            <th>ID</th>
            <th>Iteration</th>
            <th>Category</th>
            <th>Goal</th>
          </tr>
        </thead>
        <tbody id="rows"></tbody>
      </table>
    </div>
    <section class="details" id="details"></section>
  </main>
</div>

<script id="scenarioData" type="application/json">${dataJson}</script>
<script>
const payload = JSON.parse(document.getElementById("scenarioData").textContent);
const state = {
  query: "",
  iteration: "all",
  statuses: new Set(payload.statusGroups),
  deltas: new Set(payload.deltaTypes),
  selectedKey: null,
};

const rowsEl = document.getElementById("rows");
const detailsEl = document.getElementById("details");
const resultCountEl = document.getElementById("resultCount");
const iterationSelect = document.getElementById("iterationSelect");
const statusChecksEl = document.getElementById("statusChecks");
const deltaChecksEl = document.getElementById("deltaChecks");
const deltaSummaryEl = document.getElementById("deltaSummary");
const headerMeta = document.getElementById("headerMeta");

function escapeHtml(value) {
  return String(value || "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

const headerParts = [
  "source: " + payload.sourceDir,
  "generated: " + payload.generatedAt,
  "scenarios: " + payload.scenarios.length,
  "compare: " + payload.compareMode,
  "changed: " + payload.changedCount,
];
if (payload.latestIteration) {
  headerParts.push(
    "latest " + payload.latestIteration + " changed: " +
      payload.latestChangedCount + "/" + payload.latestScenarioCount,
  );
}
if (payload.baselineSourceDir) {
  headerParts.push("baseline: " + payload.baselineSourceDir);
}
headerMeta.textContent = headerParts.join(" | ");

iterationSelect.innerHTML = '<option value="all">All iterations</option>' +
  payload.iterations.map((it) => '<option value="' + escapeHtml(it) + '">' + escapeHtml(it) + '</option>').join("");
iterationSelect.addEventListener("change", () => {
  state.iteration = iterationSelect.value;
  render();
});

statusChecksEl.innerHTML = payload.statusGroups.map((status) => {
  const count = payload.statusCounts[status] || 0;
  return '<label class="check"><input type="checkbox" value="' + escapeHtml(status) + '" checked> ' +
    '<span>' + escapeHtml(status) + ' (' + count + ')</span></label>';
}).join("");
statusChecksEl.querySelectorAll("input[type=checkbox]").forEach((checkbox) => {
  checkbox.addEventListener("change", () => {
    const value = checkbox.value;
    if (checkbox.checked) {
      state.statuses.add(value);
    } else {
      state.statuses.delete(value);
    }
    render();
  });
});

deltaChecksEl.innerHTML = payload.deltaTypes.map((deltaType) => {
  const count = payload.deltaCounts[deltaType] || 0;
  return '<label class="check"><input type="checkbox" value="' + escapeHtml(deltaType) + '" checked> ' +
    '<span>' + escapeHtml(deltaType) + ' (' + count + ')</span></label>';
}).join("");
deltaChecksEl.querySelectorAll("input[type=checkbox]").forEach((checkbox) => {
  checkbox.addEventListener("change", () => {
    const value = checkbox.value;
    if (checkbox.checked) {
      state.deltas.add(value);
    } else {
      state.deltas.delete(value);
    }
    render();
  });
});

document.getElementById("search").addEventListener("input", (event) => {
  state.query = event.target.value.toLowerCase().trim();
  render();
});

function statusBadgeClass(group) {
  if (group === "PASS") return "pass";
  if (group === "FAIL") return "fail";
  if (group === "PARTIAL") return "partial";
  if (group === "DONE") return "done";
  return "partial";
}

function deltaBadgeClass(deltaType) {
  if (deltaType === "NEW") return "delta-new";
  if (deltaType === "IMPROVED") return "delta-improved";
  if (deltaType === "REGRESSED") return "delta-regressed";
  if (deltaType === "CHANGED") return "delta-changed";
  return "delta-unchanged";
}

function deltaRowClass(deltaType) {
  if (deltaType === "NEW") return "delta-new";
  if (deltaType === "IMPROVED") return "delta-improved";
  if (deltaType === "REGRESSED") return "delta-regressed";
  return "";
}

function filterScenarios() {
  return payload.scenarios.filter((item) => {
    if (state.iteration !== "all" && item.iteration !== state.iteration) {
      return false;
    }
    if (!state.statuses.has(item.statusGroup)) {
      return false;
    }
    if (!state.deltas.has(item.deltaType)) {
      return false;
    }
    if (!state.query) {
      return true;
    }

    const haystack = [
      item.id,
      item.normId,
      item.category,
      item.goal,
      item.status,
      item.deltaType,
      item.baselineStatus,
      item.objective,
      item.observation,
      item.verdict,
      item.scenarioPath,
    ].join(" ").toLowerCase();

    return haystack.includes(state.query);
  });
}

function renderRows(items) {
  rowsEl.innerHTML = items.map((item) => {
    const key = item.key;
    const activeClass = key === state.selectedKey ? "active" : "";
    const deltaClass = deltaRowClass(item.deltaType);
    const rowClass = [activeClass, deltaClass].filter(Boolean).join(" ");
    const baselineLabel = item.baselineStatus
      ? (item.baselineIteration ? item.baselineIteration + ": " : "") + item.baselineStatus
      : "no baseline";

    return '<tr class="' + rowClass + '" data-key="' + escapeHtml(key) + '">' +
      '<td><span class="badge ' + statusBadgeClass(item.statusGroup) + '">' + escapeHtml(item.statusGroup) + '</span><br><small>' + escapeHtml(item.status) + '</small></td>' +
      '<td><span class="badge ' + deltaBadgeClass(item.deltaType) + '">' + escapeHtml(item.deltaType) + '</span><br><small>' + escapeHtml(baselineLabel) + '</small></td>' +
      '<td><strong>' + escapeHtml(item.id) + '</strong><br><small>' + escapeHtml(item.normId) + '</small></td>' +
      '<td>' + escapeHtml(item.iteration) + '</td>' +
      '<td>' + escapeHtml(item.category || "-") + '</td>' +
      '<td>' + escapeHtml(item.goal || "-") + '</td>' +
      '</tr>';
  }).join("");

  rowsEl.querySelectorAll("tr").forEach((tr) => {
    tr.addEventListener("click", () => {
      state.selectedKey = tr.getAttribute("data-key");
      render();
    });
  });
}

function renderDetails(item) {
  if (!item) {
    detailsEl.innerHTML = "<p>No scenario matches the current filters.</p>";
    return;
  }

  const links = item.links.length > 0
    ? '<ul class="links">' + item.links.map((link) => (
      '<li><a href="' + escapeHtml(link.href) + '" target="_blank" rel="noreferrer">' +
      escapeHtml(link.label) + '</a> <small>(' + escapeHtml(link.sourcePath) + (link.exists ? "" : ", missing") + ')</small></li>'
    )).join("") + "</ul>"
    : "<p>No linked evidence.</p>";

  const baselineSummary = item.baselineStatus
    ? (item.baselineIteration ? item.baselineIteration + " | " : "") + item.baselineStatus
    : "none";

  detailsEl.innerHTML = [
    "<h2>" + escapeHtml(item.id) + " — " + escapeHtml(item.title) + "</h2>",
    '<div class="meta">' +
      "iteration: " + escapeHtml(item.iteration) +
      " | category: " + escapeHtml(item.category || "-") +
      " | status: " + escapeHtml(item.status) +
      " | delta: " + escapeHtml(item.deltaType) +
      " | file: " + escapeHtml(item.scenarioPath) +
    "</div>",
    '<div class="grid">',
      '<div class="card"><h3>Delta</h3><pre>' +
      escapeHtml("baseline: " + baselineSummary + "\ncurrent: " + item.status + "\nmode: " + payload.compareMode) +
      "</pre></div>",
      '<div class="card"><h3>Goal</h3><pre>' + escapeHtml(item.goal || "-") + "</pre></div>",
      '<div class="card"><h3>Objective</h3><pre>' + escapeHtml(item.objective || "-") + "</pre></div>",
      '<div class="card"><h3>Observation</h3><pre>' + escapeHtml(item.observation || "-") + "</pre></div>",
      '<div class="card"><h3>Verdict</h3><pre>' + escapeHtml(item.verdict || "-") + "</pre></div>",
      '<div class="card"><h3>Execution / Evidence</h3><pre>' + escapeHtml(item.execution || "-") + "</pre></div>",
      '<div class="card"><h3>Linked Artifacts</h3>' + links + "</div>",
    "</div>",
  ].join("");
}

function render() {
  const filtered = filterScenarios();
  if (!state.selectedKey || !filtered.some((item) => item.key === state.selectedKey)) {
    state.selectedKey = filtered.length > 0 ? filtered[0].key : null;
  }

  renderRows(filtered);
  const selected = filtered.find((item) => item.key === state.selectedKey) || null;
  renderDetails(selected);

  const changedInView = filtered.filter((item) => item.deltaType !== "UNCHANGED").length;
  resultCountEl.textContent = "Showing " + filtered.length + " / " + payload.scenarios.length + " scenarios";
  deltaSummaryEl.textContent =
    "Changed in view: " + changedInView + " / " + filtered.length +
    " | changed total: " + payload.changedCount + " / " + payload.scenarios.length +
    (payload.latestIteration
      ? " | latest " + payload.latestIteration + ": " +
        payload.latestChangedCount + " / " + payload.latestScenarioCount
      : "");
}

render();
</script>
</body>
</html>`;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const sourceRootAbs = path.resolve(args.source);
  const outputAbs = path.resolve(args.output);
  const outputDirAbs = path.dirname(outputAbs);

  if (!fs.existsSync(sourceRootAbs)) {
    throw new Error(`Source project directory does not exist: ${sourceRootAbs}`);
  }

  let baselineRootAbs = "";
  if (args.compareMode === "baseline-project") {
    if (!args.baselineSource) {
      throw new Error("--compare-mode baseline-project requires --baseline-source");
    }
    baselineRootAbs = path.resolve(args.baselineSource);
    if (!fs.existsSync(baselineRootAbs)) {
      throw new Error(`Baseline project directory does not exist: ${baselineRootAbs}`);
    }
  }

  const { iterationDirs, scenarios } = collectScenarios(sourceRootAbs, outputDirAbs);
  const baselineIndex =
    args.compareMode === "baseline-project"
      ? buildBaselineStatusIndex(baselineRootAbs)
      : new Map();

  applyDelta(scenarios, args.compareMode, baselineIndex);

  const statusCounts = {};
  const deltaCounts = {};
  let changedCount = 0;
  for (const item of scenarios) {
    statusCounts[item.statusGroup] = (statusCounts[item.statusGroup] || 0) + 1;
    deltaCounts[item.deltaType] = (deltaCounts[item.deltaType] || 0) + 1;
    if (item.deltaType !== "UNCHANGED") {
      changedCount += 1;
    }
  }

  const statusGroups = Object.keys(statusCounts).sort((a, b) => a.localeCompare(b));
  const deltaTypes = DELTA_ORDER.filter((deltaType) => (deltaCounts[deltaType] || 0) > 0);
  const latestIteration = iterationDirs.length > 0 ? iterationDirs[iterationDirs.length - 1] : "";
  const latestScenarios = latestIteration
    ? scenarios.filter((item) => item.iteration === latestIteration)
    : [];
  const latestChangedCount = latestScenarios.filter(
    (item) => item.deltaType !== "UNCHANGED",
  ).length;

  const payload = {
    sourceDir: ensureDotSlash(toPosix(path.relative(process.cwd(), sourceRootAbs))),
    baselineSourceDir: baselineRootAbs
      ? ensureDotSlash(toPosix(path.relative(process.cwd(), baselineRootAbs)))
      : "",
    compareMode: args.compareMode,
    generatedAt: new Date().toISOString(),
    iterations: iterationDirs,
    statusGroups,
    statusCounts,
    deltaTypes,
    deltaCounts,
    changedCount,
    latestIteration,
    latestScenarioCount: latestScenarios.length,
    latestChangedCount,
    scenarios,
  };

  fs.mkdirSync(outputDirAbs, { recursive: true });
  fs.writeFileSync(outputAbs, buildDashboardHtml(payload), "utf8");

  console.log(`Generated dashboard: ${toPosix(path.relative(process.cwd(), outputAbs))}`);
  console.log(`Scenarios: ${scenarios.length}`);
  console.log(`Iterations: ${iterationDirs.join(", ")}`);
  console.log(`Status groups: ${statusGroups.join(", ")}`);
  console.log(`Compare mode: ${args.compareMode}`);
  if (payload.baselineSourceDir) {
    console.log(`Baseline source: ${payload.baselineSourceDir}`);
  }
  console.log(`Changed scenarios: ${changedCount}`);
  if (latestIteration) {
    console.log(
      `Latest iteration delta: ${latestIteration} ${latestChangedCount}/${latestScenarios.length}`,
    );
  }
  console.log(
    `Delta groups: ${deltaTypes
      .map((name) => `${name}=${deltaCounts[name] || 0}`)
      .join(", ")}`,
  );
}

try {
  main();
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}

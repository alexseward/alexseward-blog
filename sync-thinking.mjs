#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const args = process.argv.slice(2);

function readArg(name, fallback) {
  const equals = args.find((arg) => arg.startsWith(`${name}=`));
  if (equals) return equals.slice(name.length + 1);

  const index = args.indexOf(name);
  if (index >= 0 && args[index + 1]) return args[index + 1];

  return fallback;
}

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const home = os.homedir();
const maxRecent = Number.parseInt(readArg('--max-recent', '24'), 10);
const outputPath = path.resolve(readArg('--output-path', path.join(scriptDir, 'data', 'thinking.json')));

const vaultCandidates = [
  process.env.THINKING_VAULT_PATH,
  path.join(home, 'Library/Mobile Documents/iCloud~md~obsidian/Documents/Alex'),
  path.join(home, 'iCloudDrive/iCloud~md~obsidian/Alex'),
  path.join(home, 'iCloudDrive/iCloud~md~obsidian/Documents/Alex'),
].filter(Boolean);

const explicitVaultPath = readArg('--vault-path', null);
const vaultPath = explicitVaultPath || vaultCandidates.find((candidate) => fs.existsSync(candidate));

if (!vaultPath || !fs.existsSync(vaultPath)) {
  throw new Error(`Vault path not found. Pass --vault-path or set THINKING_VAULT_PATH. Checked: ${vaultCandidates.join(', ')}`);
}

function walkMarkdownFiles(root) {
  if (!fs.existsSync(root)) return [];

  const entries = fs.readdirSync(root, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const fullPath = path.join(root, entry.name);

    if (entry.isDirectory()) {
      if (['.trash', 'Templates', 'Artifacts', 'copilot', '.agents'].includes(entry.name)) continue;
      files.push(...walkMarkdownFiles(fullPath));
      continue;
    }

    if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }

  return files;
}

function markdownFileCount(root, recursive = false) {
  if (!fs.existsSync(root)) return 0;

  if (recursive) return walkMarkdownFiles(root).length;

  return fs.readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith('.md'))
    .length;
}

function publicTitle(filePath) {
  return path.basename(filePath, '.md')
    .replace(/\s+– Alex Seward$/, '')
    .replace(/\s+-\s+Alex Seward$/, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function isPublicIndexNote(relativePath, title) {
  const normalised = relativePath.split(path.sep).join('/');
  if (normalised.startsWith('Clippings/')) return false;

  const indexTitles = new Set([
    'Map of Content',
    'Blog Index',
    'Source Material Index',
    'Steelmen Index',
    'Intellectual Arc',
    'Glossary',
  ]);

  return indexTitles.has(title) || /\bIndex$/.test(title);
}

function noteKind(relativePath) {
  const normalised = relativePath.split(path.sep).join('/');
  if (normalised.startsWith('Clippings/')) return 'Reading';
  if (normalised.startsWith('Blog/')) return 'Writing';
  return 'Thinking';
}

function frontmatterDates(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if (!match) return {};

  const dates = {};
  for (const field of ['updated', 'created', 'published']) {
    const fieldMatch = match[1].match(new RegExp(`^${field}:\\s*["']?([^"'\\s]+)["']?\\s*$`, 'm'));
    if (!fieldMatch) continue;

    const parsed = new Date(fieldMatch[1]);
    if (!Number.isNaN(parsed.getTime())) dates[field] = parsed;
  }

  return dates;
}

function semanticDate(filePath, kind) {
  const dates = frontmatterDates(filePath);
  const priority = kind === 'Reading'
    ? ['created', 'updated', 'published']
    : kind === 'Writing'
      ? ['published', 'updated', 'created']
      : ['updated', 'created', 'published'];

  return priority.map((field) => dates[field]).find(Boolean) || new Date(0);
}

function topicDefinitions() {
  return [
    {
      Label: 'Agentic AI',
      Match: ['agentic', 'agents', 'agent'],
      Summary: 'Agentic AI, tools, prompt engineering, and new working patterns.',
      ClusterTitle: 'AI systems becoming working practice.',
    },
    {
      Label: 'Second brain',
      Match: ['second brain', 'knowledge', 'map of content', 'vault'],
      Summary: 'Personal knowledge management, memory, and AI-supported maintenance.',
      ClusterTitle: 'Personal knowledge becoming a working system.',
    },
    {
      Label: 'Adoption layer',
      Match: ['adoption', 'capability', 'pilot', 'production', 'impact'],
      Summary: 'The organisational gap between AI experiments and repeatable value.',
      ClusterTitle: 'AI adoption meeting organisational capability.',
    },
    {
      Label: 'Responsible AI',
      Match: ['responsible', 'governance', 'literacy', 'centre of excellence'],
      Summary: 'Governance, literacy, and the practices that make AI usable safely.',
      ClusterTitle: 'Responsible AI becoming practical governance.',
    },
    {
      Label: 'Data architecture',
      Match: ['data', 'architecture', 'rag', 'retrieval'],
      Summary: 'Data foundations, architecture, retrieval, and enterprise readiness.',
      ClusterTitle: 'Data foundations shaping AI readiness.',
    },
    {
      Label: 'Prompting',
      Match: ['prompt', 'prompting'],
      Summary: 'The craft of shaping model behaviour through language and context.',
      ClusterTitle: 'Prompting as a practical interface.',
    },
  ];
}

function topicScores(notes) {
  return topicDefinitions()
    .map((definition) => {
      const score = notes.filter((note) => {
        const haystack = `${note.Title} ${note.RelativePath}`.toLowerCase();
        return definition.Match.some((term) => haystack.includes(term));
      }).length;

      return { ...definition, Score: score };
    })
    .sort((a, b) => b.Score - a.Score || a.Label.localeCompare(b.Label));
}

function noteBreakdown() {
  const notesPath = path.join(vaultPath, 'Notes');
  if (!fs.existsSync(notesPath)) return [];

  return fs.readdirSync(notesPath, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && entry.name !== 'Steelmen')
    .map((entry) => ({
      Label: entry.name,
      Count: markdownFileCount(path.join(notesPath, entry.name), true),
    }))
    .sort((a, b) => b.Count - a.Count || a.Label.localeCompare(b.Label));
}

const safeRoots = [
  path.join('Clippings', 'Processed'),
  'Blog',
  path.join('Notes', 'Concepts'),
  path.join('Notes', 'Patterns'),
  path.join('Notes', 'Frameworks'),
];

const files = safeRoots.flatMap((root) => walkMarkdownFiles(path.join(vaultPath, root)));
const notes = files
  .map((filePath) => {
    const relativePath = path.relative(vaultPath, filePath);
    const title = publicTitle(filePath);
    if (isPublicIndexNote(relativePath, title)) return null;

    const kind = noteKind(relativePath);
    const updated = semanticDate(filePath, kind);

    return {
      Title: title,
      Kind: kind,
      RelativePath: relativePath.split(path.sep).join('/'),
      Updated: updated,
      SortTime: updated.getTime(),
    };
  })
  .filter(Boolean)
  .sort((a, b) => b.SortTime - a.SortTime || a.RelativePath.localeCompare(b.RelativePath))
  .slice(0, maxRecent);

const scores = topicScores(notes);
let activeTopics = scores.filter((score) => score.Score > 0).slice(0, 4);
if (activeTopics.length < 4) activeTopics = scores.slice(0, 4);

const topicPositions = ['node-agentic', 'node-second-brain', 'node-adoption', 'node-governance'];
const notePositions = ['node-capability', 'node-production', 'node-literacy', 'node-rag'];
const nodes = [{ Label: 'Current attention', Type: 'core', Class: 'constellation-node--core' }];

activeTopics.forEach((topic, index) => {
  nodes.push({ Label: topic.Label, Type: 'topic', Class: topicPositions[index] });
});

const topicLabels = new Set(activeTopics.map((topic) => topic.Label));
const noteNodes = notes
  .filter((note) => note.Kind === 'Thinking' && !topicLabels.has(note.Title))
  .sort((a, b) => a.Title.localeCompare(b.Title))
  .filter((note, index, array) => array.findIndex((candidate) => candidate.Title === note.Title) === index)
  .slice(0, 4);

noteNodes.forEach((note, index) => {
  nodes.push({ Label: note.Title, Type: 'note', Class: notePositions[index] });
});

const activeThreads = notes
  .filter((note) => !topicLabels.has(note.Title))
  .slice(0, 4)
  .map((note) => ({
    Title: note.Title,
    Kind: note.Kind,
    Meta: note.Kind === 'Reading' ? 'Recent clipping' : note.Kind === 'Writing' ? 'Writing signal' : 'Active note',
  }));

const topTopic = activeTopics[0] || {
  Label: 'Current attention',
  Summary: 'Recent vault activity, grouped into public-safe signals.',
  ClusterTitle: 'Recent ideas gathering momentum.',
};

const today = new Date();
const payload = {
  generatedAt: today.toISOString(),
  generatedLabel: new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }).format(today),
  source: 'Public-safe vault summary',
  hero: {
    eyebrow: 'Thinking now',
    title: "A living map of what I'm thinking about.",
    intro: 'Generated from a public-safe summary of my personal knowledge base: the things that have been recurring, connecting, or gathering momentum lately.',
  },
  stats: {
    notesSampled: notes.length,
    topics: activeTopics.length,
    readings: notes.filter((note) => note.Kind === 'Reading').length,
    writing: notes.filter((note) => note.Kind === 'Writing').length,
  },
  strongestCluster: {
    eyebrow: 'Current insight',
    title: topTopic.ClusterTitle,
    summary: topTopic.Summary,
  },
  nodes,
  activeThreads,
  bridges: [
    { From: 'AI adoption', To: 'organisational capability' },
    { From: 'Second brain', To: 'personal tooling' },
    { From: 'Governance', To: 'responsible practice' },
  ],
  dashboard: {
    title: 'Vault dashboard',
    summary: 'A public-safe view of the durable knowledge base behind this page: processed sources, wiki notes, and public writing.',
    funnel: [
      { Label: 'Processed clippings', Count: markdownFileCount(path.join(vaultPath, 'Clippings', 'Processed')), Description: 'Sources triaged and connected' },
      { Label: 'Wiki notes', Count: markdownFileCount(path.join(vaultPath, 'Notes'), true), Description: 'Synthesised concepts, frameworks, research, and patterns' },
      { Label: 'Blog files', Count: markdownFileCount(path.join(vaultPath, 'Blog')), Description: 'Public writing in the vault' },
    ],
    breakdown: noteBreakdown(),
  },
  updateNote: 'This page is periodically refreshed from a public-safe summary of my personal knowledge base.',
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');

console.log(`Thinking data written to ${outputPath}`);
console.log(`Sampled ${notes.length} recent notes from ${vaultPath}`);

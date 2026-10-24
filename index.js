#!/usr/bin/env node
'use strict';

// Entrypoint for panel hosts whose startup command is fixed to
// `node /home/container/${MAIN_FILE}`.
//
// It can run from a full checkout, or as the only uploaded file: when the
// server sources are missing it clones the game repository, bootstraps the
// vendored Showdown engine, installs the TypeScript server, and launches it.
//
// Set the panel's MAIN_FILE variable to `index.js`.
//
// Optional environment variables:
//   POKEVENTURE_REPO_URL     repository to clone
//   POKEVENTURE_REPO_BRANCH  branch to clone (default: main)
//   POKEVENTURE_REPO_DIR     clone destination (default: ./PokeNext)

const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const bootstrapDir = __dirname;
const repoUrl =
  process.env.POKEVENTURE_REPO_URL ||
  'https://github.com/iwannabeyourshere/PokeNext.git';
const repoBranch = process.env.POKEVENTURE_REPO_BRANCH || 'main';
const repoDir = process.env.POKEVENTURE_REPO_DIR
  ? path.resolve(bootstrapDir, process.env.POKEVENTURE_REPO_DIR)
  : path.join(bootstrapDir, 'PokeNext');
const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';

let root = bootstrapDir;

function log(message) {
  console.log(`==> ${message}`);
}

function fail(message) {
  console.error(`\n[Pokéventure] ${message}\n`);
  process.exit(1);
}

function exists(file) {
  return fs.existsSync(file);
}

function run(command, args, cwd) {
  const result = spawnSync(command, args, {
    cwd,
    stdio: 'inherit',
    env: { ...process.env, GIT_TERMINAL_PROMPT: '0' },
  });
  if (result.error) fail(result.error.message);
  if (result.status !== 0) {
    fail(`${command} ${args.join(' ')} failed with exit code ${result.status}.`);
  }
}

function checkNode() {
  const [major, minor] = process.versions.node.split('.').map(Number);
  if (major < 22 || (major === 22 && minor < 18)) {
    fail(
      `Node 22.18+ is required (found ${process.version}). ` +
        'Change the panel Node image, then restart.',
    );
  }
}

function hasServer(dir) {
  return (
    exists(path.join(dir, 'server', 'package.json')) &&
    exists(path.join(dir, 'server', 'src', 'index.ts'))
  );
}

function ensureRepository() {
  if (hasServer(root)) return;

  log('Game repository not found; cloning it');
  if (exists(repoDir) && fs.readdirSync(repoDir).length > 0) {
    if (hasServer(repoDir)) {
      root = repoDir;
      return;
    }
    fail(
      `The clone destination ${repoDir} is not empty and is not a complete ` +
        'checkout. Remove it, or set POKEVENTURE_REPO_DIR to another path.',
    );
  }

  const args = ['clone', '--depth', '1'];
  if (repoBranch) args.push('--branch', repoBranch);
  args.push(repoUrl, repoDir);
  run('git', args, bootstrapDir);

  if (!hasServer(repoDir)) {
    fail('The clone finished, but the server sources are still missing.');
  }
  root = repoDir;
}

function showdownPath(...parts) {
  return path.join(root, 'vendor', 'pokemon-showdown', ...parts);
}

function serverPath(...parts) {
  return path.join(root, 'server', ...parts);
}

function installShowdown() {
  const dir = showdownPath();
  const built = showdownPath('dist', 'sim', 'index.js');
  const esbuild = showdownPath(
    'node_modules',
    'esbuild',
    'bin',
    'esbuild',
  );
  if (exists(built) && exists(esbuild)) return;

  if (!exists(showdownPath('package.json'))) {
    log('Fetching the Showdown engine');
    fs.mkdirSync(path.dirname(dir), { recursive: true });
    run(
      'git',
      [
        'clone',
        '--depth',
        '1',
        'https://github.com/smogon/pokemon-showdown',
        dir,
      ],
      root,
    );
  }

  log('Installing Showdown');
  run(npm, ['install', '--ignore-scripts', '--no-audit', '--no-fund'], dir);

  // npm 12 blocks dependency install scripts, so esbuild's platform binary is
  // missing unless it is fetched explicitly.
  const installer = showdownPath(
    'node_modules',
    'esbuild',
    'install.js',
  );
  if (!exists(installer)) fail('esbuild was not installed in Showdown.');
  run(process.execPath, [installer], dir);

  log('Building Showdown');
  run(process.execPath, ['build'], dir);
}

function installServer() {
  const dir = serverPath();
  const tsx = serverPath('node_modules', 'tsx', 'dist', 'cli.mjs');
  const esbuild = serverPath(
    'node_modules',
    'esbuild',
    'bin',
    'esbuild',
  );
  if (exists(tsx) && exists(esbuild)) return;

  log('Installing the game server');
  run(
    npm,
    ['install', '--include=dev', '--ignore-scripts', '--no-audit', '--no-fund'],
    dir,
  );

  const installer = serverPath(
    'node_modules',
    'esbuild',
    'install.js',
  );
  if (!exists(installer)) fail('esbuild was not installed in the server.');
  run(process.execPath, [installer], dir);
}

function startServer() {
  const tsx = serverPath('node_modules', 'tsx', 'dist', 'cli.mjs');
  const entry = serverPath('src', 'index.ts');
  if (!exists(tsx) || !exists(entry)) {
    fail('The server dependencies or source are missing.');
  }

  const child = spawn(process.execPath, [tsx, entry], {
    cwd: serverPath(),
    stdio: 'inherit',
    env: process.env,
  });

  for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
    process.on(signal, () => {
      if (!child.killed) child.kill(signal);
    });
  }

  child.on('error', (error) => fail(error.message));
  child.on('exit', (code) => process.exit(code ?? 1));
}

checkNode();
ensureRepository();
installShowdown();
installServer();
startServer();

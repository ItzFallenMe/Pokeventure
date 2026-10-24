#!/usr/bin/env node
'use strict';

// Entrypoint for panel hosts whose startup command is fixed to
// `node /home/container/${MAIN_FILE}`. It bootstraps the vendored Showdown
// engine and the TypeScript server, then launches the server in the foreground.
//
// Set the panel's MAIN_FILE variable to `index.js`.

const { spawn, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const root = __dirname;
const showdownDir = path.join(root, 'vendor', 'pokemon-showdown');
const serverDir = path.join(root, 'server');
const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';

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
    env: process.env,
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

function installShowdown() {
  const built = path.join(showdownDir, 'dist', 'sim', 'index.js');
  const esbuild = path.join(showdownDir, 'node_modules', 'esbuild', 'bin', 'esbuild');
  if (exists(built) && exists(esbuild)) return;

  if (!exists(path.join(showdownDir, 'package.json'))) {
    log('Fetching the Showdown engine');
    fs.mkdirSync(path.dirname(showdownDir), { recursive: true });
    run(
      'git',
      [
        'clone',
        '--depth',
        '1',
        'https://github.com/smogon/pokemon-showdown',
        showdownDir,
      ],
      root,
    );
  }

  log('Installing Showdown');
  run(npm, ['install', '--ignore-scripts', '--no-audit', '--no-fund'], showdownDir);

  // npm 12 blocks dependency install scripts, so esbuild's platform binary is
  // missing unless it is fetched explicitly.
  const installer = path.join(
    showdownDir,
    'node_modules',
    'esbuild',
    'install.js',
  );
  if (!exists(installer)) fail('esbuild was not installed in Showdown.');
  run(process.execPath, [installer], showdownDir);

  log('Building Showdown');
  run(process.execPath, ['build'], showdownDir);
}

function installServer() {
  const tsx = path.join(serverDir, 'node_modules', 'tsx', 'dist', 'cli.mjs');
  const esbuild = path.join(serverDir, 'node_modules', 'esbuild', 'bin', 'esbuild');
  if (exists(tsx) && exists(esbuild)) return;

  log('Installing the game server');
  run(
    npm,
    ['install', '--include=dev', '--ignore-scripts', '--no-audit', '--no-fund'],
    serverDir,
  );

  const installer = path.join(serverDir, 'node_modules', 'esbuild', 'install.js');
  if (!exists(installer)) fail('esbuild was not installed in the server.');
  run(process.execPath, [installer], serverDir);
}

function startServer() {
  const tsx = path.join(serverDir, 'node_modules', 'tsx', 'dist', 'cli.mjs');
  const entry = path.join(serverDir, 'src', 'index.ts');
  if (!exists(tsx) || !exists(entry)) {
    fail('The server dependencies or source are missing.');
  }

  const child = spawn(process.execPath, [tsx, entry], {
    cwd: serverDir,
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
installShowdown();
installServer();
startServer();

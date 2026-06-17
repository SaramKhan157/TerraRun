import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { setTimeout as wait } from 'node:timers/promises';

const startServer = () => {
  const proc = spawn('node', ['src/index.js'], {
    env: { ...process.env, PORT: '8090' },
    stdio: 'pipe',
  });
  return proc;
};

test('GET /health returns 200 ok', async () => {
  const proc = startServer();
  try {
    await wait(500);
    const res = await fetch('http://127.0.0.1:8090/health');
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.deepEqual(body, { status: 'ok' });
  } finally {
    proc.kill('SIGTERM');
  }
});

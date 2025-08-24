import type { Summary, Volumes, CommitDetails } from './types';

const BASE = '/data-snapshot-test/data';

async function get<T>(path: string): Promise<T> {
  const res = await fetch(path, { cache: 'no-cache' });
  if (!res.ok) throw new Error(`GET ${path} failed: ${res.status}`);
  return res.json();
}

export function getSummary(): Promise<Summary> {
  return get<Summary>(`${BASE}/summary.json`);
}

export function getVolumes(): Promise<Volumes> {
  return get<Volumes>(`${BASE}/volumes.json`);
}

export function getCommit(hash: string): Promise<CommitDetails> {
  return get<CommitDetails>(`${BASE}/commits/${hash}.json`);
}

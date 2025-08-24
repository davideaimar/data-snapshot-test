import { writable } from 'svelte/store';
import { goto } from '$app/navigation';

export type Selection = {
  volumeA: string;
  commitA: string;
  volumeB: string;
  commitB: string;
};

function fromURL(): Selection {
  const url = new URL(window.location.href);
  return {
    volumeA: url.searchParams.get('va') ?? '',
    commitA: url.searchParams.get('ca') ?? '',
    volumeB: url.searchParams.get('vb') ?? '',
    commitB: url.searchParams.get('cb') ?? ''
  };
}

export const selection = writable<Selection>({ volumeA: '', commitA: '', volumeB: '', commitB: '' });

export function initFromURL() {
  selection.set(fromURL());
  window.addEventListener('popstate', () => selection.set(fromURL()));
}

let firstRun = true;

selection.subscribe((val) => {
  if (firstRun) { firstRun = false; return; }
  const url = new URL(window.location.href);
  const map: Record<string, string> = {
    va: val.volumeA,
    ca: val.commitA,
    vb: val.volumeB,
    cb: val.commitB
  };
  Object.entries(map).forEach(([k, v]) => {
    if (v) url.searchParams.set(k, v);
    else url.searchParams.delete(k);
  });
  goto(url.pathname + '?' + url.searchParams.toString(), { replaceState: true, noScroll: true });
});

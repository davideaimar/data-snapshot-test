<script lang="ts">
  import { onMount } from 'svelte';
  import { getVolumes, getCommit } from '$lib/api';
  import { selection, initFromURL } from '$lib/store';
  import VolumeSelector from '$lib/components/VolumeSelector.svelte';
  import CommitSelector from '$lib/components/CommitSelector.svelte';
  import HistoryTimeline from '$lib/components/HistoryTimeline.svelte';
  import ComparisonView from '$lib/components/ComparisonView.svelte';
  import type { Volumes, CommitDetails } from '$lib/types';

  let volumes: Volumes | null = null;
  let commitA: CommitDetails | null = null;
  let commitB: CommitDetails | null = null;
  let state: any;
  selection.subscribe((v) => state = v);

  onMount(async () => {
    initFromURL();
    volumes = await getVolumes();
    if (state.commitA) commitA = await getCommit(state.commitA);
    if (state.commitB) commitB = await getCommit(state.commitB);
  });

  async function setVolumeA(v: string) {
    selection.set({ ...state, volumeA: v, commitA: '' }); commitA = null;
  }
  async function setVolumeB(v: string) {
    selection.set({ ...state, volumeB: v, commitB: '' }); commitB = null;
  }
  async function setCommitA(hash: string) {
    selection.set({ ...state, commitA: hash }); commitA = hash ? await getCommit(hash) : null;
  }
  async function setCommitB(hash: string) {
    selection.set({ ...state, commitB: hash }); commitB = hash ? await getCommit(hash) : null;
  }
</script>

{#if volumes}
  <div class="grid md:grid-cols-2 gap-4">
    <section class="border rounded p-3">
      <h2 class="font-semibold mb-2">Commit A</h2>
      <VolumeSelector {volumes} selected={state?.volumeA} onChange={setVolumeA} />
      {#if state?.volumeA}
        <div class="my-2">
          <CommitSelector commits={volumes.volumes[state.volumeA]?.commits} selected={state.commitA} onChange={setCommitA} />
        </div>
        <HistoryTimeline commits={volumes.volumes[state.volumeA]?.commits} selected={state.commitA} onSelect={setCommitA} />
      {/if}
    </section>

    <section class="border rounded p-3">
      <h2 class="font-semibold mb-2">Commit B</h2>
      <VolumeSelector {volumes} selected={state?.volumeB} onChange={setVolumeB} />
      {#if state?.volumeB}
        <div class="my-2">
          <CommitSelector commits={volumes.volumes[state.volumeB]?.commits} selected={state.commitB} onChange={setCommitB} />
        </div>
        <HistoryTimeline commits={volumes.volumes[state.volumeB]?.commits} selected={state.commitB} onSelect={setCommitB} />
      {/if}
    </section>
  </div>

  <section class="border rounded p-3 mt-4">
    <h2 class="font-semibold mb-2">Comparison</h2>
    <ComparisonView {commitA} {commitB} />
  </section>
{:else}
  <p>Loading volumes...</p>
{/if}

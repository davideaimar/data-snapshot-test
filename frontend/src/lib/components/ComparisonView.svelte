<script lang="ts">
  import type { CommitDetails } from '$lib/types';
  export let commitA: CommitDetails | null = null;
  export let commitB: CommitDetails | null = null;

  function diffFiles(a: CommitDetails, b: CommitDetails) {
    const filesA = a.files;
    const filesB = b.files;
    const all = new Set([...Object.keys(filesA), ...Object.keys(filesB)]);
    return Array.from(all).map((file) => {
      const A = filesA[file];
      const B = filesB[file];
      const status = !A ? 'added' : !B ? 'removed' : (A.sha256 !== B.sha256 ? 'changed' : 'unchanged');
      return { file, sizeA: A?.size ?? null, sizeB: B?.size ?? null, status };
    }).sort((r1, r2) => r1.file.localeCompare(r2.file));
  }
</script>

{#if commitA && commitB}
  <div class="grid grid-cols-2 gap-4 text-sm text-gray-700 mb-2">
    <div>A: {commitA.volume} • {new Date(commitA.date).toLocaleString()} • {commitA.stats.file_count} files</div>
    <div>B: {commitB.volume} • {new Date(commitB.date).toLocaleString()} • {commitB.stats.file_count} files</div>
  </div>
  <table class="w-full border border-gray-200 text-sm">
    <thead class="bg-gray-50">
      <tr>
        <th class="p-2 text-left">File</th>
        <th class="p-2">A size</th>
        <th class="p-2">B size</th>
        <th class="p-2">Status</th>
      </tr>
    </thead>
    <tbody>
      {#each diffFiles(commitA, commitB) as row}
        <tr class="{row.status === 'changed' ? 'bg-yellow-50' : row.status === 'added' ? 'bg-green-50' : row.status === 'removed' ? 'bg-red-50' : ''}">
          <td class="p-2">{row.file}</td>
          <td class="p-2 text-right">{row.sizeA ?? '-'}</td>
          <td class="p-2 text-right">{row.sizeB ?? '-'}</td>
          <td class="p-2 capitalize font-semibold">{row.status}</td>
        </tr>
      {/each}
    </tbody>
  </table>
{:else}
  <p class="text-gray-500">Select two commits to compare.</p>
{/if}

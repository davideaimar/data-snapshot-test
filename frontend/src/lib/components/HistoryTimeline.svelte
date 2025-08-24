<script lang="ts">
  import type { Commit } from '$lib/types';
  export let commits: Commit[] = [];
  export let selected: string | null = null;
  export let onSelect: (hash: string) => void;
  $: sorted = [...commits].sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime());
</script>

<div class="flex flex-col gap-1">
  {#each sorted as c}
    <button
      class="flex items-start gap-2 p-2 rounded hover:bg-gray-100 {selected === c.hash ? 'bg-blue-50' : ''}"
      on:click={() => onSelect(c.hash)}
      title={c.message}
    >
      <span class="w-3 h-3 rounded-full border-2 border-blue-500 mt-1 {selected === c.hash ? 'bg-blue-500' : ''}"></span>
      <span class="flex flex-col">
        <span class="font-semibold text-sm">{new Date(c.date).toLocaleString()}</span>
        <span class="text-xs text-gray-600">{c.message}</span>
        <span class="text-xs text-gray-500">{c.stats.file_count} files • {c.stats.total_size} bytes</span>
      </span>
    </button>
  {/each}
  {#if sorted.length === 0}
    <div class="text-gray-500 italic p-2">No commits</div>
  {/if}
</div>

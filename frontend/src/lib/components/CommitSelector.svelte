<script lang="ts">
  import type { Commit } from '$lib/types';
  export let commits: Commit[] = [];
  export let selected: string;
  export let onChange: (val: string) => void;
</script>

<select class="p-2 border rounded w-full" bind:value={selected} on:change={(e) => onChange((e.target as HTMLSelectElement).value)}>
  <option value="">-- Select commit --</option>
  {#each commits as c}
    <option value={c.hash}>
      {new Date(c.date).toLocaleString()} — {c.message}
    </option>
  {/each}
</select>

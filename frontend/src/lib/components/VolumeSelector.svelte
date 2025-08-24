<script lang="ts">
  import type { Volumes } from '$lib/types';
  export let volumes: Volumes;
  export let selected: string;
  export let onChange: (val: string) => void;
</script>

<select class="p-2 border rounded w-full" bind:value={selected} on:change={(e) => onChange((e.target as HTMLSelectElement).value)}>
  <option value="">-- Select volume --</option>
  {#each Object.keys(volumes.volumes) as v}
    <option value={v}>{v}</option>
  {/each}
</select>

<script lang="ts">
  import { Popover } from '@skeletonlabs/skeleton-svelte';
  import type { Snippet } from 'svelte';
  import type { Placement } from '@floating-ui/dom';
  import { cl_join } from '~/tools/cl_join';

  let {
    children,
    popup_state = $bindable(),
    description,
    cancel_func,
    confirm_func,
    contentBase,
    placement
  }: {
    children: Snippet;
    confirm_func?: () => void;
    cancel_func?: () => void;
    description: string;
    popup_state: boolean;
    contentBase?: string;
    placement: Placement;
  } = $props();
</script>

<Popover
  bind:open={popup_state}
  positioning={{ placement: placement }}
  arrow={false}
  contentBase={cl_join(
    'card z-50 space-y-2 p-2 rounded-lg shadow-xl bg-surface-100-900',
    contentBase
  )}
>
  {#snippet trigger()}
    {@render children()}
  {/snippet}
  {#snippet content()}
    <div class="text-lg font-bold">{description}</div>
    <div class="space-x-2">
      <button
        class="btn preset-filled-surface-300-700 rounded-lg font-semibold"
        onclick={confirm_func}
      >
        Confirm
      </button>
      <button
        onclick={() => {
          popup_state = false;
          cancel_func && cancel_func();
        }}
        class="btn preset-outlined-surface-800-200 rounded-lg font-semibold"
      >
        Cancel
      </button>
    </div>
  {/snippet}
</Popover>

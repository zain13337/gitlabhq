<script>
import { GlLink } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    ClipboardButton,
    GlLink,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
    mergeRequest: {
      type: Object,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <div>
    <p class="gl-display-flex gl-flex-wrap gl-align-items-baseline gl-gap-2 gl-mb-0">
      <span class="gl-display-flex gl-font-weight-bold">{{ __('Commit') }}</span>

      <gl-link :href="commit.commit_path" class="commit-sha-container" data-testid="commit-sha">
        {{ commit.short_id }}
      </gl-link>

      <clipboard-button
        :text="commit.id"
        :title="__('Copy commit SHA')"
        category="tertiary"
        size="small"
        class="gl-align-self-center"
      />

      <span v-if="mergeRequest">
        {{ __('in') }}
        <gl-link :href="mergeRequest.path" class="gl-text-blue-500!" data-testid="link-commit"
          >!{{ mergeRequest.iid }}</gl-link
        >
      </span>
    </p>

    <p class="gl-mb-0 gl-break-all">{{ commit.title }}</p>
  </div>
</template>

<script>
import ImageListRow from './image_list_row.vue';

export default {
  name: 'ImageList',
  components: {
    ImageListRow,
  },
  props: {
    images: {
      type: Array,
      required: true,
    },
    metadataLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
    expirationPolicy: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
};
</script>

<template>
  <ul class="gl-pl-0">
    <image-list-row
      v-for="(listItem, index) in images"
      :key="index"
      :item="listItem"
      :metadata-loading="metadataLoading"
      :expiration-policy="expirationPolicy"
      @delete="$emit('delete', $event)"
    />
  </ul>
</template>

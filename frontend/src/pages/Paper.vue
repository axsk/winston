<template>
  <Paper :paper="paper"/>
</template>

<script>
import Paper from "../components/Paper.vue";
export default {
  props: ["uuid"],
  components: {
    Paper,
  },
  computed: {
    paper() {
      return this.$store.getters.getPaper(this.uuid)
    }
  },
  watch: {
    uuid: {
      immediate: true,
      handler (val) {
      this.$store.dispatch('getPaper', val)
    }}
  }
}
</script>

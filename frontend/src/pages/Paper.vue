<template>
  <Paper v-if="paper" :paper="mypaper" @save="save"/>
</template>

<script>
import Paper from "../components/Paper.vue";
export default {
  data() { return {
    uuid: null
  }
  },
  components: {
    Paper,
  },
  computed: {
    paper() {
      return this.$store.getters.getPaper(this.uuid)
    },
    mypaper() {
      return JSON.parse(JSON.stringify(this.paper))
    }
  },
  watch: {
    '$route': {
      immediate: true,
      handler (to, from) {
        var uuid = to.params.uuid
        if (uuid == "new")
          this.$store.dispatch('newPaper').then(id=>(this.uuid=id))
        else {
          this.$store.dispatch('getPaper', uuid)
          this.$store.dispatch('getReferences', uuid)
          this.uuid = uuid
        }
      }
    },
  },
  methods: {
    save: async function(paper) {
      var id = await this.$store.dispatch('editPaper', paper)
      id = id.data
      console.log(id)
      this.uuid = id.data
    }
  }
}
</script>
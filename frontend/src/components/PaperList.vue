<template><div>
    Sort by 
    <div v-for="paper in papers" :key="paper.uuid">
        <paperlabel :paper="paper"/>
    </div>
</div>
</template>

<script>
import paperlabel from './PaperLabel.vue'

export default {
  components: {paperlabel},
  props: ['papers'],
  data() { return {
    paperlist: this.papers
  }}
}
</script>
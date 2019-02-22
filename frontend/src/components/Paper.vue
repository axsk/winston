<template>
  <div>
  	Title <el-input v-model="mypaper.title" /><br>
  	Year  <el-input v-model="mypaper.year" /><br>
    DOI   <el-input v-model="mypaper.doi" /><br>
    SemanticScholar <el-input v-model="mypaper.ssid" /><br>
  	Authors:
    <authorlist :authors="mypaper.authors" format=full :editable="true" />
  	Tags:
    <taglist v-model="mypaper.usertags" :editable="true" />
    <button @click="$emit('save', mypaper)">Save</button><br>
    <viewpdf :pid="mypaper.uuid"/>
    <div v-for="ref in mypaper.references" :key="ref.uuid">
        <paperlabel :paper="ref"/>
    </div>
  </div>
</template>

<script>
import taglist from './TagList.vue'
import authorlist from './AuthorList.vue'
import viewpdf from './ViewPDF.vue'
import paperlabel from './PaperLabel'

export default {
  components: {
     taglist, authorlist, viewpdf, paperlabel
  },
  data() { return {
    mypaper: this.paper
    }
  },
  watch: {
    paper: function (p) {
      this.mypaper = p}
  },  
  props: ['paper'],
  methods: {
    
  }
}
</script>

<template>
  <div>
  	<el-input v-model="paper.title" /><br>
  	<el-input v-model="paper.year" /><br>
  	Authors:
    <authorlist :authors="paper.authors" format=full :editable="true" />
  	Tags:
    <taglist v-model="paper.usertags" :editable="true" />
    <button @click="save()">Save</button><br>
    <viewpdf :pid="paper.uuid"/>
  </div>
</template>

<script>
import axios from 'axios'
import taglist from './TagList.vue'
import authorlist from './AuthorList.vue'
import viewpdf from './ViewPDF2.vue'

export default {
  components: {
     taglist, authorlist, viewpdf
  },
  filters: {
    parseAuthors: function(as) {
      if (as != null) {
          return as.map(function(x){
            return x.family
          }).join(", ")
        } else {
          null
        }
    }
  },
  props: ['paper'],
  methods: {
    save: function() {
      axios
      .put('http://localhost:8000/editpaper',
        JSON.stringify(this.paper))
    }
  }
}
</script>

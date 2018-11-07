<template>
  <div>
  	<el-input v-model="paper.title" /><br>
  	<el-input v-model="paper.year" /><br>
  	Authors:
    <taglist v-model="paper.authors" editable="true" />
  	Tags:
    <taglist v-model="paper.usertags" editable="true" />
    <button @click="save()">Save</button>
  </div>
</template>

<script>
import axios from 'axios'
import taglist from './Taglist.vue'

export default {
  components: {
     taglist
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

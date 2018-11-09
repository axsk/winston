<template>
  <div>
  	<el-input v-model="author.family" /><br>
  	<el-input v-model="author.given" /><br>
  	Papers:
    <div v-for="paper in papers">{{paper}}</div>
    Coworkers:
    Network:
  </div>
</template>

<script>
import axios from 'axios'

export default {
  props: ['author'],
  data() { 
    return {
      papers: []
    }
  },
  watch: {
      author: function (author) {
          this.papers = this.loadpapers(author)
      }
  },
  methods: {
    loadpapers: function(author) {
      axios
      .get('http://localhost:8000/author/'+author.uuid+'/papers')
      .then(res => this.papers = res.data)
    }
  }
}
</script>

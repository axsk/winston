<template>
  <div id="app">
    <router-link to="/search">Search</router-link>
    <router-link to="/paper/new">New</router-link>
    <router-view></router-view>
  </div>
</template>

<script>

import axios from 'axios'

export default {
  name: 'app',
  data () { 
    return {
      selection: {},
      dialogVisible: false,
      paperData: [],
      currenttab: 0
    }
  },
  methods: {
    getusertags(user) {
      let tags = axios.get('http://localhost:8000/usertags/'+user);
      return tags["data"]
    },
    
    gopaper() {
      alert("hm")
      this.$router.push('paper')
    }
  },
  mounted: function() {
    this.$root.$on('viewAuthor', (author) => {
      this.selection = {type: 'author', value: author}
      this.dialogVisible = true
    })
    this.$root.$on('viewPaper', (paper) => {
      this.selection = {type: 'paper', value: paper}
      this.currenttab = "1"
    })
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: left;
  //color: #2c3e50;
  margin-top: 20px;
}
</style>

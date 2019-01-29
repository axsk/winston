<template>
  <div id="app">
    <el-tabs>
      <el-tab-pane label="Search" @tab-click="this.$router.push('search')"/>
      <el-tab-pane label="Paper" @tab-click="gopaper" />
    </el-tabs>
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

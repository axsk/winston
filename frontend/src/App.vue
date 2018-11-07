<template>
  <div id="app">
  <el-container>
    <div class="sticky-top">
    <el-aside>
        <Search @result="update"/>
    </el-aside></div>
    <el-main>
      <el-dialog :visible.sync="dialogVisible" title="Edit">
        <Paper v-if="selectedPaper != null" :paper="selectedPaper" />
      </el-dialog>
      <paper-table :papers="paperData" v-on:row-clicked="selectpaper"/>
    </el-main>
  </el-container>

  </div>
</template>

<script>

import PaperTable from './components/PaperTable.vue'
import Paper from './components/Paper.vue'
import Search from './components/Search.vue'
import axios from 'axios'

export default {
  name: 'app',
  components: {
    Paper,
    Search,
    PaperTable
  },
  data () { 
    return {
      selectedPaper: null,
      dialogVisible: false,
      paperData: []
    }
  },
  methods: {
    selectpaper(paper) {
      this.selectedPaper = paper
      this.dialogVisible = true
    },
    getusertags(user) {
      let tags = axios.get('http://localhost:8000/usertags/'+user);
      return tags["data"]
    },
    update(results) {
      this.paperData = results
    }
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

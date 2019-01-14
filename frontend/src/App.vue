<template>
  <div id="app">
  <el-container>
    <div class="sticky-top">
    <el-aside>
        <Search @result="update"/>
    </el-aside></div>
    <el-main>
      <el-dialog :visible.sync="dialogVisible" title="Edit">
        <author v-if="selection.type == 'author'" :author="selection.value" />
      </el-dialog>
      <el-tabs :value.sync="currenttab">
        <el-tab-pane label="Search">
          <paper-table :papers="paperData"/></el-tab-pane>
        <el-tab-pane label="Paper">
          <Paper v-if="selection.type == 'paper'" :paper="selection.value" /></el-tab-pane>
      </el-tabs>
    </el-main>
  </el-container>
  </div>
</template>

<script>

import PaperTable from './components/PaperTable.vue'
import Paper from './components/Paper.vue'
import author from './components/Author.vue'
import Search from './components/Search.vue'
import axios from 'axios'

export default {
  name: 'app',
  components: {
    author,
    Paper,
    Search,
    PaperTable
  },
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
    update(results) {
      this.paperData = results
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

<template>
  <div id="app">
  <el-container>
    <div class="sticky-top">
    <el-aside>
        <Search @result="update"/>
    </el-aside></div>
    <el-main>
      <el-dialog :visible.sync="dialogVisible" title="Edit">
        <Paper v-if="currentpid != null" :pid="currentpid" />
      </el-dialog>
      <Table :datas="paperData" v-on:row-clicked="selectpaper"/>
    </el-main>
  </el-container>

  </div>
</template>

<script>

import Table from './components/Table.vue'
import Paper from './components/Paper.vue'
import Search from './components/Search.vue'
import axios from 'axios'

export default {
  name: 'app',
  components: {
    Table,
    Paper,
    Search
  },
  data () { 
    return {
      currentpid: null,
      dialogVisible: false,
      paperData: []
    }
  },
  methods: {
    selectpaper(pid) {
      this.currentpid = pid
      this.dialogVisible = true
    },
    getusertags(user) {
      let tags = axios.get('http://localhost:8000/usertags/'+user);
      alert(JSON.stringify(tags["data"]))
      return tags["data"]
    },
    update(results) {
      //alert(JSON.stringify(results))
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
  color: #2c3e50;
  margin-top: 20px;
}
</style>

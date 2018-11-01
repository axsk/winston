<template>
  <div id="app">
    <b-container fluid>
      <b-row>
          <b-col cols=2>
            <div class="sticky-top">
              <Search @result="update"/>
            </div>
          </b-col>
          <b-col cols="7">
            <Table :datas="paperData" v-on:row-clicked="selectpaper"/>
          </b-col>
          <b-col cols=3>
            <div class="sticky-top">
              <Paper v-if="currentpid != null" :pid="currentpid" />
            </div>
          </b-col>
      </b-row>
  </b-container>
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
      paperData: []
    }
  },
  methods: {
    selectpaper(pid) {
      this.currentpid = pid
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

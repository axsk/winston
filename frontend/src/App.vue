<template>
  <div id="app">
    <b-container>
      <b-row>
          <b-col>
            Search<br>
            <input><br>
            Filter tags:<br>
            Filter date:<br>
          </b-col>
          <b-col>
            <Table v-on:row-clicked="selectpaper"/>
          </b-col>
          <b-col>
            <Paper v-if="currentpid != null" :pid="currentpid" />
          </b-col>
      </b-row>
  </b-container>
  </div>
</template>

<script>
import Table from './components/Table.vue'
import Paper from './components/Paper.vue'

export default {
  name: 'app',
  components: {
    Table,
    Paper
  },
  data () { 
    return {
      currentpid: null
    }
  },
  methods: {
    selectpaper(pid) {
      this.currentpid = pid
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
  margin-top: 60px;
}
</style>

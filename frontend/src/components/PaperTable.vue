<template>
  <el-table :data="papers" @row-click="selectRow" striped>
    <el-table-column label="Year" prop="year" width=100% sortable />
    <el-table-column label="Authors" width=300px sortable> 
      <template slot-scope="scope">{{ scope.row.authors | parseAuthors }}</template>
    </el-table-column>
    <el-table-column label="Title" prop="title" sortable />
    <el-table-column label="My Tags" prop="usertags" width=100px sortable />
  </el-table>
</template>

<script>
import axios from 'axios'

export default {
  props: ['papers'],
  methods: {
    selectRow: function (row, event, column){
      this.$emit('row-clicked', row)
    },
    
  },
  filters: {
    parseAuthors: function(as) {
      if (as != "undefined") {
          return as.map(function(x){
            return x.family
          }).join(", ")
        } else {
          undefined
        }
    }
  }
}

</script>

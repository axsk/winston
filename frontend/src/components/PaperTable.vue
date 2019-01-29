<template>
  <el-table :data="papers" @row-click="selectRow" striped>
    <el-table-column label="Year" prop="year" width=100% sortable />
    <el-table-column label="Authors" width=180px sortable> 
      <template slot-scope="scope">
        <authorlist :authors="scope.row.authors"/>
       </template>
    </el-table-column>
    <el-table-column label="Title" prop="title" sortable />
    <el-table-column label="My Tags" prop="usertags" width=100px sortable>
      <template slot-scope="scope">
        <taglist :value="scope.row.usertags" />
      </template>
    </el-table-column>
  </el-table>
</template>

<script>
import authorlist from './AuthorList.vue'
import taglist from './TagList.vue'

export default {
  components: {authorlist, taglist},
  props: ['papers'],
  methods: {
    selectRow: function (row, event, column){
      this.$emit('row-clicked', row)
      this.$root.$emit('viewPaper', row)
      this.$router.push('/paper/'+row.uuid)
    }
  }
}

</script>
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
    <el-table-column label="First" prop="editfirst" sortable :sort-method="mysortfirst"/>
    <el-table-column label="Last"  prop="editlast"  sortable :sort-method="mysortlast"/>
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
    },
    mysortlast: function(a,b){return this.mysort(a.editlast, b.editlast)},
    mysortfirst: function(a,b){return this.mysort(a.editfirst, b.editfirst)},
    mysort: function(a,b){
      if (a === null) return 1
      else if (b === null) return -1
      else if (a === b) return 0
      return a < b ? -1 : 1
    }
  },
  computed:{
    mylast()  {return this.papers.map(x=>(x.editlast  == null ? "" : x.editlast))},
    myfirst() {return this.papers.map(x=>(x.editfirst == null ? "" : x.editfirst))}
  },
  filters: {
    formatdate: function (datetime) {
      var d = Date.parse(datetime)
      return "b"
      return d.getDate()
    }
  }
}

</script>
<template>
  <el-container>
    <div class="sticky-top">
      <el-aside width="180px">
        <Search @result="update"/>
      </el-aside>
    </div>
    <el-main>
      <paper-table :papers="paperData"/>
    </el-main>
  </el-container>
</template>

<script>
import Search from "../components/Search.vue";
import PaperTable from "../components/PaperTable.vue";

export default {
  name: "app",
  components: {
    Search,
    PaperTable
  },
  data () { return {
    paperData: []
  }},
  methods: {
    update(results) {
      this.paperData = results
    },
  }
};
</script>
<template>
  <el-container>
    <div class="sticky-top">
      <el-aside width="180px">
        <Search @result="update"/>
      </el-aside>
    </div>
    <el-main>
      <paperlist :papers="paperData"/>
    </el-main>
  </el-container>
</template>

<script>
import Search from "../components/Search.vue";
import paperlist from "../components/PaperList.vue";

export default {
  name: "app",
  components: {
    Search,
    paperlist
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
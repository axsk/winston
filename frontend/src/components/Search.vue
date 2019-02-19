<template>
  <el-card>
  	<div slot="header">
  		Search
  	</div>
			<el-input v-model="searchquery" @keyup.enter.native="update" />
		<el-button @click="update" value="go">Go</el-button>
	</el-form>
	<taglist :value="usertags" selectable=true @select="tagselected"/>
  </el-card>
</template>

<script>
import axios from 'axios'
import taglist from './TagList.vue'

export default {
  components: {
     taglist
  },
  data () {
    return {
      usertags: [],
      selectedtags: [],
      searchquery: "",
      result: {}
    }
  },
  mounted () {
    axios
      .get('http://localhost:8000/usertags/'+'Alex')
      .then(response => (this.usertags = response.data))
		this.update()
  },
  methods: {
  	tagselected: function (tags) {
  		this.selectedtags = [...tags]
  		this.update()
  	},
  	update() {
  		let jq = JSON.stringify({
  				usertags: this.selectedtags,
  				user: "Alex",
  				query: this.searchquery
  			})
  		axios
			.get('http://localhost:8000/search?json='+jq)
			.then(response => (this.result = response.data))
      		.finally(() => this.$emit('result', this.result))
  	}
  }
}

</script>

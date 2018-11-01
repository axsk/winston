<template>
  <div>
  	Search<br>
	<input v-model="searchquery" @keyup.enter="update">
	<button @click="update" value="go">Go</button>
	<br>

	Filter tags:<br>
	<taglist :value="usertags" selectable=true @select="tagselected"/>

	Filter date:<br>
  </div>
</template>

<script>
import axios from 'axios'
import taglist from './Taglist.vue'

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
			.get('http://localhost:8000/papers?json='+jq)
			.then(response => (this.result = response.data))
      		.finally(() => this.$emit('result', this.result))
  	}
  }
}

</script>

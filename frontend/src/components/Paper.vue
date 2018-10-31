<template>
  <div>
  	<input v-model="paper['title']"><br>
  	<input v-model="paper['year']"><br>
  	Authors:
    <taglist v-model="authors" editable=true />
  	Tags:
    <taglist v-model="tags" editable=true />
    <button @click="save()">Save</button>
  </div>
</template>

<script>
import axios from 'axios'
import taglist from './Taglist.vue'

export default {

  components: {
     taglist
  },
  props: ['pid'],
  data () {
    return {
      paper: {},
      authors: [],
      tags: []
    }
  },
  mounted () {
  	this.pid == null || this.update()
  },
  watch: {
  	pid: function (newv, oldv) {
  			this.update()
	}
  },
  methods: {
  	update: function() {
  		axios
			.get('http://localhost:8000/paper/'+this.pid)
			.then(response => (this.paper = response.data[0],
							   this.authors = response.data[1].map(x=>x.name),
							   this.tags = response.data[2].map(x=>x.name))
			)
  	}, 
    save: function() {
      axios
      .put('http://localhost:8000/editpaper',
        JSON.stringify({pid: this.pid,
          tags: this.tags,
          authors: this.authors,
          title: this.paper['title'],
          year: this.paper['year']}))
    }
  }
}
</script>

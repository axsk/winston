<template>
  <div>
  	Search<br>
	<input><br>
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
      selectedtags: []
    }
  },
  mounted () {
    axios
      .get('http://localhost:8000/usertags/'+'Alex')
      .then(response => (this.usertags = response.data))
  },
  methods: {
  	tagselected: function (tags) {
  		[...tags]
  	}
  }
}

</script>

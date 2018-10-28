<template>
  <b-table striped hover :items="items" :fields="fields" v-on:row-clicked="selectRow"></b-table>
</template>

<script>
import axios from 'axios'

export default {
  data () {
    return {
      items: [],
      fields: [
	{key: 'Year', sortable: true},
 	{key: 'Title', sortable:true},
	{key: 'Authors', sortable: true},
	{key: 'Tags', sortable: true}
      ]
    }
  },
  mounted () {
    axios
      .get('http://localhost:8000')
      .then(response => (this.items = response.data))
  },
  methods: {
    selectRow: function (item, index, event){
      this.$emit('row-clicked', item['uuid'])
    }
  }
}

</script>

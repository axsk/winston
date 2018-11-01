<template>
  <div>
    <b-table striped hover 
    :items="datas" :fields="fields"
    v-on:row-clicked="selectRow"/>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  props: ['datas'],
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
  },
  watch: { 
        datas: function(newVal, oldVal) { // watch it
          this.$forceUpdate();
        }
      }
}

</script>

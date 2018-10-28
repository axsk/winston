<template>
  <div>
    <li v-for="tag, index in value">
      {{tag}} <button @click="remove(index)"></button>
    </li>
    <li><input v-model="newtag" @keyup.enter="add"></li>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  props: ['value'],
  data () {
    return {
      newtag: []
    }
  },
  methods: {
    remove: function (index) { 
      this.value.splice(index,1)
      this.$emit('input', this.value)
    },
    add: function () {
      this.value.push(this.newtag)
      this.$emit('input', this.value)
      this.newtag = ""
    }
  }
}
</script>
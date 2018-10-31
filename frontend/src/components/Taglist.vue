<template>
  <div>
    <li v-for="tag, index in value">
      <span @click="toggle(tag)" v-bind:class="[selected.has(tag) ? 'sel' : '']">
        {{tag}} 
        <button v-if="editable" @click="remove(index)">x</button>
      </span>
    </li>
    
    <input v-if="editable" v-model="newtag" @keyup.enter="add">
  </div>
</template>

<script>
import axios from 'axios'

export default {
  props: {
    value: {},
    editable: {default: false},
    selectable: {default: false}
  },
  data () {
    return {
      newtag: [],
      selected: new Set()
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
    },
    toggle: function(i) {
      if (!this.selectable){
        return 
      }
      if (this.selected.has(i)) {
        this.selected.delete(i)
      }
      else {
        this.selected.add(i)
      }
      this.$emit('select', this.selected)
      this.$forceUpdate();
    }
  }
}
</script>

<style>
.sel {
  background-color: lightblue; 
}
</style>
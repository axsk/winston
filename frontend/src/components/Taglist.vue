<template>
  <div>
    <span v-for="tag, index in value" >
      <el-tag  
        v-bind:class="[selected.has(tag) ? 'sel' : '']"
        :closable="editable"
        @close="remove(index)"
        @click="toggle(tag)">
        {{tag}}
      </el-tag>
    </span><br>
    <input v-if="editable" v-model="newtag" @keyup.enter="add">
  </div>
</template>

<script>

export default {
  props: {
    value: {type: Array, default: ()=>{[]}},
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
      if (this.value == null) this.value = [];
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

<style scoped>
.sel {
  background-color: lightblue; 
}
</style>  
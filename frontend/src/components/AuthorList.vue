<template>
<span>
  <template v-for="author, i in authors">
      <a @click.stop="clicked(author)" href=#>{{author | parseAuthor(format)}}</a>
      <button v-if="editable" @click="remove(i)">x</button>, 
  </template><br>
  <input v-if="editable" @keyup.enter="add" v-model="addition">
</span>
</template>

<script>

export default {
  props: ['authors', 'format', 'editable'],
  data() {
    return {
      addition: ""
    }
  },
  filters: {
      parseAuthor: function (author, format) {
        if (typeof(author) == "string")
          return author
        else if (format == 'full')
          return author.given + " " + author.family
        else if (format == 'minimal' || author.given == undefined || author.given[0] == undefined)
          return author.family
        else 
          return author.given[0] + ". " + author.family
      }
  },
  methods: {
    clicked: function(author){
      this.$root.$emit('viewAuthor', author)
    },
    add: function() {
      if (this.authors == null) this.value = []
      this.authors.push(this.addition)
      this.$emit('input', this.authors)
      this.addition = ""
    },
    remove: function(index){
      this.authors.splice(index, 1)
      this.$emit('input', this.authors)
    }
  }
}

</script>

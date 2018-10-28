<template>
  <div contenteditable="true">
    <div contenteditable="false" > <span v-for="tag, index in value" style="margin-right: 2px">
      {{tag.name}}
      <button class="delete is-small" @click="remove(index)"></button>

    </span>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  props: ['value'],
  data () {
    return {
      items: []
    }
  }
}

</script>
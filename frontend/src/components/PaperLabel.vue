<template>
<div>
    <h2><router-link :to='"/paper/"+paper.uuid'>{{paper.title}}</router-link></h2>
    <p>{{paper.year}} - <authorlist :authors="paper.authors"/></p>
    <taglist :value="paper.usertags"/>
    <div v-if="haspdf">PDF</div>
</div>
</template>

<script>
import authorlist from './AuthorList.vue'
import taglist from './TagList.vue'
export default {
    components: {authorlist, taglist},
    props: ['paper'],
}
</script>

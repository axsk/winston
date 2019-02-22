<template>
<div>
    <h3><router-link :to='"/paper/"+paper.uuid'>{{paper.title}}</router-link></h3>
    <div>{{paper.year}} - <authorlist :authors="paper.authors"/></div>
    <taglist :value="paper.usertags"/>
    <div v-if="haspdf">PDF</div>
</div>
</template>

<script>
import authorlist from './AuthorList.vue'
import taglist from './TagList.vue'
export default {
    data() { return {
        haspdf: false
    }},
    components: {authorlist, taglist},
    props: ['paper'],
}
</script>

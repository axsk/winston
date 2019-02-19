import Vue from 'vue'
import Router from 'vue-router'
import Paper from '../pages/Paper.vue'
import Search from '../pages/Search.vue'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/search',
      component: Search 
    },
    {
      path: '/paper/:uuid',
      component: Paper
    },
    {
      path: '*',
      redirect: '/search'
    }
  ]
})

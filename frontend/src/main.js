import Vue from 'vue'
//import axios from 'axios'

//import BootstrapVue from 'bootstrap-vue'
//import 'bootstrap/dist/css/bootstrap.css'
//import 'bootstrap-vue/dist/bootstrap-vue.css'

import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'

import App from './App.vue'

Vue.config.productionTip = false
//Vue.use(BootstrapVue)
Vue.use(ElementUI)


new Vue({
  render: h => h(App)
}).$mount('#app')

import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue'
import App from './App.vue'
import axios from 'axios'

Vue.config.productionTip = false
Vue.use(BootstrapVue)

import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

//import { Layout } from 'bootstrap-vue/es/components';

//Vue.use(Layout);

new Vue({
  render: h => h(App)
}).$mount('#app')

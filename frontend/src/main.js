import Vue from 'vue'
import router from './router'
import store from './store'
import App from './pages/App.vue'

import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'

Vue.use(ElementUI)

Vue.config.productionTip = false

window.App = new Vue({
  el: '#app',
  router,
  store,
  render: h => h(App)
})

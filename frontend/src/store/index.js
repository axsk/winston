import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    papers: []
  },
  getters: {
    getPaper: (state) => (uuid) => {
      return state.papers.find(p => p.uuid == uuid)
    }
  },
  mutations: {
    addpaper (state, paper) {
      state.papers.push(paper)
    }
  },
  actions: {
    getPaper ({commit, getters}, uuid) {
      if (getters.getPaper(uuid) == undefined) {
        axios.get('http://localhost:8000/paper/'+uuid).then((p) => {
          commit('addpaper', p.data)
        }).catch((err) => {commit('addpaper', {uuid: uuid, error: err})})
      }
    }
  }
})

import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
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
        axios.get('http://localhost:8000/paper/'+uuid).then(p=>commit('addpaper', p.data))
      }
    },
    async editPaper ({commit, getters}, paper) {
      return await axios.put('http://localhost:8000/editpaper', JSON.stringify(paper))
    },
    newPaper ({commit}) {
      var tempid = -Math.floor(Math.random() * 1024);
      var p = {title: "", uuid: tempid, authors: [], year: "", doi: ""}
      commit('addpaper', p)
      return tempid
    }
  }
})

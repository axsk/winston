import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'

Vue.use(Vuex)

export default new Vuex.Store({
  strict: true,
  state: {
    papers: {},
    authors: {},
    notes: {},
  },
  getters: {
    getPaper: (state) => (uuid) => {
      return state.papers[uuid]
      // return state.papers.find(p => p.uuid == uuid)
    },
    getAuthor: (state, getters) => (uuid) => {
      return state.authors[uuid]
    }
  },
  mutations: {
    addpaper (state, paper) {
      Vue.set(state.papers, paper.uuid, {...state.papers[paper.uuid], ...paper})
    },
    setReferences (state, {uuid, ps}) {
      Vue.set(state.papers, uuid, {...state.papers[uuid], references: ps})
    },
    updateAuthor (state, {id, a}) {
      Vue.set(state.authors, id, {...state.authors[id], ...a})
    },
    addNote(state, {paper, notes}) {
      notes.forEach(n => {
        let id = n.uuid
        Vue.set(state.notes, id, n)
      })
      Vue.set(state.papers, paper, {...state.papers[paper], notes: notes})
    }
  },
  actions: {
    getPaper ({commit, getters, dispatch}, uuid) {
      if (getters.getPaper(uuid) == undefined) {
        axios.get('http://localhost:8000/paper/'+uuid).then(p=>commit('addpaper', p.data))
      }
      dispatch('getNotes', uuid)
    },
    async editPaper ({commit, getters}, paper) {
      return await axios.put('http://localhost:8000/editpaper', JSON.stringify(paper))
    },
    newPaper ({commit}) {
      var tempid = -Math.floor(Math.random() * 1024);
      var p = {title: "", uuid: tempid, authors: [], year: "", doi: "", ssid: ""}
      commit('addpaper', p)
      return tempid
    },
    async getReferences ({commit}, uuid) {
      var ps = (await axios.get('http://localhost:8000/paper/'+uuid+'/references')).data
      //ps.map(p=>commit('addpaper', p))
      commit('setReferences', {uuid, ps})
    },
    async getAuthor ({commit}, id) {
      var a = (await axios.get('http://localhost:8000/author/'+id)).data
      commit('updateAuthor', {id, a})
    },
    async getNotes ({commit}, id) {
        let d = (await axios.get('http://localhost:8000/comment', {params: {pid: id}})).data
        let hl = d.highlights
        let n = d.comments
        commit('addNote', {paper: id, notes: n})
    }
  }
})

<template>
<el-container>
    <el-main :style="'position:relative; min-width:'+pagewidth">
        <div v-if="boxShow" :style="{top: boxTop+'px', left: boxLeft+'px', position:'absolute', 'z-index':'1'}">
            <el-button @click="highlight">Highlight</el-button>
        </div>
        Zoom <input v-model="zoom"/><br>
        Highlights <el-button @click="loadData">load</el-button> <el-button @click="saveAll">save</el-button> <br>
        <div ref="pdfC" @mouseup="contextBox">
            <div ref="pdfContainer" id="viewer" class="pdfViewer"></div>
        </div>
        <upload :pid="pid" />
    </el-main>
    <el-aside :style="'position:relative'">        
        <div v-for="note in notes" :style="{top: note.offset+'px', position:'absolute'}">
            <el-input type="textarea" autosize size="tiny" placeholder="Please input" v-model="note.text"/> 
        </div>
    </el-aside> 
</el-container>
</template>

<script>

import pdfjs from "pdfjs-dist/webpack";
import * as pdfviewer from "pdfjs-dist/web/pdf_viewer.js"
import "pdfjs-dist/web/pdf_viewer.css"
import upload from './Upload.vue'
import axios from 'axios'

const HelloWorld = {
  props: ['msg'],
  template: `<div>
    <h1>Hello world</h1>
    <div>{{ this.msg }}</div>
  </div>`
};

export default {
    components: {upload, HelloWorld},
    props: ['pid'],
    data() {
        return {
            zoom: 1.2,
            notes: [],
            highlights: [],
            pagewidth: 100,
            pdfDocument: null,
            boxTop: 0,
            boxLeft: 0,
            boxShow: false,
            pages: [],
            LinkService: null,
        }
    },
    watch: {
        pid: {
            immediate: true,
            handler: function (pid) {
                var loadingTask = pdfjs.getDocument(
                    {url: 'http://localhost:8000/pdf/'+ pid,
                     docBaseUrl: 'http://localhost:8080/pdf'})
                loadingTask.then((pdfDocument) => {
                    this.pdfDocument = pdfDocument
                }).catch(err => {  })
            }
        },
        pdfDocument: function() {
            //this.LinkService.setDocument(this.pdfDocument)
            //this.renderpdf()

            var container = this.$refs["pdfC"]
            var pdfLinkService = new pdfviewer.PDFLinkService();
            this.LinkService = pdfLinkService
            var pdfFindController = new pdfviewer.PDFFindController({linkService: pdfLinkService, });
            var pdfViewer = new pdfviewer.PDFViewer({ container: container, linkService: pdfLinkService, findController: pdfFindController, });
            pdfLinkService.setViewer(pdfViewer);
            let pdfDocument = this.pdfDocument
            pdfViewer.setDocument(pdfDocument);
            pdfLinkService.setDocument(pdfDocument, null);
        },
        zoom: function() {
            this.renderpdf()
        }
        
    },
    methods: {
        contextBox() {
            var sel = window.getSelection()
            if (sel.type == "Range") {
                var p = this.$refs["pdfContainer"].parentElement.getClientRects()[0]
                var c = sel.getRangeAt(0).getClientRects()[0]
                this.boxTop  = c.top - p.top - 40
                this.boxLeft = c.left - p.left
                this.boxShow = true
            } else
                this.boxShow = false
            
        },
        saveAll() {
            this.saveNotes()
            this.saveHighlights()
        },

        saveNotes(){
            axios.put('http://localhost:8000/comment',
                JSON.stringify({pid: this.pid, notes: this.notes}))
        },

        saveHighlights(){
            axios.put('http://localhost:8000/comment',
                JSON.stringify({pid: this.pid, highlights: this.highlights}))
        },

        loadData(){
            axios.get('http://localhost:8000/comment',
                {params: {pid: this.pid}})
                .then(res => {
                    this.highlights = res.data.highlights
                    this.notes      = res.data.comments
                    this.highlightRender()
                    this.noteRender()})
        },

        async renderpdf() {
            var pdfDocument = this.pdfDocument
            var container = this.$refs["pdfContainer"]
            //this.clearnode(container)
            // Document loaded, retrieving the page.
            var npages = pdfDocument.numPages 
            var promises = []
            for(var page=1; page<=npages; page++) {
                var div = document.createElement("div");
                this.pages.push(div)
                container.append(div)
                promises.push(this.renderpage(pdfDocument, page, div))
            }
            await Promise.all(promises)
        },

        async renderpage(pdf, page, div) {
            var pdfPage = await pdf.getPage(page)
let linkService = this.LinkService
            let x = {}
            x.createAnnotationLayerBuilder = function (pageDiv, pdfPage, imageResourcesPath, renderInteractiveForms, l10n) 
                {
                    
                    return new pdfviewer.AnnotationLayerBuilder(
                        {pageDiv, pdfPage, imageResourcesPath, renderInteractiveForms, l10n, linkService})

                }

            
            var pdfPageView = new pdfviewer.PDFPageView({
                container: div,
                id: page,
                scale: this.zoom,
                defaultViewport: pdfPage.getViewport({ scale: this.zoom, }),
                textLayerFactory: new pdfviewer.DefaultTextLayerFactory(),
                //annotationLayerFactory: new pdfviewer.DefaultAnnotationLayerFactory(),
                annotationLayerFactory: x
                })

            await pdfPageView.setPdfPage(pdfPage)
            

            //pdfPageView.annotationLayer = new pdfviewer.AnnotationLayerBuilder({pageDiv: div, pdfPage: pdfPage, imageResourcesPath: '', renderInteractiveForms: false, linkService})

            await pdfPageView.draw()
            this.pagewidth = div.firstChild.style.width
        },
        clearnode: function (node) {
            var fc = node.firstChild;
            while( fc ) {
                node.removeChild( fc );
                fc = node.firstChild;
            }
        
        },

        highlight: function() {
            var r = window.getSelection().getRangeAt(0)

            var ser = this.serializeRange(r)
            var highlight = {location: ser, text: r.toString()}
            this.highlights.push(highlight)

            var des = this.deserializeRange(ser)
            this.highlightRange(des, highlight)
        },

        addNote: function(event) {
            //var offset = event.target.parentNode.offsetTop + event.target.parentNode.parentNode.parentNode.offsetTop
            var note = {text: "", location: event.target.highlight.location}
            this.notes.push(note)
            this.noteRender()
        },

        highlightRender: function () {
            this.highlights.forEach(h => {
                const range = this.deserializeRange(h.location)
                this.highlightRange(range, h)
            });
        },

        noteRender: function () {
            this.notes.forEach(note => {
                var node = this.deserializeRange(note.location).startContainer
                var offset = node.parentNode.offsetTop + node.parentNode.parentNode.parentNode.offsetTop
                note.offset = offset
            })
        },

        // === CODE FOR HIGHLIGHTING ===

        highlightSerialized: function(h) {
            const range = this.deserializeRange(h)
            this.highlightRange(range, h)
        },

        highlightRange: function(range, highlight) {
            if (range.startContainer.nodeName == "SPAN") return 
            // todo: bug on partially highlighted ranges
            var o1 = range.startOffset
            var n1 = range.startContainer.parentNode
            var n2 = range.endContainer.parentNode

            var rr = new Range()
            var nn = n1
            
            while (true) {
                var span = document.createElement("span")
                span.style.backgroundColor = "yellow"
                span.addEventListener("click", this.addNote);
                span.highlight = highlight
                rr.selectNodeContents(nn)
                if (nn == n1) rr.setStart(nn.firstChild, range.startOffset) // is firstChild correct here?
                if (nn == n2) rr.setEnd(nn.firstChild, range.endOffset)

                rr.surroundContents(span)

                if (nn == n2) break
                nn = nn.nextSibling
            }
        },

        serializeRange: function(r) {
            var a = this.serializePosition(r.startContainer, r.startOffset)
            var b = this.serializePosition(r.endContainer, r.endOffset)
            return a.concat(b)
        },

        deserializeRange: function(s) {
            var r = document.createRange()
            var n
            n = this.deserializePosition(s[0], s[1], s[2])
            r.setStart(n[0], n[1])
            n = this.deserializePosition(s[3], s[4], s[5])
            r.setEnd(n[0], n[1])
            return r
        },

        serializePosition: function(node, offset) {
            if (node.parentNode.nodeName == "SPAN")
                node = node.parentNode

            var div = node.parentNode

            while (node.previousSibling != null) {
                node = node.previousSibling
                offset += (node.nodeType == 3) ? node.length : node.textContent.length
            }
            
            div = this.serializeDiv(div)
            // page, ndiv, offset
            return [div[0], div[1], offset]

        },

        deserializePosition: function(page, ndiv, offset){
            var div = this.deserializeDiv(page, ndiv)
            var node = div.firstChild
            while (true) {
                var len = (node.nodeType == 3) ? node.length : node.textContent.length
                if (offset >= len) {
                    offset -= len
                    node = node.nextSibling
                } else 
                    break
            }
            return [node, offset]
        },

        serializeDiv: function(div) {
            var page = parseInt(div.parentNode.parentNode.dataset.pageNumber)
            var d = div
            var n = 0
            while(d = d.previousSibling)
                n++
            return [page, n]
        },

        deserializeDiv: function(page, ndiv) {
            return document.querySelector("[data-page-number='"+page+"'] > .textLayer > :nth-child("+(ndiv+1)+")") 
        }

    }
}



</script>

require('../node_modules/bootstrap/dist/css/bootstrap.min.css')
<template>
<el-container>
    <el-main :style="'position:relative'">
        <input v-model="zoom"/><br>
        <div v-if="show" id='pageContainer' class="pdfViewer singlePageView" :pid="pid"></div>
        <upload v-else :pid="pid" />
    </el-main>
    <el-aside :style="'position:relative'">
        <el-button @click="highlight">Highlight</el-button>
        <div v-for="note in notes" :style="{top: note.offset+'px', position:'absolute'}">
            
            <el-input
                type="textarea"
                autosize
                placeholder="Please input"
                v-model="note.text"/>
        </div>        
    </el-aside>
</el-container>
</template>

<script>

import pdfjs from "pdfjs-dist";
import * as pdfviewer from "pdfjs-dist/web/pdf_viewer.js";
import "pdfjs-dist/web/pdf_viewer.css"
import upload from './Upload.vue'

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
            show: true,
            notes: [], 
            highlights: []
        }
    },
    watch: {
        pid: {
            immediate: true,
            handler: function (pid) {
                var loadingTask = pdfjs.getDocument('http://localhost:8000/pdf/'+ pid)
                loadingTask.promise.then((pdfDocument) => {
                    this.show = true
                    var container = document.getElementById('pageContainer')
                    this.clearnode(container)
                    // Document loaded, retrieving the page.
                    var npages = pdfDocument.numPages 
                    for(var page=1; page<=npages; page++) {
                        var div = document.createElement("div");
                        container.append(div)
                        this.renderpage(pdfDocument, page, div)
                    }
                }).catch(err => {
                    console.log(err)
                    this.show = false
                })
            }            
        }
    },
    methods: {
        renderpage(pdf, page, div) {
            pdf.getPage(page).then((pdfPage) => {
                var pdfPageView = new pdfviewer.PDFPageView({
                    container: div,
                    id: page,
                    scale: this.zoom,
                    defaultViewport: pdfPage.getViewport({ scale: this.zoom, }),
                    textLayerFactory: new pdfviewer.DefaultTextLayerFactory(),
                    annotationLayerFactory: new pdfviewer.DefaultAnnotationLayerFactory(),
                    })
                pdfPageView.setPdfPage(pdfPage)
                pdfPageView.draw()
            })
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
            this.highlights.push(ser)
            var des = this.deserializeRange(ser)
            this.highlightRange(des)
        },

        addNote: function(event) {
            console.log(event)
            var offset = event.target.parentNode.offsetTop + event.target.parentNode.parentNode.parentNode.offsetTop  
            var note = {offset: offset, text: "test"} 
            this.notes.push(note)
        },

        // === CODE FOR HIGHLIGHTING ===

        highlightRange: function(r) {
            // todo: bug on partially highlighted ranges
            var o1 = r.startOffset
            var n1 = r.startContainer.parentNode
            var n2 = r.endContainer.parentNode

            var rr = new Range()
            var nn = n1
            
            while (true) {
                var span = document.createElement("span")
                span.style.backgroundColor = "yellow"
                span.addEventListener("click", this.addNote);
                rr.selectNodeContents(nn)
                if (nn == n1) rr.setStart(nn.firstChild, r.startOffset)
                if (nn == n2) rr.setEnd(nn.firstChild, r.endOffset)

                rr.surroundContents(span)

                if (nn == n2) break
                nn = nn.nextSibling
            }
        },

        serializeRange: function(r) {
            var a = this.serializePosition(r.startContainer, r.startOffset)
            var b = this.serializePosition(r.endContainer, r.endOffset)
            return [a, b]
        },

        deserializeRange: function(s) {
            var r = document.createRange()
            var n
            n = this.deserializePosition(s[0])
            r.setStart(n[0], n[1])
            n = this.deserializePosition(s[1])
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

        deserializePosition: function(s){
            var page = s[0]
            var ndiv = s[1]
            var offset = s[2]

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
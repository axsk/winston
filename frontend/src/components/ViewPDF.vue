<template>
    <div width=600px>
        <pdf
            v-for="i in numPages"
            :key="i"
            :src="src"
            :page="i"
        ></pdf>
    </div>
</template>

<script>

import pdf from 'vue-pdf'

var loadingTask = pdf.createLoadingTask('http://localhost:8000/pdf');

export default {
    components: {
        pdf
    },
    data() {
        return {
            src: loadingTask,
            numPages: undefined,
        }
    },
    mounted() {

        this.src.then(pdf => {

            this.numPages = pdf.numPages;
        });
    }
}

</script>
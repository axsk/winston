<template>
    <el-upload
        drag
        :action="'http://localhost:8000/uploadpaper/' + this.pid"
        multiple>
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">Drop file here or <em>click to upload</em></div>
    </el-upload>
</template>

<script>
export default {
    props: ['pid']
}
</script>

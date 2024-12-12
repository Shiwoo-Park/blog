# js: 파일 업.다운로드


## 업로드

- AWS presigned URL 을 발

```js
/**
 * 파일 업로드
 * file: 파일 객체
 * path: 업로드될 AWS S3 path
 */
async fileUpload(file, path) {
    var form = new FormData()
    form.append('file', file)
    form.append('path', `images/${path}`)

    try {
        const uploaded = await ApiController.post('/file-upload', form, {
        headers: {'Content-Type': 'multipart/form-data'},
    }).then((response) => response.data)

    return uploaded.file_url
}
```

## 다운로드

TBD...
# JavaScript: 파일 업로드/다운로드

## 업로드

AWS presigned URL을 발급받아 파일을 업로드하는 예제입니다.

```js
/**
 * 파일 업로드
 * @param {File} file - 파일 객체
 * @param {string} path - 업로드될 AWS S3 path
 * @returns {Promise<string>} 업로드된 파일 URL
 */
async function fileUpload(file, path) {
    const form = new FormData()
    form.append('file', file)
    form.append('path', `images/${path}`)

    try {
        const uploaded = await ApiController.post('/file-upload', form, {
            headers: {'Content-Type': 'multipart/form-data'},
        }).then((response) => response.data)

        return uploaded.file_url
    } catch (error) {
        console.error('파일 업로드 실패:', error)
        throw error
    }
}
```

## 다운로드

Blob 응답을 받아 파일을 다운로드하는 예제입니다.

```js
/**
 * 파일 다운로드
 * @param {string} url - 다운로드할 파일 URL 또는 API endpoint
 * @param {string} filename - 저장할 파일명 (선택사항)
 */
async function fileDownload(url, filename = null) {
    try {
        const response = await ApiController.get(url, {
            responseType: 'blob',
        })

        // Content-Disposition 헤더에서 파일명 추출
        const contentDisposition = response.headers['content-disposition']
        let downloadFilename = filename || 'downloaded_file'
        
        if (contentDisposition) {
            const fileNameMatch = contentDisposition.match(/filename="?(.+)"?/i)
            if (fileNameMatch && fileNameMatch.length === 2) {
                downloadFilename = fileNameMatch[1]
            }
        }

        // Blob 생성 및 다운로드
        const blob = new Blob([response.data])
        const downloadUrl = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = downloadUrl
        link.setAttribute('download', downloadFilename)
        document.body.appendChild(link)
        link.click()
        link.parentNode.removeChild(link)
        window.URL.revokeObjectURL(downloadUrl)
    } catch (error) {
        console.error('파일 다운로드 실패:', error)
        throw error
    }
}
```
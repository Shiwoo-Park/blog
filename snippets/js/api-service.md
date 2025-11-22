---
layout: post
title: "Axios를 활용한 API 호출용 서비스 모듈"
date: 2024-01-01
categories: [javascript, axios, api]
---

Axios를 활용하여 API를 호출하는 서비스 모듈입니다. 인증이 필요한 API와 인증이 필요 없는 API를 구분하여 사용할 수 있습니다.

---

## 1. ApiController

인증이 필요한 대부분의 API-v2 API 호출 시 사용되는 기본 http client object입니다. axios를 사용합니다.

```js
/**
 * 인증이 필요한 대부분의 API-v2 API 호출할때 사용되는 기본 http client object 를 설정
 * 통지 서비스용 NotificationApiController 는 별도로 관리
 */
import axios from 'axios'
import { checkAuthTokens } from 'libraries/AuthProvider'

const ApiController = axios.create({
  baseURL: process.env.NEXT_PUBLIC_EXTERNAL_API_URL,
  timeout: 60000,
  withCredentials: false,
})

ApiController.getErrorMessage = (baseURL, error) => {
  // Service 모듈에서 getErrorMessage() 에 활용됨

  const defaultErrorMessage = '오류가 발생했습니다. 관리자에게 문의하세요.'
  const errorMessage = error.response?.data?.message || defaultErrorMessage

  if (errorMessage == defaultErrorMessage) {
    console.error(`API failed: ${baseURL}`)
    console.error(error)
  } else {
    console.error(`API failed: ${baseURL} - ${errorMessage}`)
  }

  return errorMessage
}

ApiController.listParamKeyRepeatSerializer = (params) => {
  // 쿼리 파라미터에 key:[111,222] 배열 형식이 입력되었을때
  // 기본적으로는 key[]=111&key[]=222 로 전송되기때문에 DRF Filter 에서 이해를 못함.
  // 이를 해결하기위해 실제 전송되는 URL 형태를 key=111&key=222 로 변환하는 로직

  return Object.keys(params)
    .map((key) => {
      const value = params[key]

      // null 또는 빈 문자열인 경우 제외
      if (value === null || value === '') return ''

      // 배열인 경우 처리
      if (Array.isArray(value)) {
        return value
          .filter((val) => val !== null && val !== '') // 배열 값에서도 null 또는 빈 문자열 제외
          .map((val) => `${encodeURIComponent(key)}=${encodeURIComponent(val)}`)
          .join('&')
      }

      // 기본 값 처리
      return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`
    })
    .filter((param) => param !== '') // 빈 문자열인 경우 제외
    .join('&')
}

ApiController.listParamCommaSeparateSerializer = (params) => {
  // 쿼리 파라미터에 key:[111,222] 배열 형식이 입력되었을때
  // 기본적으로는 key[]=111&key[]=222 로 전송되기때문에 DRF Filter 에서 이해를 못함.
  // 이를 해결하기위해 실제 전송되는 URL 형태를 key=111,222 로 변환하는 로직
  // 백엔드 쪽에서는 BaseInFilter 사용하면 됨.

  return Object.keys(params)
    .map((key) => {
      const value = params[key]

      // null 또는 빈 문자열인 경우 제외
      if (value === null || value === '') return ''

      // 배열인 경우 처리
      if (Array.isArray(value)) {
        const commaSeparatedVal = value
          .filter((val) => val !== null && val !== '') // 배열 값에서도 null 또는 빈 문자열 제외
          .map((val) => encodeURIComponent(val))
          .join(',')
        return `${encodeURIComponent(key)}=${commaSeparatedVal}`
      }

      // 기본 값 처리
      return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`
    })
    .filter((param) => param !== '') // 빈 문자열인 경우 제외
    .join('&')
}

ApiController.interceptors.request.use(async (config) => {
  if (typeof window === 'undefined') return config

  // CSR 페이지로부터의 접근일때
  let accessToken = window.__NEXT_DATA__.props?.accessToken
  let refreshToken = window.__NEXT_DATA__.props?.refreshToken
  if (!refreshToken) return config

  // 이미 로그인한 상황일 경우
  try {
    const checkTokenResult = await checkAuthTokens(accessToken, refreshToken)
    if (!checkTokenResult.isAuthorized) {
      throw Error('ApiController - 인증 오류')
    }

    if (checkTokenResult.isRenewed) {
      accessToken = checkTokenResult.newAccessToken
      window.__NEXT_DATA__.props.accessToken = checkTokenResult.newAccessToken
      window.__NEXT_DATA__.props.refreshToken = checkTokenResult.newRefreshToken
    }
  } catch (error) {
    window.location.href = '/auth/login'
    return Promise.reject(error)
  }

  config.headers.Authorization = `Baro ${accessToken}`
  return config
})

ApiController.interceptors.response.use(
  (res) => res,
  function (error) {
    const isBrowser = typeof window != 'undefined'

    if (isBrowser) {
      if (error.response?.status == 401) {
        window.location.href = '/auth/login'
      }
    }

    return Promise.reject(error)
  }
)

export default ApiController
```

---

## 2. Django ViewSet 기반 API 서비스 모듈 템플릿

Django ViewSet 기반 API를 호출하기 위한 서비스 모듈 템플릿입니다. axios 기반이며, 인증이 필요 없는 API를 호출할 때 사용되는 기본 http client object입니다.

```js
/**
 * Django ViewSet 기반 API 용 서비스 코드 템플릿
 *
 * - 이 파일을 복사-붙여넣기하여 쉽게 코드를 작성해보세요 !!
 * - 인증이 필요없는 API 의 경우 PureApiController 를 사용하세요 !!
 * - pages/_template 하위 파일들과 함께 활용하세요~!
 */
import ApiController from 'libraries/ApiController'

export default {
  baseURL: '/cms/products',
  getErrorMessage(error) {
    return ApiController.getErrorMessage(this.baseURL, error)
  },
  async getList(params) {
    return await ApiController.get(this.baseURL, {
      params: params,
    }).then((response) => response.data)
  },
  async getDetail(id) {
    return await ApiController.get(`${this.baseURL}/${id}`).then(
      (response) => response.data
    )
  },
  async create(requestBody) {
    return await ApiController.post(this.baseURL, requestBody).then(
      (response) => response.data
    )
  },
  async update(id, requestBody) {
    return await ApiController.put(`${this.baseURL}/${id}`, requestBody).then(
      (response) => response.data
    )
  },
  async partialUpdate(id, requestBody) {
    return await ApiController.patch(`${this.baseURL}/${id}`, requestBody).then(
      (response) => response.data
    )
  },
}
```
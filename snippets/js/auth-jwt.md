---
layout: post
title: "JWT 기반 인증을 사용하는 API 호출용 모듈들"
date: 2024-01-01
categories: [javascript, jwt, auth, axios]
---

JWT 기반 인증을 사용하는 API 호출용 모듈들입니다. axios를 사용하며, 인증이 필요한 API와 인증이 필요 없는 API를 구분하여 사용할 수 있습니다.

---

## 1. 비인증 API 호출용 모듈

인증이 필요 없는 API를 호출할 때 사용되는 기본 http client object입니다. axios 기반입니다.

```js
import axios from 'axios'
const PureApiController = axios.create({
  baseURL: process.env.NEXT_PUBLIC_EXTERNAL_API_URL,
  timeout: 60000,
  withCredentials: false,
})

export default PureApiController
```

---

## 2. 인증 API 호출용 모듈

인증이 필요한 대부분의 API-v2 API 호출 시 사용되는 기본 http client object입니다.

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

## 3. JWT 인증의 토큰 발급 및 만료 전 재발급 처리용 모듈

JWT 토큰의 발급 및 만료 전 재발급을 처리하는 모듈입니다.

```js
import dayjs from 'dayjs'
import AuthService from 'services/AuthService'
import ApiController from 'libraries/ApiController'
import { createContext, useState, useContext } from 'react'

const AuthContext = createContext({
  user: {},
  accessToken: null,
  refreshToken: null,
})

const AuthProvider = ({ children, session, accessToken, refreshToken }) => {
  const [_accessToken] = useState(accessToken)
  const [_refreshToken] = useState(refreshToken)
  const [user, setUser] = useState(session?.user)
  const [pages] = useState(session?.pages)

  return (
    <AuthContext.Provider
      value={
        accessToken: _accessToken,
        refreshToken: _refreshToken,
        session: {
          user: user,
          setUser: setUser,
          pages: pages,
        },
      }
    >
      {children}
    </AuthContext.Provider>
  )
}

const useSession = () => useContext(AuthContext)

/**
 * 제공된 JWT 토큰에서 정보를 추출하여 토큰의 만료 시간 및 유효성을 확인합니다.
 *
 * @param {string} jwtToken - 검사할 JWT 토큰
 * @returns {object} 토큰의 만료 정보를 포함하는 객체를 반환합니다.
 * {
 *   maxAge: {number}, // 토큰의 남은 유효 시간(초)
 *   isExpired: {boolean}, // 토큰이 이미 만료되었는지 여부
 *   willExpireSoon: {boolean} // 토큰이 24시간 이내에 만료될 예정인지 여부
 * }
 */
const getTokenInfo = (jwtToken) => {
  const retData = {
    maxAge: 0,
    isExpired: true,
    willExpireSoon: false,
  }
  try {
    const now = dayjs()
    let payload = JSON.parse(
      Buffer.from(jwtToken.split('.')[1], 'base64').toString()
    )
    let expiresAt = dayjs.unix(payload.exp)

    retData.maxAge = payload.exp - dayjs().unix()
    retData.isExpired = expiresAt.isBefore(now)
    // 24시간 이내 만료될 예정일 경우 true
    retData.willExpireSoon = expiresAt.isBefore(now.add(1, 'day'))
  } catch (error) {
    // jwtToken 이 비어있는 경우
    console.log('Invalid JWT token')
  }
  return retData
}

/**
 * 주어진 액세스 토큰과 리프레시 토큰의 유효성을 검사하고, 필요에 따라 새 토큰을 발급받습니다.
 *
 * @param {string} accessToken - 현재 사용자의 액세스 토큰
 * @param {string} refreshToken - 현재 사용자의 리프레시 토큰
 * @returns {Promise<object>} 검증 결과를 담은 객체를 반환합니다.
 * {
 *   isAuthorized: {boolean}, // 토큰이 유효한지 여부
 *   isRenewed: {boolean}, // 토큰이 갱신되었는지 여부
 *   newAccessToken: {string | null}, // 갱신된 액세스 토큰, 갱신되지 않았다면 null
 *   newRefreshToken: {string | null} // 갱신된 리프레시 토큰, 갱신되지 않았다면 null
 * }
 */
const checkAuthTokens = async (accessToken, refreshToken) => {
  const retData = {
    isAuthorized: false,
    isRenewed: false,
    newAccessToken: null,
    newRefreshToken: null,
  }

  // accessToken 만료여부 확인
  const accessTokenInfo = getTokenInfo(accessToken)
  const refreshTokenInfo = getTokenInfo(refreshToken)
  const needToRefreshTokens =
    accessTokenInfo.isExpired || accessTokenInfo.willExpireSoon

  if (needToRefreshTokens) {
    // 토큰만료가 임박했을때도 미리 갱신처리
    if (!refreshTokenInfo.isExpired) {
      // 토큰 refresh
      try {
        const { access, refresh } = await AuthService.refreshTokens(
          refreshToken
        )
        retData.isAuthorized = true
        retData.isRenewed = true
        retData.newAccessToken = access
        retData.newRefreshToken = refresh
      } catch (error) {
        console.log(error)
        console.log('인증 토큰 갱신 실패')
      }
    } else {
      console.log('AuthProvider - All tokens are expired...')
    }
  } else {
    retData.isAuthorized = true
  }

  return retData
}

const redirectToLoginPage = async (app) => {
  const accessTokenName = process.env.NEXT_PUBLIC_ACCESS_TOKEN_NAME
  const refreshTokenName = process.env.NEXT_PUBLIC_REFRESH_TOKEN_NAME
  const secure =
    process.env.NEXT_PUBLIC_COOKIE_SECURE == 'true' ? ' Secure;' : ''

  app.ctx.res.setHeader('Set-Cookie', [
    `${accessTokenName}=deleted; path=/; max-age=0; httpOnly; ${secure}`,
    `${refreshTokenName}=deleted; path=/; max-age=0; httpOnly; ${secure}`,
  ])
  app.ctx.res.writeHead(302, {
    Location: '/auth/login',
  })
  app.ctx.res.end()
}

const authWrapper = async (app) => {
  const isBrowser = typeof window !== 'undefined'

  if (!isBrowser) {
    if (app.ctx.req.url == '/health') {
      return app
    }

    if (app.ctx.req.url.search(/\/auth\/(login|user)/) == -1) {
      const accessTokenName = process.env.NEXT_PUBLIC_ACCESS_TOKEN_NAME
      const refreshTokenName = process.env.NEXT_PUBLIC_REFRESH_TOKEN_NAME
      const secure =
        process.env.NEXT_PUBLIC_COOKIE_SECURE == 'true' ? ' Secure;' : ''

      if (
        app.ctx.req.cookies[accessTokenName] === undefined &&
        app.ctx.req.cookies[refreshTokenName] === undefined
      ) {
        console.log(
          '인증토큰 정보 없음: app.ctx.req.cookies=',
          app.ctx.req.cookies
        )
        await redirectToLoginPage(app)
        return app
      } else {
        // 인증 token 정보(2개) 발견, 세션 정보 불러오기 시작
        try {
          const headers = app.ctx.req.headers

          let accessToken = app.ctx.req.cookies[accessTokenName]
          let refreshToken = app.ctx.req.cookies[refreshTokenName]

          const checkTokenResult = await checkAuthTokens(
            accessToken,
            refreshToken
          )

          if (!checkTokenResult.isAuthorized) {
            await redirectToLoginPage(app)
            return app
          }

          if (checkTokenResult.isRenewed) {
            // 새로 발급받은 토큰들로 갈아끼운다.
            accessToken = checkTokenResult.newAccessToken
            refreshToken = checkTokenResult.newRefreshToken

            // 두 개의 쿠키를 설정
            const newAccessTokenInfo = getTokenInfo(accessToken)
            const newRefreshTokenInfo = getTokenInfo(refreshToken)
            app.ctx.res.setHeader('Set-Cookie', [
              `${accessTokenName}=${accessToken}; path=/; max-age=${newAccessTokenInfo.maxAge}; httpOnly; ${secure}`,
              `${refreshTokenName}=${refreshToken}; path=/; max-age=${newRefreshTokenInfo.maxAge}; httpOnly; ${secure}`,
            ])
          }

          delete headers['host']
          delete headers['connection']
          delete headers['content-length']

          ApiController.defaults.headers = {
            ...headers,
            Authorization: `Baro ${accessToken}`,
          }

          const user = await ApiController.get('/auth/user').then(
            (response) => response.data
          )

          if (!user.is_staff) {
            throw Error('접근 권한이 없습니다.')
          }

          const pages = await ApiController.get('/auth/access').then(
            (response) => response.data
          )

          app.ctx = {
            ...app.ctx,
            accessToken: accessToken,
            refreshToken: refreshToken,
            session: { user: user, pages: pages },
          }
        } catch (error) {
          console.error('인증 token 유효성 검사 실패:', error.stack)
          await redirectToLoginPage(app)
        }
      }
    }
  }

  return app
}

export { AuthProvider, useSession, authWrapper, getTokenInfo, checkAuthTokens }
```

---

## 4. 프론트 로그인 API: login.js

프론트엔드에서 로그인을 처리하는 API 엔드포인트입니다.

```js
import AuthService from 'services/AuthService'
import { getTokenInfo } from 'libraries/AuthProvider'

export const config = {
  api: {
    bodyParser: true,
  }
}

export default async (req, res) => {
  try {
    const { access, refresh } = await AuthService.getToken(req.body)
    const accessTokenName = process.env.NEXT_PUBLIC_ACCESS_TOKEN_NAME
    const refreshTokenName = process.env.NEXT_PUBLIC_REFRESH_TOKEN_NAME

    const accessTokenInfo = getTokenInfo(access)
    const refreshTokenInfo = getTokenInfo(refresh)
    const secure =
      process.env.NEXT_PUBLIC_COOKIE_SECURE == 'true' ? ' Secure;' : ''

    res.setHeader('Set-Cookie', [
      `${accessTokenName}=${access}; path=/; max-age=${accessTokenInfo.maxAge}; httpOnly; ${secure}`,
      `${refreshTokenName}=${refresh}; path=/; max-age=${refreshTokenInfo.maxAge}; httpOnly; ${secure}`,
    ])

    res.status(200).json({ access: access, refresh: refresh })
  } catch (error) {
    console.error(error)
    res.status(400).json({ message: '로그인 실패' })
  }
}
```

---

## 5. Service: API Controller를 사용하여 직접 endpoint 호출

API Controller를 사용하여 직접 endpoint를 호출하는 Service 모듈 예제입니다.

```js
import ApiController from 'libraries/ApiController'

export default {
  baseURL: '/inventories',
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
  async bulkUpdate(id, requestBody) {
    return await ApiController.put(
      `${this.baseURL}/bulk-update`,
      requestBody
    ).then((response) => response.data)
  },
}
```
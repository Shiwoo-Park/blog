---
layout: post
title: "ApiSelect - React 컴포넌트"
date: 2024-01-01
categories: [react, javascript, frontend]
---

Select 방식의 UI를 제공하지만 이를 백엔드 endpoint와 연결하여 사용할 수 있도록 한 컴포넌트입니다. 다양한 유틸 기능을 탑재하였으며, Django DRF의 특정 View와 호환시켜야만 사용이 가능합니다. `snippets/django/api-select.md`와 함께 사용할 수 있습니다.

---

## 1. ApiSelect 컴포넌트

ForeignKey 데이터 입력용 컴포넌트입니다. 백엔드 API와 쉽게 연동 가능한 select box UI Component입니다.
```js
/**
ForeignKey 데이터 입력용 컴포넌트

- 백엔드 API 와 아주 쉽게 연동 가능한 select box UI Component
- api-v2 에서 BaseApiSelectAPIView 를 상속받은 APIView 를 구현한뒤 endpoint 연동

<ApiSelect
  title={'도매'}
  required={true}
  showTotal
  value={formData.wholesaler_id || ''}
  onChange={(v) => {
    setData('wholesaler_id', v)
  }}
  endpoint={'/wholesalers/api-select'}
  isNullable
  helpText="- 도움말입니다.<br/>- 2번째 도움말입니다."
  helpTextContainsHTML
></ApiSelect>
*/
import ApiController from 'libraries/ApiController'
import useApiSelectData from 'libraries/ApiSelectData'
import { useEffect, useId, useRef, useState } from 'react'
import { CopyToClipboard } from 'react-copy-to-clipboard'
import Select from 'react-select'
import { useToasts } from 'react-toast-notifications'

const ApiSelect = ({
  title, // 필드명
  endpoint, // api-v2 URL path
  value, // 값
  onChange = () => {},
  required, // true 일때 title 옆에 빨간 별표 표시
  disabled = false,
  isClearable = true,
  helpText = '', // 도움말 (입력칸 하단에 파란글씨로 표시)
  helpTextContainsHTML = false, // 도움말에 html 입력 허용
  baseParams, // API request default query params
  valueField = 'id', // value 에 해당되는 모델 필드명 (기본값=id, 초기값 불러올때 query_param 에 사용)
  placeholder = '검색&선택',
  isNullable = false, // true 일때 "미지정" 선택지 표시 (value=null), optional 과 유사한 의미
  showTotal = false,
}) => {
  const isDebug = false

  const { addToast } = useToasts()
  const instanceId = useId()
  const helpTextDivClassName = 'text-sm text-blue-500 ml-1 flex'
  const { options, loading, nextPageParams, total, loadOptions } =
    useApiSelectData(endpoint, baseParams, isNullable)
  const [inputValue, setInputValue] = useState(value)
  const [copyValue, setCopyValue] = useState(value)
  const [initOption, setInitOption] = useState(null)
  const [isClient, setIsClient] = useState(false)
  const typingCollectMillisecond = 400 // API call 횟수를 줄이기 위해 검색어 타이핑 버퍼를 둠
  const timerRef = useRef(null)

  if (isDebug)
    console.log(`[ApiSelect] title=${title}, init value=${inputValue}`)

  useEffect(() => {
    setIsClient(true)
    loadInitOption()
    loadOptions()

    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current)
      }
    }
  }, [])

  const elemOnChange = (option) => {
    setCopyValue(option?.value)
    onChange(option?.value)
  }

  const loadInitOption = async () => {
    if (
      inputValue === null ||
      inputValue === undefined ||
      (typeof inputValue == 'string' && inputValue.trim() === '')
    ) {
      return
    }

    try {
      const params = { [valueField]: inputValue }
      if (isDebug)
        console.log('[ApiSelect] loadInitOption: Request params=', params)

      const response = await ApiController.get(endpoint, {
        params: params,
      })
      if (isDebug)
        console.log('[ApiSelect] loadInitOption: Response Data', response.data)

      if (response.data.count === 1) {
        if (isDebug)
          console.log('[ApiSelect] setInitOption: ', response.data.results[0])

        setInitOption(response.data.results[0]) // 초기값 옵션 세팅
      } else {
        console.error(
          `[ApiSelect] 초기값 불러오기 실패: endpoint=${endpoint}, params=${params}`
        )
      }
    } catch (error) {
      console.error('[ApiSelect] Failed to fetch data:', error)
    }
  }

  const handleInputChange = (newValue) => {
    setInputValue(newValue)

    // 검색어 타이핑 타이머 reset
    if (timerRef.current) {
      clearTimeout(timerRef.current)
    }
    timerRef.current = setTimeout(() => {
      loadOptions({ ...baseParams, search: newValue })
    }, typingCollectMillisecond)
  }

  const handleScrollToEnd = () => {
    const hasNextPage = nextPageParams !== null
    if (!loading && hasNextPage) {
      loadOptions(nextPageParams, true)
    }
  }

  // 초기값과 불러온값을 적절하게 합쳐서 최종 옵션리스트 생성
  let finalOptions = options
  if (inputValue !== null && inputValue !== undefined && initOption !== null) {
    const optionHasValue = options.some(
      (item) => String(item.value) === String(inputValue)
    )
    if (!optionHasValue) finalOptions = [initOption, ...options]
  }
  if (isDebug) console.log('Final Options:', finalOptions)

  if (!isClient) {
    // Warning: Extra attributes from the server: aria-activedescendant 경고 해결
    // SSR을 사용하는 프로젝트에서 클라이언트 측에서만 Select 컴포넌트를 렌더링하도록 처리
    return <></>
  }

  return (
    <>
      <div className="flex flex-col space-y-1">
        {title && (
          <div className="text-xs text-gray-400 font-bold">
            {title}
            {required && <span className="text-red-500"> *</span>}
            {showTotal && ` | total: ${total}`}
            {copyValue && (
              <CopyToClipboard
                text={copyValue}
                onCopy={() => {
                  addToast(`${title} ID 가 클립보드에 복사되었습니다.`, {
                    autoDismiss: true,
                  })
                }}
              >
                <i className="cursor-pointer far fa-clipboard px-2"></i>
              </CopyToClipboard>
            )}
          </div>
        )}
        <div className="w-full">
          <Select
            instanceId={instanceId}
            // options={initOption === null ? options : [initOption, ...options]}
            options={finalOptions}
            value={finalOptions.find(
              (option) => String(option.value) === String(value)
            )}
            isDisabled={disabled}
            onChange={elemOnChange}
            onInputChange={handleInputChange}
            onMenuScrollToBottom={handleScrollToEnd}
            isLoading={loading}
            placeholder={placeholder}
            isClearable={isClearable}
          />
        </div>
        {helpText && helpTextContainsHTML ? (
          <div
            className={helpTextDivClassName}
            dangerouslySetInnerHTML={ { __html: helpText } }
          />
        ) : (
          <div className={helpTextDivClassName}>{helpText}</div>
        )}
      </div>
    </>
  )
}

export default ApiSelect
```

---

## 2. ApiMultiSelect 컴포넌트

여러 개의 값을 선택할 수 있는 멀티 셀렉트 컴포넌트입니다.

```js
import ApiController from 'libraries/ApiController'
import useApiSelectData from 'libraries/ApiSelectData'
import { useEffect, useId, useRef, useState } from 'react'
import Select from 'react-select'

const ApiMultiSelect = ({
  title, // 필드명
  endpoint, // api-v2 URL path
  value = [], // 값 (리스트 형태로 받음)
  onChange = () => {},
  required, // true 일때 title 옆에 빨간 별표 표시
  disabled = false,
  isClearable = true,
  helpText = '', // 도움말 (입력칸 하단에 파란글씨로 표시)
  helpTextContainsHTML = false, // 도움말에 html 입력 허용
  baseParams, // API request default query params
  valueField = 'id', // value 에 해당되는 모델 필드명 (기본값=id, 초기값 불러올때 query_param 에 사용)
  placeholder = '검색&선택',
  isNullable = false, // true 일때 "미지정" 선택지 표시 (value=null), optional 과 유사한 의미
  showTotal = false, // 검색된 모든 option 의 전체 개수 표시 여부
  showOptionLabelList = false, // 하단에 지정한 옵션들의 label 을 리스트 형태로 별도로 제공 (직접 복.붙할때 용이하도록 처리)
}) => {
  const cleanValue = (value) => {
    if (Array.isArray(value)) {
      return value
    }

    if (typeof value === 'number') {
      return [val]
    }

    if (typeof value === 'string') {
      if (value.includes(',')) {
        return value.split(',')
      } else {
        return [value]
      }
    }

    console.warn(`[ApiMultiSelect] 유효하지 않은 value=${value}`)
    return []
  }

  const isDebug = false
  const instanceId = useId()
  const helpTextDivClassName = 'text-sm text-blue-500 ml-1 flex'
  const { options, loading, nextPageParams, total, loadOptions } =
    useApiSelectData(endpoint, baseParams, isNullable)
  const [initOptions, setInitOptions] = useState([])
  const [inputValueArray, setInputValueArray] = useState(cleanValue(value))
  const [isClient, setIsClient] = useState(false)
  const typingCollectMillisecond = 400
  const timerRef = useRef(null)

  useEffect(() => {
    setIsClient(true)
    loadInitOptions()
    loadOptions()

    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current)
      }
    }
  }, [])

  const elemOnChange = (selectedOptions) => {
    if (isDebug) console.log('elemOnChange():', selectedOptions)
    const selectedValues = selectedOptions
      ? selectedOptions.map((opt) => opt.value)
      : []
    setInputValueArray(selectedValues)
    setInitOptions([...initOptions, ...selectedOptions])
    onChange(selectedValues)
  }

  const loadInitOptions = async () => {
    if (!inputValueArray.length) return

    try {
      // inputValue 가 리스트일때는 콤마로 구분하여 전송
      if (isDebug) console.log('[ApiMultiSelect] inputValue:', inputValueArray)
      const params = { [valueField]: inputValueArray.join(',') }
      const response = await ApiController.get(endpoint, {
        params: params,
      })
      setInitOptions(response.data.results)
    } catch (error) {
      console.error('[ApiMultiSelect] Failed to fetch data:', error)
    }
  }

  const handleInputChange = (newValue) => {
    if (timerRef.current) {
      clearTimeout(timerRef.current)
    }
    timerRef.current = setTimeout(() => {
      loadOptions({ ...baseParams, search: newValue })
    }, typingCollectMillisecond)
  }

  const handleScrollToEnd = () => {
    const hasNextPage = nextPageParams !== null
    if (!loading && hasNextPage) {
      loadOptions(nextPageParams, true)
    }
  }

  let finalOptions = [...initOptions, ...options]
  finalOptions = Array.from(
    // value 중복 아이템 제거
    new Map(finalOptions.map((item) => [item.value, item])).values()
  )

  if (isDebug) console.log('Final Options:', finalOptions)

  if (!isClient) {
    return <></>
  }

  return (
    <>
      <div className="flex flex-col space-y-1">
        {title && (
          <div className="text-xs text-gray-400 font-bold">
            {title}
            {required && <span className="text-red-500"> *</span>}
            {showTotal && ` | total: ${total}`}
          </div>
        )}
        <div className="w-full">
          <Select
            instanceId={instanceId}
            options={finalOptions}
            value={finalOptions.filter((option) => {
              if (
                inputValueArray.length > 0 &&
                typeof inputValueArray[0] === 'string'
              ) {
                return inputValueArray.includes(String(option.value))
              } else {
                return inputValueArray.includes(option.value)
              }
            })}
            isMulti
            isDisabled={disabled}
            onChange={elemOnChange}
            onInputChange={handleInputChange}
            onMenuScrollToBottom={handleScrollToEnd}
            isLoading={loading}
            placeholder={placeholder}
            isClearable={isClearable}
          />
        </div>
        {helpText && helpTextContainsHTML ? (
          <div
            className={helpTextDivClassName}
            dangerouslySetInnerHTML={ { __html: helpText } }
          />
        ) : (
          <div className={helpTextDivClassName}>{helpText}</div>
        )}
        {showOptionLabelList && (
          <div>
            {finalOptions
              .filter((option) => {
                if (
                  inputValueArray.length > 0 &&
                  typeof inputValueArray[0] === 'string'
                ) {
                  return inputValueArray.includes(String(option.value))
                } else {
                  return inputValueArray.includes(option.value)
                }
              })
              .map((option) => {
                return (
                  <>
                    {option.label}
                    <br />
                  </>
                )
              })}
          </div>
        )}
      </div>
    </>
  )
}

export default ApiMultiSelect
```
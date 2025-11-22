---
layout: post
title: "React - useForm() 의 기본 사용법"
date: 2024-07-09
categories: [frontend, react, forms]
---
React Hook Form의 `useForm` 훅 사용법에 대해 설명해 드리겠습니다.

`useForm`은 React Hook Form 라이브러리의 핵심 기능으로, 폼 상태 관리와 유효성 검사를 쉽게 할 수 있게 해줍니다. 주요 사용법은 다음과 같습니다:

1. 기본 사용:

```javascript
import { useForm } from "react-hook-form";

function MyForm() {
  const { register, handleSubmit, formState: { errors } } = useForm();

  const onSubmit = (data) => console.log(data);

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("firstName", { required: true })} />
      {errors.firstName && <span>This field is required</span>}
      <input {...register("lastName", { required: true })} />
      {errors.lastName && <span>This field is required</span>}
      <input type="submit" />
    </form>
  );
}
```

2. 초기값 설정:

```javascript
const { register, handleSubmit } = useForm({
  defaultValues: {
    firstName: "John",
    lastName: "Doe"
  }
});
```

3. 유효성 검사 규칙:

```javascript
<input {...register("age", { min: 18, max: 99 })} />
```

4. 커스텀 유효성 검사:

```javascript
const { register, handleSubmit } = useForm({
  validate: {
    username: (value) => value.length > 5 || "Username must be longer than 5 characters"
  }
});
```

5. 필드 값 감시:

```javascript
const { watch } = useForm();
const watchUsername = watch("username");
```

6. 에러 처리:

```javascript
const { formState: { errors } } = useForm();
// 사용:
{errors.username && <span>{errors.username.message}</span>}
```

7. 폼 리셋:

```javascript
const { reset } = useForm();
// 사용:
reset();
```

8. 동적 필드:

```javascript
const { fields, append, remove } = useFieldArray({
  control,
  name: "items"
});
```

9. 비제어 컴포넌트로 사용:

```javascript
const { register } = useForm();
<input {...register("example")} />;
```

10. 조건부 필드:

```javascript
const { watch } = useForm();
const watchShowAge = watch("showAge", false);

return (
  <form>
    <input type="checkbox" {...register("showAge")} />
    {watchShowAge && <input type="number" {...register("age")} />}
  </form>
);
```

`useForm`은 이외에도 다양한 기능을 제공합니다. 폼의 복잡성에 따라 적절한 기능을 선택하여 사용할 수 있습니다. 

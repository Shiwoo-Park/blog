# js 프로젝트에서 Enum 관리를 위한 모듈

- 타입스크립트 기반일경우 타입까지 정의한 버전

## enums/base.tsx

- 공통 코드 모듈 파일

```js
/**
 * 프로젝트의 Enum 형태 필드들을 관리하기위한 유틸 함수들 모음
 * 
 * [사용법]

1. Enum 필드 선언

import { EnumItem } from "../base";

export const PharmacyFranchiseType: EnumObject = Object.freeze({
  ONNURI: { value: "FT_01", label: "온누리" },
  MEDIPHARM: { value: "FT_02", label: "메디팜" },
  OPTIMA: { value: "FT_03", label: "옵티마" },
  HUBASE: { value: "FT_04", label: "휴베이스" },
});

2. 모델 인터페이스 선언

export interface Pharmacy {
  id: number | null;
  name: string;
  ...
  franchise_type: EnumValue<typeof PharmacyFranchiseType> | null;
  ...
}

*/
export interface EnumItem {
  value: string;
  label: string;
}

export type EnumObject = Record<string, EnumItem>;

type ValueOf<T> = T[keyof T];

export type EnumValue<T extends EnumObject> = ValueOf<T>["value"];

export function getOptionsByEnum(
  enumObject: EnumObject,
  {
    includeEmptyChoice = false,
    excludes = [],
    includes = [],
  }: {
    includeEmptyChoice?: boolean;
    excludes?: EnumItem[];
    includes?: EnumItem[];
  } = {},
) {
  const includeValues = includes.map((item) => item.value);
  const excludeValues = excludes.map((item) => item.value);

  const filteredOptions = (Object.values(enumObject) as EnumItem[]).filter(
    ({ value }) => {
      if (includeValues.length > 0) return includeValues.includes(value);
      if (excludeValues.length > 0) return !excludeValues.includes(value);
      return true;
    },
  );

  if (includeEmptyChoice) {
    return [{ label: "전체", value: "" }, ...filteredOptions];
  }

  return filteredOptions;
}

export function getEnum(
  enumObject: EnumObject,
  enumValue: string,
): EnumItem | null {
  return (
    (Object.values(enumObject) as EnumItem[]).find(
      (item) => item.value === enumValue,
    ) || null
  );
}

export function getEnumLabel(
  enumObject: EnumObject,
  enumValue: string,
): string {
  const type = getEnum(enumObject, enumValue);
  return type ? type.label : "정의 되지 않음";
}
```
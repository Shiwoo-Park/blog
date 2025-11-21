---
layout: post
title: "git squash (커밋 합치기)"
date: 2024-04-19
categories: [git, workflow]
---

# git squash (커밋 합치기)

> 날짜: 2024-04-19

이 문서에서는 예제로 최근 3개 커밋을 squash(=하나의 커밋으로 묶기) 하는 방법을 적어두었습니다.

Git에서 최근 3개의 커밋을 squash하는 과정은 interactive rebase를 사용하여 진행할 수 있습니다. 여기 간단한 단계를 안내해 드리겠습니다:

1. **Rebase 시작하기**:
   ```bash
   git rebase -i HEAD~3
   ```
   - 이 명령어는 최근 3개의 커밋을 수정할 수 있는 rebase 세션을 시작합니다.

2. **커밋 squash하기**:
   - 텍스트 편집기가 열리면, **가장 최근 커밋을 제외한** 나머지 커밋 앞에 있는 `pick`을 `squash`나 `s`로 변경합니다. 
   - 이렇게 설정하면, 선택한 커밋들이 바로 이전 커밋과 합쳐집니다.

3. **커밋 메시지 편집하기**:
   - 커밋들을 squash하고 나면, 커밋 메시지를 편집하는 창이 나타납니다. 
   - 여기서는 원하는 커밋 메시지를 작성하거나 기존 메시지를 정리할 수 있습니다.

4. **변경사항 완료 및 적용하기**:
   - 모든 편집을 마친 후에는 변경사항을 저장하고 rebase를 완료합니다.
   - 이렇게 하면 지정된 커밋들이 하나로 합쳐진 상태로 로컬 레포지토리에 적용됩니다.

   ```
   # 변경사항 강제로 remote 반영 (force push)
   git push origin --force
   # Remote tracking branch 가 설정이 안되어있다면
   git push origin feature-branch-name --force

   # rebase 취소하기
   git rebase --abort
   ```

---

[목록으로](https://shiwoo-park.github.io/blog)

# GitHub 등록 가이드 (budget_book_codex)

> 본 문서는 `budget_book_codex` 프로젝트를 **GitHub Private 저장소**에 등록하기 위한 절차서입니다.
> 인증 방식: **GitHub CLI (`gh`)** / 저장소 가시성: **Private** / .gitignore: 본 가이드에 따라 사전 점검 완료.

---

## 0. 사전 확인

| 항목 | 확인 방법 | 비고 |
|------|----------|------|
| `git` 설치 | `git --version` | 2.30+ 권장 |
| `gh` 설치 | `gh --version` | 미설치 시 https://cli.github.com 참고 |
| GitHub 계정 로그인 | `gh auth status` | 미인증 시 `gh auth login` 실행 |
| 현재 위치 | `pwd` | `/Users/sangminseok/claude/budget_book_codex` 인지 확인 |

> macOS Homebrew 사용자는 다음으로 한번에 설치 가능합니다.
> ```bash
> brew install git gh
> ```

---

## 1. (선택) 임시로 생성된 `.git` 정리

검증 과정에서 `.git/` 폴더가 이미 생성되어 있을 수 있습니다. **그대로 사용해도 무방**하지만, 깨끗하게 새로 시작하려면 한 줄로 제거하십시오.

```bash
cd "/Users/sangminseok/claude/budget_book_codex"
rm -rf .git
```

---

## 2. Git 초기화 및 사용자 정보 설정

```bash
cd "/Users/sangminseok/claude/budget_book_codex"

# 기본 브랜치를 main 으로 초기화
git init -b main

# 커밋 작성자 정보 (저장소 단위 설정)
git config user.name  "미니"
git config user.email "seoksm@winitech.com"
```

> 전역(global)으로 이미 설정되어 있다면 위 두 줄은 생략 가능합니다.

---

## 3. 추적 대상 사전 점검

```bash
# 추적될 파일이 어떤 것들인지 미리 확인 (커밋 전에 반드시!)
git status

# .gitignore 가 빌드 산출물/도구 런타임을 제외하는지 검증
git check-ignore -v tools/node-24 tools/jdk-21 backend/build frontend/node_modules backend/data
```

`.gitignore` 적용 후 추적 후보 파일은 **약 182개** 수준이어야 합니다(3,375개에서 줄어듦).
만약 `tools/node-24`, `tools/jdk-21`, `node_modules`, `build` 등이 status에 보이면 **커밋하지 말고** `.gitignore`를 재점검하십시오.

---

## 4. 최초 커밋

```bash
git add .
git commit -m "chore: initial commit - budget_book_codex (Spring Boot + Vite/React)"
```

---

## 5. GitHub Private 저장소 생성 + Push (한 번에)

`gh repo create` 한 줄로 **저장소 생성 → remote 등록 → push** 까지 완료됩니다.

```bash
# 본인 GitHub 계정 하위에 private 저장소 생성 후 현재 디렉토리를 push
gh repo create budget-book-codex \
    --private \
    --source=. \
    --remote=origin \
    --push \
    --description "가계부 풀스택 프로젝트 (Spring Boot + Vite/React)"
```

- `--private` : 비공개 저장소 (요청하신 사항)
- `--source=.` : 현재 폴더를 그대로 사용
- `--remote=origin` : remote 이름을 origin 으로 등록
- `--push` : 생성과 동시에 push

성공 시 다음과 같은 메시지가 출력됩니다.
```
✓ Created repository <계정>/budget-book-codex on GitHub
✓ Added remote git@github.com:<계정>/budget-book-codex.git
✓ Pushed commits to git@github.com:<계정>/budget-book-codex.git
```

---

## 6. 등록 결과 열기

```bash
gh repo view --web
```

---

## 부록 A. `gh` 인증이 안 되어 있을 때

```bash
gh auth login
```

선택 옵션:
1. `GitHub.com` 선택
2. 프로토콜은 **HTTPS** 또는 **SSH** 중 편한 것
3. **Login with a web browser** 선택 (one-time code 발급)
4. 브라우저에서 코드 입력 → 권한 승인

---

## 부록 B. 이미 다른 remote가 있던 경우

```bash
git remote -v                       # 현재 remote 확인
git remote remove origin            # 기존 origin 제거
# 이후 5단계 다시 수행
```

---

## 부록 C. 시큐어 코딩 후속 조치 (권장)

현재 `backend/src/main/resources/application.yml` 에 **JWT secret이 평문**으로 포함되어 있습니다.

```yaml
app:
  auth:
    jwt-secret: budget-book-codex-local-dev-secret-change-me-2026
```

Private 저장소라도, **권한 위임/협업자 추가 시 노출 위험**이 있으므로 다음 중 하나의 방식으로 분리하는 것을 권장합니다.

1. **환경 변수 주입 방식**
    ```yaml
    app:
      auth:
        jwt-secret: ${APP_AUTH_JWT_SECRET:dev-only-fallback}
    ```
    `.env`, OS 환경변수, 또는 IDE Run Configuration 에서 주입.

2. **profile 분리** — `application-local.yml`, `application-prod.yml` 로 나누고 `.gitignore` 처리 (이미 본 가이드의 `.gitignore`에 반영됨).

3. **Secret Manager 사용** — HashiCorp Vault, AWS Secrets Manager, Spring Cloud Config 등.

> 본 변경은 이번 GitHub 등록과 별개로 다음 PR/커밋에서 처리하시면 됩니다.

---

## 부록 D. 자주 만나는 오류

| 오류 메시지 | 원인 | 해결 |
|------------|------|------|
| `error: pathspec ... did not match any files` | `git add` 대상이 비어있음 | `git status` 로 추적 후보 확인 |
| `remote origin already exists` | 이미 remote 등록됨 | `git remote remove origin` 후 재시도 |
| `Permission denied (publickey)` | SSH 키 미등록 | `gh auth login` 다시 수행하거나 HTTPS로 전환 |
| `RPC failed; HTTP 400 ... large file` | 100MB 초과 파일 포함 | `.gitignore` 점검, 필요 시 Git LFS |

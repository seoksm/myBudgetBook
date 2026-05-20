# Phase 1 — 개발환경 점검·설치 스크립트 사용 가이드

가계부 웹앱 개발을 위한 **프로젝트 로컬 격리** 환경 구축 스크립트입니다.
**MacBook Air (Apple Silicon) / macOS 26 Tahoe 또는 15 Sequoia** 기준.

## 핵심 컨셉

```
이미 시스템에 설치된 도구   →  그대로 사용 (재설치 안 함)
새로 설치할 도구            →  프로젝트의 tools/ 폴더에 다운로드
환경 활성화                  →  source activate-env.sh 한 줄
```

시스템 PATH/Homebrew 를 건드리지 않으므로 다른 프로젝트와 버전 충돌이 없습니다.

## 파일 3종

| 파일 | 용도 |
|---|---|
| `install-dev-env.sh` | 누락된 도구를 **`tools/` 에 다운로드** (단계마다 Y/n 확인) |
| `activate-env.sh` | 현재 셸에 `tools/` 도구를 **활성화** (PATH/JAVA_HOME 설정) — **`source` 로 실행** |
| `check-dev-env.sh` | 시스템 + `tools/` 환경을 **점검** (안전, 변경 없음) |

## 권장 사용 순서

### 1단계. 설치

```bash
cd ~/claude/budget_book_codex
bash install-dev-env.sh
```

각 단계에서 **Y/n** 으로 확인을 받습니다. 이미 시스템에 21+ Java나 24+ Node가 있다면 자동으로 건너뜁니다.

새로 다운로드하는 항목 (시스템 미설치 시에만):

| 도구 | 다운로드 위치 | 출처 | 용량 |
|---|---|---|---|
| **JDK 21 LTS** (Temurin) | `tools/jdk-21/` | Adoptium 공식 API | ~190MB |
| **Node.js 24 LTS** | `tools/node-24/` | nodejs.org 공식 | ~50MB |
| **Visual Studio Code** | `tools/Visual Studio Code.app/` | code.visualstudio.com | ~150MB |
| **(선택) DBeaver CE** | `tools/DBeaver.app/` | dbeaver.io | ~150MB |

총 디스크 사용량: **약 400~500MB** (모두 새로 받을 때 기준)

### 2단계. 환경 활성화

```bash
source activate-env.sh
```

현재 셸에 다음이 세팅됩니다:
- `JAVA_HOME` → `tools/jdk-21/Contents/Home`
- `PATH` 앞단에 → JDK + Node + Visual Studio Code 추가

> **⚠️ 중요:** `bash activate-env.sh` 는 안 됩니다. 반드시 **`source`** 또는 **`.`** 로 실행해야 현재 셸에 적용됩니다.

### 3단계. 점검

```bash
bash check-dev-env.sh
```

✓ / ! / ✗ 표시로 8개 섹션을 점검합니다.

- **✓ (초록)** — 통과
- **! (노랑)** — 경고 (있어도 진행 가능, 대부분 activate-env.sh 실행으로 해결)
- **✗ (빨강)** — 실패 (수정 필요)

마지막에 **수정 명령 모음**이 출력되니, 필요한 것만 골라 복사·실행하면 됩니다.

---

## 점검 항목 (8개 섹션)

| # | 항목 | 권장 |
|---|---|---|
| 1 | **시스템** | macOS 15+ / arm64 / 디스크 15GB+ / 메모리 8GB+ |
| 2 | **tools/ 폴더 구조** | tools/ 와 activate-env.sh 존재 |
| 3 | **Git** | 시스템 git + user.name/email |
| 4 | **Java 21** | tools/jdk-21 또는 시스템 Java 21 |
| 5 | **Node 24** | tools/node-24 또는 시스템 Node 24+ |
| 6 | **Visual Studio Code + 확장 11종** | tools/ 또는 /Applications/ |
| 7 | **포트** | 18080(Spring) / 15173(Vite) 사용 가능 |
| 8 | **DBeaver** | 선택 |

---

## 일상 워크플로우

새 터미널을 열 때마다:

```bash
cd ~/claude/budget_book_codex
source activate-env.sh
# ... 개발 ...
```

귀찮으면 `~/.zshrc` 에 함수 등록:

```bash
# ~/.zshrc 끝에 추가
bbc() { cd ~/claude/budget_book_codex && source activate-env.sh; }
```

이후 새 터미널에서 `bb` 한 번이면 진입+활성화 끝.

---

## 자주 만나는 문제

### "command not found: java" — activate-env.sh 안 했을 때
```bash
source activate-env.sh
```

### Visual Studio Code 가 "이 앱을 열 수 없습니다" 라고 나올 때 (Gatekeeper)
공식 zip을 다운로드한 경우 처음 한 번만 Gatekeeper가 막을 수 있습니다. install 스크립트는 자동으로 quarantine 속성을 제거하지만, 수동으로도 가능:
```bash
xattr -dr com.apple.quarantine "tools/Visual Studio Code.app"
```

### 포트 18080/15173 이미 사용 중
```bash
lsof -iTCP:18080 -sTCP:LISTEN     # 어떤 프로세스인지 확인
kill $(lsof -tiTCP:18080)          # 종료
```

### tools/ 를 통째로 삭제하고 재설치하고 싶을 때
```bash
rm -rf tools
bash install-dev-env.sh
```

### activate-env.sh 가 source 안 되면 (zsh/bash 혼용 시)
`activate-env.sh` 는 bash 문법이지만 zsh 에서도 source 됩니다. 만약 안 되면:
```bash
. ./activate-env.sh        # `source` 대신 점 표기
```

### 다른 프로젝트와 충돌
이 프로젝트는 `tools/` 안에 모든 걸 두므로 **다른 프로젝트와 자동 격리**됩니다. 시스템 PATH 는 건드리지 않습니다. activate-env.sh 를 source 한 셸에서만 적용되고, 새 터미널을 열면 원래 시스템 환경입니다.

### Git 이 없을 때
macOS Command Line Tools 가 보통 git 을 제공합니다:
```bash
xcode-select --install
```

---

## tools/ 폴더가 만들어 내는 격리 효과

```
일반 방식 (시스템 설치)              tools/ 격리 방식
────────────────────────             ──────────────────
~/Library/Java/.../JavaVM            budget_book_codex/tools/jdk-21/
~/.nvm/versions/node/v24/            budget_book_codex/tools/node-24/
/Applications/VSCode.app             budget_book_codex/tools/Visual Studio Code.app/

시스템 PATH 변경                     PATH 는 source 한 셸에서만 변경
다른 프로젝트도 영향                 다른 프로젝트 영향 없음
삭제하려면 여러 폴더                 폴더 통째 삭제로 끝
```

---

## 다음 단계

Phase 1 점검이 통과되면 **`가계부앱_개발계획.md` 의 Phase 2 (프로젝트 초기 셋업)** 으로 진행하세요. 보일러플레이트 자동 생성이 필요하면 알려주세요.

#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - 개발환경 일괄 설치 스크립트 (Phase 1) — 프로젝트 로컬 버전
#
# 대상   : MacBook Air (Apple Silicon) / macOS 26 Tahoe 또는 15 Sequoia
# 사용법 : bash install-dev-env.sh
#
# 철학:
#   - 이미 시스템에 설치된 도구는 그대로 사용 (재설치 안 함)
#   - 새로 설치할 도구는 모두 ./tools/ 폴더에 다운로드 (시스템 오염 X)
#   - 활성화는 'source activate-env.sh' 한 줄로
#
# 자동 설치 대상 (이미 없을 때만):
#   - JDK 21 LTS (Eclipse Temurin)      → tools/jdk-21/
#   - Node.js 24 LTS                     → tools/node-24/
#   - Visual Studio Code                 → tools/Visual Studio Code.app/
#   - Visual Studio Code 확장 12종       → 사용자 기본 위치 (~/.vscode/extensions/)
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

say()  { echo -e "${BOLD}${BLUE}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
skip() { echo -e "  ${YELLOW}↷${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${DIM}↳ $1${NC}"; }

ask() {
  read -r -p "$(echo -e "${BOLD}? $1 [Y/n] ${NC}")" REPLY
  REPLY=${REPLY:-Y}
  [[ "$REPLY" =~ ^[Yy]$ ]]
}

has() { command -v "$1" >/dev/null 2>&1; }

# 프로젝트 루트 및 tools 폴더
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"
mkdir -p "$TOOLS_DIR"

# 아키텍처 판정
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  arm64|aarch64) JDK_ARCH="aarch64"; NODE_ARCH="arm64"; VSCODE_ARCH="darwin-arm64";;
  x86_64)        JDK_ARCH="x64";     NODE_ARCH="x64";   VSCODE_ARCH="darwin";;
  *) err "지원하지 않는 아키텍처: $ARCH_RAW"; exit 1;;
esac

# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — 개발환경 일괄 설치 (프로젝트 로컬)                            ║${NC}"
echo -e "${BOLD}${BLUE}║  Java 21 + Node 24 + Visual Studio Code → tools/                          ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DIM}프로젝트 루트 : $PROJECT_DIR${NC}"
echo -e "${DIM}tools 폴더    : $TOOLS_DIR${NC}"
echo -e "${DIM}아키텍처      : $ARCH_RAW${NC}"
echo ""

if [ "$ARCH_RAW" != "arm64" ]; then
  echo -e "${YELLOW}경고: Apple Silicon이 아닙니다. 그래도 진행 가능하지만 다운로드 URL이 다를 수 있습니다.${NC}"
fi

if ! ask "설치를 시작할까요? (디스크 ~500MB 필요)"; then
  echo "취소되었습니다."
  exit 0
fi

# =============================================================================
say "1/6. Git (시스템 확인만)"

if has git; then
  ok "Git $(git --version | awk '{print $3}') — 시스템 사용"
  # Git 사용자 정보
  if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
    read -r -p "  Git user.name (예: 홍길동): " GIT_NAME
    [ -n "$GIT_NAME" ] && git config --global user.name "$GIT_NAME"
  fi
  if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    read -r -p "  Git user.email (예: you@example.com): " GIT_EMAIL
    [ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
  fi
else
  err "Git 미설치"
  info "macOS Command Line Tools를 설치하세요: xcode-select --install"
  info "또는: git을 별도 설치 후 다시 실행"
fi

# =============================================================================
say "2/6. Java 21 LTS (Eclipse Temurin)"

JDK_LOCAL_DIR="$TOOLS_DIR/jdk-21"
JDK_LOCAL_HOME="$JDK_LOCAL_DIR/Contents/Home"

# 시스템 Java 21 또는 project-local Java 21 이미 있는지 확인
JAVA_OK=false
if [ -x "$JDK_LOCAL_HOME/bin/java" ]; then
  ok "Java 21 이미 project-local 에 설치됨 ($JDK_LOCAL_DIR)"
  JAVA_OK=true
elif has java; then
  SYS_JAVA_VER=$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')
  if [ "$SYS_JAVA_VER" = "21" ]; then
    ok "Java 21 시스템에 이미 설치됨 — 그대로 사용"
    JAVA_OK=true
  else
    info "시스템에 Java $SYS_JAVA_VER 가 있지만 21 LTS 권장. tools/ 에 21을 추가 설치합니다."
  fi
fi

if [ "$JAVA_OK" = "false" ]; then
  if ask "Temurin 21 LTS 를 tools/jdk-21/ 에 다운로드 설치할까요?"; then
    TEMURIN_URL="https://api.adoptium.net/v3/binary/latest/21/ga/mac/${JDK_ARCH}/jdk/hotspot/normal/eclipse"
    TMP_TGZ="/tmp/temurin21-$$.tar.gz"
    info "다운로드: $TEMURIN_URL"
    curl -fSL --progress-bar -o "$TMP_TGZ" "$TEMURIN_URL"

    info "압축 해제 중..."
    rm -rf "$JDK_LOCAL_DIR"
    mkdir -p "$JDK_LOCAL_DIR"
    # tar 의 첫 디렉토리(jdk-21.x.y+z) 를 벗겨내고 jdk-21 로 직접 추출
    tar -xzf "$TMP_TGZ" -C "$JDK_LOCAL_DIR" --strip-components=1
    rm -f "$TMP_TGZ"

    if [ -x "$JDK_LOCAL_HOME/bin/java" ]; then
      ok "Java 21 설치 완료: $JDK_LOCAL_DIR"
      info "버전: $("$JDK_LOCAL_HOME/bin/java" -version 2>&1 | head -1)"
    else
      err "설치 실패 — $JDK_LOCAL_HOME/bin/java 없음"
    fi
  else
    skip "Java 21 설치 건너뜀"
  fi
fi

# =============================================================================
say "3/6. Node.js 24 LTS"

NODE_LOCAL_DIR="$TOOLS_DIR/node-24"

NODE_OK=false
if [ -x "$NODE_LOCAL_DIR/bin/node" ]; then
  ok "Node 24 이미 project-local 에 설치됨 ($NODE_LOCAL_DIR)"
  NODE_OK=true
elif has node; then
  SYS_NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$SYS_NODE_VER" -ge 24 ] 2>/dev/null; then
    ok "Node $(node -v) 시스템에 이미 설치됨 — 그대로 사용"
    NODE_OK=true
  else
    info "시스템 Node $(node -v) — 24 LTS 권장. tools/ 에 24를 추가 설치합니다."
  fi
fi

if [ "$NODE_OK" = "false" ]; then
  if ask "Node.js 24 LTS 를 tools/node-24/ 에 다운로드 설치할까요?"; then
    # 최신 24.x LTS 버전 조회
    info "최신 Node 24 버전 조회 중..."
    NODE_VER=$(curl -fsSL "https://nodejs.org/download/release/latest-v24.x/" 2>/dev/null \
               | grep -o 'node-v24\.[0-9]*\.[0-9]*' | head -1 | sed 's/node-//')
    if [ -z "$NODE_VER" ]; then
      err "Node.js 버전 조회 실패 — 네트워크 확인"
    else
      NODE_TARBALL="node-${NODE_VER}-darwin-${NODE_ARCH}.tar.gz"
      NODE_URL="https://nodejs.org/dist/${NODE_VER}/${NODE_TARBALL}"
      TMP_TGZ="/tmp/${NODE_TARBALL}"
      info "다운로드: $NODE_URL"
      curl -fSL --progress-bar -o "$TMP_TGZ" "$NODE_URL"

      info "압축 해제 중..."
      rm -rf "$NODE_LOCAL_DIR"
      mkdir -p "$NODE_LOCAL_DIR"
      tar -xzf "$TMP_TGZ" -C "$NODE_LOCAL_DIR" --strip-components=1
      rm -f "$TMP_TGZ"

      if [ -x "$NODE_LOCAL_DIR/bin/node" ]; then
        ok "Node $NODE_VER 설치 완료: $NODE_LOCAL_DIR"
      else
        err "설치 실패"
      fi
    fi
  else
    skip "Node 설치 건너뜀"
  fi
fi

# =============================================================================
say "4/6. Visual Studio Code"

VSCODE_LOCAL_APP="$TOOLS_DIR/Visual Studio Code.app"
VSCODE_LOCAL_CODE="$VSCODE_LOCAL_APP/Contents/Resources/app/bin/code"
VSCODE_SYSTEM_APP="/Applications/Visual Studio Code.app"

VSCODE_OK=false
if [ -x "$VSCODE_LOCAL_CODE" ]; then
  ok "Visual Studio Code 이미 project-local 에 설치됨"
  VSCODE_OK=true
elif [ -d "$VSCODE_SYSTEM_APP" ]; then
  ok "Visual Studio Code 시스템(/Applications)에 이미 설치됨 — 그대로 사용"
  VSCODE_OK=true
fi

if [ "$VSCODE_OK" = "false" ]; then
  if ask "Visual Studio Code 를 tools/ 에 다운로드 설치할까요?"; then
    VSCODE_URL="https://update.code.visualstudio.com/latest/${VSCODE_ARCH}/stable"
    TMP_ZIP="/tmp/vscode-$$.zip"
    info "다운로드: $VSCODE_URL"
    curl -fSL --progress-bar -o "$TMP_ZIP" "$VSCODE_URL"

    info "압축 해제 중..."
    rm -rf "$VSCODE_LOCAL_APP"
    # macOS 의 unzip 으로 풀면 'Visual Studio Code.app' 폴더가 생성됨
    unzip -q "$TMP_ZIP" -d "$TOOLS_DIR"
    rm -f "$TMP_ZIP"

    if [ -x "$VSCODE_LOCAL_CODE" ]; then
      ok "Visual Studio Code 설치 완료: $VSCODE_LOCAL_APP"
      # Gatekeeper quarantine 속성 제거 (안 하면 macOS가 차단)
      xattr -dr com.apple.quarantine "$VSCODE_LOCAL_APP" 2>/dev/null || true
      info "Finder 에서 더블클릭하거나 'open \"$VSCODE_LOCAL_APP\"' 로 실행"
    else
      err "설치 실패"
    fi
  else
    skip "Visual Studio Code 설치 건너뜀"
  fi
fi

# =============================================================================
say "5/6. Visual Studio Code 확장 일괄 설치"

# project-local code 가 있으면 그걸로, 없으면 시스템 code
if [ -x "$VSCODE_LOCAL_CODE" ]; then
  CODE_BIN="$VSCODE_LOCAL_CODE"
  info "사용: project-local code"
elif has code; then
  CODE_BIN="code"
  info "사용: 시스템 code"
else
  CODE_BIN=""
fi

if [ -n "$CODE_BIN" ]; then
  EXTS=(
    "vscjava.vscode-java-pack"
    "vmware.vscode-boot-dev-pack"
    "vscjava.vscode-gradle"
    "vscjava.vscode-lombok"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "dsznajder.es7-react-js-snippets"
    "bradlc.vscode-tailwindcss"
    "formulahendry.auto-rename-tag"
    "eamodio.gitlens"
    "humao.rest-client"
    "christian-kohler.path-intellisense"
  )

  if ask "Visual Studio Code 확장 ${#EXTS[@]}개를 일괄 설치할까요?"; then
    for ext in "${EXTS[@]}"; do
      echo "  설치 중: $ext"
      "$CODE_BIN" --install-extension "$ext" --force >/dev/null 2>&1 \
        && ok "$ext" || err "$ext 실패"
    done
  fi
else
  err "'code' 명령을 찾을 수 없어 확장 자동 설치를 건너뜁니다."
fi

# =============================================================================
say "6/6. (선택) DBeaver — 시스템 또는 tools/ 에 설치"

if [ -d "/Applications/DBeaver.app" ] || [ -d "$TOOLS_DIR/DBeaver.app" ]; then
  ok "DBeaver 이미 설치됨"
else
  if ask "DBeaver Community 를 tools/ 에 다운로드 설치할까요?"; then
    # 공식 매크OS arm64 DMG
    if [ "$JDK_ARCH" = "aarch64" ]; then
      DBEAVER_URL="https://dbeaver.io/files/dbeaver-ce-latest-macos-aarch64.dmg"
    else
      DBEAVER_URL="https://dbeaver.io/files/dbeaver-ce-latest-macos.dmg"
    fi
    TMP_DMG="/tmp/dbeaver-$$.dmg"
    info "다운로드: $DBEAVER_URL"
    curl -fSL --progress-bar -o "$TMP_DMG" "$DBEAVER_URL"

    info "DMG 마운트 후 .app 복사 중..."
    MOUNT_POINT=$(hdiutil attach -nobrowse "$TMP_DMG" | tail -1 | awk '{print $3}')
    if [ -d "$MOUNT_POINT/DBeaver.app" ]; then
      cp -R "$MOUNT_POINT/DBeaver.app" "$TOOLS_DIR/"
      hdiutil detach "$MOUNT_POINT" -quiet
      xattr -dr com.apple.quarantine "$TOOLS_DIR/DBeaver.app" 2>/dev/null || true
      ok "DBeaver 설치 완료: $TOOLS_DIR/DBeaver.app"
    else
      err "DMG 안에 DBeaver.app 을 찾을 수 없음"
      hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    fi
    rm -f "$TMP_DMG"
  else
    skip "DBeaver 건너뜀"
  fi
fi

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 1 설치 완료!                                                    ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}다음 단계${NC}"
echo ""
echo "  1) 프로젝트 환경 활성화 (현재 셸에서):"
echo -e "       ${BLUE}source activate-env.sh${NC}"
echo ""
echo "  2) 설치 결과 점검:"
echo -e "       ${BLUE}bash check-dev-env.sh${NC}"
echo ""
echo "  3) Visual Studio Code 실행:"
if [ -x "$VSCODE_LOCAL_CODE" ]; then
  echo -e "       ${BLUE}open \"$VSCODE_LOCAL_APP\"${NC}"
  echo "     또는 source activate-env.sh 후:"
  echo -e "       ${BLUE}code .${NC}"
elif has code; then
  echo -e "       ${BLUE}code .${NC}"
fi
echo ""
echo -e "${DIM}새 터미널을 열 때마다 'source activate-env.sh' 를 실행해야 합니다.${NC}"
echo -e "${DIM}자동화하려면 ~/.zshrc 에 'cd ~/claude/budget_book_codex && source activate-env.sh' 추가.${NC}"
echo ""

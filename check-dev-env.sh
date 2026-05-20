#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - 개발환경 자동 점검 스크립트 (Phase 1) — 프로젝트 로컬 인식
# 대상: MacBook Air (Apple Silicon) / macOS 26 Tahoe 또는 15 Sequoia
# 사용법: bash check-dev-env.sh
#
# 시스템 PATH 의 도구와 tools/ 폴더 안의 project-local 도구를
# 모두 인식합니다. (tools/ 가 우선 순위)
# =============================================================================

set +e

# ----- 색상 -----
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ----- 카운터 -----
PASS=0
FAIL=0
WARN=0
FIX_CMDS=()

# 프로젝트 루트
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"

# ----- 헬퍼 -----
print_header() {
  echo ""
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_section() {
  echo ""
  echo -e "${BOLD}${CYAN}[$1]${NC}"
}

ok()   { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗${NC} $1";   FAIL=$((FAIL+1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; WARN=$((WARN+1)); }
info() { echo -e "  ${DIM}↳ $1${NC}"; }

has() { command -v "$1" >/dev/null 2>&1; }
add_fix() { FIX_CMDS+=("$1"); }

# =============================================================================
print_header "🍎  가계부 웹앱 — 개발환경 점검 시작"
echo -e "  ${DIM}점검 시간   : $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ${DIM}프로젝트    : $PROJECT_DIR${NC}"
echo -e "  ${DIM}tools 폴더  : $TOOLS_DIR${NC}"

# =============================================================================
print_section "1. 시스템 (macOS / 아키텍처 / 자원)"

if has sw_vers; then
  MACOS_VER=$(sw_vers -productVersion)
  MACOS_MAJOR=${MACOS_VER%%.*}
  if [ "$MACOS_MAJOR" -ge 15 ]; then
    ok "macOS $MACOS_VER"
  else
    warn "macOS $MACOS_VER — 권장: 15(Sequoia) 또는 26(Tahoe) 이상"
  fi
else
  fail "macOS 환경이 아닙니다 (이 스크립트는 macOS 전용)"
fi

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  ok "Apple Silicon (arm64) — MacBook Air M1/M2/M3/M4"
elif [ "$ARCH" = "x86_64" ]; then
  warn "Intel Mac (x86_64) — Apple Silicon 권장. 그래도 진행 가능"
else
  warn "알 수 없는 아키텍처: $ARCH"
fi

if has df; then
  DISK_FREE_GB=$(df -g / 2>/dev/null | awk 'NR==2 {print $4}')
  if [ -n "$DISK_FREE_GB" ]; then
    if [ "$DISK_FREE_GB" -ge 15 ]; then
      ok "디스크 여유 ${DISK_FREE_GB}GB"
    else
      warn "디스크 여유 ${DISK_FREE_GB}GB — 최소 15GB 권장"
    fi
  fi
fi

MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
if [ -n "$MEM_BYTES" ]; then
  MEM_GB=$((MEM_BYTES / 1024 / 1024 / 1024))
  if [ "$MEM_GB" -ge 16 ]; then
    ok "메모리 ${MEM_GB}GB (쾌적)"
  elif [ "$MEM_GB" -ge 8 ]; then
    ok "메모리 ${MEM_GB}GB (개발 가능)"
  else
    warn "메모리 ${MEM_GB}GB — 8GB 이상 권장"
  fi
fi

# =============================================================================
print_section "2. tools/ 폴더 구조"

if [ -d "$TOOLS_DIR" ]; then
  ok "tools/ 폴더 존재"
  ls -1 "$TOOLS_DIR" 2>/dev/null | head -10 | while read -r item; do
    info "$item"
  done
else
  warn "tools/ 폴더 없음 — install-dev-env.sh 실행 시 자동 생성"
fi

# activate-env.sh 존재
if [ -f "$PROJECT_DIR/activate-env.sh" ]; then
  ok "activate-env.sh 존재"
else
  warn "activate-env.sh 없음"
fi

# =============================================================================
print_section "3. Git (시스템)"

if has git; then
  ok "Git $(git --version | awk '{print $3}')"
  GIT_NAME=$(git config --global user.name 2>/dev/null)
  GIT_EMAIL=$(git config --global user.email 2>/dev/null)
  if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    warn "git user.name / user.email 미설정"
    add_fix 'git config --global user.name "Your Name"'
    add_fix 'git config --global user.email "you@example.com"'
  else
    info "user: $GIT_NAME <$GIT_EMAIL>"
  fi
else
  fail "Git 미설치"
  add_fix "xcode-select --install   # macOS Command Line Tools 설치"
fi

# =============================================================================
print_section "4. Java 21 LTS"

JDK_LOCAL_HOME="$TOOLS_DIR/jdk-21/Contents/Home"
JDK_LOCAL_JAVA="$JDK_LOCAL_HOME/bin/java"

if [ -x "$JDK_LOCAL_JAVA" ]; then
  LOCAL_JAVA_VER=$("$JDK_LOCAL_JAVA" -version 2>&1 | head -1 | sed -E 's/.*"([0-9.]+).*/\1/')
  ok "Java $LOCAL_JAVA_VER (project-local: tools/jdk-21)"
  info "$($JDK_LOCAL_JAVA -version 2>&1 | head -1)"
elif has java; then
  SYS_JAVA_VER=$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')
  if [ "$SYS_JAVA_VER" = "21" ]; then
    ok "Java 21 (시스템) — $(java -version 2>&1 | head -1)"
  else
    warn "시스템 Java $SYS_JAVA_VER — 21 LTS 권장. tools/jdk-21 추가 설치 가능"
    add_fix "bash install-dev-env.sh   # Java 21을 tools/ 에 추가"
  fi
else
  fail "Java 미설치 (시스템/tools 모두)"
  add_fix "bash install-dev-env.sh   # Java 21을 tools/ 에 설치"
fi

# JAVA_HOME 환경변수 (activate-env.sh 가 source 되었는지 확인)
if [ -n "$JAVA_HOME" ]; then
  if [ -d "$JAVA_HOME" ]; then
    if [[ "$JAVA_HOME" == "$TOOLS_DIR"* ]]; then
      ok "JAVA_HOME → tools/ (project-local 활성화됨)"
    else
      ok "JAVA_HOME=$JAVA_HOME (시스템)"
    fi
  else
    fail "JAVA_HOME 경로 없음: $JAVA_HOME"
  fi
else
  warn "JAVA_HOME 미설정 — 'source activate-env.sh' 실행 필요"
  add_fix "source activate-env.sh"
fi

# =============================================================================
print_section "5. Node.js 24 LTS"

NODE_LOCAL_DIR="$TOOLS_DIR/node-24"
NODE_LOCAL_BIN="$NODE_LOCAL_DIR/bin/node"

if [ -x "$NODE_LOCAL_BIN" ]; then
  LOCAL_NODE_VER=$("$NODE_LOCAL_BIN" -v | sed 's/v//')
  ok "Node v$LOCAL_NODE_VER (project-local: tools/node-24)"
elif has node; then
  SYS_NODE_VER=$(node -v | sed 's/v//')
  SYS_NODE_MAJOR=${SYS_NODE_VER%%.*}
  if [ "$SYS_NODE_MAJOR" -ge 24 ]; then
    ok "Node v$SYS_NODE_VER (시스템)"
  elif [ "$SYS_NODE_MAJOR" -ge 22 ]; then
    warn "Node v$SYS_NODE_VER (시스템) — 권장: 24 LTS"
    add_fix "bash install-dev-env.sh   # Node 24를 tools/ 에 추가"
  else
    fail "Node v$SYS_NODE_VER — 너무 낮음, 24 LTS 필요"
    add_fix "bash install-dev-env.sh"
  fi
else
  fail "Node 미설치 (시스템/tools 모두)"
  add_fix "bash install-dev-env.sh   # Node 24를 tools/ 에 설치"
fi

# npm
if has npm; then
  ok "npm $(npm -v)"
else
  warn "npm 미발견 (Node 설치/activate-env.sh 확인)"
fi

# =============================================================================
print_section "6. Visual Studio Code + 필수 확장"

VSCODE_LOCAL_APP="$TOOLS_DIR/Visual Studio Code.app"
VSCODE_LOCAL_CODE="$VSCODE_LOCAL_APP/Contents/Resources/app/bin/code"
VSCODE_SYSTEM_APP="/Applications/Visual Studio Code.app"

CODE_BIN=""
if [ -x "$VSCODE_LOCAL_CODE" ]; then
  ok "Visual Studio Code (project-local: tools/Visual Studio Code.app)"
  CODE_BIN="$VSCODE_LOCAL_CODE"
elif [ -d "$VSCODE_SYSTEM_APP" ]; then
  ok "Visual Studio Code (시스템: /Applications)"
  if has code; then
    CODE_BIN="code"
  fi
elif has code; then
  ok "Visual Studio Code ('code' CLI 발견)"
  CODE_BIN="code"
else
  fail "Visual Studio Code 미설치 (시스템/tools 모두)"
  add_fix "bash install-dev-env.sh   # tools/ 에 설치"
fi

# 확장 점검
if [ -n "$CODE_BIN" ]; then
  INSTALLED_EXTS=$("$CODE_BIN" --list-extensions 2>/dev/null)

  REQUIRED_EXTS=(
    "vscjava.vscode-java-pack:Extension Pack for Java (백엔드 필수)"
    "vmware.vscode-boot-dev-pack:Spring Boot Extension Pack"
    "vscjava.vscode-gradle:Gradle for Java"
    "vscjava.vscode-lombok:Lombok Annotations Support"
    "dbaeumer.vscode-eslint:ESLint"
    "esbenp.prettier-vscode:Prettier"
    "dsznajder.es7-react-js-snippets:ES7+ React snippets"
    "bradlc.vscode-tailwindcss:Tailwind CSS IntelliSense"
    "formulahendry.auto-rename-tag:Auto Rename Tag"
    "eamodio.gitlens:GitLens"
    "humao.rest-client:REST Client"
  )

  MISSING_EXTS=()
  for entry in "${REQUIRED_EXTS[@]}"; do
    EXT_ID="${entry%%:*}"
    EXT_NAME="${entry#*:}"
    if echo "$INSTALLED_EXTS" | grep -qi "^${EXT_ID}$"; then
      ok "확장: $EXT_NAME"
    else
      fail "확장 누락: $EXT_NAME"
      MISSING_EXTS+=("$EXT_ID")
    fi
  done

  if [ ${#MISSING_EXTS[@]} -gt 0 ]; then
    add_fix "# 누락된 Visual Studio Code 확장 일괄 설치"
    for ext in "${MISSING_EXTS[@]}"; do
      add_fix "\"$CODE_BIN\" --install-extension $ext"
    done
  fi
fi

# =============================================================================
print_section "7. 포트 사용 가능 여부 (18080 / 15173)"

check_port() {
  local PORT=$1
  local DESC=$2
  if lsof -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then
    PID_INFO=$(lsof -iTCP:$PORT -sTCP:LISTEN -P -n | tail -1 | awk '{print $1" (PID "$2")"}')
    warn "포트 $PORT ($DESC) 이미 사용 중 — $PID_INFO"
    info "종료: kill \$(lsof -tiTCP:$PORT)"
  else
    ok "포트 $PORT ($DESC) 사용 가능"
  fi
}
check_port 18080 "Spring Boot"
check_port 15173 "Vite Dev Server"

# =============================================================================
print_section "8. (선택) DBeaver"

if [ -d "/Applications/DBeaver.app" ]; then
  ok "DBeaver (시스템)"
elif [ -d "$TOOLS_DIR/DBeaver.app" ]; then
  ok "DBeaver (project-local)"
else
  warn "DBeaver 미설치 (운영 DB 작업 시 권장, 필수 아님)"
fi

# =============================================================================
print_header "📊  점검 결과 요약"

TOTAL=$((PASS + FAIL + WARN))
echo ""
echo -e "  ${GREEN}✓ 통과   : ${PASS}${NC}"
echo -e "  ${YELLOW}! 경고   : ${WARN}${NC}"
echo -e "  ${RED}✗ 실패   : ${FAIL}${NC}"
echo -e "  ${DIM}  전체   : ${TOTAL}${NC}"

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
  echo ""
  echo -e "  ${BOLD}${GREEN}🎉  모든 항목 통과! Phase 2(프로젝트 셋업)로 진입할 수 있습니다.${NC}"
elif [ $FAIL -eq 0 ]; then
  echo ""
  echo -e "  ${BOLD}${YELLOW}⚠  필수 항목은 통과했지만 경고가 있습니다. 위 메시지 확인.${NC}"
  echo -e "  ${DIM}대부분 'source activate-env.sh' 한 줄로 해결됩니다.${NC}"
else
  echo ""
  echo -e "  ${BOLD}${RED}❌  실패한 필수 항목이 있습니다. 아래 명령을 실행하세요.${NC}"
fi

# =============================================================================
if [ ${#FIX_CMDS[@]} -gt 0 ]; then
  print_header "🛠   수정 명령 모음"
  echo ""
  for cmd in "${FIX_CMDS[@]}"; do
    if [[ "$cmd" == \#* ]]; then
      echo -e "${DIM}$cmd${NC}"
    else
      echo "$cmd"
    fi
  done
  echo ""
fi

echo ""
exit $FAIL

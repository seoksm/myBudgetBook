#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - 프로젝트 로컬 개발환경 활성화
#
# 사용법:
#   source activate-env.sh        ← 이 파일은 반드시 source 로 실행해야 합니다.
#                                   (bash activate-env.sh 는 효과가 없습니다)
#
# 동작:
#   tools/ 폴더 안의 JDK, Node, Visual Studio Code 를 현재 셸의
#   JAVA_HOME / PATH 에 우선 등록합니다. 시스템에 설치된 같은 이름의
#   도구가 있더라도 이 프로젝트에서는 tools/ 안의 것이 사용됩니다.
# =============================================================================

# source 로 실행되었는지 검사
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  echo "⚠  이 스크립트는 'source' 로 실행해야 합니다:"
  echo "     source activate-env.sh"
  exit 1
fi

# 프로젝트 루트 (이 스크립트가 있는 폴더)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"

# 색상
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_DIM='\033[2m'
_NC='\033[0m'

echo ""
echo -e "${_GREEN}▶ 가계부 프로젝트 환경 활성화${_NC}"
echo -e "${_DIM}  $PROJECT_DIR${_NC}"

# -----------------------------------------------------------------------------
# Java 21 (project-local 우선, 없으면 시스템)
# -----------------------------------------------------------------------------
if [ -d "$TOOLS_DIR/jdk-21/Contents/Home" ]; then
  export JAVA_HOME="$TOOLS_DIR/jdk-21/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo -e "  ${_GREEN}✓${_NC} Java 21 (project-local)"
elif command -v java >/dev/null 2>&1; then
  echo -e "  ${_YELLOW}!${_NC} Java (system) — tools/jdk-21 미설치, 시스템 Java 사용"
else
  echo -e "  ${_YELLOW}!${_NC} Java 미설치 — install-dev-env.sh 실행 필요"
fi

# -----------------------------------------------------------------------------
# Node 24 (project-local 우선)
# -----------------------------------------------------------------------------
if [ -d "$TOOLS_DIR/node-24/bin" ]; then
  export PATH="$TOOLS_DIR/node-24/bin:$PATH"
  echo -e "  ${_GREEN}✓${_NC} Node 24 (project-local)"
elif command -v node >/dev/null 2>&1; then
  echo -e "  ${_YELLOW}!${_NC} Node (system) — tools/node-24 미설치, 시스템 Node 사용"
else
  echo -e "  ${_YELLOW}!${_NC} Node 미설치 — install-dev-env.sh 실행 필요"
fi

# -----------------------------------------------------------------------------
# Visual Studio Code CLI (project-local 우선)
# -----------------------------------------------------------------------------
VSCODE_LOCAL_BIN="$TOOLS_DIR/Visual Studio Code.app/Contents/Resources/app/bin"
if [ -x "$VSCODE_LOCAL_BIN/code" ]; then
  export PATH="$VSCODE_LOCAL_BIN:$PATH"
  echo -e "  ${_GREEN}✓${_NC} Visual Studio Code (project-local)"
elif command -v code >/dev/null 2>&1; then
  echo -e "  ${_YELLOW}!${_NC} Visual Studio Code (system) 사용"
fi

# -----------------------------------------------------------------------------
# 현재 활성 버전 출력
# -----------------------------------------------------------------------------
echo ""
echo -e "${_DIM}활성 버전:${_NC}"
if command -v java >/dev/null 2>&1; then
  echo "  $(java -version 2>&1 | head -1)"
fi
if command -v node >/dev/null 2>&1; then
  echo "  Node $(node -v)    npm $(npm -v)"
fi
echo ""
echo -e "${_DIM}프로젝트 디렉토리를 떠나면 'unset JAVA_HOME' 또는 새 셸을 열어 비활성화.${_NC}"
echo ""

#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 — 프로젝트 폴더 정리
#
# 사용법: bash cleanup.sh
#
# 처리:
#   1) 백업 파일(.bak*) 제거
#   2) 빌드 산출물(frontend/dist, backend/build) 제거
#   3) Phase1~8 가이드를 docs/ 폴더로 이동
#
# 보존(절대 삭제 안 함):
#   - backend/data/         H2 DB (실제 거래 데이터)
#   - tools/                Java/Node/VSCode 격리 환경
#   - frontend/node_modules npm 패키지
#   - frontend/src/         소스 코드
#   - backend/src/          소스 코드
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

say()  { echo -e "${BOLD}${BLUE}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
skip() { echo -e "  ${YELLOW}↷${NC} $1"; }
info() { echo -e "  ${DIM}↳ $1${NC}"; }

cd "$(dirname "${BASH_SOURCE[0]}")"
PROJECT_DIR="$(pwd)"

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — 폴더 정리                                       ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${DIM}프로젝트: $PROJECT_DIR${NC}"
echo ""

# ─── 1. 정리 전 디스크 사용량 ──────────────────────────────────────────
say "1/4. 정리 전 디스크 사용량"
TOTAL_BEFORE=$(du -sh "$PROJECT_DIR" 2>/dev/null | awk '{print $1}')
info "전체 폴더 크기: $TOTAL_BEFORE"
du -sh frontend/dist backend/build 2>/dev/null | while read line; do info "$line"; done
echo

# ─── 2. 백업 파일 제거 ─────────────────────────────────────────────────
say "2/4. 백업 파일 제거"
shopt -s nullglob
BAK_FILES=( setup-phase*.sh.bak* backend/build.gradle.bak* )
if [ ${#BAK_FILES[@]} -eq 0 ]; then
  skip "백업 파일 없음"
else
  for f in "${BAK_FILES[@]}"; do
    [ -e "$f" ] && rm -f "$f" && ok "삭제: $f"
  done
fi
echo

# ─── 3. 빌드 산출물 제거 ───────────────────────────────────────────────
say "3/4. 빌드 산출물 제거 (재실행 시 자동 재생성됨)"
if [ -d frontend/dist ]; then
  rm -rf frontend/dist
  ok "삭제: frontend/dist"
else
  skip "frontend/dist 없음"
fi
if [ -d backend/build ]; then
  rm -rf backend/build
  ok "삭제: backend/build"
else
  skip "backend/build 없음"
fi
if [ -d frontend/.vite ]; then
  rm -rf frontend/.vite
  ok "삭제: frontend/.vite (Vite 캐시)"
fi
echo

# ─── 4. Phase 가이드를 docs/ 폴더로 이동 ───────────────────────────────
say "4/4. Phase 가이드를 docs/ 폴더로 정리"
mkdir -p docs
moved=0
for f in Phase*-사용가이드.md; do
  if [ -f "$f" ]; then
    mv "$f" docs/
    ok "이동: $f → docs/"
    moved=$((moved+1))
  fi
done
if [ $moved -eq 0 ]; then
  skip "이동할 Phase 가이드 없음 (이미 정리됨)"
fi

# 개발계획서도 docs/로 이동
if [ -f "가계부앱_개발계획.md" ]; then
  mv "가계부앱_개발계획.md" docs/
  ok "이동: 가계부앱_개발계획.md → docs/"
fi
echo

# ─── 결과 요약 ─────────────────────────────────────────────────────────
TOTAL_AFTER=$(du -sh "$PROJECT_DIR" 2>/dev/null | awk '{print $1}')
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  ✓ 정리 완료                                                   ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}디스크 사용량:${NC}"
echo "   정리 전: $TOTAL_BEFORE"
echo "   정리 후: $TOTAL_AFTER"
echo ""
echo -e "${BOLD}최종 폴더 구조:${NC}"
ls -F | head -30
echo ""
echo -e "${DIM}* tools/, backend/data/, frontend/node_modules/, backend/src/, frontend/src/ 는 보존됨${NC}"
echo -e "${DIM}* 빌드는 'npm run dev' 또는 './gradlew bootRun' 으로 다시 자동 생성${NC}"

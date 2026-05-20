#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - Phase 8 PWA 설치 가능한 웹앱 만들기
#
# 사용법:
#   source activate-env.sh           ← Phase 1 환경 활성화
#   bash setup-phase8-pwa.sh          ← Phase 8 실행 (Phase 6 완료 후)
#
# 생성/수정:
#   - npm install vite-plugin-pwa workbox-window
#   - public/budget-icon.svg          (앱 아이콘 SVG, 1024x1024)
#   - vite.config.ts                  (PWA 플러그인 추가)
#   - index.html                       (manifest 메타, 테마 색상)
#   - src/hooks/usePwaInstall.ts      (설치 프롬프트 훅)
#   - src/components/InstallBanner.tsx (설치 안내 배너)
#   - src/App.tsx                     (배너 표시)
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

say()  { echo -e "${BOLD}${BLUE}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${DIM}↳ $1${NC}"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FE="$PROJECT_DIR/frontend"
SRC="$FE/src"

# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — Phase 8 PWA (Progressive Web App)                            ║${NC}"
echo -e "${BOLD}${BLUE}║  홈 화면 설치 + 오프라인 캐시 + 앱 아이콘                                   ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -d "$SRC/routes" ]; then
  err "Phase 6 (프론트엔드) 가 완료되어야 합니다."
  exit 1
fi

# =============================================================================
say "1/5. vite-plugin-pwa 패키지 설치"
# =============================================================================

cd "$FE"
info "vite-plugin-pwa + workbox-window 설치 중..."
npm install -D vite-plugin-pwa
npm install workbox-window
ok "PWA 의존성 설치 완료"

# =============================================================================
say "2/5. 앱 아이콘 SVG 생성 (PWA 매니페스트가 자동 PNG 변환)"
# =============================================================================

mkdir -p "$FE/public"

# 가계부 SVG 아이콘 (지갑/돈 형상, 1024×1024)
cat > "$FE/public/budget-icon.svg" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" fill="none">
  <!-- 배경 그라데이션 -->
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0ea5e9"/>
      <stop offset="100%" stop-color="#06b6d4"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" rx="224" fill="url(#bg)"/>

  <!-- 지갑 본체 -->
  <rect x="232" y="320" width="560" height="400" rx="48"
        fill="white" stroke="white" stroke-width="0"/>

  <!-- 지갑 상단 (덮개) -->
  <path d="M232 320 Q232 240 312 240 L712 240 Q792 240 792 320 L792 380 L232 380 Z"
        fill="#0284c7"/>

  <!-- 동전 슬롯 -->
  <circle cx="704" cy="520" r="48" fill="#0ea5e9"/>
  <circle cx="704" cy="520" r="24" fill="#0284c7"/>

  <!-- 화폐 기호 ₩ -->
  <text x="380" y="600" font-family="system-ui, -apple-system, sans-serif"
        font-weight="900" font-size="240" fill="#0284c7">₩</text>
</svg>
EOF
ok "public/budget-icon.svg (앱 아이콘, 1024×1024)"

# favicon.svg 도 같은 아이콘 (브라우저 탭)
cp "$FE/public/budget-icon.svg" "$FE/public/favicon.svg"
ok "public/favicon.svg (브라우저 탭 아이콘)"

# =============================================================================
say "3/5. vite.config.ts 갱신 (PWA 플러그인 추가)"
# =============================================================================

cat > "$FE/vite.config.ts" <<'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { VitePWA } from 'vite-plugin-pwa';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'budget-icon.svg'],
      manifest: {
        name: 'MyBudgetBook 가계부',
        short_name: '가계부',
        description: '반응형 웹 가계부 - 수입·지출·예산·SMS 자동입력',
        theme_color: '#0ea5e9',
        background_color: '#f8fafc',
        display: 'standalone',
        orientation: 'portrait',
        scope: '/',
        start_url: '/',
        lang: 'ko-KR',
        icons: [
          {
            src: 'budget-icon.svg',
            sizes: '192x192 512x512 1024x1024',
            type: 'image/svg+xml',
            purpose: 'any maskable',
          },
        ],
        categories: ['finance', 'productivity'],
      },
      workbox: {
        // 정적 자산은 캐시 우선, API 호출은 네트워크 우선
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/cdn\.jsdelivr\.net\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'cdn-cache',
              expiration: { maxEntries: 50, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
          {
            urlPattern: /\/api\/.*/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'api-cache',
              networkTimeoutSeconds: 5,
              expiration: { maxEntries: 100, maxAgeSeconds: 60 * 60 },
              cacheableResponse: { statuses: [0, 200] },
            },
          },
        ],
      },
      devOptions: {
        enabled: true, // dev 모드(15173)에서도 PWA 동작 — API 프록시까지 한 번에 가능
        type: 'module',
        navigateFallback: 'index.html',
      },
    }),
  ],
  // npm run preview (port 14173) — 프록시 필요
  preview: {
    port: 14173,
    proxy: {
      '/api': {
        target: 'http://localhost:18080',
        changeOrigin: true,
      },
    },
  },
  server: {
    port: 15173,
    proxy: {
      '/api': {
        target: 'http://localhost:18080',
        changeOrigin: true,
      },
    },
  },
});
EOF
ok "vite.config.ts (PWA 플러그인 추가)"

# =============================================================================
say "4/5. index.html 갱신 (메타 태그 + 테마 색상)"
# =============================================================================

cat > "$FE/index.html" <<'EOF'
<!doctype html>
<html lang="ko">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />
    <meta name="theme-color" content="#0ea5e9" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="default" />
    <meta name="apple-mobile-web-app-title" content="가계부" />
    <link rel="apple-touch-icon" href="/budget-icon.svg" />
    <title>MyBudgetBook 가계부</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
ok "index.html (PWA 메타 + iOS 홈 화면 추가 지원)"

# =============================================================================
say "5/5. 설치 프롬프트 훅 + 배너 컴포넌트"
# =============================================================================

mkdir -p "$SRC/hooks"

# ─── usePwaInstall 훅 ──────────────────────────────────────────────────
cat > "$SRC/hooks/usePwaInstall.ts" <<'EOF'
import { useEffect, useState } from 'react';

/**
 * PWA 설치 가능 여부 + 설치 트리거 훅.
 *
 * - 데스크톱 Chrome/Edge: `beforeinstallprompt` 이벤트로 설치 가능
 * - iOS Safari: 자동 프롬프트 불가 → "공유 → 홈 화면에 추가" 안내
 */
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export function usePwaInstall() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstalled, setIsInstalled] = useState(false);
  const [isIos, setIsIos] = useState(false);

  useEffect(() => {
    // iOS 감지
    const ua = window.navigator.userAgent;
    const ios = /iPhone|iPad|iPod/.test(ua);
    setIsIos(ios);

    // 이미 standalone 모드면 설치 완료된 상태
    const standalone = window.matchMedia('(display-mode: standalone)').matches
      || (window.navigator as unknown as { standalone?: boolean }).standalone === true;
    setIsInstalled(standalone);

    // beforeinstallprompt 캐치
    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', handler);

    // appinstalled 이벤트
    const installedHandler = () => setIsInstalled(true);
    window.addEventListener('appinstalled', installedHandler);

    return () => {
      window.removeEventListener('beforeinstallprompt', handler);
      window.removeEventListener('appinstalled', installedHandler);
    };
  }, []);

  const promptInstall = async (): Promise<boolean> => {
    if (!deferredPrompt) return false;
    await deferredPrompt.prompt();
    const choice = await deferredPrompt.userChoice;
    setDeferredPrompt(null);
    return choice.outcome === 'accepted';
  };

  return {
    canInstall: !!deferredPrompt,
    isInstalled,
    isIos,
    promptInstall,
  };
}
EOF
ok "hooks/usePwaInstall.ts"

# ─── InstallBanner 컴포넌트 ────────────────────────────────────────────
mkdir -p "$SRC/components"
cat > "$SRC/components/InstallBanner.tsx" <<'EOF'
import { useState, useEffect } from 'react';
import { Download, Share, Plus, X } from 'lucide-react';
import { usePwaInstall } from '../hooks/usePwaInstall';

const DISMISS_KEY = 'budget-install-dismissed';

export function InstallBanner() {
  const { canInstall, isInstalled, isIos, promptInstall } = usePwaInstall();
  const [dismissed, setDismissed] = useState(true);

  useEffect(() => {
    setDismissed(localStorage.getItem(DISMISS_KEY) === '1');
  }, []);

  const dismiss = () => {
    localStorage.setItem(DISMISS_KEY, '1');
    setDismissed(true);
  };

  if (isInstalled || dismissed) return null;
  if (!canInstall && !isIos) return null;

  return (
    <div className="fixed bottom-20 md:bottom-4 left-3 right-3 md:left-auto md:right-4 md:w-80 z-40
                    bg-sky-600 text-white rounded-2xl shadow-xl p-4
                    animate-in slide-in-from-bottom duration-300">
      <button
        onClick={dismiss}
        className="absolute top-2 right-2 p-1 rounded hover:bg-white/20"
        aria-label="닫기"
      >
        <X size={16} />
      </button>

      <div className="flex items-start gap-3 pr-4">
        <Download size={28} className="flex-shrink-0 mt-1" />
        <div className="flex-1">
          <div className="font-bold">앱으로 설치하기</div>
          <div className="text-sm text-sky-100 mt-1">
            홈 화면에 추가하면 빠른 실행 + 오프라인 사용 가능
          </div>

          {canInstall ? (
            <button
              onClick={async () => { if (await promptInstall()) dismiss(); }}
              className="mt-3 bg-white text-sky-600 font-semibold px-4 py-1.5 rounded-lg text-sm"
            >
              설치
            </button>
          ) : isIos ? (
            <div className="text-xs text-sky-100 mt-2 flex items-center gap-1 flex-wrap">
              하단 <Share size={14} className="inline" /> 공유 →
              <Plus size={14} className="inline" /> 홈 화면에 추가
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}
EOF
ok "components/InstallBanner.tsx"

# ─── App.tsx 에 배너 삽입 ──────────────────────────────────────────────
APP_TSX="$SRC/App.tsx"
if ! grep -q "InstallBanner" "$APP_TSX"; then
  # AppLayout import 다음 줄에 InstallBanner import 추가
  awk '
    /from '"'"'\.\/components\/AppLayout'"'"'/ {
      print
      print "import { InstallBanner } from '"'"'./components/InstallBanner'"'"';"
      next
    }
    /^      <BrowserRouter>/ {
      print "      <InstallBanner />"
      print
      next
    }
    { print }
  ' "$APP_TSX" > "${APP_TSX}.tmp" && mv "${APP_TSX}.tmp" "$APP_TSX"
  ok "App.tsx 에 <InstallBanner /> 삽입"
else
  info "App.tsx 에 InstallBanner 이미 있음"
fi

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 8 PWA 설정 완료!                                                 ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}생성/수정 파일${NC}"
echo "  • public/budget-icon.svg, favicon.svg"
echo "  • vite.config.ts (VitePWA 플러그인)"
echo "  • index.html (theme-color, apple meta)"
echo "  • src/hooks/usePwaInstall.ts"
echo "  • src/components/InstallBanner.tsx"
echo "  • src/App.tsx (배너 삽입)"
echo ""
echo -e "${BOLD}동작 확인 방법${NC}"
echo ""
echo "  1) ${BOLD}프로덕션 빌드로 PWA 테스트${NC} (개발 모드는 SW 비활성)"
echo -e "       ${BLUE}cd frontend && npm run build && npm run preview${NC}"
echo "       → http://localhost:14173 열기"
echo ""
echo "  2) ${BOLD}데스크톱 Chrome${NC}"
echo "       주소창 우측의 ⊕ 설치 아이콘 → '설치'"
echo "       또는 화면 하단의 푸른 '앱으로 설치하기' 배너"
echo ""
echo "  3) ${BOLD}모바일 (iOS Safari)${NC}"
echo "       하단 ${BOLD}공유${NC} 버튼 → '홈 화면에 추가'"
echo "       앱 아이콘이 추가되어 풀스크린 앱처럼 실행됨"
echo ""
echo "  4) ${BOLD}모바일 (Android Chrome)${NC}"
echo "       자동 설치 프롬프트 또는 메뉴 → '앱 설치'"
echo ""
echo -e "${DIM}개발 모드에선 SW 비활성. 'npm run build' 후 'npm run preview' 로 테스트.${NC}"
echo ""

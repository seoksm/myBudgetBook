# Phase 8 — PWA (홈 화면 설치 + 오프라인) 사용 가이드

가계부를 진짜 "앱처럼" 만들어 주는 마지막 단계입니다. 사용자가 브라우저에서 한 번만 "홈 화면에 추가"하면, 그 다음부터는 풀스크린 앱처럼 실행됩니다.

## 한 줄 요약

```bash
cd ~/claude/budget_book_codex
source activate-env.sh
bash setup-phase8-pwa.sh

cd frontend
npm run dev
# → http://localhost:15173
```

## 사전 조건

| 조건 | 확인 |
|---|---|
| Phase 6 완료 (frontend 존재) | `ls frontend/src/App.tsx` |
| 환경 활성화 | `source activate-env.sh` |

## 생성/수정되는 것

### 신규 파일

| 파일 | 역할 |
|---|---|
| `public/budget-icon.svg` | 앱 아이콘 (1024×1024 SVG, 지갑 + ₩ 마크) |
| `public/favicon.svg` | 브라우저 탭 아이콘 (동일 SVG) |
| `src/hooks/usePwaInstall.ts` | 설치 가능 여부 + 트리거 훅 (`beforeinstallprompt` 활용) |
| `src/components/InstallBanner.tsx` | 설치 유도, 새 버전 적용, 오프라인 준비 배너 |
| `src/pwa/cleanupLegacyPwaCaches.ts` | 이전 설정에서 남은 `api-cache` 정리 |

### 수정 파일

| 파일 | 내용 |
|---|---|
| `vite.config.ts` | `VitePWA()` 플러그인 추가, 매니페스트 + 캐시 전략 |
| `index.html` | `<meta name="theme-color">`, iOS apple-touch-icon |
| `src/App.tsx` | `<InstallBanner />` 컴포넌트 삽입 |
| `package.json` | `vite-plugin-pwa` (devDep), `workbox-window` (dep) |

## PWA 가 주는 4가지 효과

1. **홈 화면 설치** — iOS/Android/Chrome OS 등 모든 플랫폼
2. **풀스크린 실행** — 브라우저 주소창 없이 네이티브 앱처럼
3. **오프라인 앱 셸 캐시** — 정적 자산과 앱 화면 캐시
4. **앱 아이콘** — 작업 표시줄 / 도크 / Spotlight 검색 노출

## 캐시 전략 (vite.config.ts)

| 경로 | 전략 | 의미 |
|---|---|---|
| CDN (cdn.jsdelivr.net) | **CacheFirst** | 캐시 우선 (Pretendard 폰트) |
| 자체 정적 자산 | **PrecacheAndRoute** (기본) | 빌드시 모두 precache |
| `/api/*` | **캐시 제외** | 인증/저장 요청 안정성을 위해 Service Worker가 가로채지 않음 |

오프라인 상태에서는 앱 화면 자체와 정적 리소스는 열릴 수 있습니다. 거래 조회/저장 같은 API 기능은 백엔드 연결이 필요합니다.

## 설치 방법별 안내

### 데스크톱 (Chrome / Edge)

1. `npm run dev` 로 띄움
2. http://localhost:15173 접속
3. 주소창 우측의 **⊕ 설치** 아이콘 클릭
4. 또는 화면 하단의 푸른 "**앱으로 설치하기**" 배너의 "설치" 버튼

### Android (Chrome)

1. 모바일 Chrome 으로 사이트 접속
2. 자동으로 "앱 설치" 프롬프트 표시 (또는 메뉴 → "앱 설치")
3. 홈 화면에 아이콘 생성됨

### iOS (Safari) — 자동 프롬프트 불가

1. 하단 **공유** 버튼 (네모+위쪽 화살표)
2. 메뉴에서 "**홈 화면에 추가**" 선택
3. 확인 → 홈 화면에 아이콘

설치 후 그 아이콘으로 실행하면 풀스크린 모드.

> iOS Safari 의 PWA 는 자동 설치 프롬프트를 지원하지 않으므로 `InstallBanner.tsx` 가 iOS 감지 시 "공유 → 홈 화면에 추가" 안내 텍스트를 보여줍니다.

## 디버깅

### Chrome DevTools → Application 탭

- **Manifest** — 매니페스트가 잘 로드됐는지 확인
- **Service Workers** — `sw.js` 가 activated 상태인지
- **Cache Storage** — `workbox-precache-v2-...`, `cdn-cache` 가 보여야 함. `api-cache`는 만들지 않음
- **Lighthouse** 탭 → PWA 점수 측정 (점수 90+ 가 목표)

### Service Worker 가 안 잡힐 때

```bash
# 1. dev 모드에서도 15173에서 PWA가 동작
cd frontend
npm run dev

# 2. 배포 빌드 기준으로도 같은 15173에서 확인 가능
cd frontend
npm run build && npm run preview

# 3. 그래도 안되면 캐시 클리어
# Chrome DevTools → Application → Clear storage → "Clear site data"
```

## 앱 업데이트 흐름

빌드가 바뀌면 앱 화면 하단에 "새 버전이 준비됐습니다" 배너가 표시됩니다.

1. `지금 적용` 클릭
2. 대기 중인 Service Worker가 활성화됨
3. 새 앱 번들이 로드됨

이 흐름을 사용하면 오래된 PWA 캐시 때문에 화면이 꼬이는 일을 줄일 수 있습니다.

### 매니페스트 검증

```bash
curl http://localhost:15173/manifest.webmanifest | jq
```

## 아이콘 변경

`public/budget-icon.svg` 를 원하는 SVG 로 덮어쓰면 됩니다. 권장 사양:

- viewBox `0 0 1024 1024`
- 둥근 모서리는 SVG 내부에서 처리 (iOS 가 또 라운드 마스크 적용)
- 단색/단순한 디자인이 작은 사이즈에서 잘 보임

PNG 가 필요한 환경(구형 안드로이드 등)에선 [maskable.app](https://maskable.app/) 으로 SVG → 다양한 사이즈 PNG 변환 후 매니페스트의 `icons` 배열에 추가.

## 배포 시 주의사항

**프로덕션 배포 (Phase 9 — 진행 예정)** 시 HTTPS 필수입니다. PWA 는 HTTP 에서는 service worker 가 등록되지 않습니다 (localhost 는 예외).

| 호스팅 | HTTPS | 추천도 |
|---|---|---|
| Railway | 자동 ✓ | ★★★ |
| Render | 자동 ✓ | ★★★ |
| Fly.io | 자동 ✓ | ★★ |
| 자체 서버 + Let's Encrypt | 수동 설정 | ★ |
| Cloudflare Pages (프론트만) | 자동 ✓ | ★★★ (백엔드는 별도) |

## 완료 현황

| Phase | 상태 |
|---|---|
| 1. 개발환경 | ✓ |
| 2. 보일러플레이트 | ✓ |
| 4. 도메인 + 시드 | ✓ |
| 5. REST API + Swagger | ✓ |
| 6. 프론트엔드 화면 | ✓ |
| 7. SMS 파서 | ✓ |
| **8. PWA 설치** | **✓ 신규** |
| 9. 마감 (git/README/배포) | 다음 |

## 다음 단계

마지막 단계인 **마감/배포** 가 남았습니다:

- git 정리 (의미 있는 커밋 분리, .gitignore 점검)
- README.md 작성 (스크린샷, 실행 방법, 기능 목록)
- 배포 옵션 비교 + Railway 자동 배포 스크립트

`마감해줘` 또는 `Phase 9 시작해줘` 로 진행하세요.

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
      registerType: 'prompt',
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
        cleanupOutdatedCaches: true,
        clientsClaim: true,
        navigateFallbackDenylist: [/^\/api\//, /^\/h2-console/],
        // API는 인증/쓰기 요청이 섞여 있으므로 Service Worker가 가로채지 않는다.
        // 정적 앱 셸과 CDN 리소스만 캐시해 PWA 설치성과 API 안정성을 분리한다.
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/cdn\.jsdelivr\.net\/.*/i,
            handler: 'CacheFirst',
            options: {
              cacheName: 'cdn-cache',
              expiration: { maxEntries: 50, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
        ],
      },
      devOptions: {
        enabled: true, // 15173 개발 서버에서도 PWA 설치 흐름을 확인한다.
        type: 'module',
        navigateFallback: 'index.html',
      },
    }),
  ],
  server: {
    port: 15173,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://localhost:18080',
        changeOrigin: true,
      },
    },
  },
  // npm run dev / npm run preview 모두 15173으로 통합
  preview: {
    port: 15173,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://localhost:18080',
        changeOrigin: true,
      },
    },
  },
});

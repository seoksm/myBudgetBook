#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - Phase 2 프로젝트 보일러플레이트 자동 생성
#
# 사용법:
#   source activate-env.sh      ← 먼저 Phase 1 환경 활성화
#   bash setup-project.sh        ← 그 다음 실행
#
# 동작:
#   1) Spring Initializr API 로 backend/ 생성
#   2) 우리 표준 폴더 구조 + HelloController + CORS 설정 주입
#   3) Vite + React + TS 로 frontend/ 생성
#   4) 필수 라이브러리 + Tailwind v4 설치
#   5) Vite proxy 설정 + App.tsx 에 Hello API 호출 코드 삽입
#   6) .vscode/ 워크스페이스 설정 (compound 디버깅)
#   7) 루트 git init + .gitignore
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

# 프로젝트 루트
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — Phase 2 프로젝트 보일러플레이트 자동 생성                   ║${NC}"
echo -e "${BOLD}${BLUE}║  Spring Boot 3.5 + React 19 + Vite + Tailwind v4                          ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${DIM}프로젝트 루트: $PROJECT_DIR${NC}"
echo ""

# =============================================================================
# 사전 점검
# =============================================================================
say "사전 점검 — 환경 활성화 확인"

if ! has java; then
  err "java 명령을 찾을 수 없습니다."
  info "먼저 'source activate-env.sh' 를 실행하세요."
  exit 1
fi
ok "Java: $(java -version 2>&1 | head -1)"

if ! has node; then
  err "node 명령을 찾을 수 없습니다."
  info "먼저 'source activate-env.sh' 를 실행하세요."
  exit 1
fi
ok "Node: $(node -v)    npm: $(npm -v)"

if ! has curl; then
  err "curl 이 필요합니다."
  exit 1
fi

echo ""
if ! ask "계속 진행할까요?"; then
  echo "취소되었습니다."
  exit 0
fi

# =============================================================================
say "1/7. Spring Boot 백엔드 생성 (Spring Initializr API)"
# =============================================================================

if [ -d "$PROJECT_DIR/backend" ]; then
  if ask "backend/ 폴더가 이미 있습니다. 삭제하고 다시 생성할까요?"; then
    rm -rf "$PROJECT_DIR/backend"
  else
    skip "백엔드 생성 건너뜀"
    SKIP_BACKEND=true
  fi
fi

if [ -z "${SKIP_BACKEND:-}" ]; then
  TMP_ZIP="/tmp/spring-starter-$$.zip"
  info "Spring Initializr 에서 starter zip 다운로드..."
  curl -fSL --progress-bar \
    -G "https://start.spring.io/starter.zip" \
    --data-urlencode "type=gradle-project" \
    --data-urlencode "language=java" \
    --data-urlencode "bootVersion=3.5.0" \
    --data-urlencode "baseDir=backend" \
    --data-urlencode "groupId=com.mybudget" \
    --data-urlencode "artifactId=backend" \
    --data-urlencode "name=backend" \
    --data-urlencode "description=MyBudgetBook backend (Spring Boot)" \
    --data-urlencode "packageName=com.mybudget.backend" \
    --data-urlencode "packaging=jar" \
    --data-urlencode "javaVersion=21" \
    --data-urlencode "dependencies=web,data-jpa,h2,mysql,lombok,validation,devtools,actuator" \
    -o "$TMP_ZIP"

  info "압축 해제..."
  unzip -q "$TMP_ZIP" -d "$PROJECT_DIR"
  rm -f "$TMP_ZIP"
  ok "backend/ 생성 완료"
fi

# =============================================================================
say "2/7. 백엔드 커스터마이징 — 폴더 구조 + Hello API + CORS"
# =============================================================================

BE_PKG_DIR="$PROJECT_DIR/backend/src/main/java/com/mybudget/backend"

if [ -d "$BE_PKG_DIR" ]; then
  mkdir -p "$BE_PKG_DIR/controller" \
           "$BE_PKG_DIR/service" \
           "$BE_PKG_DIR/repository" \
           "$BE_PKG_DIR/domain" \
           "$BE_PKG_DIR/dto" \
           "$BE_PKG_DIR/config" \
           "$BE_PKG_DIR/exception" \
           "$BE_PKG_DIR/util"
  ok "표준 폴더 8종 생성 (controller/service/repository/domain/dto/config/exception/util)"

  # ─── HelloController.java ──────────────────────────────────────────────
  cat > "$BE_PKG_DIR/controller/HelloController.java" <<'EOF'
package com.mybudget.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HelloController {

    @GetMapping("/hello")
    public Map<String, Object> hello() {
        return Map.of(
            "message", "Hello from Spring Boot 3.5 !",
            "timestamp", LocalDateTime.now().toString(),
            "backend", "Spring Boot",
            "java", System.getProperty("java.version")
        );
    }
}
EOF
  ok "HelloController.java 생성"

  # ─── WebConfig.java (CORS) ─────────────────────────────────────────────
  cat > "$BE_PKG_DIR/config/WebConfig.java" <<'EOF'
package com.mybudget.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:15173", "http://localhost:15174")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
EOF
  ok "WebConfig.java (CORS) 생성"

  # ─── application.yml ──────────────────────────────────────────────────
  rm -f "$PROJECT_DIR/backend/src/main/resources/application.properties"
  cat > "$PROJECT_DIR/backend/src/main/resources/application.yml" <<'EOF'
spring:
  application:
    name: budget-book-backend
  profiles:
    active: dev

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        format_sql: true

  datasource:
    url: jdbc:h2:file:./data/mybudget_codex;DB_CLOSE_DELAY=-1;MODE=MySQL
    driver-class-name: org.h2.Driver
    username: sa
    password:

  h2:
    console:
      enabled: true
      path: /h2-console

server:
  port: 18080

management:
  endpoints:
    web:
      exposure:
        include: health,info

logging:
  level:
    org.hibernate.SQL: DEBUG
    com.mybudget.backend: DEBUG
EOF
  ok "application.yml 생성 (H2 + JPA + Actuator)"

  # 빈 디렉토리 표시용
  echo "# 거래내역 등 추후 생성될 도메인 패키지" > "$BE_PKG_DIR/domain/.gitkeep"
  echo "# Service 계층" > "$BE_PKG_DIR/service/.gitkeep"
  echo "# Repository 계층" > "$BE_PKG_DIR/repository/.gitkeep"
  echo "# DTO" > "$BE_PKG_DIR/dto/.gitkeep"
  echo "# 예외 처리" > "$BE_PKG_DIR/exception/.gitkeep"
  echo "# 유틸 (SMS 파서 등)" > "$BE_PKG_DIR/util/.gitkeep"
fi

# =============================================================================
say "3/7. React 프론트엔드 생성 (Vite + TypeScript)"
# =============================================================================

if [ -d "$PROJECT_DIR/frontend" ]; then
  if ask "frontend/ 폴더가 이미 있습니다. 삭제하고 다시 생성할까요?"; then
    rm -rf "$PROJECT_DIR/frontend"
  else
    skip "프론트엔드 생성 건너뜀"
    SKIP_FRONTEND=true
  fi
fi

if [ -z "${SKIP_FRONTEND:-}" ]; then
  cd "$PROJECT_DIR"
  info "Vite 템플릿으로 frontend/ 생성..."
  info "  (npm 확인 프롬프트는 자동으로 'y' 응답합니다)"
  # npm_config_yes=true 로 'Ok to proceed?' 류 프롬프트를 자동 승인
  # 출력은 보이게 둬서 진행 상황 확인 가능
  npm_config_yes=true npm create vite@latest frontend -- --template react-ts

  if [ ! -d "$PROJECT_DIR/frontend" ]; then
    err "frontend/ 생성 실패 — 수동으로 다음 명령을 실행해보세요:"
    info "  npm_config_yes=true npm create vite@latest frontend -- --template react-ts"
    exit 1
  fi

  cd "$PROJECT_DIR/frontend"
  info "기본 의존성 설치 (시간이 1~2분 걸립니다)..."
  npm install

  info "프로젝트 라이브러리 설치..."
  npm install \
    react-router-dom \
    axios \
    @tanstack/react-query \
    zustand \
    react-hook-form \
    zod \
    date-fns \
    lucide-react \
    recharts \
    clsx

  info "Tailwind CSS v4 설치..."
  npm install -D tailwindcss @tailwindcss/vite

  ok "frontend/ 생성 + 의존성 설치 완료"
fi

# =============================================================================
say "4/7. 프론트엔드 커스터마이징 — 폴더 구조 + 프록시 + Hello UI"
# =============================================================================

FE_SRC="$PROJECT_DIR/frontend/src"

if [ -d "$FE_SRC" ]; then
  mkdir -p "$FE_SRC/routes" \
           "$FE_SRC/components" \
           "$FE_SRC/features" \
           "$FE_SRC/api" \
           "$FE_SRC/stores" \
           "$FE_SRC/hooks" \
           "$FE_SRC/utils" \
           "$FE_SRC/constants" \
           "$FE_SRC/styles"
  ok "표준 폴더 9종 생성"

  # ─── vite.config.ts (proxy + tailwind) ─────────────────────────────────
  cat > "$PROJECT_DIR/frontend/vite.config.ts" <<'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
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
  ok "vite.config.ts (프록시 + Tailwind) 생성"

  # ─── src/styles/index.css ──────────────────────────────────────────────
  cat > "$FE_SRC/styles/index.css" <<'EOF'
@import "tailwindcss";

/* Pretendard 한글 폰트 (CDN) */
@import url('https://cdn.jsdelivr.net/gh/orioncactus/pretendard@latest/dist/web/static/pretendard.min.css');

html, body, #root {
  height: 100%;
  margin: 0;
  font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
EOF
  ok "styles/index.css (Tailwind + Pretendard) 생성"

  # ─── src/api/client.ts ─────────────────────────────────────────────────
  cat > "$FE_SRC/api/client.ts" <<'EOF'
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Hello API (Phase 2 연동 검증용)
export interface HelloResponse {
  message: string;
  timestamp: string;
  backend: string;
  java: string;
}

export const fetchHello = () =>
  apiClient.get<HelloResponse>('/hello').then((r) => r.data);
EOF
  ok "api/client.ts 생성"

  # ─── src/main.tsx ─────────────────────────────────────────────────────
  cat > "$FE_SRC/main.tsx" <<'EOF'
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './styles/index.css';
import App from './App.tsx';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
EOF
  ok "main.tsx 갱신"

  # ─── src/App.tsx (Hello API 호출 UI) ──────────────────────────────────
  cat > "$FE_SRC/App.tsx" <<'EOF'
import { useEffect, useState } from 'react';
import { fetchHello, type HelloResponse } from './api/client';

function App() {
  const [data, setData] = useState<HelloResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchHello()
      .then((res) => {
        setData(res);
        setLoading(false);
      })
      .catch((e) => {
        setError(e.message);
        setLoading(false);
      });
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-sky-50 to-emerald-50 flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 space-y-6">
        <div className="text-center">
          <div className="text-5xl mb-3">💰</div>
          <h1 className="text-2xl font-bold text-slate-800">MyBudgetBook</h1>
          <p className="text-sm text-slate-500 mt-1">반응형 가계부 웹앱 · Phase 2</p>
        </div>

        <div className="border-t border-slate-100 pt-4">
          <h2 className="text-sm font-semibold text-slate-600 mb-3">
            백엔드 연결 상태
          </h2>

          {loading && (
            <div className="text-slate-400 text-sm">⏳ 연결 중...</div>
          )}

          {error && (
            <div className="bg-rose-50 border border-rose-200 rounded-lg p-3 text-sm text-rose-700">
              <div className="font-semibold mb-1">❌ 연결 실패</div>
              <div className="text-xs">{error}</div>
              <div className="text-xs mt-2 text-rose-600">
                Spring Boot 가 18080 포트에 떠 있는지 확인하세요.
              </div>
            </div>
          )}

          {data && (
            <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-3 space-y-1 text-sm">
              <div className="text-emerald-700 font-semibold">✅ 연결 성공</div>
              <div className="text-slate-700">
                <span className="text-slate-500">message:</span> {data.message}
              </div>
              <div className="text-slate-700 text-xs">
                <span className="text-slate-500">backend:</span> {data.backend}
              </div>
              <div className="text-slate-700 text-xs">
                <span className="text-slate-500">java:</span> {data.java}
              </div>
              <div className="text-slate-700 text-xs">
                <span className="text-slate-500">at:</span> {data.timestamp}
              </div>
            </div>
          )}
        </div>

        <div className="border-t border-slate-100 pt-4 text-xs text-slate-400 text-center">
          Phase 3 → 데이터 설계 / 인기 가계부앱 기능 명세
        </div>
      </div>
    </div>
  );
}

export default App;
EOF
  ok "App.tsx (Hello API 호출 UI) 생성"

  # ─── App.css 제거 (사용 안 함)
  rm -f "$FE_SRC/App.css"

  # ─── README 자리 ──────────────────────────────────────────────────────
  cat > "$PROJECT_DIR/frontend/.gitignore.template" <<'EOF'
# Vite 가 기본 생성한 .gitignore 가 사용됩니다
EOF
  rm -f "$PROJECT_DIR/frontend/.gitignore.template"
fi

# =============================================================================
say "5/7. .vscode/ 워크스페이스 설정"
# =============================================================================

mkdir -p "$PROJECT_DIR/.vscode"

# ─── launch.json (compound: BE + FE 동시) ──────────────────────────────
cat > "$PROJECT_DIR/.vscode/launch.json" <<'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Spring Boot - Backend",
      "request": "launch",
      "cwd": "${workspaceFolder}/backend",
      "mainClass": "com.mybudget.backend.BackendApplication",
      "projectName": "backend",
      "console": "integratedTerminal"
    },
    {
      "type": "node",
      "name": "Vite - Frontend",
      "request": "launch",
      "cwd": "${workspaceFolder}/frontend",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "console": "integratedTerminal"
    }
  ],
  "compounds": [
    {
      "name": "▶ Full Stack (Backend + Frontend)",
      "configurations": ["Spring Boot - Backend", "Vite - Frontend"],
      "stopAll": true
    }
  ]
}
EOF
ok ".vscode/launch.json (compound) 생성"

# ─── settings.json ─────────────────────────────────────────────────────
# tools/jdk-21 가 있으면 그 경로를 가리키도록 동적으로 설정
JDK_RUNTIME_PATH="$PROJECT_DIR/tools/jdk-21/Contents/Home"
if [ ! -d "$JDK_RUNTIME_PATH" ] && [ -n "$JAVA_HOME" ]; then
  JDK_RUNTIME_PATH="$JAVA_HOME"
fi

cat > "$PROJECT_DIR/.vscode/settings.json" <<EOF
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[java]": {
    "editor.defaultFormatter": "redhat.java",
    "editor.tabSize": 4
  },
  "[typescript]": { "editor.tabSize": 2 },
  "[typescriptreact]": { "editor.tabSize": 2 },
  "java.configuration.runtimes": [
    {
      "name": "JavaSE-21",
      "path": "${JDK_RUNTIME_PATH}",
      "default": true
    }
  ],
  "java.compile.nullAnalysis.mode": "automatic",
  "spring-boot.ls.problem.application-properties.unknown-property": "WARNING",
  "files.exclude": {
    "**/.gradle": true,
    "**/build": true,
    "**/node_modules": true,
    "**/dist": true
  },
  "search.exclude": {
    "**/tools": true,
    "**/build": true,
    "**/dist": true
  }
}
EOF
ok ".vscode/settings.json 생성 (Java 런타임: $JDK_RUNTIME_PATH)"

# ─── extensions.json (워크스페이스 추천 확장) ─────────────────────────
cat > "$PROJECT_DIR/.vscode/extensions.json" <<'EOF'
{
  "recommendations": [
    "vscjava.vscode-java-pack",
    "vmware.vscode-boot-dev-pack",
    "vscjava.vscode-gradle",
    "vscjava.vscode-lombok",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "dsznajder.es7-react-js-snippets",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag",
    "eamodio.gitlens",
    "humao.rest-client"
  ]
}
EOF
ok ".vscode/extensions.json (추천 확장) 생성"

# =============================================================================
say "6/7. REST Client 테스트 파일 (.http)"
# =============================================================================

mkdir -p "$PROJECT_DIR/http"
cat > "$PROJECT_DIR/http/hello.http" <<'EOF'
### Spring Boot 가 살아있는지 확인
GET http://localhost:18080/api/hello

### Actuator 헬스 체크
GET http://localhost:18080/actuator/health

### H2 콘솔 (브라우저에서 열기)
# http://localhost:18080/h2-console
# JDBC URL: jdbc:h2:file:./data/mybudget_codex
# Username: sa
# Password: (비워두기)
EOF
ok "http/hello.http (REST Client 확장으로 클릭 한 번 테스트)"

# =============================================================================
say "7/7. 루트 .gitignore + git 초기화"
# =============================================================================

if [ ! -f "$PROJECT_DIR/.gitignore" ]; then
  cat > "$PROJECT_DIR/.gitignore" <<'EOF'
# 프로젝트 로컬 도구 (각자 install-dev-env.sh 로 다운로드)
tools/

# Java / Gradle
.gradle/
backend/build/
backend/out/
backend/bin/
backend/data/
backend/*.log

# Node / Vite
frontend/node_modules/
frontend/dist/
frontend/dist-ssr/

# IDE
.vscode/launch.json.local
.idea/

# OS
.DS_Store
Thumbs.db

# 환경변수
.env
.env.local
.env.*.local
EOF
  ok ".gitignore 생성"
else
  info ".gitignore 이미 존재 — 건너뜀"
fi

if [ ! -d "$PROJECT_DIR/.git" ]; then
  if ask "git 저장소를 초기화하고 첫 커밋을 만들까요?"; then
    cd "$PROJECT_DIR"
    git init -q
    git add .
    git commit -q -m "chore: Phase 2 - Spring Boot 3.5 + React 19 + Vite + Tailwind v4 boilerplate"
    ok "git 초기화 + 첫 커밋 완료"
  fi
else
  info ".git 이미 존재 — 건너뜀"
fi

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 2 보일러플레이트 생성 완료!                                     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}다음 단계${NC}"
echo ""
echo "  1) Visual Studio Code 로 프로젝트 열기:"
echo -e "       ${BLUE}code .${NC}"
echo ""
echo "  2) F5 → '▶ Full Stack (Backend + Frontend)' 선택"
echo "     → Spring Boot(18080) + Vite(15173) 동시 실행"
echo ""
echo "  3) 또는 수동 실행 (터미널 2개):"
echo -e "       ${BLUE}# 터미널 A (백엔드)${NC}"
echo -e "       ${BLUE}cd backend && ./gradlew bootRun${NC}"
echo -e "       ${BLUE}# 터미널 B (프론트엔드)${NC}"
echo -e "       ${BLUE}cd frontend && npm run dev${NC}"
echo ""
echo "  4) 브라우저에서 확인:"
echo -e "       ${BLUE}http://localhost:15173${NC}  ← Hello UI"
echo -e "       ${BLUE}http://localhost:18080/api/hello${NC}  ← REST 직접"
echo -e "       ${BLUE}http://localhost:18080/h2-console${NC}  ← H2 DB"
echo ""
echo -e "${DIM}'✅ 연결 성공' 카드가 보이면 Phase 2 완료. Phase 3(기능 명세)로 진입.${NC}"
echo ""

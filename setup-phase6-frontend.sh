#!/usr/bin/env bash
# =============================================================================
# 가계부 웹앱 - Phase 6 프론트엔드 화면 자동 생성
#
# 사용법:
#   source activate-env.sh           ← Phase 1 환경 활성화
#   bash setup-phase6-frontend.sh    ← Phase 6 실행
#                                     (Phase 5 까지 완료되어 있어야 함)
#
# 생성물 (총 ~35 파일):
#   - API 함수      10개 : accounts, categories, transactions, ... (react-query 친화)
#   - 유틸 + 상수    3개 : format, date, theme
#   - 스토어        1개 : Zustand uiStore (다크모드)
#   - 공통 컴포넌트  8개 : AppLayout, BottomTabBar, Sidebar, AmountInput, CategoryGrid, TxCard, EmptyState, Skeleton
#   - 페이지       10개 : Home, Transactions, AddTransaction, Calendar, Stats, Budgets, Accounts, Categories, Settings, Sms
#   - App.tsx 재작성 (Router + QueryClient + 다크모드)
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
echo -e "${BOLD}${BLUE}║  가계부 웹앱 — Phase 6 프론트엔드 화면 자동 생성                            ║${NC}"
echo -e "${BOLD}${BLUE}║  React Router + React Query + Tailwind v4 + 모바일 퍼스트                  ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 사전 점검
if [ ! -d "$SRC" ]; then
  err "frontend/ 가 없습니다. 먼저 'bash setup-project.sh' (Phase 2) 를 실행하세요."
  exit 1
fi

mkdir -p "$SRC/api" "$SRC/components" "$SRC/routes" "$SRC/stores" \
         "$SRC/hooks" "$SRC/utils" "$SRC/constants" "$SRC/styles" "$SRC/features"

# =============================================================================
say "1/4. API client 함수 10개 + 유틸 + 스토어"
# =============================================================================

# ─── api/client.ts (재작성: 에러 핸들링 강화) ──────────────────────────
cat > "$SRC/api/client.ts" <<'EOF'
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: '/api',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

apiClient.interceptors.response.use(
  (r) => r,
  (err) => {
    const message = err.response?.data?.message || err.message || '알 수 없는 오류';
    return Promise.reject(new Error(message));
  }
);
EOF
ok "api/client.ts"

# ─── api/types.ts ──────────────────────────────────────────────────────
cat > "$SRC/api/types.ts" <<'EOF'
export type AccountType = 'CASH' | 'DEPOSIT' | 'CHECK_CARD' | 'CREDIT_CARD' | 'INVESTMENT' | 'LOAN';
export type CategoryKind = 'INCOME' | 'EXPENSE';
export type TransactionKind = 'INCOME' | 'EXPENSE' | 'TRANSFER';
export type TransactionSource = 'MANUAL' | 'SMS' | 'RECURRING';

export interface Account {
  id: number;
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  color?: string;
  statementDay?: number;
  paymentDay?: number;
  sortOrder: number;
  archived: boolean;
  createdAt: string;
}

export interface Category {
  id: number;
  name: string;
  kind: CategoryKind;
  parentId?: number;
  icon?: string;
  color?: string;
  sortOrder: number;
  archived: boolean;
}

export interface Transaction {
  id: number;
  kind: TransactionKind;
  amount: number;
  accountId: number;
  accountName: string;
  categoryId?: number;
  categoryName?: string;
  memo?: string;
  occurredAt: string;
  source: TransactionSource;
  installmentMonths?: number;
  installmentSeq?: number;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface MonthlySummary {
  year: number;
  month: number;
  totalIncome: number;
  totalExpense: number;
  net: number;
  transactionCount: number;
}

export interface CategoryBreakdown {
  categoryId: number;
  name: string;
  color: string;
  amount: number;
  percentage: number;
}

export interface CalendarDay {
  date: string;
  income: number;
  expense: number;
}

export interface CalendarMonth {
  year: number;
  month: number;
  days: CalendarDay[];
  totalIncome: number;
  totalExpense: number;
}

export interface Budget {
  id: number;
  year: number;
  month: number;
  categoryId: number;
  categoryName: string;
  amount: number;
}

export interface BudgetProgress {
  categoryId: number;
  categoryName: string;
  color?: string;
  budgetAmount: number;
  spentAmount: number;
  percentage: number;
}
EOF
ok "api/types.ts"

# ─── api/accounts.ts ───────────────────────────────────────────────────
cat > "$SRC/api/accounts.ts" <<'EOF'
import { apiClient } from './client';
import type { Account, AccountType } from './types';

export const fetchAccounts = () =>
  apiClient.get<Account[]>('/accounts').then((r) => r.data);

export const createAccount = (data: {
  name: string;
  type: AccountType;
  balance?: number;
  color?: string;
}) => apiClient.post<Account>('/accounts', data).then((r) => r.data);

export const updateAccount = (id: number, data: { name: string; color?: string; archived?: boolean }) =>
  apiClient.put<Account>(`/accounts/${id}`, data).then((r) => r.data);

export const deleteAccount = (id: number) =>
  apiClient.delete(`/accounts/${id}`);
EOF
ok "api/accounts.ts"

# ─── api/categories.ts ─────────────────────────────────────────────────
cat > "$SRC/api/categories.ts" <<'EOF'
import { apiClient } from './client';
import type { Category, CategoryKind } from './types';

export const fetchCategories = (kind?: CategoryKind) =>
  apiClient.get<Category[]>('/categories', { params: { kind } }).then((r) => r.data);

export const createCategory = (data: {
  name: string;
  kind: CategoryKind;
  parentId?: number;
  icon?: string;
  color?: string;
}) => apiClient.post<Category>('/categories', data).then((r) => r.data);

export const updateCategory = (id: number, data: {
  name: string;
  icon?: string;
  color?: string;
  archived?: boolean;
}) => apiClient.put<Category>(`/categories/${id}`, data).then((r) => r.data);

export const deleteCategory = (id: number) =>
  apiClient.delete(`/categories/${id}`);
EOF
ok "api/categories.ts"

# ─── api/transactions.ts ───────────────────────────────────────────────
cat > "$SRC/api/transactions.ts" <<'EOF'
import { apiClient } from './client';
import type { Transaction, TransactionKind } from './types';

export interface TransactionFilter {
  from: string;
  to: string;
  accountId?: number;
  categoryId?: number;
}

export const fetchTransactions = (filter: TransactionFilter) =>
  apiClient.get<Transaction[]>('/transactions', { params: filter }).then((r) => r.data);

export const searchTransactions = (q: string) =>
  apiClient.get<Transaction[]>('/transactions/search', { params: { q } }).then((r) => r.data);

export const fetchTransaction = (id: number) =>
  apiClient.get<Transaction>(`/transactions/${id}`).then((r) => r.data);

export interface TransactionInput {
  kind: TransactionKind;
  amount: number;
  accountId: number;
  categoryId?: number;
  memo?: string;
  occurredAt: string;
  tags?: string[];
}

export const createTransaction = (data: TransactionInput) =>
  apiClient.post<Transaction>('/transactions', data).then((r) => r.data);

export const updateTransaction = (id: number, data: TransactionInput) =>
  apiClient.put<Transaction>(`/transactions/${id}`, data).then((r) => r.data);

export const deleteTransaction = (id: number) =>
  apiClient.delete(`/transactions/${id}`);
EOF
ok "api/transactions.ts"

# ─── api/stats.ts ──────────────────────────────────────────────────────
cat > "$SRC/api/stats.ts" <<'EOF'
import { apiClient } from './client';
import type { MonthlySummary, CategoryBreakdown, CalendarMonth, TransactionKind } from './types';

export const fetchMonthly = (year: number, month: number) =>
  apiClient.get<MonthlySummary>('/stats/monthly', { params: { year, month } }).then((r) => r.data);

export const fetchByCategory = (from: string, to: string, kind: TransactionKind = 'EXPENSE') =>
  apiClient.get<CategoryBreakdown[]>('/stats/by-category', {
    params: { from, to, kind }
  }).then((r) => r.data);

export const fetchCalendar = (year: number, month: number) =>
  apiClient.get<CalendarMonth>('/stats/calendar', { params: { year, month } }).then((r) => r.data);
EOF
ok "api/stats.ts"

# ─── api/budgets.ts ────────────────────────────────────────────────────
cat > "$SRC/api/budgets.ts" <<'EOF'
import { apiClient } from './client';
import type { Budget, BudgetProgress } from './types';

export const fetchBudgets = (year: number, month: number) =>
  apiClient.get<Budget[]>('/budgets', { params: { year, month } }).then((r) => r.data);

export const upsertBudget = (data: {
  year: number;
  month: number;
  categoryId: number;
  amount: number;
}) => apiClient.post<Budget>('/budgets', data).then((r) => r.data);

export const fetchBudgetProgress = (year: number, month: number) =>
  apiClient.get<BudgetProgress[]>('/budgets/progress', { params: { year, month } }).then((r) => r.data);

export const deleteBudget = (id: number) =>
  apiClient.delete(`/budgets/${id}`);
EOF
ok "api/budgets.ts"

# ─── api/tags.ts ────────────────────────────────────────────────────────
cat > "$SRC/api/tags.ts" <<'EOF'
import { apiClient } from './client';

export interface Tag { id: number; name: string; color?: string; }

export const fetchTags = () =>
  apiClient.get<Tag[]>('/tags').then((r) => r.data);

export const createTag = (data: { name: string; color?: string }) =>
  apiClient.post<Tag>('/tags', data).then((r) => r.data);

export const deleteTag = (id: number) =>
  apiClient.delete(`/tags/${id}`);
EOF
ok "api/tags.ts"

# ─── api/transfers.ts ──────────────────────────────────────────────────
cat > "$SRC/api/transfers.ts" <<'EOF'
import { apiClient } from './client';

export interface Transfer {
  id: number;
  fromAccountId: number;
  fromAccountName: string;
  toAccountId: number;
  toAccountName: string;
  amount: number;
  occurredAt: string;
  memo?: string;
}

export const fetchTransfers = (from: string, to: string) =>
  apiClient.get<Transfer[]>('/transfers', { params: { from, to } }).then((r) => r.data);

export const createTransfer = (data: {
  fromAccountId: number;
  toAccountId: number;
  amount: number;
  occurredAt: string;
  memo?: string;
}) => apiClient.post<Transfer>('/transfers', data).then((r) => r.data);

export const deleteTransfer = (id: number) =>
  apiClient.delete(`/transfers/${id}`);
EOF
ok "api/transfers.ts"

# ─── utils/format.ts ───────────────────────────────────────────────────
cat > "$SRC/utils/format.ts" <<'EOF'
import { format, parseISO } from 'date-fns';
import { ko } from 'date-fns/locale';

/** 1234567 → "1,234,567원" */
export const fmtWon = (n: number, suffix = '원') =>
  new Intl.NumberFormat('ko-KR').format(n) + suffix;

/** 1234567 → "1,234,567" (단위 없음) */
export const fmtNum = (n: number) =>
  new Intl.NumberFormat('ko-KR').format(n);

/** "12000" → 12000 (콤마 제거) */
export const parseAmount = (s: string): number => {
  const n = parseInt(s.replace(/[^\d-]/g, ''), 10);
  return isNaN(n) ? 0 : n;
};

/** ISO 문자열 → "5월 17일 화" */
export const fmtDateKo = (iso: string, pattern = 'M월 d일 EEE') =>
  format(parseISO(iso), pattern, { locale: ko });

/** ISO 문자열 → "14:23" */
export const fmtTime = (iso: string) =>
  format(parseISO(iso), 'HH:mm');

/** Date → "2026-05-17T12:00:00" */
export const toLocalIso = (d: Date): string => {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
};
EOF
ok "utils/format.ts"

# ─── utils/date.ts ─────────────────────────────────────────────────────
cat > "$SRC/utils/date.ts" <<'EOF'
import { startOfMonth, endOfMonth } from 'date-fns';
import { toLocalIso } from './format';

/** YYYY-MM 의 첫 날 ISO */
export const monthFromIso = (year: number, month: number): string => {
  const d = startOfMonth(new Date(year, month - 1, 1));
  return toLocalIso(d);
};

/** YYYY-MM 의 마지막 날 23:59 ISO */
export const monthToIso = (year: number, month: number): string => {
  const d = endOfMonth(new Date(year, month - 1, 1));
  d.setHours(23, 59, 59);
  return toLocalIso(d);
};

/** 현재 년/월 */
export const nowYearMonth = (): { year: number; month: number } => {
  const d = new Date();
  return { year: d.getFullYear(), month: d.getMonth() + 1 };
};
EOF
ok "utils/date.ts"

# ─── constants/theme.ts ────────────────────────────────────────────────
cat > "$SRC/constants/theme.ts" <<'EOF'
/** 거래 종류별 강조 색 (Tailwind 클래스명) */
export const kindColors = {
  INCOME: 'text-emerald-600 dark:text-emerald-400',
  EXPENSE: 'text-rose-600 dark:text-rose-400',
  TRANSFER: 'text-sky-600 dark:text-sky-400',
} as const;

/** 계좌 유형별 한국어 라벨 + 색상 */
export const accountTypeLabel = {
  CASH: '현금',
  DEPOSIT: '예금',
  CHECK_CARD: '체크카드',
  CREDIT_CARD: '신용카드',
  INVESTMENT: '투자',
  LOAN: '대출',
} as const;
EOF
ok "constants/theme.ts"

# ─── stores/uiStore.ts ─────────────────────────────────────────────────
cat > "$SRC/stores/uiStore.ts" <<'EOF'
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface UiState {
  darkMode: boolean;
  toggleDark: () => void;
  setDark: (v: boolean) => void;
}

export const useUiStore = create<UiState>()(
  persist(
    (set) => ({
      darkMode: false,
      toggleDark: () => set((s) => {
        const next = !s.darkMode;
        document.documentElement.classList.toggle('dark', next);
        return { darkMode: next };
      }),
      setDark: (v) => {
        document.documentElement.classList.toggle('dark', v);
        set({ darkMode: v });
      },
    }),
    { name: 'budget-ui' }
  )
);
EOF
ok "stores/uiStore.ts"

# =============================================================================
say "2/4. 레이아웃 + 공통 컴포넌트"
# =============================================================================

# ─── AppLayout (모바일 하단탭 + PC 사이드바) ──────────────────────────
cat > "$SRC/components/AppLayout.tsx" <<'EOF'
import { Outlet, NavLink } from 'react-router-dom';
import {
  Home, ListChecks, PlusCircle, PieChart, Settings,
  Calendar, Wallet, Tags, MessageSquare, Target,
} from 'lucide-react';

const navItems = [
  { to: '/', label: '홈', icon: Home },
  { to: '/transactions', label: '내역', icon: ListChecks },
  { to: '/transactions/new', label: '추가', icon: PlusCircle, primary: true },
  { to: '/stats', label: '통계', icon: PieChart },
  { to: '/settings', label: '설정', icon: Settings },
];

const sideExtra = [
  { to: '/calendar', label: '달력', icon: Calendar },
  { to: '/budgets', label: '예산', icon: Target },
  { to: '/accounts', label: '계좌', icon: Wallet },
  { to: '/categories', label: '카테고리', icon: Tags },
  { to: '/sms', label: 'SMS 붙여넣기', icon: MessageSquare },
];

export function AppLayout() {
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100">
      <div className="md:flex">
        {/* PC 사이드바 */}
        <aside className="hidden md:flex md:flex-col md:w-60 md:min-h-screen md:fixed md:border-r md:border-slate-200 md:dark:border-slate-800 md:bg-white md:dark:bg-slate-900">
          <div className="p-5 border-b border-slate-200 dark:border-slate-800">
            <div className="text-xl font-bold">💰 MyBudgetBook</div>
            <div className="text-xs text-slate-500 mt-1">반응형 가계부</div>
          </div>
          <nav className="flex flex-col p-3 gap-1">
            {[...navItems, ...sideExtra].map((it) => (
              <NavLink
                key={it.to}
                to={it.to}
                end={it.to === '/'}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2 rounded-lg transition ${
                    isActive
                      ? 'bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300 font-semibold'
                      : 'hover:bg-slate-100 dark:hover:bg-slate-800'
                  }`
                }
              >
                <it.icon size={18} />
                <span className="text-sm">{it.label}</span>
              </NavLink>
            ))}
          </nav>
        </aside>

        {/* 메인 영역 */}
        <main className="flex-1 md:ml-60 pb-20 md:pb-0">
          <div className="max-w-3xl mx-auto px-4 py-4 md:py-8">
            <Outlet />
          </div>
        </main>
      </div>

      {/* 모바일 하단 탭 */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 z-50">
        <div className="flex">
          {navItems.map((it) => (
            <NavLink
              key={it.to}
              to={it.to}
              end={it.to === '/'}
              className={({ isActive }) =>
                `flex-1 flex flex-col items-center py-2.5 gap-0.5 transition ${
                  isActive
                    ? 'text-sky-600 dark:text-sky-400'
                    : 'text-slate-500 dark:text-slate-400'
                }`
              }
            >
              <it.icon size={it.primary ? 28 : 22} />
              <span className="text-[10px]">{it.label}</span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  );
}
EOF
ok "AppLayout.tsx"

# ─── AmountInput.tsx ───────────────────────────────────────────────────
cat > "$SRC/components/AmountInput.tsx" <<'EOF'
import { fmtNum, parseAmount } from '../utils/format';

interface Props {
  value: number;
  onChange: (n: number) => void;
  className?: string;
  placeholder?: string;
  autoFocus?: boolean;
}

export function AmountInput({ value, onChange, className, placeholder, autoFocus }: Props) {
  return (
    <div className={`relative ${className || ''}`}>
      <input
        type="text"
        inputMode="numeric"
        value={value === 0 ? '' : fmtNum(value)}
        onChange={(e) => onChange(parseAmount(e.target.value))}
        placeholder={placeholder || '0'}
        autoFocus={autoFocus}
        className="w-full text-3xl font-bold text-right py-3 px-4 bg-transparent
                   border-b-2 border-slate-200 dark:border-slate-700
                   focus:border-sky-500 outline-none"
      />
      <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg pointer-events-none">
        원
      </span>
    </div>
  );
}
EOF
ok "AmountInput.tsx"

# ─── CategoryGrid.tsx ──────────────────────────────────────────────────
cat > "$SRC/components/CategoryGrid.tsx" <<'EOF'
import type { Category } from '../api/types';

interface Props {
  categories: Category[];
  selectedId?: number;
  onSelect: (c: Category) => void;
}

export function CategoryGrid({ categories, selectedId, onSelect }: Props) {
  if (!categories.length) {
    return <div className="text-center text-slate-400 py-6">카테고리가 없습니다</div>;
  }
  return (
    <div className="grid grid-cols-4 gap-3">
      {categories.map((c) => {
        const isSel = c.id === selectedId;
        return (
          <button
            key={c.id}
            type="button"
            onClick={() => onSelect(c)}
            className={`p-3 rounded-xl border-2 transition flex flex-col items-center gap-1 ${
              isSel
                ? 'border-sky-500 bg-sky-50 dark:bg-sky-900/30'
                : 'border-slate-200 dark:border-slate-700 hover:border-slate-300'
            }`}
          >
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold"
              style={{ background: c.color || '#64748b' }}
            >
              {c.name.charAt(0)}
            </div>
            <span className="text-xs leading-tight text-center">{c.name}</span>
          </button>
        );
      })}
    </div>
  );
}
EOF
ok "CategoryGrid.tsx"

# ─── TxCard.tsx ────────────────────────────────────────────────────────
cat > "$SRC/components/TxCard.tsx" <<'EOF'
import { Link } from 'react-router-dom';
import type { Transaction } from '../api/types';
import { fmtWon, fmtTime } from '../utils/format';
import { kindColors } from '../constants/theme';

export function TxCard({ tx }: { tx: Transaction }) {
  const sign = tx.kind === 'INCOME' ? '+' : tx.kind === 'EXPENSE' ? '-' : '';
  return (
    <Link
      to={`/transactions/${tx.id}`}
      className="flex items-center gap-3 p-3 rounded-xl bg-white dark:bg-slate-900
                 border border-slate-100 dark:border-slate-800
                 hover:shadow-md transition"
    >
      <div className="flex-1 min-w-0">
        <div className="flex items-baseline gap-2">
          <span className="font-medium text-sm">{tx.categoryName || '미분류'}</span>
          <span className="text-[11px] text-slate-400">{fmtTime(tx.occurredAt)}</span>
        </div>
        <div className="text-xs text-slate-500 truncate mt-0.5">
          {tx.memo || tx.accountName}
        </div>
      </div>
      <div className={`text-right ${kindColors[tx.kind]}`}>
        <div className="font-bold">{sign}{fmtWon(tx.amount, '')}</div>
        <div className="text-[10px] text-slate-400">{tx.accountName}</div>
      </div>
    </Link>
  );
}
EOF
ok "TxCard.tsx"

# ─── EmptyState.tsx ────────────────────────────────────────────────────
cat > "$SRC/components/EmptyState.tsx" <<'EOF'
import type { ReactNode } from 'react';

interface Props {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}

export function EmptyState({ icon, title, description, action }: Props) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="text-5xl mb-3 text-slate-300 dark:text-slate-600">
        {icon || '📭'}
      </div>
      <div className="font-semibold text-slate-700 dark:text-slate-200">{title}</div>
      {description && (
        <div className="text-sm text-slate-500 mt-1">{description}</div>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
EOF
ok "EmptyState.tsx"

# ─── Skeleton.tsx ──────────────────────────────────────────────────────
cat > "$SRC/components/Skeleton.tsx" <<'EOF'
export function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={`animate-pulse bg-slate-200 dark:bg-slate-800 rounded ${className || 'h-4 w-full'}`}
    />
  );
}
EOF
ok "Skeleton.tsx"

# ─── PageHeader.tsx ────────────────────────────────────────────────────
cat > "$SRC/components/PageHeader.tsx" <<'EOF'
import { useNavigate } from 'react-router-dom';
import { ChevronLeft } from 'lucide-react';
import type { ReactNode } from 'react';

interface Props {
  title: string;
  back?: boolean;
  right?: ReactNode;
}

export function PageHeader({ title, back, right }: Props) {
  const navigate = useNavigate();
  return (
    <div className="flex items-center justify-between mb-4">
      <div className="flex items-center gap-2">
        {back && (
          <button
            onClick={() => navigate(-1)}
            className="p-1 -ml-1 rounded hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <ChevronLeft size={24} />
          </button>
        )}
        <h1 className="text-xl md:text-2xl font-bold">{title}</h1>
      </div>
      {right}
    </div>
  );
}
EOF
ok "PageHeader.tsx"

# =============================================================================
say "3/4. 페이지 10개"
# =============================================================================

# ─── HomePage.tsx ──────────────────────────────────────────────────────
cat > "$SRC/routes/HomePage.tsx" <<'EOF'
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Plus, TrendingUp, TrendingDown, Wallet } from 'lucide-react';
import { fetchMonthly } from '../api/stats';
import { fetchTransactions } from '../api/transactions';
import { fetchAccounts } from '../api/accounts';
import { fetchBudgetProgress } from '../api/budgets';
import { PageHeader } from '../components/PageHeader';
import { TxCard } from '../components/TxCard';
import { EmptyState } from '../components/EmptyState';
import { Skeleton } from '../components/Skeleton';
import { fmtWon } from '../utils/format';
import { monthFromIso, monthToIso, nowYearMonth } from '../utils/date';

export default function HomePage() {
  const { year, month } = nowYearMonth();

  const { data: summary, isLoading: loadingSummary } = useQuery({
    queryKey: ['stats', 'monthly', year, month],
    queryFn: () => fetchMonthly(year, month),
  });

  const { data: recent, isLoading: loadingTx } = useQuery({
    queryKey: ['transactions', 'recent', year, month],
    queryFn: () => fetchTransactions({
      from: monthFromIso(year, month),
      to: monthToIso(year, month),
    }),
  });

  const { data: accounts } = useQuery({
    queryKey: ['accounts'],
    queryFn: fetchAccounts,
  });

  const { data: budgets } = useQuery({
    queryKey: ['budgets', 'progress', year, month],
    queryFn: () => fetchBudgetProgress(year, month),
  });

  return (
    <div className="space-y-5">
      <PageHeader
        title={`${year}년 ${month}월`}
        right={
          <Link
            to="/transactions/new"
            className="md:hidden bg-sky-600 text-white p-2 rounded-full shadow"
          >
            <Plus size={20} />
          </Link>
        }
      />

      {/* 이달 요약 카드 */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white dark:bg-slate-900 rounded-2xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500 flex items-center gap-1">
            <TrendingUp size={14} className="text-emerald-500" /> 수입
          </div>
          <div className="font-bold text-emerald-600 dark:text-emerald-400 mt-1">
            {loadingSummary ? <Skeleton className="h-5 w-16" /> : fmtWon(summary?.totalIncome ?? 0, '')}
          </div>
        </div>
        <div className="bg-white dark:bg-slate-900 rounded-2xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500 flex items-center gap-1">
            <TrendingDown size={14} className="text-rose-500" /> 지출
          </div>
          <div className="font-bold text-rose-600 dark:text-rose-400 mt-1">
            {loadingSummary ? <Skeleton className="h-5 w-16" /> : fmtWon(summary?.totalExpense ?? 0, '')}
          </div>
        </div>
        <div className="bg-white dark:bg-slate-900 rounded-2xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500 flex items-center gap-1">
            <Wallet size={14} /> 잔액
          </div>
          <div className="font-bold mt-1">
            {loadingSummary ? <Skeleton className="h-5 w-16" /> : fmtWon((summary?.net ?? 0), '')}
          </div>
        </div>
      </div>

      {/* 자산 요약 */}
      <section>
        <h2 className="text-sm font-semibold mb-2 text-slate-600 dark:text-slate-400">자산</h2>
        <div className="space-y-2">
          {accounts?.slice(0, 4).map((a) => (
            <div key={a.id} className="flex items-center justify-between p-3 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800">
              <div>
                <div className="font-medium text-sm">{a.name}</div>
                <div className="text-xs text-slate-400">{a.type}</div>
              </div>
              <div className="font-bold">{fmtWon(a.balance)}</div>
            </div>
          ))}
        </div>
      </section>

      {/* 예산 진행률 (상위 3개) */}
      {budgets && budgets.length > 0 && (
        <section>
          <h2 className="text-sm font-semibold mb-2 text-slate-600 dark:text-slate-400">예산 진행</h2>
          <div className="space-y-2">
            {budgets.slice(0, 3).map((b) => (
              <div key={b.categoryId} className="p-3 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800">
                <div className="flex justify-between text-sm mb-1">
                  <span>{b.categoryName}</span>
                  <span className={b.percentage > 100 ? 'text-rose-600 font-bold' : 'text-slate-500'}>
                    {Math.round(b.percentage)}%
                  </span>
                </div>
                <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${
                      b.percentage > 100 ? 'bg-rose-500' : b.percentage > 80 ? 'bg-amber-500' : 'bg-emerald-500'
                    }`}
                    style={{ width: `${Math.min(b.percentage, 100)}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* 최근 거래 5건 */}
      <section>
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-sm font-semibold text-slate-600 dark:text-slate-400">최근 거래</h2>
          <Link to="/transactions" className="text-xs text-sky-600">전체 보기</Link>
        </div>
        {loadingTx ? (
          <div className="space-y-2">
            <Skeleton className="h-14 w-full rounded-xl" />
            <Skeleton className="h-14 w-full rounded-xl" />
          </div>
        ) : recent && recent.length > 0 ? (
          <div className="space-y-2">
            {recent.slice(0, 5).map((tx) => <TxCard key={tx.id} tx={tx} />)}
          </div>
        ) : (
          <EmptyState
            icon="💸"
            title="이달 거래가 없습니다"
            description="우측 하단 + 버튼으로 첫 거래를 추가해보세요"
          />
        )}
      </section>
    </div>
  );
}
EOF
ok "HomePage.tsx"

# ─── TransactionsPage.tsx ──────────────────────────────────────────────
cat > "$SRC/routes/TransactionsPage.tsx" <<'EOF'
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search } from 'lucide-react';
import { fetchTransactions, searchTransactions } from '../api/transactions';
import { PageHeader } from '../components/PageHeader';
import { TxCard } from '../components/TxCard';
import { EmptyState } from '../components/EmptyState';
import { Skeleton } from '../components/Skeleton';
import { fmtDateKo } from '../utils/format';
import { monthFromIso, monthToIso, nowYearMonth } from '../utils/date';

export default function TransactionsPage() {
  const { year, month } = nowYearMonth();
  const [keyword, setKeyword] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['transactions', { year, month, keyword }],
    queryFn: () => keyword
      ? searchTransactions(keyword)
      : fetchTransactions({ from: monthFromIso(year, month), to: monthToIso(year, month) }),
  });

  // 일자별 그룹핑
  const grouped: Record<string, typeof data> = {};
  data?.forEach((tx) => {
    const date = tx.occurredAt.slice(0, 10);
    if (!grouped[date]) grouped[date] = [];
    grouped[date]!.push(tx);
  });
  const sortedDates = Object.keys(grouped).sort().reverse();

  return (
    <div className="space-y-4">
      <PageHeader title="거래내역" />

      {/* 검색 */}
      <div className="relative">
        <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          type="text"
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
          placeholder="메모/가맹점 검색..."
          className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700
                     bg-white dark:bg-slate-900 outline-none focus:border-sky-500"
        />
      </div>

      {isLoading ? (
        <div className="space-y-2">
          <Skeleton className="h-14 rounded-xl" />
          <Skeleton className="h-14 rounded-xl" />
          <Skeleton className="h-14 rounded-xl" />
        </div>
      ) : sortedDates.length === 0 ? (
        <EmptyState icon="🔍" title="검색 결과가 없습니다" />
      ) : (
        <div className="space-y-4">
          {sortedDates.map((date) => {
            const dayTotal = grouped[date]!.reduce((sum, tx) =>
              sum + (tx.kind === 'INCOME' ? tx.amount : tx.kind === 'EXPENSE' ? -tx.amount : 0), 0);
            return (
              <div key={date}>
                <div className="flex justify-between items-baseline mb-1.5 px-1">
                  <span className="text-xs font-semibold text-slate-500">
                    {fmtDateKo(date + 'T00:00:00')}
                  </span>
                  <span className={`text-xs font-semibold ${dayTotal > 0 ? 'text-emerald-600' : dayTotal < 0 ? 'text-rose-600' : 'text-slate-400'}`}>
                    {dayTotal > 0 ? '+' : ''}{new Intl.NumberFormat('ko-KR').format(dayTotal)}
                  </span>
                </div>
                <div className="space-y-1.5">
                  {grouped[date]!.map((tx) => <TxCard key={tx.id} tx={tx} />)}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
EOF
ok "TransactionsPage.tsx"

# ─── AddTransactionPage.tsx ────────────────────────────────────────────
cat > "$SRC/routes/AddTransactionPage.tsx" <<'EOF'
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { fetchAccounts } from '../api/accounts';
import { fetchCategories } from '../api/categories';
import { createTransaction, type TransactionInput } from '../api/transactions';
import type { TransactionKind, Category } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { AmountInput } from '../components/AmountInput';
import { CategoryGrid } from '../components/CategoryGrid';
import { toLocalIso } from '../utils/format';

export default function AddTransactionPage() {
  const navigate = useNavigate();
  const qc = useQueryClient();

  const [kind, setKind] = useState<TransactionKind>('EXPENSE');
  const [amount, setAmount] = useState(0);
  const [accountId, setAccountId] = useState<number | undefined>();
  const [category, setCategory] = useState<Category | undefined>();
  const [memo, setMemo] = useState('');

  const { data: accounts } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });
  const { data: categories } = useQuery({
    queryKey: ['categories', kind],
    queryFn: () => fetchCategories(kind === 'INCOME' ? 'INCOME' : 'EXPENSE'),
    enabled: kind !== 'TRANSFER',
  });

  const mutation = useMutation({
    mutationFn: (data: TransactionInput) => createTransaction(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
      qc.invalidateQueries({ queryKey: ['accounts'] });
      navigate('/transactions');
    },
  });

  const submit = () => {
    if (!amount || !accountId) {
      alert('금액과 계좌를 선택해주세요');
      return;
    }
    if (kind !== 'TRANSFER' && !category) {
      alert('카테고리를 선택해주세요');
      return;
    }
    mutation.mutate({
      kind, amount, accountId,
      categoryId: category?.id,
      memo: memo || undefined,
      occurredAt: toLocalIso(new Date()),
    });
  };

  return (
    <div className="space-y-5">
      <PageHeader title="거래 추가" back />

      {/* 종류 토글 */}
      <div className="grid grid-cols-3 gap-2 p-1 bg-slate-100 dark:bg-slate-800 rounded-xl">
        {(['EXPENSE', 'INCOME', 'TRANSFER'] as TransactionKind[]).map((k) => (
          <button
            key={k}
            type="button"
            onClick={() => { setKind(k); setCategory(undefined); }}
            className={`py-2 rounded-lg text-sm font-medium transition ${
              kind === k
                ? k === 'INCOME' ? 'bg-emerald-500 text-white'
                : k === 'EXPENSE' ? 'bg-rose-500 text-white'
                : 'bg-sky-500 text-white'
                : 'text-slate-600 dark:text-slate-300'
            }`}
          >
            {k === 'INCOME' ? '수입' : k === 'EXPENSE' ? '지출' : '이체'}
          </button>
        ))}
      </div>

      {/* 금액 입력 */}
      <AmountInput value={amount} onChange={setAmount} autoFocus />

      {/* 계좌 선택 */}
      <div>
        <label className="text-xs font-semibold text-slate-500 mb-2 block">계좌</label>
        <div className="flex flex-wrap gap-2">
          {accounts?.map((a) => (
            <button
              key={a.id}
              type="button"
              onClick={() => setAccountId(a.id)}
              className={`px-3 py-1.5 rounded-lg text-sm border transition ${
                accountId === a.id
                  ? 'border-sky-500 bg-sky-50 dark:bg-sky-900/30 text-sky-700 dark:text-sky-300 font-medium'
                  : 'border-slate-200 dark:border-slate-700'
              }`}
            >
              {a.name}
            </button>
          ))}
        </div>
      </div>

      {/* 카테고리 그리드 */}
      {kind !== 'TRANSFER' && (
        <div>
          <label className="text-xs font-semibold text-slate-500 mb-2 block">카테고리</label>
          <CategoryGrid
            categories={categories ?? []}
            selectedId={category?.id}
            onSelect={setCategory}
          />
        </div>
      )}

      {/* 메모 */}
      <div>
        <label className="text-xs font-semibold text-slate-500 mb-2 block">메모 (선택)</label>
        <input
          type="text"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
          placeholder="예: 스타벅스 아메리카노"
          maxLength={200}
          className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700
                     bg-white dark:bg-slate-900 outline-none focus:border-sky-500"
        />
      </div>

      {/* 저장 */}
      <button
        type="button"
        onClick={submit}
        disabled={mutation.isPending}
        className="w-full bg-sky-600 hover:bg-sky-700 active:bg-sky-800 text-white font-semibold py-3 rounded-xl transition disabled:opacity-50"
      >
        {mutation.isPending ? '저장 중...' : '저장'}
      </button>
    </div>
  );
}
EOF
ok "AddTransactionPage.tsx"

# ─── CalendarPage.tsx ──────────────────────────────────────────────────
cat > "$SRC/routes/CalendarPage.tsx" <<'EOF'
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { fetchCalendar } from '../api/stats';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';
import { fmtWon } from '../utils/format';

export default function CalendarPage() {
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);

  const { data, isLoading } = useQuery({
    queryKey: ['calendar', year, month],
    queryFn: () => fetchCalendar(year, month),
  });

  const prev = () => {
    if (month === 1) { setYear(y => y - 1); setMonth(12); }
    else setMonth(m => m - 1);
  };
  const next = () => {
    if (month === 12) { setYear(y => y + 1); setMonth(1); }
    else setMonth(m => m + 1);
  };

  // 캘린더 그리드 생성
  const firstDay = new Date(year, month - 1, 1).getDay();
  const lastDate = new Date(year, month, 0).getDate();
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: lastDate }, (_, i) => i + 1),
  ];

  const dayMap = new Map(data?.days.map((d) => [d.date, d]) ?? []);

  return (
    <div className="space-y-4">
      <PageHeader title="달력" />

      <div className="flex items-center justify-between bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800">
        <button onClick={prev} className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">
          <ChevronLeft size={20} />
        </button>
        <div className="font-bold">{year}년 {month}월</div>
        <button onClick={next} className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">
          <ChevronRight size={20} />
        </button>
      </div>

      {isLoading ? (
        <Skeleton className="h-96 rounded-xl" />
      ) : (
        <>
          <div className="grid grid-cols-7 gap-px bg-slate-200 dark:bg-slate-800 rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800">
            {['일', '월', '화', '수', '목', '금', '토'].map((d, i) => (
              <div key={d} className={`bg-slate-50 dark:bg-slate-900 text-center text-xs py-2 font-semibold ${
                i === 0 ? 'text-rose-500' : i === 6 ? 'text-sky-500' : 'text-slate-600 dark:text-slate-400'
              }`}>{d}</div>
            ))}
            {cells.map((day, i) => {
              if (!day) return <div key={i} className="bg-white dark:bg-slate-900 min-h-[68px]" />;
              const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
              const info = dayMap.get(dateStr);
              const dow = (firstDay + day - 1) % 7;
              return (
                <div key={i} className="bg-white dark:bg-slate-900 min-h-[68px] p-1.5 text-[10px]">
                  <div className={`font-semibold ${dow === 0 ? 'text-rose-500' : dow === 6 ? 'text-sky-500' : ''}`}>
                    {day}
                  </div>
                  {info && (
                    <>
                      {info.income > 0 && <div className="text-emerald-600 dark:text-emerald-400">+{fmtWon(info.income, '')}</div>}
                      {info.expense > 0 && <div className="text-rose-600 dark:text-rose-400">-{fmtWon(info.expense, '')}</div>}
                    </>
                  )}
                </div>
              );
            })}
          </div>

          <div className="grid grid-cols-2 gap-3 text-sm">
            <div className="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800">
              <div className="text-xs text-slate-500">이달 수입</div>
              <div className="text-emerald-600 dark:text-emerald-400 font-bold mt-1">
                {fmtWon(data?.totalIncome ?? 0)}
              </div>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800">
              <div className="text-xs text-slate-500">이달 지출</div>
              <div className="text-rose-600 dark:text-rose-400 font-bold mt-1">
                {fmtWon(data?.totalExpense ?? 0)}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
EOF
ok "CalendarPage.tsx"

# ─── StatsPage.tsx ─────────────────────────────────────────────────────
cat > "$SRC/routes/StatsPage.tsx" <<'EOF'
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';
import { fetchByCategory, fetchMonthly } from '../api/stats';
import type { TransactionKind } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';
import { EmptyState } from '../components/EmptyState';
import { fmtWon } from '../utils/format';
import { monthFromIso, monthToIso, nowYearMonth } from '../utils/date';

export default function StatsPage() {
  const { year, month } = nowYearMonth();
  const [kind, setKind] = useState<TransactionKind>('EXPENSE');

  const { data: summary } = useQuery({
    queryKey: ['stats', 'monthly', year, month],
    queryFn: () => fetchMonthly(year, month),
  });

  const { data: byCategory, isLoading } = useQuery({
    queryKey: ['stats', 'byCategory', year, month, kind],
    queryFn: () => fetchByCategory(monthFromIso(year, month), monthToIso(year, month), kind),
  });

  return (
    <div className="space-y-5">
      <PageHeader title={`통계 · ${year}.${month}`} />

      <div className="grid grid-cols-2 gap-3">
        <div className="bg-white dark:bg-slate-900 rounded-xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500">총 수입</div>
          <div className="text-emerald-600 dark:text-emerald-400 font-bold text-lg mt-1">
            {fmtWon(summary?.totalIncome ?? 0)}
          </div>
        </div>
        <div className="bg-white dark:bg-slate-900 rounded-xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500">총 지출</div>
          <div className="text-rose-600 dark:text-rose-400 font-bold text-lg mt-1">
            {fmtWon(summary?.totalExpense ?? 0)}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2 p-1 bg-slate-100 dark:bg-slate-800 rounded-xl">
        {(['EXPENSE', 'INCOME'] as TransactionKind[]).map((k) => (
          <button
            key={k}
            onClick={() => setKind(k)}
            className={`py-2 rounded-lg text-sm font-medium transition ${
              kind === k ? 'bg-white dark:bg-slate-700 shadow' : 'text-slate-500'
            }`}
          >
            {k === 'INCOME' ? '수입' : '지출'} 분석
          </button>
        ))}
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-xl p-4 border border-slate-100 dark:border-slate-800">
        <h3 className="text-sm font-semibold mb-3">카테고리별</h3>
        {isLoading ? (
          <Skeleton className="h-64" />
        ) : !byCategory || byCategory.length === 0 ? (
          <EmptyState title="데이터가 없습니다" />
        ) : (
          <>
            <div className="h-64">
              <ResponsiveContainer>
                <PieChart>
                  <Pie
                    data={byCategory}
                    dataKey="amount"
                    nameKey="name"
                    cx="50%" cy="50%" outerRadius={80}
                  >
                    {byCategory.map((entry, i) => (
                      <Cell key={i} fill={entry.color || '#64748b'} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v) => typeof v === 'number' ? fmtWon(v) : String(v ?? 0)} />
                  <Legend wrapperStyle={{ fontSize: 12 }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="space-y-1.5 mt-3">
              {byCategory.map((c) => (
                <div key={c.categoryId} className="flex items-center justify-between text-sm">
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 rounded-full" style={{ background: c.color || '#64748b' }} />
                    <span>{c.name}</span>
                  </div>
                  <div className="text-right">
                    <span className="font-medium">{fmtWon(c.amount)}</span>
                    <span className="text-xs text-slate-400 ml-2">{c.percentage}%</span>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
EOF
ok "StatsPage.tsx"

# ─── BudgetsPage.tsx ───────────────────────────────────────────────────
cat > "$SRC/routes/BudgetsPage.tsx" <<'EOF'
import { useQuery } from '@tanstack/react-query';
import { fetchBudgetProgress } from '../api/budgets';
import { PageHeader } from '../components/PageHeader';
import { EmptyState } from '../components/EmptyState';
import { Skeleton } from '../components/Skeleton';
import { fmtWon } from '../utils/format';
import { nowYearMonth } from '../utils/date';

export default function BudgetsPage() {
  const { year, month } = nowYearMonth();
  const { data, isLoading } = useQuery({
    queryKey: ['budgets', 'progress', year, month],
    queryFn: () => fetchBudgetProgress(year, month),
  });

  return (
    <div className="space-y-4">
      <PageHeader title={`예산 · ${year}.${month}`} />

      {isLoading ? (
        <Skeleton className="h-32" />
      ) : !data || data.length === 0 ? (
        <EmptyState
          icon="🎯"
          title="설정된 예산이 없습니다"
          description="카테고리별 예산은 Swagger UI 의 /api/budgets POST 로 추가할 수 있습니다 (UI 는 곧 추가 예정)"
        />
      ) : (
        <div className="space-y-3">
          {data.map((b) => {
            const overBudget = b.percentage > 100;
            const warning = b.percentage > 80;
            return (
              <div key={b.categoryId} className="bg-white dark:bg-slate-900 rounded-xl p-4 border border-slate-100 dark:border-slate-800">
                <div className="flex justify-between items-baseline mb-2">
                  <span className="font-semibold">{b.categoryName}</span>
                  <span className={`text-sm font-bold ${overBudget ? 'text-rose-600' : warning ? 'text-amber-600' : 'text-slate-600 dark:text-slate-300'}`}>
                    {Math.round(b.percentage)}%
                  </span>
                </div>
                <div className="h-2.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden mb-2">
                  <div
                    className={`h-full transition-all ${
                      overBudget ? 'bg-rose-500' : warning ? 'bg-amber-500' : 'bg-emerald-500'
                    }`}
                    style={{ width: `${Math.min(b.percentage, 100)}%` }}
                  />
                </div>
                <div className="flex justify-between text-xs text-slate-500">
                  <span>{fmtWon(b.spentAmount)} 사용</span>
                  <span>예산 {fmtWon(b.budgetAmount)}</span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
EOF
ok "BudgetsPage.tsx"

# ─── AccountsPage.tsx ──────────────────────────────────────────────────
cat > "$SRC/routes/AccountsPage.tsx" <<'EOF'
import { useQuery } from '@tanstack/react-query';
import { fetchAccounts } from '../api/accounts';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';
import { EmptyState } from '../components/EmptyState';
import { fmtWon } from '../utils/format';
import { accountTypeLabel } from '../constants/theme';

export default function AccountsPage() {
  const { data, isLoading } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });

  return (
    <div className="space-y-4">
      <PageHeader title="자산" />

      {isLoading ? (
        <Skeleton className="h-32" />
      ) : !data || data.length === 0 ? (
        <EmptyState icon="🏦" title="등록된 계좌가 없습니다" />
      ) : (
        <div className="space-y-2">
          {data.map((a) => (
            <div key={a.id} className="flex items-center justify-between p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold"
                  style={{ background: a.color || '#94a3b8' }}
                >
                  {a.name.charAt(0)}
                </div>
                <div>
                  <div className="font-medium">{a.name}</div>
                  <div className="text-xs text-slate-400">{accountTypeLabel[a.type]}</div>
                </div>
              </div>
              <div className="text-right">
                <div className="font-bold">{fmtWon(a.balance)}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF
ok "AccountsPage.tsx"

# ─── CategoriesPage.tsx ────────────────────────────────────────────────
cat > "$SRC/routes/CategoriesPage.tsx" <<'EOF'
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchCategories } from '../api/categories';
import type { CategoryKind } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';

export default function CategoriesPage() {
  const [kind, setKind] = useState<CategoryKind>('EXPENSE');
  const { data, isLoading } = useQuery({
    queryKey: ['categories', kind],
    queryFn: () => fetchCategories(kind),
  });

  return (
    <div className="space-y-4">
      <PageHeader title="카테고리" />

      <div className="grid grid-cols-2 gap-2 p-1 bg-slate-100 dark:bg-slate-800 rounded-xl">
        {(['EXPENSE', 'INCOME'] as CategoryKind[]).map((k) => (
          <button
            key={k}
            onClick={() => setKind(k)}
            className={`py-2 rounded-lg text-sm font-medium transition ${
              kind === k ? 'bg-white dark:bg-slate-700 shadow' : 'text-slate-500'
            }`}
          >
            {k === 'INCOME' ? '수입' : '지출'}
          </button>
        ))}
      </div>

      {isLoading ? (
        <Skeleton className="h-32" />
      ) : (
        <div className="grid grid-cols-3 gap-2">
          {data?.map((c) => (
            <div key={c.id} className="flex flex-col items-center p-3 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800">
              <div
                className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold mb-1"
                style={{ background: c.color || '#64748b' }}
              >
                {c.name.charAt(0)}
              </div>
              <div className="text-xs text-center">{c.name}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF
ok "CategoriesPage.tsx"

# ─── SettingsPage.tsx ──────────────────────────────────────────────────
cat > "$SRC/routes/SettingsPage.tsx" <<'EOF'
import { Moon, Sun, Database, FileText } from 'lucide-react';
import { useUiStore } from '../stores/uiStore';
import { PageHeader } from '../components/PageHeader';

export default function SettingsPage() {
  const darkMode = useUiStore((s) => s.darkMode);
  const toggleDark = useUiStore((s) => s.toggleDark);

  return (
    <div className="space-y-4">
      <PageHeader title="설정" />

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800 overflow-hidden">
        <button
          onClick={toggleDark}
          className="w-full flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/50"
        >
          <div className="flex items-center gap-3">
            {darkMode ? <Moon size={20} /> : <Sun size={20} />}
            <span>다크 모드</span>
          </div>
          <div className={`w-11 h-6 rounded-full relative transition ${darkMode ? 'bg-sky-600' : 'bg-slate-300'}`}>
            <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-all ${darkMode ? 'left-5' : 'left-0.5'}`} />
          </div>
        </button>

        <a
          href="http://localhost:18080/h2-console"
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-3 p-4 border-t border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50"
        >
          <Database size={20} />
          <span>H2 데이터베이스 콘솔</span>
        </a>

        <a
          href="http://localhost:18080/swagger-ui.html"
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-3 p-4 border-t border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50"
        >
          <FileText size={20} />
          <span>API 문서 (Swagger UI)</span>
        </a>
      </div>

      <div className="text-xs text-center text-slate-400">
        MyBudgetBook v0.1.0 · 개발 모드
      </div>
    </div>
  );
}
EOF
ok "SettingsPage.tsx"

# ─── SmsPage.tsx (Phase 7 에서 본격 구현, 일단 placeholder) ────────────
cat > "$SRC/routes/SmsPage.tsx" <<'EOF'
import { PageHeader } from '../components/PageHeader';
import { EmptyState } from '../components/EmptyState';

export default function SmsPage() {
  return (
    <div className="space-y-4">
      <PageHeader title="SMS 붙여넣기" />
      <EmptyState
        icon="📱"
        title="Phase 7 에서 구현 예정"
        description="카드사 SMS 텍스트를 붙여넣으면 자동으로 거래가 등록됩니다. 백엔드 정규식 8개는 이미 준비되어 있습니다."
      />
    </div>
  );
}
EOF
ok "SmsPage.tsx"

# =============================================================================
say "4/4. App.tsx 재작성 (Router + QueryClient + 다크모드) + main.tsx"
# =============================================================================

# ─── App.tsx (재작성) ──────────────────────────────────────────────────
cat > "$SRC/App.tsx" <<'EOF'
import { useEffect } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppLayout } from './components/AppLayout';
import HomePage from './routes/HomePage';
import TransactionsPage from './routes/TransactionsPage';
import AddTransactionPage from './routes/AddTransactionPage';
import CalendarPage from './routes/CalendarPage';
import StatsPage from './routes/StatsPage';
import BudgetsPage from './routes/BudgetsPage';
import AccountsPage from './routes/AccountsPage';
import CategoriesPage from './routes/CategoriesPage';
import SettingsPage from './routes/SettingsPage';
import SmsPage from './routes/SmsPage';
import { useUiStore } from './stores/uiStore';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false },
  },
});

function App() {
  const darkMode = useUiStore((s) => s.darkMode);
  useEffect(() => {
    document.documentElement.classList.toggle('dark', darkMode);
  }, [darkMode]);

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route element={<AppLayout />}>
            <Route index element={<HomePage />} />
            <Route path="transactions" element={<TransactionsPage />} />
            <Route path="transactions/new" element={<AddTransactionPage />} />
            <Route path="calendar" element={<CalendarPage />} />
            <Route path="stats" element={<StatsPage />} />
            <Route path="budgets" element={<BudgetsPage />} />
            <Route path="accounts" element={<AccountsPage />} />
            <Route path="categories" element={<CategoriesPage />} />
            <Route path="settings" element={<SettingsPage />} />
            <Route path="sms" element={<SmsPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;
EOF
ok "App.tsx (Router + QueryClient + 다크모드)"

# ─── styles/index.css (Tailwind v4 + 다크모드 클래스 활성화) ────────────
cat > "$SRC/index.css" <<'EOF'
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));

@import url('https://cdn.jsdelivr.net/gh/orioncactus/pretendard@latest/dist/web/static/pretendard.min.css');

html, body, #root {
  height: 100%;
  margin: 0;
  font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

html { scroll-behavior: smooth; }
body { background: rgb(248 250 252); }
.dark body { background: rgb(2 6 23); }

/* 입력값 모바일 확대 방지 */
input, textarea, select { font-size: 16px; }
EOF
ok "styles/index.css (Tailwind v4 + 다크모드 variant + 모바일 확대 방지)"

# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║  🎉  Phase 6 프론트엔드 화면 생성 완료!                                     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}생성 결과${NC}"
echo "  • API 함수    : 9개 (accounts, categories, transactions, stats, budgets, tags, transfers, ...)"
echo "  • 유틸 + 상수 : format, date, theme"
echo "  • 스토어       : uiStore (다크모드 + localStorage 영속)"
echo "  • 공통 컴포넌트: AppLayout, AmountInput, CategoryGrid, TxCard, EmptyState, Skeleton, PageHeader"
echo "  • 페이지       : 10개 (Home/Transactions/Add/Calendar/Stats/Budgets/Accounts/Categories/Settings/Sms)"
echo "  • App.tsx     : Router + QueryClient + 다크모드"
echo "  • index.css   : Tailwind v4 + Pretendard + dark variant"
echo ""
echo -e "${BOLD}다음 단계${NC}"
echo ""
echo "  1) 백엔드가 떠 있어야 합니다 (18080 포트):"
echo -e "       ${BLUE}cd backend && ./gradlew bootRun${NC}"
echo ""
echo "  2) 새 터미널에서 프론트 실행:"
echo -e "       ${BLUE}cd frontend && npm run dev${NC}"
echo ""
echo "  3) 브라우저:"
echo -e "       ${BLUE}http://localhost:15173${NC}"
echo "     → 모바일 뷰 (chrome devtools F12 → device toolbar) 로 보면 하단 탭바"
echo "     → PC 뷰는 좌측 사이드바"
echo ""
echo "  4) 첫 거래 추가:"
echo "     하단 + 버튼 → 금액 입력 → 계좌 선택 → 카테고리 선택 → 저장"
echo "     → 홈 대시보드에 즉시 반영 + 계좌 잔액 자동 갱신"
echo ""
echo -e "${DIM}Phase 7 (SMS 파서 본격 구현) 또는 Phase 8 (PWA/JWT 인증) 으로 진입 가능합니다.${NC}"
echo ""

import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { ArrowRight, Landmark } from 'lucide-react';
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
import { accountTypeLabel, isBalanceManagedAccount } from '../constants/theme';

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

  const accountList = Array.isArray(accounts) ? accounts : [];
  const recentList = Array.isArray(recent) ? recent : [];
  const budgetList = Array.isArray(budgets) ? budgets : [];
  const totalBalance = accountList
    .filter((account) => isBalanceManagedAccount(account.type))
    .reduce((sum, account) => sum + account.balance, 0);
  const net = summary?.net ?? 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title={`${year}년 ${month}월`}
      />

      <section className="rounded-lg bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="p-5 md:p-6 bg-slate-950 text-white">
          <div className="flex items-start justify-between gap-4">
            <div>
              <div className="text-sm text-slate-300">총 자산</div>
              <div className="mt-2 text-3xl md:text-4xl font-bold tracking-tight tabular-nums">
                {fmtWon(totalBalance)}
              </div>
            </div>
            <Link
              to="/accounts"
              className="inline-flex items-center gap-1.5 rounded-lg bg-white/10 hover:bg-white/15 border border-white/10 px-3 py-2 text-sm text-slate-100"
            >
              계좌
              <ArrowRight size={16} />
            </Link>
          </div>
          <div className="mt-5 grid grid-cols-3 gap-2">
            <div className="rounded-lg bg-white/10 border border-white/10 p-3">
              <div className="text-[11px] text-slate-300">수입</div>
              <div className="mt-1 font-semibold text-emerald-300 tabular-nums truncate">
                {loadingSummary ? '-' : fmtWon(summary?.totalIncome ?? 0, '')}
              </div>
            </div>
            <div className="rounded-lg bg-white/10 border border-white/10 p-3">
              <div className="text-[11px] text-slate-300">지출</div>
              <div className="mt-1 font-semibold text-rose-300 tabular-nums truncate">
                {loadingSummary ? '-' : fmtWon(summary?.totalExpense ?? 0, '')}
              </div>
            </div>
            <div className="rounded-lg bg-white/10 border border-white/10 p-3">
              <div className="text-[11px] text-slate-300">흐름</div>
              <div className={`mt-1 font-semibold tabular-nums truncate ${net >= 0 ? 'text-sky-200' : 'text-amber-200'}`}>
                {loadingSummary ? '-' : fmtWon(net, '')}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 자산 요약 */}
      <section>
        <div className="flex justify-between items-center mb-3">
          <h2 className="text-sm font-semibold text-slate-700 dark:text-slate-300">자산</h2>
          <Link to="/accounts" className="text-xs font-medium text-sky-600 dark:text-sky-400">관리</Link>
        </div>
        <div className="grid md:grid-cols-2 gap-2">
          {accountList.slice(0, 4).map((a) => (
            <div key={a.id} className="flex items-center justify-between gap-3 p-4 bg-white dark:bg-slate-900 rounded-lg border border-slate-200/80 dark:border-slate-800 shadow-sm">
              <div className="flex items-center gap-3 min-w-0">
                <div
                  className="w-10 h-10 rounded-lg flex items-center justify-center text-white shrink-0"
                  style={{ background: a.color || '#0ea5e9' }}
                >
                  <Landmark size={18} />
                </div>
                <div className="min-w-0">
                  <div className="font-medium text-sm truncate">{a.name}</div>
                  <div className="text-xs text-slate-400">{accountTypeLabel[a.type]}</div>
                </div>
              </div>
              <div className="font-bold tabular-nums whitespace-nowrap">
                {isBalanceManagedAccount(a.type) ? fmtWon(a.balance) : '잔액 미관리'}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 예산 진행률 (상위 3개) */}
      {budgetList.length > 0 && (
        <section>
          <h2 className="text-sm font-semibold mb-3 text-slate-700 dark:text-slate-300">예산 진행</h2>
          <div className="space-y-2">
            {budgetList.slice(0, 3).map((b) => (
              <div key={b.categoryId} className="p-4 bg-white dark:bg-slate-900 rounded-lg border border-slate-200/80 dark:border-slate-800 shadow-sm">
                <div className="flex justify-between text-sm mb-1">
                  <span className="font-medium">{b.categoryName}</span>
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
        <div className="flex justify-between items-center mb-3">
          <h2 className="text-sm font-semibold text-slate-700 dark:text-slate-300">최근 거래</h2>
          <Link to="/transactions" className="text-xs font-medium text-sky-600 dark:text-sky-400">전체 보기</Link>
        </div>
        {loadingTx ? (
          <div className="space-y-2">
            <Skeleton className="h-14 w-full rounded-lg" />
            <Skeleton className="h-14 w-full rounded-lg" />
          </div>
        ) : recentList.length > 0 ? (
          <div className="space-y-2">
            {recentList.slice(0, 5).map((tx) => <TxCard key={tx.id} tx={tx} />)}
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

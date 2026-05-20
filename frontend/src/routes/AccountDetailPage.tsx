import { useParams, useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowDownLeft, ArrowUpRight, CreditCard, Repeat } from 'lucide-react';
import { fetchAccount, fetchAccountActivities } from '../api/accounts';
import { PageHeader } from '../components/PageHeader';
import { MonthPicker } from '../components/MonthPicker';
import { Skeleton } from '../components/Skeleton';
import { EmptyState } from '../components/EmptyState';
import { accountTypeLabel, isBalanceManagedAccount } from '../constants/theme';
import { fmtDateKo, fmtWon } from '../utils/format';
import { monthFromIso, monthToIso, nowYearMonth } from '../utils/date';

export default function AccountDetailPage() {
  const { id } = useParams();
  const accountId = Number(id);
  const initial = nowYearMonth();
  const [params, setParams] = useSearchParams();
  const year = Number(params.get('year') || initial.year);
  const month = Number(params.get('month') || initial.month);

  const { data: account } = useQuery({
    queryKey: ['accounts', accountId],
    queryFn: () => fetchAccount(accountId),
    enabled: Number.isFinite(accountId),
  });

  const { data: activities, isLoading } = useQuery({
    queryKey: ['accounts', accountId, 'activities', year, month],
    queryFn: () => fetchAccountActivities(accountId, monthFromIso(year, month), monthToIso(year, month)),
    enabled: Number.isFinite(accountId),
  });

  const list = activities ?? [];
  const balanceManaged = account ? isBalanceManagedAccount(account.type) : true;
  const income = list.filter((a) => a.amount > 0).reduce((sum, a) => sum + a.amount, 0);
  const expense = list.filter((a) => a.amount < 0).reduce((sum, a) => sum + Math.abs(a.amount), 0);

  const setMonth = (nextYear: number, nextMonth: number) => {
    const next = new URLSearchParams(params);
    next.set('year', String(nextYear));
    next.set('month', String(nextMonth));
    setParams(next, { replace: true });
  };

  return (
    <div className="space-y-5">
      <PageHeader title={account?.name ?? '자산 내역'} back />

      <section className="rounded-lg bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="p-5 bg-slate-950 text-white">
          <div className="text-sm text-slate-300">{account ? accountTypeLabel[account.type] : '자산'}</div>
          <div className="mt-1 text-2xl font-bold tracking-tight">{account?.name ?? '-'}</div>
          <div className="mt-4 text-sm text-slate-300">{balanceManaged ? '현재 잔액' : '관리 방식'}</div>
          <div className="mt-1 text-3xl font-bold tabular-nums">
            {balanceManaged ? fmtWon(account?.balance ?? 0) : '잔액 미관리'}
          </div>
          {account?.type === 'CHECK_CARD' && (
            <div className="mt-3 inline-flex items-center gap-1.5 rounded-lg bg-white/10 border border-white/10 px-3 py-1.5 text-sm text-slate-100">
              <CreditCard size={15} />
              {account.linkedDepositAccountName ? `${account.linkedDepositAccountName}에서 출금` : '연결 예금 없음'}
            </div>
          )}
          {account?.type === 'CREDIT_CARD' && (
            <div className="mt-3 inline-flex items-center gap-1.5 rounded-lg bg-white/10 border border-white/10 px-3 py-1.5 text-sm text-slate-100">
              <CreditCard size={15} />
              지출 내역만 기록
            </div>
          )}
        </div>
        <div className="grid grid-cols-2 divide-x divide-slate-100 dark:divide-slate-800">
          <div className="p-4">
            <div className="text-xs text-slate-500">{balanceManaged ? '입금' : '환불/취소'}</div>
            <div className="mt-1 font-bold text-emerald-600 dark:text-emerald-400 tabular-nums">{fmtWon(income)}</div>
          </div>
          <div className="p-4">
            <div className="text-xs text-slate-500">{balanceManaged ? '출금' : '사용액'}</div>
            <div className="mt-1 font-bold text-rose-600 dark:text-rose-400 tabular-nums">{fmtWon(expense)}</div>
          </div>
        </div>
      </section>

      <div className="flex justify-center bg-white dark:bg-slate-900 rounded-lg p-2 border border-slate-200/80 dark:border-slate-800 shadow-sm">
        <MonthPicker year={year} month={month} onChange={setMonth} showArrows />
      </div>

      {isLoading ? (
        <div className="space-y-2">
          <Skeleton className="h-16 rounded-lg" />
          <Skeleton className="h-16 rounded-lg" />
        </div>
      ) : list.length === 0 ? (
        <EmptyState icon="📒" title={`${year}년 ${month}월 내역이 없습니다`} />
      ) : (
        <div className="space-y-2">
          {list.map((activity) => {
            const positive = activity.amount > 0;
            const transfer = activity.sourceType === 'TRANSFER';
            const Icon = transfer ? Repeat : positive ? ArrowDownLeft : ArrowUpRight;
            return (
              <div
                key={`${activity.sourceType}-${activity.sourceId}-${activity.kind}`}
                className="flex items-center gap-3 p-4 rounded-lg bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 shadow-sm"
              >
                <div className={`h-10 w-10 rounded-lg flex items-center justify-center shrink-0 ${
                  positive
                    ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-300'
                    : 'bg-rose-50 text-rose-600 dark:bg-rose-950/40 dark:text-rose-300'
                }`}>
                  <Icon size={18} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-semibold text-sm truncate">{activity.title}</div>
                  <div className="text-xs text-slate-500 truncate">
                    {fmtDateKo(activity.occurredAt, 'M월 d일 HH:mm')} · {activity.subtitle}
                    {activity.memo ? ` · ${activity.memo}` : ''}
                  </div>
                </div>
                <div className={`font-bold tabular-nums whitespace-nowrap ${positive ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'}`}>
                  {positive ? '+' : '-'}{fmtWon(Math.abs(activity.amount), '')}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

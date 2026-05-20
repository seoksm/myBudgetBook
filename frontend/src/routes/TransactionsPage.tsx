import { useSearchParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Search } from 'lucide-react';
import { fetchTransactions, searchTransactions } from '../api/transactions';
import { PageHeader } from '../components/PageHeader';
import { TxCard } from '../components/TxCard';
import { EmptyState } from '../components/EmptyState';
import { Skeleton } from '../components/Skeleton';
import { MonthPicker } from '../components/MonthPicker';
import { fmtDateKo } from '../utils/format';
import { monthFromIso, monthToIso, nowYearMonth } from '../utils/date';

export default function TransactionsPage() {
  const initial = nowYearMonth();
  // 필터를 URL 쿼리스트링에 보관 → 상세에서 돌아올 때 그대로 복원됨
  const [params, setParams] = useSearchParams();
  const year = Number(params.get('year') || initial.year);
  const month = Number(params.get('month') || initial.month);
  const keyword = params.get('q') || '';

  const setFilter = (next: { year?: number; month?: number; q?: string }) => {
    const merged = new URLSearchParams(params);
    if (next.year !== undefined) merged.set('year', String(next.year));
    if (next.month !== undefined) merged.set('month', String(next.month));
    if (next.q !== undefined) {
      if (next.q) merged.set('q', next.q);
      else merged.delete('q');
    }
    setParams(merged, { replace: true });
  };

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

      {/* 년/월 선택 */}
      <div className="flex justify-center bg-white dark:bg-slate-900 rounded-xl p-2 border border-slate-100 dark:border-slate-800">
        <MonthPicker
          year={year}
          month={month}
          onChange={(y, m) => setFilter({ year: y, month: m })}
          showArrows
        />
      </div>

      {/* 검색 */}
      <div className="relative">
        <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
        <input
          type="text"
          value={keyword}
          onChange={(e) => setFilter({ q: e.target.value })}
          placeholder="메모/가맹점 검색 (전체 기간)"
          className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700
                     bg-white dark:bg-slate-900 outline-none focus:border-sky-500"
        />
        {keyword && (
          <div className="text-[11px] text-slate-400 mt-1 px-1">
            검색 모드: 위 년월 필터는 비활성, 전체 기간 검색
          </div>
        )}
      </div>

      {isLoading ? (
        <div className="space-y-2">
          <Skeleton className="h-14 rounded-xl" />
          <Skeleton className="h-14 rounded-xl" />
          <Skeleton className="h-14 rounded-xl" />
        </div>
      ) : sortedDates.length === 0 ? (
        <EmptyState
          icon="🔍"
          title={keyword ? '검색 결과가 없습니다' : `${year}년 ${month}월 거래가 없습니다`}
        />
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

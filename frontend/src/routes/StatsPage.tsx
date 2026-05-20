import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';
import { fetchByCategory } from '../api/stats';
import type { TransactionKind } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';
import { EmptyState } from '../components/EmptyState';
import { MonthPicker } from '../components/MonthPicker';
import { fmtWon } from '../utils/format';
import { monthFromIso, monthToIso, nowYearMonth } from '../utils/date';

export default function StatsPage() {
  const initial = nowYearMonth();
  // 기간 — 시작 년월(FROM) ~ 종료 년월(TO)
  const [fromYear, setFromYear] = useState(initial.year);
  const [fromMonth, setFromMonth] = useState(initial.month);
  const [toYear, setToYear] = useState(initial.year);
  const [toMonth, setToMonth] = useState(initial.month);
  const [kind, setKind] = useState<TransactionKind>('EXPENSE');

  // FROM > TO 인 경우 자동 보정 (예: 사용자가 거꾸로 선택 시)
  const ymKey = (y: number, m: number) => y * 100 + m;
  const isReversed = ymKey(fromYear, fromMonth) > ymKey(toYear, toMonth);

  const fromIso = monthFromIso(
    isReversed ? toYear : fromYear,
    isReversed ? toMonth : fromMonth
  );
  const toIso = monthToIso(
    isReversed ? fromYear : toYear,
    isReversed ? fromMonth : toMonth
  );

  // 카테고리별 합계 — 지정 기간 + 종류
  const { data: byCategory, isLoading } = useQuery({
    queryKey: ['stats', 'byCategory', fromIso, toIso, kind],
    queryFn: () => fetchByCategory(fromIso, toIso, kind),
  });

  // 수입/지출 양쪽 합계 (요약 카드용)
  const { data: incomeByCategory } = useQuery({
    queryKey: ['stats', 'byCategory', fromIso, toIso, 'INCOME'],
    queryFn: () => fetchByCategory(fromIso, toIso, 'INCOME'),
  });
  const { data: expenseByCategory } = useQuery({
    queryKey: ['stats', 'byCategory', fromIso, toIso, 'EXPENSE'],
    queryFn: () => fetchByCategory(fromIso, toIso, 'EXPENSE'),
  });

  const totalIncome = (incomeByCategory ?? []).reduce((s, c) => s + c.amount, 0);
  const totalExpense = (expenseByCategory ?? []).reduce((s, c) => s + c.amount, 0);

  const rangeLabel = isReversed
    ? `${toYear}.${toMonth} ~ ${fromYear}.${fromMonth} (자동 보정)`
    : (fromYear === toYear && fromMonth === toMonth
        ? `${fromYear}.${fromMonth}`
        : `${fromYear}.${fromMonth} ~ ${toYear}.${toMonth}`);

  return (
    <div className="space-y-5">
      <PageHeader title="통계" />

      {/* 기간 선택 (시작/종료) */}
      <div className="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800 space-y-2">
        <div className="flex justify-center">
          <MonthPicker
            year={fromYear}
            month={fromMonth}
            onChange={(y, m) => { setFromYear(y); setFromMonth(m); }}
            label="시작"
          />
        </div>
        <div className="flex justify-center">
          <MonthPicker
            year={toYear}
            month={toMonth}
            onChange={(y, m) => { setToYear(y); setToMonth(m); }}
            label="종료"
          />
        </div>
        <div className="text-center text-xs text-slate-500 pt-1">
          기간: {rangeLabel}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="bg-white dark:bg-slate-900 rounded-xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500">총 수입</div>
          <div className="text-emerald-600 dark:text-emerald-400 font-bold text-lg mt-1">
            {fmtWon(totalIncome)}
          </div>
        </div>
        <div className="bg-white dark:bg-slate-900 rounded-xl p-4 border border-slate-100 dark:border-slate-800">
          <div className="text-xs text-slate-500">총 지출</div>
          <div className="text-rose-600 dark:text-rose-400 font-bold text-lg mt-1">
            {fmtWon(totalExpense)}
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
          <EmptyState title="해당 기간 데이터가 없습니다" />
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

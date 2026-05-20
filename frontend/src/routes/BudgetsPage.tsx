import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus } from 'lucide-react';
import { fetchBudgetProgress, upsertBudget } from '../api/budgets';
import { fetchCategories } from '../api/categories';
import { PageHeader } from '../components/PageHeader';
import { EmptyState } from '../components/EmptyState';
import { Skeleton } from '../components/Skeleton';
import { MonthPicker } from '../components/MonthPicker';
import { fmtWon, fmtNum, parseAmount } from '../utils/format';
import { nowYearMonth } from '../utils/date';

export default function BudgetsPage() {
  const qc = useQueryClient();
  const initial = nowYearMonth();
  const [year, setYear] = useState(initial.year);
  const [month, setMonth] = useState(initial.month);
  const [adding, setAdding] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['budgets', 'progress', year, month],
    queryFn: () => fetchBudgetProgress(year, month),
  });

  const { data: categories } = useQuery({
    queryKey: ['categories', 'EXPENSE'],
    queryFn: () => fetchCategories('EXPENSE'),
  });

  const upsertMut = useMutation({
    mutationFn: upsertBudget,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['budgets'] });
      setAdding(false);
    },
  });

  return (
    <div className="space-y-4">
      <PageHeader
        title="예산"
        right={
          <button
            onClick={() => setAdding(true)}
            className="bg-sky-600 text-white p-2 rounded-full"
            aria-label="예산 추가"
          >
            <Plus size={18} />
          </button>
        }
      />

      {/* 년/월 선택 */}
      <div className="flex justify-center bg-white dark:bg-slate-900 rounded-xl p-2 border border-slate-100 dark:border-slate-800">
        <MonthPicker
          year={year}
          month={month}
          onChange={(y, m) => { setYear(y); setMonth(m); }}
          showArrows
        />
      </div>

      {isLoading ? (
        <Skeleton className="h-32" />
      ) : !data || data.length === 0 ? (
        <EmptyState
          icon="🎯"
          title="설정된 예산이 없습니다"
          description="카테고리별 월 예산을 설정해 지출을 관리하세요"
          action={
            <button
              onClick={() => setAdding(true)}
              className="bg-sky-600 text-white px-4 py-2 rounded-lg text-sm font-medium"
            >
              첫 예산 추가
            </button>
          }
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

      {adding && (
        <BudgetForm
          year={year}
          month={month}
          categories={categories ?? []}
          existingIds={(data ?? []).map((b) => b.categoryId)}
          onCancel={() => setAdding(false)}
          onSave={(categoryId, amount) =>
            upsertMut.mutate({ year, month, categoryId, amount })
          }
        />
      )}
    </div>
  );
}

function BudgetForm({
  year, month, categories, existingIds, onCancel, onSave,
}: {
  year: number;
  month: number;
  categories: { id: number; name: string }[];
  existingIds: number[];
  onCancel: () => void;
  onSave: (categoryId: number, amount: number) => void;
}) {
  const [categoryId, setCategoryId] = useState<number | ''>('');
  const [amount, setAmount] = useState(0);

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white dark:bg-slate-900 rounded-2xl p-5 w-full max-w-md space-y-3">
        <h2 className="font-bold text-lg">{year}년 {month}월 예산</h2>
        <div>
          <label className="text-xs font-semibold text-slate-500">카테고리</label>
          <select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : '')}
            className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1"
          >
            <option value="">카테고리 선택...</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}{existingIds.includes(c.id) ? ' (이미 설정됨 — 갱신)' : ''}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="text-xs font-semibold text-slate-500">월 예산</label>
          <input
            type="text"
            inputMode="numeric"
            value={amount === 0 ? '' : fmtNum(amount)}
            onChange={(e) => setAmount(parseAmount(e.target.value))}
            placeholder="0"
            className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1"
          />
        </div>
        <div className="flex gap-2 pt-2">
          <button onClick={onCancel} className="flex-1 py-2 rounded-lg border border-slate-200 dark:border-slate-700">
            취소
          </button>
          <button
            onClick={() => categoryId && amount > 0 && onSave(categoryId, amount)}
            disabled={!categoryId || amount <= 0}
            className="flex-1 py-2 rounded-lg bg-sky-600 text-white font-semibold disabled:opacity-50"
          >
            저장
          </button>
        </div>
      </div>
    </div>
  );
}

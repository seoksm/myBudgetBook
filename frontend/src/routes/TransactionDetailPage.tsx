import { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Trash2 } from 'lucide-react';
import { fetchAccounts } from '../api/accounts';
import { fetchCategories } from '../api/categories';
import {
  fetchTransaction, updateTransaction, deleteTransaction, type TransactionInput,
} from '../api/transactions';
import type { TransactionKind, Category } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { AmountInput } from '../components/AmountInput';
import { CategoryGrid } from '../components/CategoryGrid';
import { Skeleton } from '../components/Skeleton';
import { toLocalIso } from '../utils/format';

export default function TransactionDetailPage() {
  const { id: idParam } = useParams<{ id: string }>();
  const id = Number(idParam);
  const navigate = useNavigate();
  const location = useLocation();
  const qc = useQueryClient();
  // TxCard 가 전달한 from 경로 (필터/검색어 포함) — 없으면 기본 /transactions
  const backTo = (location.state as { from?: string } | null)?.from || '/transactions';

  const { data, isLoading } = useQuery({
    queryKey: ['transactions', id],
    queryFn: () => fetchTransaction(id),
    enabled: !!id,
  });

  const [kind, setKind] = useState<TransactionKind>('EXPENSE');
  const [amount, setAmount] = useState(0);
  const [accountId, setAccountId] = useState<number | undefined>();
  const [category, setCategory] = useState<Category | undefined>();
  const [memo, setMemo] = useState('');
  const [occurredAt, setOccurredAt] = useState('');

  const { data: accounts } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });
  const { data: categories } = useQuery({
    queryKey: ['categories', kind],
    queryFn: () => fetchCategories(kind === 'INCOME' ? 'INCOME' : 'EXPENSE'),
    enabled: kind !== 'TRANSFER',
  });

  useEffect(() => {
    if (data) {
      setKind(data.kind);
      setAmount(data.amount);
      setAccountId(data.accountId);
      setMemo(data.memo || '');
      setOccurredAt(data.occurredAt.slice(0, 16)); // YYYY-MM-DDTHH:mm 부분만
      if (data.categoryId && categories) {
        const c = categories.find((cat) => cat.id === data.categoryId);
        if (c) setCategory(c);
      }
    }
  }, [data, categories]);

  const updateMutation = useMutation({
    mutationFn: (input: TransactionInput) => updateTransaction(id, input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
      qc.invalidateQueries({ queryKey: ['accounts'] });
      navigate(backTo, { replace: true });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: () => deleteTransaction(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
      qc.invalidateQueries({ queryKey: ['accounts'] });
      navigate(backTo, { replace: true });
    },
  });

  const submit = () => {
    if (!amount || !accountId) { alert('금액과 계좌를 입력해주세요'); return; }
    if (kind !== 'TRANSFER' && !category) { alert('카테고리를 선택해주세요'); return; }
    updateMutation.mutate({
      kind, amount, accountId,
      categoryId: category?.id,
      memo: memo || undefined,
      occurredAt: occurredAt ? occurredAt + ':00' : toLocalIso(new Date()),
    });
  };

  const handleDelete = () => {
    if (!confirm('이 거래를 삭제할까요? 계좌 잔액이 되돌려집니다.')) return;
    deleteMutation.mutate();
  };

  if (isLoading) {
    return (
      <div className="space-y-4">
        <PageHeader title="거래 상세" back />
        <Skeleton className="h-80" />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="거래 수정"
        back
        right={
          <button
            onClick={handleDelete}
            className="text-rose-600 dark:text-rose-400 p-2 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-900/30"
            aria-label="삭제"
          >
            <Trash2 size={20} />
          </button>
        }
      />

      <div className="grid grid-cols-3 gap-2 p-1 bg-slate-100 dark:bg-slate-800 rounded-xl">
        {(['EXPENSE', 'INCOME', 'TRANSFER'] as TransactionKind[]).map((k) => (
          <button
            key={k} type="button"
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

      <AmountInput value={amount} onChange={setAmount} />

      <div>
        <label className="text-xs font-semibold text-slate-500 mb-2 block">날짜·시각</label>
        <input
          type="datetime-local"
          value={occurredAt}
          onChange={(e) => setOccurredAt(e.target.value)}
          className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700
                     bg-white dark:bg-slate-900 outline-none focus:border-sky-500"
        />
      </div>

      <div>
        <label className="text-xs font-semibold text-slate-500 mb-2 block">계좌</label>
        <div className="flex flex-wrap gap-2">
          {accounts?.map((a) => (
            <button
              key={a.id} type="button"
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

      <div>
        <label className="text-xs font-semibold text-slate-500 mb-2 block">메모</label>
        <input
          type="text" value={memo} onChange={(e) => setMemo(e.target.value)}
          maxLength={200}
          className="w-full px-3 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700
                     bg-white dark:bg-slate-900 outline-none focus:border-sky-500"
        />
      </div>

      <button
        type="button" onClick={submit} disabled={updateMutation.isPending}
        className="w-full bg-sky-600 hover:bg-sky-700 text-white font-semibold py-3 rounded-xl transition disabled:opacity-50"
      >
        {updateMutation.isPending ? '저장 중...' : '수정 저장'}
      </button>
    </div>
  );
}

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { fetchAccounts } from '../api/accounts';
import { fetchCategories } from '../api/categories';
import { createTransaction, type TransactionInput } from '../api/transactions';
import { createTransfer } from '../api/transfers';
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
  const [toAccountId, setToAccountId] = useState<number | undefined>();
  const [category, setCategory] = useState<Category | undefined>();
  const [memo, setMemo] = useState('');
  const [occurredAt, setOccurredAt] = useState(() => {
    // datetime-local 포맷: YYYY-MM-DDTHH:mm
    const d = new Date();
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  });

  const { data: accounts } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });
  const depositAccounts = accounts?.filter((a) => a.type === 'DEPOSIT') ?? [];
  const selectedAccount = accounts?.find((a) => a.id === accountId);
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

  const transferMutation = useMutation({
    mutationFn: createTransfer,
    onSuccess: (saved) => {
      qc.invalidateQueries({ queryKey: ['transfers'] });
      qc.invalidateQueries({ queryKey: ['accounts'] });
      navigate(`/accounts/${saved.fromAccountId}`);
    },
  });

  const submit = () => {
    if (kind === 'TRANSFER') {
      if (!amount || !accountId || !toAccountId) {
        alert('금액, 보내는 예금, 받는 예금을 선택해주세요');
        return;
      }
      if (accountId === toAccountId) {
        alert('보내는 예금과 받는 예금은 달라야 합니다');
        return;
      }
      transferMutation.mutate({
        fromAccountId: accountId,
        toAccountId,
        amount,
        memo: memo || undefined,
        occurredAt: occurredAt ? occurredAt + ':00' : toLocalIso(new Date()),
      });
      return;
    }

    if (!amount || !accountId) {
      alert('금액과 계좌를 선택해주세요');
      return;
    }
    if (!category) {
      alert('카테고리를 선택해주세요');
      return;
    }
    mutation.mutate({
      kind, amount, accountId,
      categoryId: category?.id,
      memo: memo || undefined,
      occurredAt: occurredAt ? occurredAt + ':00' : toLocalIso(new Date()),
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
            onClick={() => {
              setKind(k);
              setCategory(undefined);
              setAccountId(undefined);
              setToAccountId(undefined);
            }}
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

      {/* 날짜·시각 */}
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

      {kind === 'TRANSFER' ? (
        <div className="grid md:grid-cols-2 gap-3">
          <div>
            <label className="text-xs font-semibold text-slate-500 mb-2 block">보내는 예금</label>
            <div className="flex flex-wrap gap-2">
              {depositAccounts.map((a) => (
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
          <div>
            <label className="text-xs font-semibold text-slate-500 mb-2 block">받는 예금</label>
            <div className="flex flex-wrap gap-2">
              {depositAccounts.map((a) => (
                <button
                  key={a.id}
                  type="button"
                  onClick={() => setToAccountId(a.id)}
                  disabled={a.id === accountId}
                  className={`px-3 py-1.5 rounded-lg text-sm border transition disabled:opacity-40 ${
                    toAccountId === a.id
                      ? 'border-sky-500 bg-sky-50 dark:bg-sky-900/30 text-sky-700 dark:text-sky-300 font-medium'
                      : 'border-slate-200 dark:border-slate-700'
                  }`}
                >
                  {a.name}
                </button>
              ))}
            </div>
          </div>
          {depositAccounts.length < 2 && (
            <div className="md:col-span-2 text-sm text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950/40 border border-amber-100 dark:border-amber-900 rounded-lg p-3">
              이체를 하려면 예금 계좌가 2개 이상 필요합니다.
            </div>
          )}
        </div>
      ) : (
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
                {a.type === 'CHECK_CARD' && a.linkedDepositAccountName && (
                  <span className="ml-1 text-[11px] text-slate-400">({a.linkedDepositAccountName})</span>
                )}
              </button>
            ))}
          </div>
          {kind === 'EXPENSE' && selectedAccount?.type === 'CHECK_CARD' && !selectedAccount.linkedDepositAccountId && (
            <div className="mt-2 text-sm text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950/40 border border-amber-100 dark:border-amber-900 rounded-lg p-3">
              체크카드 지출을 저장하려면 자산 화면에서 연결 예금을 먼저 지정해야 합니다.
            </div>
          )}
        </div>
      )}

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
        disabled={mutation.isPending || transferMutation.isPending}
        className="w-full bg-sky-600 hover:bg-sky-700 active:bg-sky-800 text-white font-semibold py-3 rounded-xl transition disabled:opacity-50"
      >
        {mutation.isPending || transferMutation.isPending ? '저장 중...' : '저장'}
      </button>
    </div>
  );
}

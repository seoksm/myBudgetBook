import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ListChecks, Plus, Pencil, Trash2 } from 'lucide-react';
import {
  fetchAccounts, createAccount, updateAccount, deleteAccount,
} from '../api/accounts';
import type { Account, AccountType } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';
import { EmptyState } from '../components/EmptyState';
import { fmtWon } from '../utils/format';
import { accountTypeLabel, isBalanceManagedAccount } from '../constants/theme';

export default function AccountsPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });

  const [editing, setEditing] = useState<Account | 'new' | null>(null);

  const invalidate = () => qc.invalidateQueries({ queryKey: ['accounts'] });

  const createMut = useMutation({
    mutationFn: createAccount,
    onSuccess: () => { invalidate(); setEditing(null); },
  });
  const updateMut = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Parameters<typeof updateAccount>[1] }) =>
      updateAccount(id, data),
    onSuccess: () => { invalidate(); setEditing(null); },
  });
  const deleteMut = useMutation({
    mutationFn: deleteAccount,
    onSuccess: invalidate,
  });

  const handleDelete = (a: Account) => {
    if (!confirm(`"${a.name}" 계좌를 삭제할까요?\n연결된 거래가 있으면 삭제 실패할 수 있습니다.`)) return;
    deleteMut.mutate(a.id);
  };

  return (
    <div className="space-y-4">
      <PageHeader
        title="자산"
        right={
          <button
            onClick={() => setEditing('new')}
            className="bg-sky-600 text-white p-2 rounded-full"
            aria-label="추가"
          >
            <Plus size={18} />
          </button>
        }
      />

      {isLoading ? (
        <Skeleton className="h-32" />
      ) : !data || data.length === 0 ? (
        <EmptyState
          icon="🏦"
          title="등록된 계좌가 없습니다"
          action={
            <button
              onClick={() => setEditing('new')}
              className="bg-sky-600 text-white px-4 py-2 rounded-lg text-sm font-medium"
            >
              첫 계좌 추가
            </button>
          }
        />
      ) : (
        <div className="space-y-2">
          {data.map((a) => (
            <div
              key={a.id}
              className="flex items-center justify-between p-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800"
            >
              <div className="flex items-center gap-3 flex-1 min-w-0">
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold flex-shrink-0"
                  style={{ background: a.color || '#94a3b8' }}
                >
                  {a.name.charAt(0)}
                </div>
                <div className="min-w-0">
                  <div className="font-medium truncate">{a.name}</div>
                  <div className="text-xs text-slate-400">
                    {accountTypeLabel[a.type]}
                    {a.type === 'CHECK_CARD' && a.linkedDepositAccountName && (
                      <span> · {a.linkedDepositAccountName} 연결</span>
                    )}
                  </div>
                </div>
              </div>
              <div className="text-right flex items-center gap-2">
                <div className="font-bold tabular-nums whitespace-nowrap">
                  {isBalanceManagedAccount(a.type) ? fmtWon(a.balance) : '잔액 미관리'}
                </div>
                <Link
                  to={`/accounts/${a.id}`}
                  className="p-1.5 rounded hover:bg-slate-100 dark:hover:bg-slate-800"
                  aria-label="내역"
                >
                  <ListChecks size={16} />
                </Link>
                <button
                  onClick={() => setEditing(a)}
                  className="p-1.5 rounded hover:bg-slate-100 dark:hover:bg-slate-800"
                  aria-label="수정"
                >
                  <Pencil size={16} />
                </button>
                <button
                  onClick={() => handleDelete(a)}
                  className="p-1.5 rounded text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-900/30"
                  aria-label="삭제"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {editing && (
        <AccountForm
          account={editing === 'new' ? null : editing}
          accounts={data ?? []}
          onCancel={() => setEditing(null)}
          onSave={(form) => {
            if (editing === 'new') {
              createMut.mutate({
                name: form.name,
                type: form.type,
                balance: isBalanceManagedAccount(form.type) ? form.balance : 0,
                color: form.color,
                linkedDepositAccountId: form.linkedDepositAccountId,
              });
            } else {
              updateMut.mutate({
                id: editing.id,
                data: {
                  name: form.name,
                  color: form.color,
                  balance: isBalanceManagedAccount(form.type) ? form.balance : undefined,
                  linkedDepositAccountId: form.linkedDepositAccountId,
                  archived: form.archived,
                },
              });
            }
          }}
        />
      )}
    </div>
  );
}

interface FormState {
  name: string;
  type: AccountType;
  balance: number;
  color: string;
  archived: boolean;
  linkedDepositAccountId?: number;
}

function AccountForm({
  account, accounts, onCancel, onSave,
}: {
  account: Account | null;
  accounts: Account[];
  onCancel: () => void;
  onSave: (data: FormState) => void;
}) {
  const depositAccounts = accounts.filter((a) => a.type === 'DEPOSIT' && a.id !== account?.id);
  const [form, setForm] = useState<FormState>({
    name: account?.name ?? '',
    type: account?.type ?? 'CASH',
    balance: account?.balance ?? 0,
    color: account?.color ?? '#0ea5e9',
    archived: account?.archived ?? false,
    linkedDepositAccountId: account?.linkedDepositAccountId,
  });

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white dark:bg-slate-900 rounded-2xl p-5 w-full max-w-md space-y-3">
        <h2 className="font-bold text-lg">{account ? '계좌 수정' : '계좌 추가'}</h2>
        <div>
          <label className="text-xs font-semibold text-slate-500">이름</label>
          <input
            type="text"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1"
            autoFocus
          />
        </div>
        <div>
          <label className="text-xs font-semibold text-slate-500">유형</label>
          <select
            value={form.type}
            disabled={!!account}
            onChange={(e) => {
              const nextType = e.target.value as AccountType;
              setForm({
                ...form,
                type: nextType,
                balance: isBalanceManagedAccount(nextType) ? form.balance : 0,
                linkedDepositAccountId: nextType === 'CHECK_CARD' ? form.linkedDepositAccountId : undefined,
              });
            }}
            className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1 disabled:opacity-50"
          >
            {Object.entries(accountTypeLabel).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </div>
        {form.type === 'CHECK_CARD' && (
          <div>
            <label className="text-xs font-semibold text-slate-500">연결 예금</label>
            <select
              value={form.linkedDepositAccountId ?? ''}
              onChange={(e) => setForm({
                ...form,
                linkedDepositAccountId: e.target.value ? Number(e.target.value) : undefined,
              })}
              className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1"
            >
              <option value="">선택 안 함</option>
              {depositAccounts.map((a) => (
                <option key={a.id} value={a.id}>{a.name}</option>
              ))}
            </select>
            <div className="text-[11px] text-slate-500 mt-1">
              체크카드 지출은 선택한 예금 계좌 잔액에서 출금됩니다.
            </div>
          </div>
        )}
        {isBalanceManagedAccount(form.type) && (
          <div>
            <label className="text-xs font-semibold text-slate-500">{account ? '현재 잔액' : '초기 잔액'}</label>
            <input
              type="number"
              value={form.balance}
              onChange={(e) => setForm({ ...form, balance: Number(e.target.value) })}
              className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1"
            />
            {account && (
              <div className="text-[11px] text-slate-500 mt-1">
                거래 수정 오류 등으로 잔액이 어긋났을 때 실제 잔액으로 보정할 수 있습니다.
              </div>
            )}
          </div>
        )}
        {!isBalanceManagedAccount(form.type) && (
          <div className="rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 p-3 text-sm text-slate-600 dark:text-slate-300">
            체크카드와 신용카드는 잔액을 직접 관리하지 않습니다. 카드 사용 내역은 거래로 기록되고, 체크카드는 연결 예금에서 출금됩니다.
          </div>
        )}
        <div>
          <label className="text-xs font-semibold text-slate-500">색상</label>
          <input
            type="color"
            value={form.color}
            onChange={(e) => setForm({ ...form, color: e.target.value })}
            className="w-full h-10 rounded-lg border border-slate-200 dark:border-slate-700 mt-1"
          />
        </div>
        <div className="flex gap-2 pt-2">
          <button onClick={onCancel} className="flex-1 py-2 rounded-lg border border-slate-200 dark:border-slate-700">
            취소
          </button>
          <button
            onClick={() => onSave(form)}
            disabled={!form.name.trim()}
            className="flex-1 py-2 rounded-lg bg-sky-600 text-white font-semibold disabled:opacity-50"
          >
            저장
          </button>
        </div>
      </div>
    </div>
  );
}

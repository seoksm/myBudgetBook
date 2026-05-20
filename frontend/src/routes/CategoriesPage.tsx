import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import {
  fetchCategories, createCategory, updateCategory, deleteCategory,
} from '../api/categories';
import type { Category, CategoryKind } from '../api/types';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';

export default function CategoriesPage() {
  const qc = useQueryClient();
  const [kind, setKind] = useState<CategoryKind>('EXPENSE');
  const [editing, setEditing] = useState<Category | 'new' | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['categories', kind],
    queryFn: () => fetchCategories(kind),
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ['categories'] });

  const createMut = useMutation({
    mutationFn: createCategory,
    onSuccess: () => { invalidate(); setEditing(null); },
  });
  const updateMut = useMutation({
    mutationFn: ({ id, data }: { id: number; data: Parameters<typeof updateCategory>[1] }) =>
      updateCategory(id, data),
    onSuccess: () => { invalidate(); setEditing(null); },
  });
  const deleteMut = useMutation({
    mutationFn: deleteCategory,
    onSuccess: invalidate,
  });

  const handleDelete = (c: Category) => {
    if (!confirm(`"${c.name}" 카테고리를 삭제할까요?\n연결된 거래가 있으면 실패할 수 있습니다.`)) return;
    deleteMut.mutate(c.id);
  };

  return (
    <div className="space-y-4">
      <PageHeader
        title="카테고리"
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
            <div
              key={c.id}
              className="relative flex flex-col items-center p-3 bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800"
            >
              <div
                className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold mb-1"
                style={{ background: c.color || '#64748b' }}
              >
                {c.name.charAt(0)}
              </div>
              <div className="text-xs text-center">{c.name}</div>
              <div className="absolute top-1 right-1 flex flex-col gap-1">
                <button
                  onClick={() => setEditing(c)}
                  className="p-1 rounded bg-slate-100 dark:bg-slate-800 hover:bg-slate-200"
                  aria-label="수정"
                >
                  <Pencil size={11} />
                </button>
                <button
                  onClick={() => handleDelete(c)}
                  className="p-1 rounded text-rose-600 bg-rose-50 dark:bg-rose-900/30 hover:bg-rose-100"
                  aria-label="삭제"
                >
                  <Trash2 size={11} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {editing && (
        <CategoryForm
          category={editing === 'new' ? null : editing}
          defaultKind={kind}
          onCancel={() => setEditing(null)}
          onSave={(form) => {
            if (editing === 'new') {
              createMut.mutate({
                name: form.name,
                kind: form.kind,
                icon: form.icon || undefined,
                color: form.color,
              });
            } else {
              updateMut.mutate({
                id: editing.id,
                data: {
                  name: form.name,
                  icon: form.icon || undefined,
                  color: form.color,
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
  kind: CategoryKind;
  icon: string;
  color: string;
  archived: boolean;
}

function CategoryForm({
  category, defaultKind, onCancel, onSave,
}: {
  category: Category | null;
  defaultKind: CategoryKind;
  onCancel: () => void;
  onSave: (data: FormState) => void;
}) {
  const [form, setForm] = useState<FormState>({
    name: category?.name ?? '',
    kind: category?.kind ?? defaultKind,
    icon: category?.icon ?? '',
    color: category?.color ?? '#ef4444',
    archived: category?.archived ?? false,
  });

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center p-4 z-50">
      <div className="bg-white dark:bg-slate-900 rounded-2xl p-5 w-full max-w-md space-y-3">
        <h2 className="font-bold text-lg">{category ? '카테고리 수정' : '카테고리 추가'}</h2>
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
          <label className="text-xs font-semibold text-slate-500">종류</label>
          <select
            value={form.kind}
            disabled={!!category}
            onChange={(e) => setForm({ ...form, kind: e.target.value as CategoryKind })}
            className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 mt-1 disabled:opacity-50"
          >
            <option value="EXPENSE">지출</option>
            <option value="INCOME">수입</option>
          </select>
        </div>
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

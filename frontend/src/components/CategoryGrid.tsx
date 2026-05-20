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

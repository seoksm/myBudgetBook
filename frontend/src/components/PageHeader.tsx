import { useNavigate } from 'react-router-dom';
import { ChevronLeft } from 'lucide-react';
import type { ReactNode } from 'react';

interface Props {
  title: string;
  back?: boolean;
  right?: ReactNode;
}

export function PageHeader({ title, back, right }: Props) {
  const navigate = useNavigate();
  return (
    <div className="flex items-center justify-between gap-3 mb-5">
      <div className="flex items-center gap-2 min-w-0">
        {back && (
          <button
            onClick={() => navigate(-1)}
            className="p-2 -ml-2 rounded-lg hover:bg-white dark:hover:bg-slate-900 border border-transparent hover:border-slate-200 dark:hover:border-slate-800"
          >
            <ChevronLeft size={24} />
          </button>
        )}
        <h1 className="text-xl md:text-2xl font-bold tracking-tight truncate">{title}</h1>
      </div>
      {right && <div className="shrink-0">{right}</div>}
    </div>
  );
}

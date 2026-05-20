import type { ReactNode } from 'react';

interface Props {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}

export function EmptyState({ icon, title, description, action }: Props) {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="text-5xl mb-3 text-slate-300 dark:text-slate-600">
        {icon || '📭'}
      </div>
      <div className="font-semibold text-slate-700 dark:text-slate-200">{title}</div>
      {description && (
        <div className="text-sm text-slate-500 mt-1">{description}</div>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

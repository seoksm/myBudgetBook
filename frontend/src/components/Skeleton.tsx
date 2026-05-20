export function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={`animate-pulse bg-slate-200 dark:bg-slate-800 rounded ${className || 'h-4 w-full'}`}
    />
  );
}

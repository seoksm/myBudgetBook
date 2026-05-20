import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { fetchCalendar } from '../api/stats';
import { PageHeader } from '../components/PageHeader';
import { Skeleton } from '../components/Skeleton';
import { fmtWon } from '../utils/format';

export default function CalendarPage() {
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);

  const { data, isLoading } = useQuery({
    queryKey: ['calendar', year, month],
    queryFn: () => fetchCalendar(year, month),
  });

  const prev = () => {
    if (month === 1) { setYear(y => y - 1); setMonth(12); }
    else setMonth(m => m - 1);
  };
  const next = () => {
    if (month === 12) { setYear(y => y + 1); setMonth(1); }
    else setMonth(m => m + 1);
  };

  // 캘린더 그리드 생성
  const firstDay = new Date(year, month - 1, 1).getDay();
  const lastDate = new Date(year, month, 0).getDate();
  const cells: (number | null)[] = [
    ...Array(firstDay).fill(null),
    ...Array.from({ length: lastDate }, (_, i) => i + 1),
  ];

  const dayMap = new Map(data?.days.map((d) => [d.date, d]) ?? []);

  return (
    <div className="space-y-4">
      <PageHeader title="달력" />

      <div className="flex items-center justify-between bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800">
        <button onClick={prev} className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">
          <ChevronLeft size={20} />
        </button>
        <div className="font-bold">{year}년 {month}월</div>
        <button onClick={next} className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800">
          <ChevronRight size={20} />
        </button>
      </div>

      {isLoading ? (
        <Skeleton className="h-96 rounded-xl" />
      ) : (
        <>
          <div className="grid grid-cols-7 gap-px bg-slate-200 dark:bg-slate-800 rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800">
            {['일', '월', '화', '수', '목', '금', '토'].map((d, i) => (
              <div key={d} className={`bg-slate-50 dark:bg-slate-900 text-center text-xs py-2 font-semibold ${
                i === 0 ? 'text-rose-500' : i === 6 ? 'text-sky-500' : 'text-slate-600 dark:text-slate-400'
              }`}>{d}</div>
            ))}
            {cells.map((day, i) => {
              if (!day) return <div key={i} className="bg-white dark:bg-slate-900 min-h-[68px]" />;
              const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
              const info = dayMap.get(dateStr);
              const dow = (firstDay + day - 1) % 7;
              return (
                <div key={i} className="bg-white dark:bg-slate-900 min-h-[68px] p-1.5 text-[10px]">
                  <div className={`font-semibold ${dow === 0 ? 'text-rose-500' : dow === 6 ? 'text-sky-500' : ''}`}>
                    {day}
                  </div>
                  {info && (
                    <>
                      {info.income > 0 && <div className="text-emerald-600 dark:text-emerald-400">+{fmtWon(info.income, '')}</div>}
                      {info.expense > 0 && <div className="text-rose-600 dark:text-rose-400">-{fmtWon(info.expense, '')}</div>}
                    </>
                  )}
                </div>
              );
            })}
          </div>

          <div className="grid grid-cols-2 gap-3 text-sm">
            <div className="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800">
              <div className="text-xs text-slate-500">이달 수입</div>
              <div className="text-emerald-600 dark:text-emerald-400 font-bold mt-1">
                {fmtWon(data?.totalIncome ?? 0)}
              </div>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-xl p-3 border border-slate-100 dark:border-slate-800">
              <div className="text-xs text-slate-500">이달 지출</div>
              <div className="text-rose-600 dark:text-rose-400 font-bold mt-1">
                {fmtWon(data?.totalExpense ?? 0)}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

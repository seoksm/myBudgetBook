import { ChevronLeft, ChevronRight } from 'lucide-react';

interface Props {
  year: number;
  month: number;
  onChange: (year: number, month: number) => void;
  /** 기간 선택용 라벨 (예: "시작", "종료"). 단일 선택 시 undefined. */
  label?: string;
  /** 좌우 ◀ ▶ 빠른 이동 버튼 노출 (단일 선택용) */
  showArrows?: boolean;
}

/**
 * 년/월 선택 공용 컴포넌트.
 *
 * - 모바일에서도 잘 동작하는 native select 사용
 * - showArrows=true 인 경우 좌우 화살표로 월 이동
 */
export function MonthPicker({ year, month, onChange, label, showArrows }: Props) {
  const now = new Date();
  const currentYear = now.getFullYear();
  // 현재년도 기준 ±5년 (-5 ~ +1)
  const years = Array.from({ length: 7 }, (_, i) => currentYear - 5 + i);

  const prev = () => {
    if (month === 1) onChange(year - 1, 12);
    else onChange(year, month - 1);
  };
  const next = () => {
    if (month === 12) onChange(year + 1, 1);
    else onChange(year, month + 1);
  };

  return (
    <div className="flex items-center gap-2">
      {label && <span className="text-xs font-semibold text-slate-500 shrink-0">{label}</span>}

      {showArrows && (
        <button
          onClick={prev}
          className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
          aria-label="이전 달"
        >
          <ChevronLeft size={18} />
        </button>
      )}

      <select
        value={year}
        onChange={(e) => onChange(Number(e.target.value), month)}
        className="px-2 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-sm"
      >
        {years.map((y) => (
          <option key={y} value={y}>{y}년</option>
        ))}
      </select>

      <select
        value={month}
        onChange={(e) => onChange(year, Number(e.target.value))}
        className="px-2 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-sm"
      >
        {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
          <option key={m} value={m}>{m}월</option>
        ))}
      </select>

      {showArrows && (
        <button
          onClick={next}
          className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
          aria-label="다음 달"
        >
          <ChevronRight size={18} />
        </button>
      )}
    </div>
  );
}

import { Link, useLocation } from 'react-router-dom';
import type { Transaction } from '../api/types';
import { fmtWon, fmtTime } from '../utils/format';
import { kindColors } from '../constants/theme';

export function TxCard({ tx }: { tx: Transaction }) {
  const sign = tx.kind === 'INCOME' ? '+' : tx.kind === 'EXPENSE' ? '-' : '';
  const location = useLocation();
  // 현재 페이지의 검색 파라미터를 state.from 으로 전달 → 상세에서 돌아갈 때 그대로 복원
  const fromPath = location.pathname + location.search;
  return (
    <Link
      to={`/transactions/${tx.id}`}
      state={{ from: fromPath }}
      className="flex items-center gap-3 p-4 rounded-lg bg-white dark:bg-slate-900
                 border border-slate-200/80 dark:border-slate-800 shadow-sm
                 hover:border-sky-200 dark:hover:border-sky-900 hover:shadow-md transition"
    >
      <div className="flex-1 min-w-0">
        <div className="flex items-baseline gap-2">
          <span className="font-semibold text-sm truncate">{tx.categoryName || '미분류'}</span>
          <span className="text-[11px] text-slate-400">{fmtTime(tx.occurredAt)}</span>
        </div>
        <div className="text-xs text-slate-500 truncate mt-0.5">
          {tx.memo || tx.accountName}
        </div>
      </div>
      <div className={`text-right shrink-0 ${kindColors[tx.kind]}`}>
        <div className="font-bold tabular-nums whitespace-nowrap">{sign}{fmtWon(tx.amount, '')}</div>
        <div className="text-[10px] text-slate-400">{tx.accountName}</div>
      </div>
    </Link>
  );
}

import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Sparkles, CheckCircle2, AlertCircle } from 'lucide-react';
import { parseSms, type SmsParseResult } from '../api/sms';
import { fetchAccounts } from '../api/accounts';
import { createTransaction } from '../api/transactions';
import { PageHeader } from '../components/PageHeader';
import { EmptyState } from '../components/EmptyState';
import { fmtWon, fmtDateKo, fmtTime } from '../utils/format';

interface ParsedRow extends SmsParseResult {
  selected: boolean;
  accountId?: number;
  categoryId?: number;
}

export default function SmsPage() {
  const qc = useQueryClient();
  const [text, setText] = useState('');
  const [rows, setRows] = useState<ParsedRow[]>([]);
  const [failed, setFailed] = useState<string[]>([]);
  const [savedCount, setSavedCount] = useState(0);

  const { data: accounts } = useQuery({ queryKey: ['accounts'], queryFn: fetchAccounts });
  const defaultAccountId = accounts?.[0]?.id;

  const parseMutation = useMutation({
    mutationFn: parseSms,
    onSuccess: (res) => {
      setRows(res.results.map((r) => ({
        ...r,
        selected: true,
        accountId: defaultAccountId,
        categoryId: r.suggestedCategoryId ?? undefined,
      })));
      setFailed(res.failed);
      setSavedCount(0);
    },
  });

  const saveMutation = useMutation({
    mutationFn: async (selectedRows: ParsedRow[]) => {
      let saved = 0;
      for (const r of selectedRows) {
        if (!r.accountId) continue;
        await createTransaction({
          kind: 'EXPENSE',
          amount: r.amount,
          accountId: r.accountId,
          categoryId: r.categoryId,
          memo: r.storeName ?? undefined,
          occurredAt: r.occurredAt,
        });
        saved++;
      }
      return saved;
    },
    onSuccess: (saved) => {
      setSavedCount(saved);
      setRows([]);
      setText('');
      qc.invalidateQueries({ queryKey: ['transactions'] });
      qc.invalidateQueries({ queryKey: ['accounts'] });
      qc.invalidateQueries({ queryKey: ['stats'] });
    },
  });

  const selectedCount = rows.filter((r) => r.selected).length;

  const toggleRow = (idx: number) => {
    setRows((rs) => rs.map((r, i) => i === idx ? { ...r, selected: !r.selected } : r));
  };

  const toggleAll = () => {
    const allSelected = rows.every((r) => r.selected);
    setRows((rs) => rs.map((r) => ({ ...r, selected: !allSelected })));
  };

  return (
    <div className="space-y-4">
      <PageHeader title="SMS 붙여넣기" />

      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-100 dark:border-slate-800 p-4 space-y-3">
        <div className="text-xs text-slate-500">
          카드사 결제 SMS 를 그대로 복사 → 붙여넣기. 여러 건도 한 번에 가능합니다.
        </div>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          rows={6}
          placeholder={`예) [Web발신] KB국민카드(1234) 12,300원 일시불 12/05 14:23 스타벅스\n     신한카드 승인 홍길동 5,500원(일시불) 05/17 12:34 GS25`}
          className="w-full px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700
                     bg-slate-50 dark:bg-slate-800/50 font-mono text-xs outline-none focus:border-sky-500
                     placeholder:text-slate-300 dark:placeholder:text-slate-600"
        />
        <button
          onClick={() => parseMutation.mutate(text)}
          disabled={!text.trim() || parseMutation.isPending}
          className="w-full bg-sky-600 hover:bg-sky-700 disabled:opacity-50 text-white font-medium py-2.5 rounded-lg flex items-center justify-center gap-2"
        >
          <Sparkles size={16} />
          {parseMutation.isPending ? '파싱 중...' : '파싱하기'}
        </button>
      </div>

      {savedCount > 0 && (
        <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-900/30 border border-emerald-200 dark:border-emerald-700 rounded-lg text-sm">
          <CheckCircle2 size={18} className="text-emerald-600 dark:text-emerald-400" />
          <span>{savedCount}개 거래 저장 완료</span>
        </div>
      )}

      {rows.length > 0 && (
        <>
          <div className="flex items-center justify-between">
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input
                type="checkbox"
                checked={rows.every((r) => r.selected)}
                onChange={toggleAll}
                className="w-4 h-4 accent-sky-600"
              />
              <span>전체 선택 ({selectedCount}/{rows.length})</span>
            </label>
            <button
              onClick={() => saveMutation.mutate(rows.filter((r) => r.selected))}
              disabled={selectedCount === 0 || saveMutation.isPending}
              className="bg-sky-600 hover:bg-sky-700 disabled:opacity-50 text-white text-sm font-medium px-4 py-2 rounded-lg"
            >
              {saveMutation.isPending ? '저장 중...' : `${selectedCount}건 저장`}
            </button>
          </div>

          <div className="space-y-2">
            {rows.map((r, i) => (
              <div
                key={i}
                className={`p-3 rounded-xl border-2 transition ${
                  r.selected
                    ? 'border-sky-500 bg-sky-50/30 dark:bg-sky-900/10'
                    : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 opacity-60'
                }`}
              >
                <div className="flex items-start gap-3">
                  <input
                    type="checkbox"
                    checked={r.selected}
                    onChange={() => toggleRow(i)}
                    className="w-5 h-5 mt-1 accent-sky-600 flex-shrink-0"
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between items-baseline gap-2">
                      <div className="font-semibold truncate">{r.storeName || '(가맹점 미상)'}</div>
                      <div className="text-rose-600 dark:text-rose-400 font-bold">
                        -{fmtWon(r.amount)}
                      </div>
                    </div>
                    <div className="text-xs text-slate-500 mt-0.5">
                      {fmtDateKo(r.occurredAt)} {fmtTime(r.occurredAt)} · {r.cardName}
                      {r.installmentMonths && ` · ${r.installmentMonths}개월 할부`}
                    </div>

                    <div className="grid grid-cols-2 gap-2 mt-2">
                      <select
                        value={r.accountId || ''}
                        onChange={(e) => {
                          const v = e.target.value ? Number(e.target.value) : undefined;
                          setRows((rs) => rs.map((row, idx) => idx === i ? { ...row, accountId: v } : row));
                        }}
                        className="text-xs px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900"
                      >
                        <option value="">계좌 선택...</option>
                        {accounts?.map((a) => (
                          <option key={a.id} value={a.id}>{a.name}</option>
                        ))}
                      </select>
                      <div className="text-xs px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 text-slate-600 dark:text-slate-300 truncate">
                        {r.suggestedCategoryName || '(카테고리 미지정)'}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {failed.length > 0 && (
        <div className="bg-amber-50 dark:bg-amber-900/30 border border-amber-200 dark:border-amber-700 rounded-xl p-3">
          <div className="flex items-center gap-2 text-amber-700 dark:text-amber-300 text-sm font-semibold mb-2">
            <AlertCircle size={16} /> 파싱 실패 {failed.length}건
          </div>
          <div className="space-y-1 text-xs font-mono text-slate-600 dark:text-slate-400">
            {failed.map((f, i) => <div key={i}>· {f}</div>)}
          </div>
          <div className="text-[11px] text-slate-500 mt-2">
            카드사 패턴이 시드에 없거나, 형식이 달라서 인식되지 않은 SMS입니다.
            정규식은 H2 콘솔 SMS_PARSER_RULES 테이블에서 추가/수정할 수 있습니다.
          </div>
        </div>
      )}

      {rows.length === 0 && failed.length === 0 && !parseMutation.isPending && (
        <EmptyState
          icon="📱"
          title="아직 파싱 결과가 없습니다"
          description="위에 카드 SMS를 붙여넣고 '파싱하기' 를 눌러주세요. KB국민/신한/삼성/현대/롯데/우리/하나/BC 8개 카드사 지원."
        />
      )}
    </div>
  );
}

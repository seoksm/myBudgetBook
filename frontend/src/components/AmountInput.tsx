import { fmtNum, parseAmount } from '../utils/format';

interface Props {
  value: number;
  onChange: (n: number) => void;
  className?: string;
  placeholder?: string;
  autoFocus?: boolean;
}

export function AmountInput({ value, onChange, className, placeholder, autoFocus }: Props) {
  return (
    <div className={`relative ${className || ''}`}>
      <input
        type="text"
        inputMode="numeric"
        value={value === 0 ? '' : fmtNum(value)}
        onChange={(e) => onChange(parseAmount(e.target.value))}
        placeholder={placeholder || '0'}
        autoFocus={autoFocus}
        className="w-full text-3xl font-bold text-right py-3 pl-4 pr-12 bg-transparent
                   border-b-2 border-slate-200 dark:border-slate-700
                   focus:border-sky-500 outline-none"
      />
      <span className="absolute right-4 bottom-3 text-slate-400 text-base pointer-events-none">
        원
      </span>
    </div>
  );
}

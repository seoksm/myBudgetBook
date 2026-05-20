import { format, parseISO } from 'date-fns';
import { ko } from 'date-fns/locale';

/** 1234567 → "1,234,567원" */
export const fmtWon = (n: number, suffix = '원') =>
  new Intl.NumberFormat('ko-KR').format(n) + suffix;

/** 1234567 → "1,234,567" (단위 없음) */
export const fmtNum = (n: number) =>
  new Intl.NumberFormat('ko-KR').format(n);

/** "12000" → 12000 (콤마 제거) */
export const parseAmount = (s: string): number => {
  const n = parseInt(s.replace(/[^\d-]/g, ''), 10);
  return isNaN(n) ? 0 : n;
};

/** ISO 문자열 → "5월 17일 화" */
export const fmtDateKo = (iso: string, pattern = 'M월 d일 EEE') =>
  format(parseISO(iso), pattern, { locale: ko });

/** ISO 문자열 → "14:23" */
export const fmtTime = (iso: string) =>
  format(parseISO(iso), 'HH:mm');

/** Date → "2026-05-17T12:00:00" */
export const toLocalIso = (d: Date): string => {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
};

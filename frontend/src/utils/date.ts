import { startOfMonth, endOfMonth } from 'date-fns';
import { toLocalIso } from './format';

/** YYYY-MM 의 첫 날 ISO */
export const monthFromIso = (year: number, month: number): string => {
  const d = startOfMonth(new Date(year, month - 1, 1));
  return toLocalIso(d);
};

/** YYYY-MM 의 마지막 날 23:59 ISO */
export const monthToIso = (year: number, month: number): string => {
  const d = endOfMonth(new Date(year, month - 1, 1));
  d.setHours(23, 59, 59);
  return toLocalIso(d);
};

/** 현재 년/월 */
export const nowYearMonth = (): { year: number; month: number } => {
  const d = new Date();
  return { year: d.getFullYear(), month: d.getMonth() + 1 };
};

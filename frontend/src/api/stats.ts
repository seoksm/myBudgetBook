import { apiClient } from './client';
import type { MonthlySummary, CategoryBreakdown, CalendarMonth, TransactionKind } from './types';

export const fetchMonthly = (year: number, month: number) =>
  apiClient.get<MonthlySummary>('/stats/monthly', { params: { year, month } }).then((r) => r.data);

export const fetchByCategory = (from: string, to: string, kind: TransactionKind = 'EXPENSE') =>
  apiClient.get<CategoryBreakdown[]>('/stats/by-category', {
    params: { from, to, kind }
  }).then((r) => r.data);

export const fetchCalendar = (year: number, month: number) =>
  apiClient.get<CalendarMonth>('/stats/calendar', { params: { year, month } }).then((r) => r.data);

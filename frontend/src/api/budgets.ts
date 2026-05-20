import { apiClient } from './client';
import type { Budget, BudgetProgress } from './types';

export const fetchBudgets = (year: number, month: number) =>
  apiClient.get<Budget[]>('/budgets', { params: { year, month } }).then((r) => r.data);

export const upsertBudget = (data: {
  year: number;
  month: number;
  categoryId: number;
  amount: number;
}) => apiClient.post<Budget>('/budgets', data).then((r) => r.data);

export const fetchBudgetProgress = (year: number, month: number) =>
  apiClient.get<BudgetProgress[]>('/budgets/progress', { params: { year, month } }).then((r) => r.data);

export const deleteBudget = (id: number) =>
  apiClient.delete(`/budgets/${id}`);

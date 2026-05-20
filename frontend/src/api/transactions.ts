import { apiClient } from './client';
import type { Transaction, TransactionKind } from './types';

export interface TransactionFilter {
  from: string;
  to: string;
  accountId?: number;
  categoryId?: number;
}

export const fetchTransactions = (filter: TransactionFilter) =>
  apiClient.get<Transaction[]>('/transactions', { params: filter }).then((r) => r.data);

export const searchTransactions = (q: string) =>
  apiClient.get<Transaction[]>('/transactions/search', { params: { q } }).then((r) => r.data);

export const fetchTransaction = (id: number) =>
  apiClient.get<Transaction>(`/transactions/${id}`).then((r) => r.data);

export interface TransactionInput {
  kind: TransactionKind;
  amount: number;
  accountId: number;
  categoryId?: number;
  memo?: string;
  occurredAt: string;
  tags?: string[];
}

export const createTransaction = (data: TransactionInput) =>
  apiClient.post<Transaction>('/transactions', data).then((r) => r.data);

export const updateTransaction = (id: number, data: TransactionInput) =>
  apiClient.put<Transaction>(`/transactions/${id}`, data).then((r) => r.data);

export const deleteTransaction = (id: number) =>
  apiClient.delete(`/transactions/${id}`);

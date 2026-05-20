import { apiClient } from './client';

export interface Transfer {
  id: number;
  fromAccountId: number;
  fromAccountName: string;
  toAccountId: number;
  toAccountName: string;
  amount: number;
  occurredAt: string;
  memo?: string;
}

export const fetchTransfers = (from: string, to: string) =>
  apiClient.get<Transfer[]>('/transfers', { params: { from, to } }).then((r) => r.data);

export const createTransfer = (data: {
  fromAccountId: number;
  toAccountId: number;
  amount: number;
  occurredAt: string;
  memo?: string;
}) => apiClient.post<Transfer>('/transfers', data).then((r) => r.data);

export const deleteTransfer = (id: number) =>
  apiClient.delete(`/transfers/${id}`);

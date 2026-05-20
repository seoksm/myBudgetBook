import { apiClient } from './client';
import type { Account, AccountActivity, AccountType } from './types';

export const fetchAccounts = () =>
  apiClient.get<Account[]>('/accounts').then((r) => r.data);

export const fetchAccount = (id: number) =>
  apiClient.get<Account>(`/accounts/${id}`).then((r) => r.data);

export const fetchAccountActivities = (id: number, from: string, to: string) =>
  apiClient.get<AccountActivity[]>(`/accounts/${id}/activities`, { params: { from, to } }).then((r) => r.data);

export const createAccount = (data: {
  name: string;
  type: AccountType;
  balance?: number;
  color?: string;
  linkedDepositAccountId?: number;
}) => apiClient.post<Account>('/accounts', data).then((r) => r.data);

export const updateAccount = (id: number, data: {
  name: string;
  color?: string;
  archived?: boolean;
  linkedDepositAccountId?: number;
}) =>
  apiClient.put<Account>(`/accounts/${id}`, data).then((r) => r.data);

export const deleteAccount = (id: number) =>
  apiClient.delete(`/accounts/${id}`);

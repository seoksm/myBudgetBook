import { apiClient } from './client';
import type { Category, CategoryKind } from './types';

export const fetchCategories = (kind?: CategoryKind) =>
  apiClient.get<Category[]>('/categories', { params: { kind } }).then((r) => r.data);

export const createCategory = (data: {
  name: string;
  kind: CategoryKind;
  parentId?: number;
  icon?: string;
  color?: string;
}) => apiClient.post<Category>('/categories', data).then((r) => r.data);

export const updateCategory = (id: number, data: {
  name: string;
  icon?: string;
  color?: string;
  archived?: boolean;
}) => apiClient.put<Category>(`/categories/${id}`, data).then((r) => r.data);

export const deleteCategory = (id: number) =>
  apiClient.delete(`/categories/${id}`);

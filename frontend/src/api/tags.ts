import { apiClient } from './client';

export interface Tag { id: number; name: string; color?: string; }

export const fetchTags = () =>
  apiClient.get<Tag[]>('/tags').then((r) => r.data);

export const createTag = (data: { name: string; color?: string }) =>
  apiClient.post<Tag>('/tags', data).then((r) => r.data);

export const deleteTag = (id: number) =>
  apiClient.delete(`/tags/${id}`);

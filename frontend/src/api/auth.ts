import { apiClient } from './client';
import type { AuthUser } from '../stores/authStore';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest extends LoginRequest {
  displayName: string;
}

export interface AuthResponse {
  token: string;
  user: AuthUser;
}

export const login = (data: LoginRequest) =>
  apiClient.post<AuthResponse>('/auth/login', data).then((r) => r.data);

export const register = (data: RegisterRequest) =>
  apiClient.post<AuthResponse>('/auth/register', data).then((r) => r.data);

export const fetchMe = () =>
  apiClient.get<AuthUser>('/auth/me').then((r) => r.data);

export const logout = () =>
  apiClient.post<void>('/auth/logout').then((r) => r.data);

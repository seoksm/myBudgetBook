import { apiClient } from './client';

export interface SmsParseResult {
  raw: string;
  cardName: string;
  amount: number;
  storeName: string | null;
  occurredAt: string;
  installmentMonths: number | null;
  suggestedCategoryId: number | null;
  suggestedCategoryName: string | null;
}

export interface SmsParseResponse {
  totalLines: number;
  parsedCount: number;
  failedCount: number;
  results: SmsParseResult[];
  failed: string[];
}

export const parseSms = (text: string) =>
  apiClient.post<SmsParseResponse>('/sms/parse', { text }).then((r) => r.data);

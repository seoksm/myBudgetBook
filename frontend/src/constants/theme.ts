import type { AccountType } from '../api/types';

/** 거래 종류별 강조 색 (Tailwind 클래스명) */
export const kindColors = {
  INCOME: 'text-emerald-600 dark:text-emerald-400',
  EXPENSE: 'text-rose-600 dark:text-rose-400',
  TRANSFER: 'text-sky-600 dark:text-sky-400',
} as const;

/** 계좌 유형별 한국어 라벨 + 색상 */
export const accountTypeLabel = {
  CASH: '현금',
  DEPOSIT: '예금',
  CHECK_CARD: '체크카드',
  CREDIT_CARD: '신용카드',
  INVESTMENT: '투자',
  LOAN: '대출',
} as const;

export const isBalanceManagedAccount = (type: AccountType) =>
  type !== 'CHECK_CARD' && type !== 'CREDIT_CARD';

export type AccountType = 'CASH' | 'DEPOSIT' | 'CHECK_CARD' | 'CREDIT_CARD' | 'INVESTMENT' | 'LOAN';
export type CategoryKind = 'INCOME' | 'EXPENSE';
export type TransactionKind = 'INCOME' | 'EXPENSE' | 'TRANSFER';
export type TransactionSource = 'MANUAL' | 'SMS' | 'RECURRING';

export interface Account {
  id: number;
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  color?: string;
  statementDay?: number;
  paymentDay?: number;
  linkedDepositAccountId?: number;
  linkedDepositAccountName?: string;
  sortOrder: number;
  archived: boolean;
  createdAt: string;
}

export interface AccountActivity {
  sourceType: 'TRANSACTION' | 'TRANSFER';
  sourceId: number;
  kind: 'INCOME' | 'EXPENSE' | 'TRANSFER_IN' | 'TRANSFER_OUT' | 'TRANSFER';
  amount: number;
  title: string;
  subtitle: string;
  memo?: string;
  occurredAt: string;
  relatedAccountId?: number;
  relatedAccountName?: string;
}

export interface Category {
  id: number;
  name: string;
  kind: CategoryKind;
  parentId?: number;
  icon?: string;
  color?: string;
  sortOrder: number;
  archived: boolean;
}

export interface Transaction {
  id: number;
  kind: TransactionKind;
  amount: number;
  accountId: number;
  accountName: string;
  balanceAccountId?: number;
  balanceAccountName?: string;
  categoryId?: number;
  categoryName?: string;
  memo?: string;
  occurredAt: string;
  source: TransactionSource;
  installmentMonths?: number;
  installmentSeq?: number;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

export interface MonthlySummary {
  year: number;
  month: number;
  totalIncome: number;
  totalExpense: number;
  net: number;
  transactionCount: number;
}

export interface CategoryBreakdown {
  categoryId: number;
  name: string;
  color: string;
  amount: number;
  percentage: number;
}

export interface CalendarDay {
  date: string;
  income: number;
  expense: number;
}

export interface CalendarMonth {
  year: number;
  month: number;
  days: CalendarDay[];
  totalIncome: number;
  totalExpense: number;
}

export interface Budget {
  id: number;
  year: number;
  month: number;
  categoryId: number;
  categoryName: string;
  amount: number;
}

export interface BudgetProgress {
  categoryId: number;
  categoryName: string;
  color?: string;
  budgetAmount: number;
  spentAmount: number;
  percentage: number;
}

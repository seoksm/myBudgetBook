import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppLayout } from './components/AppLayout';
import { InstallBanner } from './components/InstallBanner';
import { ProtectedRoute } from './components/ProtectedRoute';
import HomePage from './routes/HomePage';
import TransactionsPage from './routes/TransactionsPage';
import AddTransactionPage from './routes/AddTransactionPage';
import TransactionDetailPage from './routes/TransactionDetailPage';
import CalendarPage from './routes/CalendarPage';
import StatsPage from './routes/StatsPage';
import BudgetsPage from './routes/BudgetsPage';
import AccountsPage from './routes/AccountsPage';
import AccountDetailPage from './routes/AccountDetailPage';
import CategoriesPage from './routes/CategoriesPage';
import SettingsPage from './routes/SettingsPage';
import SmsPage from './routes/SmsPage';
import LoginPage from './routes/LoginPage';
import { useUiStore } from './stores/uiStore';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, retry: 1, refetchOnWindowFocus: false },
  },
});

function App() {
  const darkMode = useUiStore((s) => s.darkMode);
  useEffect(() => {
    document.documentElement.classList.toggle('dark', darkMode);
  }, [darkMode]);

  return (
    <QueryClientProvider client={queryClient}>
      <InstallBanner />
      <BrowserRouter>
        <Routes>
          <Route path="login" element={<LoginPage />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route index element={<HomePage />} />
              <Route path="transactions" element={<TransactionsPage />} />
              <Route path="transactions/new" element={<AddTransactionPage />} />
              <Route path="transactions/:id" element={<TransactionDetailPage />} />
              <Route path="calendar" element={<CalendarPage />} />
              <Route path="stats" element={<StatsPage />} />
              <Route path="budgets" element={<BudgetsPage />} />
              <Route path="accounts" element={<AccountsPage />} />
              <Route path="accounts/:id" element={<AccountDetailPage />} />
              <Route path="categories" element={<CategoriesPage />} />
              <Route path="settings" element={<SettingsPage />} />
              <Route path="sms" element={<SmsPage />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;

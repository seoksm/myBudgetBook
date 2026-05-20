import { useMemo, useState } from 'react';
import type { FormEvent } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useLocation, useNavigate } from 'react-router-dom';
import { LockKeyhole, Mail, UserRound, WalletCards } from 'lucide-react';
import { login, register } from '../api/auth';
import { useAuthStore } from '../stores/authStore';

type AuthMode = 'login' | 'register';
const REMEMBER_EMAIL_KEY = 'budget-remember-email';

interface LocationState {
  from?: string;
}

interface AuthFormValues {
  mode: AuthMode;
  email: string;
  password: string;
  displayName: string;
}

export default function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const setAuth = useAuthStore((s) => s.setAuth);

  const [mode, setMode] = useState<AuthMode>('login');
  const [email, setEmail] = useState(() => localStorage.getItem(REMEMBER_EMAIL_KEY) ?? '');
  const [rememberEmail, setRememberEmail] = useState(() => !!localStorage.getItem(REMEMBER_EMAIL_KEY));
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  const redirectTo = useMemo(() => {
    const state = location.state as LocationState | null;
    return state?.from && state.from !== '/login' ? state.from : '/';
  }, [location.state]);

  const mutation = useMutation({
    mutationFn: (values: AuthFormValues) => {
      if (values.mode === 'register') {
        return register({
          email: values.email,
          password: values.password,
          displayName: values.displayName,
        });
      }
      return login({ email: values.email, password: values.password });
    },
    onSuccess: (data, values) => {
      if (values.mode === 'login') {
        if (rememberEmail) {
          localStorage.setItem(REMEMBER_EMAIL_KEY, values.email);
        } else {
          localStorage.removeItem(REMEMBER_EMAIL_KEY);
        }
      }
      setAuth(data.token, data.user);
      navigate(redirectTo, { replace: true });
    },
    onError: (error: Error) => {
      setFormError(error.message);
    },
  });

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmedEmail = email.trim();
    const trimmedName = displayName.trim();

    if (!trimmedEmail) {
      setFormError('이메일을 입력해 주세요.');
      return;
    }
    if (password.length < 8) {
      setFormError('비밀번호는 8자 이상이어야 합니다.');
      return;
    }
    if (mode === 'register' && !trimmedName) {
      setFormError('표시 이름을 입력해 주세요.');
      return;
    }

    setEmail(trimmedEmail);
    setDisplayName(trimmedName);
    setFormError(null);
    mutation.mutate({ mode, email: trimmedEmail, password, displayName: trimmedName });
  };

  const switchMode = (nextMode: AuthMode) => {
    setMode(nextMode);
    setFormError(null);
  };

  return (
    <main className="min-h-screen bg-slate-100 dark:bg-slate-950 text-slate-900 dark:text-slate-100 px-4 py-8 flex items-center justify-center">
      <section className="w-full max-w-md">
        <div className="mb-5">
          <div className="flex items-center gap-3">
            <div className="inline-flex h-12 w-12 items-center justify-center rounded-lg bg-sky-600 text-white shadow-sm">
              <WalletCards size={26} />
            </div>
            <div>
              <h1 className="text-2xl font-bold tracking-tight">MyBudgetBook</h1>
              <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                개인 가계부에 로그인하세요
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg shadow-sm overflow-hidden">
          <div className="grid grid-cols-2 border-b border-slate-200 dark:border-slate-800">
            <button
              type="button"
              onClick={() => switchMode('login')}
              className={`py-3 text-sm font-semibold transition ${
                mode === 'login'
                  ? 'bg-slate-950 text-white dark:bg-sky-600 dark:text-white'
                  : 'text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800/60'
              }`}
            >
              로그인
            </button>
            <button
              type="button"
              onClick={() => switchMode('register')}
              className={`py-3 text-sm font-semibold transition ${
                mode === 'register'
                  ? 'bg-slate-950 text-white dark:bg-sky-600 dark:text-white'
                  : 'text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800/60'
              }`}
            >
              회원가입
            </button>
          </div>

          <form onSubmit={submit} className="p-5 space-y-4">
            {mode === 'register' && (
              <label className="block">
                <span className="text-sm font-medium">표시 이름</span>
                <div className="mt-1.5 flex items-center gap-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 px-3 focus-within:border-sky-500">
                  <UserRound size={18} className="text-slate-400 shrink-0" />
                  <input
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    autoComplete="name"
                    className="min-w-0 flex-1 bg-transparent py-3 outline-none text-sm"
                    placeholder="예: 상민"
                  />
                </div>
              </label>
            )}

            <label className="block">
              <span className="text-sm font-medium">이메일</span>
              <div className="mt-1.5 flex items-center gap-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 px-3 focus-within:border-sky-500">
                <Mail size={18} className="text-slate-400 shrink-0" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="email"
                  className="min-w-0 flex-1 bg-transparent py-3 outline-none text-sm"
                  placeholder="you@example.com"
                />
              </div>
            </label>

            <label className="block">
              <span className="text-sm font-medium">비밀번호</span>
              <div className="mt-1.5 flex items-center gap-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 px-3 focus-within:border-sky-500">
                <LockKeyhole size={18} className="text-slate-400 shrink-0" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete={mode === 'register' ? 'new-password' : 'current-password'}
                  className="min-w-0 flex-1 bg-transparent py-3 outline-none text-sm"
                  placeholder="8자 이상"
                />
              </div>
            </label>

            {mode === 'login' && (
              <label className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-300">
                <input
                  type="checkbox"
                  checked={rememberEmail}
                  onChange={(e) => setRememberEmail(e.target.checked)}
                  className="h-4 w-4 rounded border-slate-300 text-sky-600 focus:ring-sky-500"
                />
                아이디 기억
              </label>
            )}

            {(formError || mutation.isError) && (
              <div className="rounded-lg bg-rose-50 dark:bg-rose-950/40 border border-rose-100 dark:border-rose-900 px-3 py-2 text-sm text-rose-700 dark:text-rose-300">
                {formError}
              </div>
            )}

            <button
              type="submit"
              disabled={mutation.isPending}
              className="w-full rounded-lg bg-sky-600 text-white py-3 text-sm font-semibold hover:bg-sky-700 disabled:opacity-60 disabled:cursor-not-allowed shadow-sm"
            >
              {mutation.isPending
                ? '처리 중...'
                : mode === 'register'
                  ? '계정 만들기'
                  : '로그인'}
            </button>
          </form>
        </div>
      </section>
    </main>
  );
}

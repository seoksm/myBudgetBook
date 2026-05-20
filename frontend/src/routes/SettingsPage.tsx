import { Moon, Sun, Database, FileText, LogOut, ShieldCheck } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useUiStore } from '../stores/uiStore';
import { useAuthStore } from '../stores/authStore';
import { PageHeader } from '../components/PageHeader';

export default function SettingsPage() {
  const navigate = useNavigate();
  const darkMode = useUiStore((s) => s.darkMode);
  const toggleDark = useUiStore((s) => s.toggleDark);
  const user = useAuthStore((s) => s.user);
  const clearAuth = useAuthStore((s) => s.clearAuth);

  const handleLogout = () => {
    clearAuth();
    navigate('/login', { replace: true });
  };

  return (
    <div className="space-y-4">
      <PageHeader title="설정" />

      <div className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200/80 dark:border-slate-800 p-4 shadow-sm">
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-start gap-3 min-w-0">
            <div className="h-10 w-10 rounded-lg bg-sky-100 dark:bg-sky-950/60 text-sky-700 dark:text-sky-300 flex items-center justify-center shrink-0">
              <ShieldCheck size={20} />
            </div>
            <div className="min-w-0">
              <div className="font-semibold truncate">{user?.displayName ?? '로그인 사용자'}</div>
              <div className="text-sm text-slate-500 dark:text-slate-400 truncate">{user?.email}</div>
            </div>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="shrink-0 inline-flex items-center gap-2 rounded-lg border border-slate-200 dark:border-slate-700 px-3 py-2 text-sm hover:bg-slate-50 dark:hover:bg-slate-800"
          >
            <LogOut size={16} />
            로그아웃
          </button>
        </div>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200/80 dark:border-slate-800 overflow-hidden shadow-sm">
        <button
          onClick={toggleDark}
          className="w-full flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/50"
        >
          <div className="flex items-center gap-3">
            {darkMode ? <Moon size={20} /> : <Sun size={20} />}
            <span>다크 모드</span>
          </div>
          <div className={`w-11 h-6 rounded-full relative transition ${darkMode ? 'bg-sky-600' : 'bg-slate-300'}`}>
            <div className={`w-5 h-5 bg-white rounded-full absolute top-0.5 transition-all ${darkMode ? 'left-5' : 'left-0.5'}`} />
          </div>
        </button>

        <a
          href="http://localhost:18080/h2-console"
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-3 p-4 border-t border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50"
        >
          <Database size={20} />
          <span>H2 데이터베이스 콘솔</span>
        </a>

        <a
          href="http://localhost:18080/swagger-ui.html"
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-3 p-4 border-t border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50"
        >
          <FileText size={20} />
          <span>API 문서 (Swagger UI)</span>
        </a>
      </div>

      <div className="text-xs text-center text-slate-400">
        MyBudgetBook v0.1.0 · 개발 모드
      </div>
    </div>
  );
}

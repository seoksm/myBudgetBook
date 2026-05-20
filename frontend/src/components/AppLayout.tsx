import { Outlet, NavLink } from 'react-router-dom';
import {
  Home, ListChecks, PlusCircle, PieChart, Settings,
  Calendar, Wallet, Tags, MessageSquare, Target, WalletCards,
} from 'lucide-react';
import { useAuthStore } from '../stores/authStore';

const navItems = [
  { to: '/', label: '홈', icon: Home },
  { to: '/transactions', label: '내역', icon: ListChecks },
  { to: '/transactions/new', label: '추가', icon: PlusCircle, primary: true },
  { to: '/stats', label: '통계', icon: PieChart },
  { to: '/settings', label: '설정', icon: Settings },
];

const sideExtra = [
  { to: '/calendar', label: '달력', icon: Calendar },
  { to: '/budgets', label: '예산', icon: Target },
  { to: '/accounts', label: '계좌', icon: Wallet },
  { to: '/categories', label: '카테고리', icon: Tags },
  { to: '/sms', label: 'SMS 붙여넣기', icon: MessageSquare },
];

export function AppLayout() {
  const user = useAuthStore((s) => s.user);

  return (
    <div className="min-h-screen bg-slate-100 dark:bg-slate-950 text-slate-900 dark:text-slate-100">
      <div className="md:flex">
        {/* PC 사이드바 */}
        <aside className="hidden md:flex md:flex-col md:w-64 md:min-h-screen md:fixed md:border-r md:border-slate-200/80 md:dark:border-slate-800 md:bg-white/90 md:dark:bg-slate-900/90 md:backdrop-blur">
          <div className="p-5 border-b border-slate-200/80 dark:border-slate-800">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-lg bg-sky-600 text-white flex items-center justify-center shadow-sm">
                <WalletCards size={22} />
              </div>
              <div className="min-w-0">
                <div className="text-lg font-bold tracking-tight">MyBudgetBook</div>
                <div className="text-xs text-slate-500 mt-0.5 truncate">{user?.displayName ?? '내 가계부'}</div>
              </div>
            </div>
          </div>
          <nav className="flex flex-col p-3 gap-1.5">
            {[...navItems, ...sideExtra].map((it) => (
              <NavLink
                key={it.to}
                to={it.to}
                end={it.to === '/'}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2.5 rounded-lg transition border ${
                    isActive
                      ? 'bg-sky-50 border-sky-100 text-sky-700 dark:bg-sky-950/40 dark:border-sky-900/50 dark:text-sky-300 font-semibold shadow-sm'
                      : 'border-transparent text-slate-600 dark:text-slate-300 hover:bg-slate-100/80 dark:hover:bg-slate-800/70'
                  }`
                }
              >
                <it.icon size={18} />
                <span className="text-sm">{it.label}</span>
              </NavLink>
            ))}
          </nav>
        </aside>

        {/* 메인 영역 */}
        <main className="flex-1 md:ml-64 pb-24 md:pb-0">
          <div className="max-w-5xl mx-auto px-4 py-4 md:px-8 md:py-8">
            <Outlet />
          </div>
        </main>
      </div>

      {/* 모바일 하단 탭 */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-slate-900/95 backdrop-blur border-t border-slate-200 dark:border-slate-800 z-50">
        <div className="flex px-1 pb-[env(safe-area-inset-bottom)]">
          {navItems.map((it) => (
            <NavLink
              key={it.to}
              to={it.to}
              end={it.to === '/'}
              className={({ isActive }) =>
                `flex-1 flex flex-col items-center py-2.5 gap-0.5 transition ${
                  isActive
                    ? 'text-sky-600 dark:text-sky-400'
                    : 'text-slate-500 dark:text-slate-400'
                }`
              }
            >
              <span className={it.primary ? 'rounded-lg bg-sky-600 text-white p-1.5 -mt-4 shadow-lg shadow-sky-600/25' : ''}>
                <it.icon size={it.primary ? 26 : 22} />
              </span>
              <span className="text-[10px]">{it.label}</span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  );
}

import { useState, useEffect } from 'react';
import { CheckCircle2, Download, RefreshCw, Share, Plus, X } from 'lucide-react';
import { useRegisterSW } from 'virtual:pwa-register/react';
import { usePwaInstall } from '../hooks/usePwaInstall';

const DISMISS_KEY = 'budget-install-dismissed-v2';
const OFFLINE_READY_DISMISS_KEY = 'budget-offline-ready-dismissed';

export function InstallBanner() {
  const { canInstall, isInstalled, isIos, promptInstall } = usePwaInstall();
  const [dismissed, setDismissed] = useState(true);
  const [offlineDismissed, setOfflineDismissed] = useState(true);
  const {
    offlineReady: [offlineReady, setOfflineReady],
    needRefresh: [needRefresh, setNeedRefresh],
    updateServiceWorker,
  } = useRegisterSW({
    immediate: true,
    onRegisterError(error) {
      console.error('PWA registration failed', error);
    },
  });

  useEffect(() => {
    setDismissed(localStorage.getItem(DISMISS_KEY) === '1');
    setOfflineDismissed(localStorage.getItem(OFFLINE_READY_DISMISS_KEY) === '1');
  }, []);

  const dismiss = () => {
    localStorage.setItem(DISMISS_KEY, '1');
    setDismissed(true);
  };

  const dismissOfflineReady = () => {
    localStorage.setItem(OFFLINE_READY_DISMISS_KEY, '1');
    setOfflineDismissed(true);
    setOfflineReady(false);
  };

  if (needRefresh) {
    return (
      <div className="fixed bottom-20 md:bottom-4 left-3 right-3 md:left-auto md:right-4 md:w-96 z-40
                      bg-slate-950 text-white rounded-2xl shadow-xl p-4
                      animate-in slide-in-from-bottom duration-300">
        <button
          onClick={() => setNeedRefresh(false)}
          className="absolute top-2 right-2 p-1 rounded hover:bg-white/20"
          aria-label="나중에"
        >
          <X size={16} />
        </button>

        <div className="flex items-start gap-3 pr-4">
          <RefreshCw size={28} className="flex-shrink-0 mt-1 text-sky-300" />
          <div className="flex-1">
            <div className="font-bold">새 버전이 준비됐습니다</div>
            <div className="text-sm text-slate-300 mt-1">
              최신 화면과 캐시를 적용하려면 앱을 새로고침하세요.
            </div>
            <button
              onClick={() => updateServiceWorker(true)}
              className="mt-3 bg-white text-slate-950 font-semibold px-4 py-1.5 rounded-lg text-sm"
            >
              지금 적용
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (offlineReady && !offlineDismissed) {
    return (
      <div className="fixed bottom-20 md:bottom-4 left-3 right-3 md:left-auto md:right-4 md:w-80 z-40
                      bg-emerald-600 text-white rounded-2xl shadow-xl p-4
                      animate-in slide-in-from-bottom duration-300">
        <button
          onClick={dismissOfflineReady}
          className="absolute top-2 right-2 p-1 rounded hover:bg-white/20"
          aria-label="닫기"
        >
          <X size={16} />
        </button>

        <div className="flex items-start gap-3 pr-4">
          <CheckCircle2 size={28} className="flex-shrink-0 mt-1" />
          <div className="flex-1">
            <div className="font-bold">오프라인 실행 준비 완료</div>
            <div className="text-sm text-emerald-50 mt-1">
              앱 화면과 정적 자산이 기기에 저장됐습니다.
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (isInstalled || dismissed) return null;

  return (
    <div className="fixed bottom-20 md:bottom-4 left-3 right-3 md:left-auto md:right-4 md:w-80 z-40
                    bg-sky-600 text-white rounded-2xl shadow-xl p-4
                    animate-in slide-in-from-bottom duration-300">
      <button
        onClick={dismiss}
        className="absolute top-2 right-2 p-1 rounded hover:bg-white/20"
        aria-label="닫기"
      >
        <X size={16} />
      </button>

      <div className="flex items-start gap-3 pr-4">
        <Download size={28} className="flex-shrink-0 mt-1" />
        <div className="flex-1">
          <div className="font-bold">앱으로 설치하기</div>
          <div className="text-sm text-sky-100 mt-1">
            {canInstall
              ? '홈 화면에 추가하면 빠른 실행 + 오프라인 사용 가능'
              : isIos
                ? 'Safari 공유 메뉴에서 홈 화면에 추가할 수 있습니다'
                : '주소창의 설치 아이콘 또는 브라우저 메뉴에서 앱으로 설치할 수 있습니다'}
          </div>

          {canInstall ? (
            <button
              onClick={async () => { if (await promptInstall()) dismiss(); }}
              className="mt-3 bg-white text-sky-600 font-semibold px-4 py-1.5 rounded-lg text-sm"
            >
              설치
            </button>
          ) : isIos ? (
            <div className="text-xs text-sky-100 mt-2 flex items-center gap-1 flex-wrap">
              하단 <Share size={14} className="inline" /> 공유 →
              <Plus size={14} className="inline" /> 홈 화면에 추가
            </div>
          ) : (
            <div className="text-xs text-sky-100 mt-2">
              Chrome/Edge: 주소창 오른쪽 설치 아이콘 또는 메뉴 → 앱 설치
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

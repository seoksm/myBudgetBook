import { useEffect, useState } from 'react';

/**
 * PWA 설치 가능 여부 + 설치 트리거 훅.
 *
 * - 데스크톱 Chrome/Edge: `beforeinstallprompt` 이벤트로 설치 가능
 * - iOS Safari: 자동 프롬프트 불가 → "공유 → 홈 화면에 추가" 안내
 */
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export function usePwaInstall() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstalled, setIsInstalled] = useState(false);
  const [isIos, setIsIos] = useState(false);

  useEffect(() => {
    // iOS 감지
    const ua = window.navigator.userAgent;
    const ios = /iPhone|iPad|iPod/.test(ua);
    setIsIos(ios);

    // 이미 standalone 모드면 설치 완료된 상태
    const standalone = window.matchMedia('(display-mode: standalone)').matches
      || (window.navigator as unknown as { standalone?: boolean }).standalone === true;
    setIsInstalled(standalone);

    // beforeinstallprompt 캐치
    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', handler);

    // appinstalled 이벤트
    const installedHandler = () => setIsInstalled(true);
    window.addEventListener('appinstalled', installedHandler);

    return () => {
      window.removeEventListener('beforeinstallprompt', handler);
      window.removeEventListener('appinstalled', installedHandler);
    };
  }, []);

  const promptInstall = async (): Promise<boolean> => {
    if (!deferredPrompt) return false;
    await deferredPrompt.prompt();
    const choice = await deferredPrompt.userChoice;
    setDeferredPrompt(null);
    return choice.outcome === 'accepted';
  };

  return {
    canInstall: !!deferredPrompt,
    isInstalled,
    isIos,
    promptInstall,
  };
}

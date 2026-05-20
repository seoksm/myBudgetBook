export function cleanupLegacyPwaCaches() {
  if (!import.meta.env.DEV || !('caches' in window)) {
    return;
  }

  window.addEventListener('load', () => {
    caches.keys()
      .then((keys) => Promise.all(
        keys
          .filter((key) => key === 'api-cache')
          .map((key) => caches.delete(key)),
      ))
      .catch(() => undefined);
  });
}

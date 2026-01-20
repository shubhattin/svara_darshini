// Stub module for PWA when building for Android
export function useRegisterSW() {
  return {
    needRefresh: { subscribe: () => () => {}, current: false },
    updateServiceWorker: async () => {}
  };
}

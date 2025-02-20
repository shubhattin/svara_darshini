export const indactivity_timeout = (time_ms: number, func: () => void) => {
  const activityEvents: string[] = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];

  let inactivityTimeout: number;

  const resetInactivityTimer = (): void => {
    window.clearTimeout(inactivityTimeout);
    inactivityTimeout = window.setTimeout(func, time_ms);
  };

  resetInactivityTimer();

  activityEvents.forEach((event) => {
    document.addEventListener(event, resetInactivityTimer, false);
  });
};

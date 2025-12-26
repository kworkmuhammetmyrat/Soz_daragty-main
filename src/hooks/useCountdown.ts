import { useEffect, useState } from 'react';

const TIMER_DURATION = 30;

export const useCountdown = (
  active: boolean,
  startedAt: string | null,
  onTimeout: () => void
) => {
  const [timeRemaining, setTimeRemaining] = useState(TIMER_DURATION);

  useEffect(() => {
    if (!startedAt) {
      setTimeRemaining(TIMER_DURATION);
      return;
    }

    const calculateRemaining = () => {
      const elapsed = (Date.now() - new Date(startedAt).getTime()) / 1000;
      const remaining = TIMER_DURATION - elapsed;

      if (remaining <= 0) {
        if (active) {
          onTimeout();
        }
        setTimeRemaining(0);
      } else {
        setTimeRemaining(Math.max(0, Math.ceil(remaining)));
      }
    };

    calculateRemaining();

    const interval = setInterval(calculateRemaining, 250);
    return () => clearInterval(interval);
  }, [active, startedAt, onTimeout]);

  return timeRemaining;
};
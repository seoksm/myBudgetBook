import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface UiState {
  darkMode: boolean;
  toggleDark: () => void;
  setDark: (v: boolean) => void;
}

export const useUiStore = create<UiState>()(
  persist(
    (set) => ({
      darkMode: false,
      toggleDark: () => set((s) => {
        const next = !s.darkMode;
        document.documentElement.classList.toggle('dark', next);
        return { darkMode: next };
      }),
      setDark: (v) => {
        document.documentElement.classList.toggle('dark', v);
        set({ darkMode: v });
      },
    }),
    { name: 'budget-ui' }
  )
);

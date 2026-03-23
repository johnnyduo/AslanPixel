/**
 * Shared quest input state — lets LeftPanel and BottomPanel stay in sync.
 * LeftPanel "Deploy" button sets the intent; BottomPanel auto-runs it.
 */
import { create } from "zustand";

interface QuestInputStore {
  pendingIntent: string | null;
  setPendingIntent: (intent: string) => void;
  clearPendingIntent: () => void;
}

export const useQuestInput = create<QuestInputStore>((set) => ({
  pendingIntent: null,
  setPendingIntent: (intent) => set({ pendingIntent: intent }),
  clearPendingIntent: () => set({ pendingIntent: null }),
}));

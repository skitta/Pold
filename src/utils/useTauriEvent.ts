import { listen, Event, UnlistenFn } from "@tauri-apps/api/event";
import { onUnmounted } from "vue";

export interface InputData {
  key: string;
  name: string;
  volume: number;
  value: number;
  modified_volumn: number;
}

export interface Record {
  id: number;
  inputs: InputData[];
  min_value: number;
  max_value: number;
  target_value: number;
}

export function useTauriEvent<T>(
  eventName: string,
  callback: (payload: T) => void,
  options?: {
    immediate?: boolean;
    onError?: (error: unknown) => void;
  },
): {
  start: () => Promise<void>;
  stop: () => void;
} {
  let unlisten: UnlistenFn | null = null;
  const immediate = options?.immediate ?? true;

  const start = async () => {
    try {
      unlisten = await listen<T>(eventName, (event: Event<T>) => {
        callback(event.payload);
      });
    } catch (error) {
      options?.onError?.(error);
      console.error(`[useTauriEvent] 监听事件 "${eventName}" 失败:`, error);
    }
  };

  const stop = () => {
    unlisten?.();
    unlisten = null;
  };

  if (immediate) {
    start();
  }

  onUnmounted(() => {
    stop();
  });

  return { start, stop };
}

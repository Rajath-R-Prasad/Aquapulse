import { useEffect, useState, useSyncExternalStore } from 'react';

export function useDelayedFlag(flag, ms) {
  const [value, setValue] = useState(false);
  useEffect(() => {
    if (!flag) {
      setValue(false);
      return undefined;
    }
    const t = setTimeout(() => setValue(true), ms);
    return () => clearTimeout(t);
  }, [flag, ms]);
  return value;
}

export function useDebounced(value, ms = 250) {
  const [v, setV] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setV(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return v;
}

let nowValue = Date.now();
let timer = null;
const subs = new Set();
const subscribe = (cb) => {
  subs.add(cb);
  if (!timer) {
    nowValue = Date.now();
    timer = setInterval(() => {
      nowValue = Date.now();
      subs.forEach((f) => f());
    }, 1000);
  }
  return () => {
    subs.delete(cb);
    if (!subs.size) {
      clearInterval(timer);
      timer = null;
    }
  };
};
export const useNow = () => useSyncExternalStore(subscribe, () => nowValue);

export function debounce(fn, ms) {
  let t;
  return (...a) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...a), ms);
  };
}

export function throttle(fn, ms) {
  let last = 0;
  let t;
  return (...a) => {
    const rem = ms - (Date.now() - last);
    if (rem <= 0) {
      last = Date.now();
      fn(...a);
    } else {
      clearTimeout(t);
      t = setTimeout(() => {
        last = Date.now();
        fn(...a);
      }, rem);
    }
  };
}

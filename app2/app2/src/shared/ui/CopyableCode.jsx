import { useState } from 'react';
import { Check, Copy } from 'lucide-react';

export function CopyableCode({ value }) {
  const [copied, setCopied] = useState(false);
  const copy = async (e) => {
    e.stopPropagation();
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      setCopied(false);
    }
  };
  return (
    <span className="inline-flex items-center gap-1.5">
      <span className="font-semibold">{value}</span>
      <button type="button" onClick={copy} aria-label={`Copy ${value}`} className="rounded-sm p-1 text-ink-3 hover:bg-muted hover:text-ink">
        {copied ? <Check className="size-3.5 text-success" /> : <Copy className="size-3.5" />}
      </button>
    </span>
  );
}

import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Overlay } from './Overlay';
import { Button } from './Button';
import { isInline } from '../api/errors';

const buildSchema = (required, min) =>
  z.object({
    reason: required
      ? z.string().trim().min(min, min > 1 ? `Enter at least ${min} characters` : 'A reason is required')
      : z.string().trim().optional(),
  });

export function ConfirmDialog({
  open, onClose, title, description, confirmLabel = 'Confirm', tone = 'primary',
  reasonLabel, reasonRequired = false, minLength = 1, onConfirm, children,
}) {
  const [key, setKey] = useState('');
  const [error, setError] = useState(null);
  const [pending, setPending] = useState(false);
  const { register, handleSubmit, reset, formState: { errors } } = useForm({
    resolver: zodResolver(buildSchema(reasonRequired, minLength)),
    defaultValues: { reason: '' },
  });

  useEffect(() => {
    if (open) {
      setKey(crypto.randomUUID());
      setError(null);
      reset({ reason: '' });
    }
  }, [open, reset]);

  const submit = handleSubmit(async (values) => {
    setPending(true);
    setError(null);
    try {
      await onConfirm({ key, reason: values.reason || undefined });
      onClose();
    } catch (e) {
      if (e?.status === 409) onClose();
      else if (isInline(e)) setError(e.message);
    } finally {
      setPending(false);
    }
  });

  return (
    <Overlay
      open={open}
      onClose={pending ? undefined : onClose}
      title={title}
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={pending}>Cancel</Button>
          <Button variant={tone === 'danger' ? 'danger' : 'primary'} loading={pending} onClick={submit}>{confirmLabel}</Button>
        </>
      }
    >
      <form onSubmit={submit} className="space-y-3">
        {description && <p className="text-sm text-ink-2">{description}</p>}
        {children}
        {reasonLabel && (
          <div>
            <label htmlFor="confirm-reason" className="mb-1 block text-sm font-medium">{reasonLabel}</label>
            <textarea
              id="confirm-reason"
              rows={3}
              {...register('reason')}
              className="w-full rounded-md border border-line-strong bg-surface px-3 py-2 text-sm"
            />
            {errors.reason && <p className="mt-1 text-xs text-danger">{errors.reason.message}</p>}
          </div>
        )}
        {error && <p role="alert" className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger">{error}</p>}
        <button type="submit" className="hidden" />
      </form>
    </Overlay>
  );
}

export const ReasonDialog = (props) => <ConfirmDialog reasonRequired {...props} />;

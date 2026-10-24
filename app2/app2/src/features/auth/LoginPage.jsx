import { useState } from 'react';
import { Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import { Droplets } from 'lucide-react';
import { supabase } from '@/shared/supabase/client';
import { api } from '@/shared/api/client';
import { strings } from '@/shared/lib/strings';
import { Button } from '@/shared/ui/Button';
import { Field, TextInput } from '@/shared/ui/FormControls';
import { Splash } from '@/app/guards';
import { useSession } from './useSession';

export default function LoginPage() {
  const { session, loading } = useSession();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const requestedNext = searchParams.get('next');
  const next = requestedNext?.startsWith('/') && !requestedNext.startsWith('//') ? requestedNext : '/map';
  const [error, setError] = useState(null);
  const [operatorSignup, setOperatorSignup] = useState(false);
  const expired = sessionStorage.getItem('jr_expired') === '1';
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (loading) return <Splash />;
  if (session) return <Navigate to={next} replace />;

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);
    const form = event.currentTarget;
    const values = new FormData(form);
    const email = String(values.get('email') ?? '').trim().toLowerCase();
    const password = String(values.get('password') ?? '');
    const emailInput = form.elements.namedItem('email');
    if (!email || !password) {
      setError('Enter your email and password.');
      return;
    }
    if (!emailInput.validity.valid) {
      setError('Enter a valid email address.');
      return;
    }

    const fullName = String(values.get('full_name') ?? '').trim();
    const setupCode = String(values.get('setup_code') ?? '').trim();
    if (operatorSignup) {
      if (!fullName || !setupCode) {
        setError('Enter your name and the one-time operator setup code.');
        return;
      }
      if (password.length < 8) {
        setError('Use a password with at least 8 characters.');
        return;
      }
      setIsSubmitting(true);
      try {
        const setup = await api.get('/v1/auth/operator-signup-status');
        const browserHost = new URL(
          import.meta.env.VITE_SUPABASE_URL ?? 'http://localhost:54321',
        ).hostname;
        const browserProjectRef = browserHost.endsWith('.supabase.co')
          ? browserHost.slice(0, -'.supabase.co'.length)
          : null;
        if (
          setup.supabase_project_ref
          && browserProjectRef
          && setup.supabase_project_ref !== browserProjectRef
        ) {
          setError(
            `The backend is configured for Supabase project "${setup.supabase_project_ref}", but this web app uses "${browserProjectRef}". Set the same project URL in backend/.env and app2/.env, then restart both services.`,
          );
          return;
        }
        if (setup.claim_recorded || setup.active_operator_exists) {
          setError(
            setup.active_operator_exists
              ? 'An operator account is already registered in the backend Supabase project. Confirm the project reference shown here matches your Supabase dashboard; if it does, reset that operator user’s password in Supabase and sign in.'
              : 'The one-time signup claim is recorded, but there is no active operator profile in the backend database. Check that backend/.env and app2/.env use the same Supabase project before retrying.',
          );
          return;
        }
        await api.post('/v1/auth/operator-signup', {
          body: {
            email,
            password,
            full_name: fullName,
            setup_code: setupCode,
          },
        });
      } catch (signupError) {
        setError(signupError.message);
        return;
      } finally {
        setIsSubmitting(false);
      }
    }
    setIsSubmitting(true);
    try {
      const { error: err } = await supabase.auth.signInWithPassword({ email, password });
      if (err) {
        setError(
          err.message.toLowerCase().includes('invalid login credentials')
            ? 'Supabase could not find an account with this email and password. If you already submitted operator signup, check Authentication → Users in your Supabase project; the account may have been created with a different password. Use Supabase password recovery or reset the user password, then sign in again.'
            : `Supabase sign-in failed: ${err.message}`,
        );
        return;
      }
      sessionStorage.removeItem('jr_expired');
      navigate(next, { replace: true });
    } catch (signInError) {
      setError(`Could not reach Supabase Auth: ${signInError.message}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex h-full items-center justify-center bg-app p-6">
      <form onSubmit={onSubmit} className="w-full max-w-[400px] space-y-4 rounded-lg border border-line bg-surface p-8 shadow-md" noValidate>
        <div className="flex items-center gap-2 text-2xl font-semibold text-primary">
          <Droplets className="size-7" aria-hidden="true" />
          {strings.appName}
        </div>
        <p className="text-sm text-ink-2">
          {operatorSignup ? 'Create the one-time operator account' : 'Sign in to the operator dashboard'}
        </p>
        {expired && !error && <p role="status" className="rounded-md bg-warning-soft px-3 py-2 text-sm text-warning">{strings.sessionExpired}</p>}
        {error && <p role="alert" className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger">{error}</p>}
        {operatorSignup && (
          <>
            <Field label="Full name" htmlFor="full_name">
              <TextInput id="full_name" name="full_name" autoComplete="name" />
            </Field>
            <Field label="One-time setup code" htmlFor="setup_code">
              <TextInput id="setup_code" name="setup_code" type="password" autoComplete="off" />
            </Field>
            <p className="text-xs text-ink-2">
              Use the code configured as <code>OPERATOR_SIGNUP_CODE</code> in the backend environment. This signup is available once.
            </p>
          </>
        )}
        <Field label="Email" htmlFor="email">
          <TextInput id="email" name="email" type="email" autoComplete="email" autoCapitalize="none" spellCheck={false} />
        </Field>
        <Field label="Password" htmlFor="password">
          <TextInput id="password" name="password" type="password" autoComplete={operatorSignup ? 'new-password' : 'current-password'} />
        </Field>
        <Button type="submit" loading={isSubmitting} className="w-full">
          {operatorSignup ? 'Create operator account' : 'Sign in'}
        </Button>
        <button
          type="button"
          onClick={() => {
            setError(null);
            setOperatorSignup((current) => !current);
          }}
          className="w-full text-center text-sm text-primary hover:underline"
        >
          {operatorSignup ? 'Already have an operator account? Sign in' : 'First-time setup? Create operator account'}
        </button>
      </form>
    </div>
  );
}

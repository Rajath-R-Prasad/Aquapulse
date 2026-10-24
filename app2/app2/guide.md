#  Web Dashboard: Folder Guide

React 18 + Vite + Tailwind CSS v4, JavaScript only.

```bash
npm install
cp .env.example .env     # fill in API and Supabase values
npm run dev              # npm run build, npm test
```

## Structure

```text
AquaPulse/
  index.html                  Vite entry
  vite.config.js              React + Tailwind plugins, "@" alias to src, app version define
  jsconfig.json               Editor path alias
  .env.example                API, Supabase and map settings
  public/favicon.svg
  src/
    main.jsx                  Mounts <Providers/>, imports fonts, Leaflet CSS, global CSS
    index.css                 Tailwind import, token-to-utility mapping, animations, map marker styles
    styles/tokens.css         Design tokens (colours, radius, shadows)

    app/                      Application shell
      providers.jsx           QueryClient, SessionProvider, Router, Toaster
      router.jsx              Routes (lazy loaded), route titles, guards
      guards.jsx              Splash, RequireAuth, RequireStaff, RequireAdmin
      AppShell.jsx            Layout, top progress bar, realtime provider, notifications drawer
      Sidebar.jsx             Navigation groups, approvals badge
      Topbar.jsx              Page title, global search, LiveIndicator, bell, user menu

    features/                 One folder per screen area
      auth/                   LoginPage, AccessDenied, useSession (context), useMe
      dashboard/              DashboardPage, KpiStrip, ActiveEventsPanel, hooks
      map/                    MapPage (filters, URL-synced pipe), PipeDrawer (overview, signals, history)
      events/                 EventsPage, EventDetailPage, hooks (filters in URL, list, detail, log, actions)
        tabs/                 OverviewTab, SignalsTab, WorkOrderTab, TimelineTab
      isolation/              IsolationPanel and hooks (acknowledge, confirm closed/restored, dismiss)
      dispatch/               DispatchDialog (ranked engineers sheet) and hooks
      workorders/             WorkOrdersPage, WorkOrderReviewPage, EvidenceGallery, hooks
      engineers/              EngineersPage and hooks
      simulation/             SimulationPage (ADMIN) and hooks
      notifications/          NotificationsDrawer and hooks
      settings/               SettingsPage

    shared/                   Code used by more than one feature
      api/
        client.js             fetch wrapper: bearer token, Idempotency-Key, problem+json errors
        errors.js             ApiError, Supabase read helpers (sb, sbPage, sbCount), handleApiError
        useAction.js          Mutation helper with error handling and cache invalidation
      supabase/
        client.js             Supabase client (anon key only)
        realtime.jsx          RealtimeProvider (one channel per table), useLiveStatus, useLiveSignals
      data/                   Shared query hooks
        network.js            Network geometry + pipe state merge, signals, ML scores, pipe history
        events.js             Open events, global search
        counts.js             Awaiting-approval and open-advisory counts
      map/
        MapView.jsx           The single Leaflet map used on Dashboard, Map and Event detail
        AssetPopup.jsx        Pipe popup content
      ui/                     Presentational components
        Button, Card, Overlay (dialog and sheet), ConfirmDialog (+ReasonDialog), Badges (StatusBadge, SourceBadge),
        Skeletons, States (Empty, Error, StillLoading), DataTable, FormControls, Tabs, Stepper, Timeline,
        SlaTimer, Time, CopyableCode, KpiCard, SignalChart, PipeSignals
      lib/
        statusMap.js          Labels, tones, icons and map colours for every status domain
        strings.js            User-facing copy in one file
        time.js, format.js    IST dates and number formatting
        geo.js                [lon, lat] to [lat, lon] swap, map env config
        hooks.js              useNow, useDebounced, useDelayedFlag, debounce, throttle
        cn.js                 Class name merge helper
        __tests__/            Vitest unit tests
```

## Conventions

- Reads go through Supabase (RLS + Realtime). Every write goes through the FastAPI `/v1` endpoints.
- Realtime events invalidate TanStack Query caches. The one exception is `signal_latest`, which is patched in place.
- Components render; hooks fetch. Screens do not call `fetch` or Supabase directly.
- Shared code lives in `shared/`. `EventDetailPage` composes the isolation, dispatch and work-order features.
- Status colours, labels and icons come only from `shared/lib/statusMap.js`.

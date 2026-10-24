import {
  Ban, CircleAlert, CircleCheck, ClipboardCheck, Droplets, Info, Minus, Octagon, Siren, TriangleAlert, Wifi, WifiOff, Wrench,
} from 'lucide-react';

const m = (label, tone, icon = null, color = '#94A3B8') => ({ label, tone, icon, color });

export const STATUS = {
  pipeState: {
    NORMAL: m('Normal', 'success', CircleCheck, '#16A34A'),
    WARNING: m('Warning', 'warning', TriangleAlert, '#F59E0B'),
    LEAK: m('Leak', 'danger', Droplets, '#DC2626'),
    ISOLATED: m('Isolated', 'purple', Ban, '#7C3AED'),
    UNDER_REPAIR: m('Under repair', 'info', Wrench, '#2563EB'),
    PENDING_VERIFICATION: m('Awaiting approval', 'teal', ClipboardCheck, '#0D9488'),
  },
  severity: {
    NONE: m('None', 'grey', Minus, '#94A3B8'),
    MINOR: m('Minor', 'info', Info, '#2563EB'),
    MODERATE: m('Moderate', 'warning', CircleAlert, '#F59E0B'),
    MAJOR: m('Major', 'orange', TriangleAlert, '#EA580C'),
    CRITICAL: m('Critical', 'danger', Siren, '#DC2626'),
  },
  priority: {
    P1: m('P1 Urgent', 'danger'),
    P2: m('P2 High', 'orange'),
    P3: m('P3 Normal', 'warning'),
    P4: m('P4 Low', 'grey'),
  },
  eventStatus: {
    DETECTED: m('Detected', 'danger'),
    ACKNOWLEDGED: m('Acknowledged', 'warning'),
    DISPATCHED: m('Dispatched', 'info'),
    IN_PROGRESS: m('In progress', 'info'),
    REPAIR_SUBMITTED: m('Repair submitted', 'teal'),
    CLOSED: m('Closed', 'success'),
    FALSE_ALARM: m('False alarm', 'grey'),
  },
  woStatus: {
    UNASSIGNED: m('Needs engineer', 'warning'),
    ASSIGNED: m('Assigned', 'info'),
    ACCEPTED: m('Accepted', 'info'),
    EN_ROUTE: m('En route', 'info'),
    ON_SITE: m('On site', 'purple'),
    SUBMITTED: m('Awaiting approval', 'teal'),
    REWORK: m('Rework', 'orange'),
    COMPLETED: m('Completed', 'success'),
    CANCELLED: m('Cancelled', 'grey'),
  },
  advisoryStatus: {
    OPEN: m('Action needed', 'danger', Octagon),
    ACKNOWLEDGED: m('Acknowledged', 'warning', Octagon),
    ISOLATED: m('Isolated', 'purple', Octagon),
    RESTORED: m('Restored', 'success', Octagon),
    DISMISSED: m('Dismissed', 'grey', Octagon),
  },
  urgency: {
    IMMEDIATE: m('Immediate', 'danger'),
    RECOMMENDED: m('Recommended', 'warning'),
    ADVISORY: m('Advisory', 'grey'),
  },
  engineerStatus: {
    AVAILABLE: m('Available', 'success'),
    ASSIGNED: m('Assigned', 'info'),
    EN_ROUTE: m('En route', 'info'),
    ON_SITE: m('On site', 'purple'),
    OFF_DUTY: m('Off duty', 'grey'),
  },
  deviceStatus: {
    ONLINE: m('Online', 'success', Wifi),
    OFFLINE: m('Offline', 'danger', WifiOff),
    MAINTENANCE: m('Maintenance', 'warning'),
    PROVISIONED: m('Provisioned', 'grey'),
    RETIRED: m('Retired', 'grey'),
  },
  valveState: {
    OPEN: m('Open', 'success'),
    CLOSED: m('Closed', 'purple'),
    PARTIAL: m('Partial', 'warning'),
  },
  twinStatus: {
    PENDING: m('Pending', 'warning'),
    DELIVERED: m('Delivered', 'info'),
    APPLIED: m('Applied', 'success'),
    FAILED: m('Failed', 'danger'),
  },
};

export const getStatus = (domain, value) =>
  STATUS[domain]?.[value] ?? { label: value == null ? '—' : String(value), tone: 'grey', icon: null, color: '#94A3B8' };

export const SEVERITY_RANK = { NONE: 0, MINOR: 1, MODERATE: 2, MAJOR: 3, CRITICAL: 4 };
export const PIPE_STATES = Object.keys(STATUS.pipeState);
export const SEVERITIES = Object.keys(STATUS.severity);
export const EVENT_STATUSES = Object.keys(STATUS.eventStatus);
export const LIVE_WO_STATUSES = ['UNASSIGNED', 'ASSIGNED', 'ACCEPTED', 'EN_ROUTE', 'ON_SITE', 'REWORK'];

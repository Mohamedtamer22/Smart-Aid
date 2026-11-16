import { Component, computed, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from './core/auth.service';
import { EccApiService } from './core/ecc-api.service';

type PortalTab =
  | 'overview'
  | 'hospitals'
  | 'pharmacy'
  | 'bloodbank'
  | 'providers'
  | 'admin'
  | 'analytics';

@Component({
  selector: 'app-root',
  imports: [CommonModule, FormsModule],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit, OnDestroy {
  email = 'demo.admin@smartaid.local';
  password = '';
  showPassword = signal<boolean>(false);
  loginError = signal<string | null>(null);
  statusBanner = signal<string | null>(null);
  bannerTone = signal<'success' | 'error' | 'info'>('success');
  loading = signal<boolean>(false);
  refreshing = signal<boolean>(false);
  activeTab = signal<PortalTab>('overview');
  autoRefresh = signal<boolean>(true);
  lastSyncedAt = signal<string>('—');
  incidentFilter = signal<string>('');
  userFilter = signal<string>('');

  // Core ECC & Admin State
  overview = signal<Record<string, unknown> | null>(null);
  emsDashboard = signal<Record<string, unknown> | null>(null);
  liveIncidents = signal<Array<Record<string, unknown>>>([]);
  selectedIncidentId = signal<string | null>(null);
  smartErResults = signal<Array<Record<string, unknown>>>([]);

  // Resources & Healthcare State
  hospitals = signal<Array<Record<string, unknown>>>([]);
  ambulances = signal<Array<Record<string, unknown>>>([]);
  aeds = signal<Array<Record<string, unknown>>>([]);
  pharmacies = signal<Array<Record<string, unknown>>>([]);
  pendingOrders = signal<Array<Record<string, unknown>>>([]);
  deliveries = signal<Array<Record<string, unknown>>>([]);
  bloodBanks = signal<Array<Record<string, unknown>>>([]);
  bloodInventory = signal<Array<Record<string, unknown>>>([]);
  bloodRequests = signal<Array<Record<string, unknown>>>([]);
  laboratories = signal<Array<Record<string, unknown>>>([]);
  labAppointments = signal<Array<Record<string, unknown>>>([]);
  providers = signal<Array<Record<string, unknown>>>([]);
  providerAppointments = signal<Array<Record<string, unknown>>>([]);
  handovers = signal<Array<Record<string, unknown>>>([]);

  // Admin Governance & Analytics State
  users = signal<Array<Record<string, unknown>>>([]);
  volunteers = signal<Array<Record<string, unknown>>>([]);
  auditLogs = signal<Array<Record<string, unknown>>>([]);
  analytics = signal<Record<string, unknown> | null>(null);
  researchReport = signal<Record<string, unknown> | null>(null);

  filteredIncidents = computed(() => {
    const q = this.incidentFilter().trim().toLowerCase();
    const list = this.liveIncidents();
    if (!q) return list;
    return list.filter((inc) => {
      const text = `${inc['id'] ?? ''} ${inc['emergencyType'] ?? ''} ${inc['priority'] ?? ''} ${inc['status'] ?? ''}`.toLowerCase();
      return text.includes(q);
    });
  });

  filteredUsers = computed(() => {
    const q = this.userFilter().trim().toLowerCase();
    const list = this.users();
    if (!q) return list;
    return list.filter((u) => {
      const roles = Array.isArray(u['roles']) ? (u['roles'] as string[]).join(' ') : '';
      const text = `${u['displayName'] ?? ''} ${u['email'] ?? ''} ${roles}`.toLowerCase();
      return text.includes(q);
    });
  });

  selectedCongestion: Record<string, number> = {};
  private pollTimer: ReturnType<typeof setInterval> | null = null;

  constructor(
    public readonly auth: AuthService,
    private readonly api: EccApiService,
  ) {}

  ngOnInit(): void {
    if (this.auth.isAuthenticated()) {
      this.activeTab.set(this.defaultTabForRoles(this.auth.roles()));
      this.refreshAll();
      this.startPolling();
    }
  }

  defaultTabForRoles(roles: string[]): PortalTab {
    if (roles.includes('ADMIN') || roles.includes('EMS')) return 'overview';
    if (roles.includes('HOSPITAL')) return 'hospitals';
    if (roles.includes('PHARMACIST')) return 'pharmacy';
    if (roles.includes('BLOOD_BANK_STAFF')) return 'bloodbank';
    if (roles.includes('LAB_STAFF') || roles.includes('DOCTOR')) return 'providers';
    return 'overview';
  }

  showBanner(message: string, tone: 'success' | 'error' | 'info' = 'success'): void {
    this.bannerTone.set(tone);
    this.statusBanner.set(message);
  }

  ngOnDestroy(): void {
    this.stopPolling();
  }

  toggleAutoRefresh(): void {
    const next = !this.autoRefresh();
    this.autoRefresh.set(next);
    if (next) {
      this.startPolling();
    } else {
      this.stopPolling();
    }
  }

  togglePasswordVisibility(): void {
    this.showPassword.set(!this.showPassword());
  }

  dismissBanner(): void {
    this.statusBanner.set(null);
  }

  private startPolling(): void {
    this.stopPolling();
    if (!this.autoRefresh()) return;
    this.pollTimer = setInterval(() => {
      if (this.auth.isAuthenticated()) {
        this.refreshAll(true);
      }
    }, 5000);
  }

  private stopPolling(): void {
    if (this.pollTimer !== null) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  selectDemoRole(email: string): void {
    this.email = email;
  }

  isSandboxSession(): boolean {
    const currentEmail = this.auth.currentUser()?.email ?? '';
    return currentEmail.endsWith('.local') || currentEmail.startsWith('demo.');
  }

  operatorInitials(): string {
    const name = (this.auth.currentUser()?.displayName ?? 'SA').trim();
    if (!name) return 'SA';
    const parts = name.split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }

  onLogin(): void {
    this.loginError.set(null);
    this.loading.set(true);
    this.auth.login(this.email.trim(), this.password).subscribe({
      next: () => {
        this.loading.set(false);
        this.password = '';
        this.showPassword.set(false);
        this.activeTab.set(this.defaultTabForRoles(this.auth.roles()));
        this.refreshAll();
        this.startPolling();
      },
      error: (err) => {
        this.loading.set(false);
        this.loginError.set(
          err?.error?.message ??
            'Authentication failed. Ensure Spring Boot API is running on localhost:8080.',
        );
      },
    });
  }

  onLogout(): void {
    this.stopPolling();
    this.auth.logout();
    this.activeTab.set('overview');
    this.selectedIncidentId.set(null);
    this.statusBanner.set(null);
    this.incidentFilter.set('');
    this.userFilter.set('');
  }

  setTab(tab: PortalTab): void {
    this.activeTab.set(tab);
  }

  refreshAll(silent = false): void {
    if (!silent) {
      this.statusBanner.set(null);
      this.refreshing.set(true);
      setTimeout(() => this.refreshing.set(false), 600);
    }
    this.lastSyncedAt.set(new Date().toLocaleTimeString());

    if (this.auth.hasAnyRole('ADMIN')) {
      this.api.getAdminOverview().subscribe({ next: (d) => this.overview.set(d), error: () => {} });
      this.api.getAdminUsers().subscribe({ next: (d) => this.users.set(d), error: () => {} });
      this.api.getAdminVolunteers().subscribe({ next: (d) => this.volunteers.set(d), error: () => {} });
      this.api.getAuditLogs().subscribe({ next: (d) => this.auditLogs.set(d), error: () => {} });
    }

    if (this.auth.hasAnyRole('EMS', 'ADMIN')) {
      this.api.getEmsDashboard().subscribe({
        next: (d) => {
          this.emsDashboard.set(d);
          const list = (d['incidents'] as Array<Record<string, unknown>> | undefined) ?? [];
          this.liveIncidents.set(list);
        },
        error: () => {},
      });
      this.api.getSmartErResearchComparison().subscribe({
        next: (d) => this.researchReport.set(d),
        error: () => {},
      });
    }

    if (this.auth.hasAnyRole('EMS', 'ADMIN', 'VOLUNTEER')) {
      this.api.getAnalyticsDashboard().subscribe({
        next: (d) => this.analytics.set(d),
        error: () => {},
      });
    }

    this.api.getHospitals().subscribe({
      next: (list) => {
        this.hospitals.set(list);
        for (const h of list) {
          const id = String(h['id'] ?? '');
          if (id && this.selectedCongestion[id] === undefined) {
            this.selectedCongestion[id] = 35;
          }
        }
      },
      error: () => {},
    });

    this.api.getAmbulances().subscribe({ next: (d) => this.ambulances.set(d), error: () => {} });
    this.api.getAeds().subscribe({ next: (d) => this.aeds.set(d), error: () => {} });
    this.api.getPharmacies().subscribe({ next: (d) => this.pharmacies.set(d), error: () => {} });

    if (this.auth.hasAnyRole('PHARMACIST', 'ADMIN')) {
      this.api.getPendingMedicineOrders().subscribe({ next: (d) => this.pendingOrders.set(d), error: () => {} });
      this.api.getDeliveries().subscribe({ next: (d) => this.deliveries.set(d), error: () => {} });
    }

    this.api.getBloodBanks().subscribe({ next: (d) => this.bloodBanks.set(d), error: () => {} });
    this.api.getBloodInventory().subscribe({ next: (d) => this.bloodInventory.set(d), error: () => {} });
    this.api.getBloodRequests().subscribe({ next: (d) => this.bloodRequests.set(d), error: () => {} });
    this.api.getLaboratories().subscribe({ next: (d) => this.laboratories.set(d), error: () => {} });
    this.api.getMedicalProviders().subscribe({ next: (d) => this.providers.set(d), error: () => {} });

    if (this.auth.hasAnyRole('LAB_STAFF', 'DOCTOR', 'ADMIN')) {
      this.api.getAllLabAppointments().subscribe({ next: (d) => this.labAppointments.set(d), error: () => {} });
    }
    if (this.auth.hasAnyRole('DOCTOR', 'ADMIN')) {
      this.api.getAllProviderAppointments().subscribe({ next: (d) => this.providerAppointments.set(d), error: () => {} });
    }
    if (this.auth.hasAnyRole('HOSPITAL', 'EMS', 'DOCTOR', 'ADMIN')) {
      this.api.getPendingHandovers().subscribe({ next: (d) => this.handovers.set(d), error: () => {} });
    }
  }

  inspectSmartEr(incidentId: string): void {
    this.selectedIncidentId.set(incidentId);
    this.smartErResults.set([]);
    this.api.getSmartErRecommendations(incidentId).subscribe({
      next: (recs) => this.smartErResults.set(recs),
      error: () =>
        this.showBanner('Could not load Smart ER recommendations for this incident.', 'error'),
    });
  }

  dispatchEms(incidentId: string): void {
    this.api.assignEmsToIncident(incidentId).subscribe({
      next: () => {
        this.showBanner(`EMS coordination started for incident ${incidentId.slice(0, 8)}...`, 'success');
        this.refreshAll(true);
      },
      error: () =>
        this.showBanner('Incident already assigned or EMS transition not allowed in current state.', 'error'),
    });
  }

  setCongestionPreset(hospitalId: string, pct: number): void {
    this.selectedCongestion[hospitalId] = pct;
  }

  updateCapacity(hospitalId: string): void {
    const raw = Number(this.selectedCongestion[hospitalId] ?? 35);
    const val = Number.isNaN(raw) ? 35 : Math.max(0, Math.min(100, Math.round(raw)));
    this.selectedCongestion[hospitalId] = val;
    this.api.updateHospitalCapacity(hospitalId, val, 'ECC Web Portal Update').subscribe({
      next: () => {
        this.showBanner(`Hospital capacity updated to ${val}% congestion.`, 'success');
        this.refreshAll(true);
      },
      error: () =>
        this.showBanner('Permission denied or failed to update hospital capacity.', 'error'),
    });
  }

  acknowledgeHandover(handoverId: string): void {
    const staff = this.auth.currentUser()?.displayName ?? 'Hospital ER Lead';
    this.api.acknowledgeHandover(handoverId, staff).subscribe({
      next: () => {
        this.showBanner(`Medical handover acknowledged by ${staff}.`, 'success');
        this.refreshAll(true);
      },
      error: () =>
        this.showBanner('Unable to acknowledge handover (requires HOSPITAL/DOCTOR/ADMIN role).', 'error'),
    });
  }

  advanceOrderStatus(orderId: string, status: string): void {
    this.api.updateMedicineOrderStatus(orderId, status).subscribe({
      next: () => {
        this.showBanner(`Pharmacy order updated to ${status}.`, 'success');
        this.refreshAll(true);
      },
      error: () => this.showBanner('Unable to update order status.', 'error'),
    });
  }

  advanceDeliveryStatus(trackingCode: string, status: string): void {
    this.api.updateDeliveryStatus(trackingCode, status).subscribe({
      next: () => {
        this.showBanner(`Delivery ${trackingCode} marked ${status}.`, 'success');
        this.refreshAll(true);
      },
      error: () => this.showBanner('Unable to update delivery status.', 'error'),
    });
  }

  fulfillBloodRequest(requestId: string): void {
    this.api.updateBloodRequestStatus(requestId, 'FULFILLED').subscribe({
      next: () => {
        this.showBanner('Blood request marked FULFILLED.', 'success');
        this.refreshAll(true);
      },
      error: () => this.showBanner('Unable to update blood request status.', 'error'),
    });
  }

  publishLabResult(appId: string): void {
    this.api.publishLabResult(appId, 'Verified Panel Complete — Within Reference Range').subscribe({
      next: () => {
        this.showBanner('Laboratory report published and marked COMPLETED.', 'success');
        this.refreshAll(true);
      },
      error: () => this.showBanner('Unable to publish laboratory result.', 'error'),
    });
  }

  confirmProviderAppointment(appId: string): void {
    this.api.updateProviderAppointmentStatus(appId, 'CONFIRMED').subscribe({
      next: () => {
        this.showBanner('Medical provider appointment CONFIRMED.', 'success');
        this.refreshAll(true);
      },
      error: () => this.showBanner('Unable to update appointment status.', 'error'),
    });
  }

  verifyVolunteerAccount(userId: string): void {
    this.api.verifyVolunteer(userId).subscribe({
      next: () => {
        this.showBanner('Volunteer verified and cleared for Smart Dispatch.', 'success');
        this.refreshAll(true);
      },
      error: () => this.showBanner('Unable to verify volunteer.', 'error'),
    });
  }

  safeRoles(roles: unknown): string[] {
    return Array.isArray(roles) ? roles.map((r) => String(r)) : [];
  }

  formatCoords(loc: unknown): string {
    const obj = loc as Record<string, unknown> | null | undefined;
    if (!obj) return '—';
    const lat = Number(obj['latitude'] ?? 0).toFixed(4);
    const lng = Number(obj['longitude'] ?? 0).toFixed(4);
    return `${lat}, ${lng}`;
  }

  formatTime(ts: unknown): string {
    if (!ts) return '—';
    const raw = String(ts);
    const parsed = new Date(raw);
    if (Number.isNaN(parsed.getTime())) return raw;
    return parsed.toLocaleString(undefined, {
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  priorityClass(priority: unknown): string {
    const p = String(priority ?? '').toUpperCase();
    if (p === 'CRITICAL' || p === 'EMERGENCY') return 'badge-critical';
    if (p === 'HIGH' || p === 'URGENT') return 'badge-high';
    return 'badge-standard';
  }

  statusClass(status: unknown): string {
    const s = String(status ?? '').toUpperCase();
    if (
      s === 'RESOLVED' ||
      s === 'COMPLETED' ||
      s === 'FULFILLED' ||
      s === 'DELIVERED' ||
      s === 'VERIFIED' ||
      s === 'ACTIVE' ||
      s === 'AVAILABLE' ||
      s === 'CONFIRMED'
    ) {
      return 'status-success';
    }
    if (
      s === 'EMS_ASSIGNED' ||
      s === 'RESPONDER_ASSIGNED' ||
      s === 'AMBULANCE_ASSIGNED' ||
      s === 'DISPATCHED' ||
      s === 'IN_TRANSIT' ||
      s === 'EN_ROUTE' ||
      s === 'HOSPITAL_SELECTED'
    ) {
      return 'status-info';
    }
    if (s === 'SEARCHING' || s === 'PENDING' || s === 'SCHEDULED' || s === 'NEW') {
      return 'status-warning';
    }
    if (s === 'CANCELLED' || s === 'DISABLED' || s === 'CRITICAL') {
      return 'status-critical';
    }
    return 'status-muted';
  }

  congestionClass(val: number | null | undefined): string {
    const n = val === null || val === undefined ? 35 : Number(val);
    if (Number.isNaN(n)) return 'bar-green';
    if (n >= 75) return 'bar-red';
    if (n >= 45) return 'bar-amber';
    return 'bar-green';
  }

  bloodLevelPercent(units: unknown): number {
    const n = Number(units ?? 0);
    if (Number.isNaN(n) || n <= 0) return 0;
    return Math.min(100, Math.round((n / 20) * 100));
  }

  bloodLevelClass(units: unknown): string {
    const n = Number(units ?? 0);
    if (n <= 4) return 'blood-critical';
    if (n <= 9) return 'blood-low';
    return 'blood-healthy';
  }

  asPercent(val: unknown): number {
    const n = Number(val ?? 0);
    if (Number.isNaN(n)) return 0;
    return Math.max(0, Math.min(100, n));
  }
}

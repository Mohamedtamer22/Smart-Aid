import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class EccApiService {
  constructor(
    private readonly http: HttpClient,
    private readonly auth: AuthService,
  ) {}

  private url(path: string): string {
    return `${this.auth.apiBase}${path}`;
  }

  // Admin & ECC Overview
  getAdminOverview() {
    return this.http.get<Record<string, unknown>>(this.url('/api/admin/overview'));
  }

  getAdminUsers() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/admin/users'));
  }

  updateUserStatus(userId: string, enabled: boolean) {
    return this.http.patch<Record<string, unknown>>(
      this.url(`/api/admin/users/${userId}/status`),
      { enabled },
    );
  }

  getAdminVolunteers() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/admin/volunteers'));
  }

  verifyVolunteer(userId: string) {
    return this.http.post<void>(this.url(`/api/admin/volunteers/${userId}/verify`), {});
  }

  getAuditLogs() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/admin/audit-logs'));
  }

  // EMS & Live Incidents + Smart ER
  getEmsDashboard() {
    return this.http.get<Record<string, unknown>>(this.url('/api/ems/dashboard'));
  }

  assignEmsToIncident(incidentId: string) {
    return this.http.post<Record<string, unknown>>(
      this.url(`/api/ems/incidents/${incidentId}/assign`),
      {},
    );
  }

  getSmartErRecommendations(incidentId: string) {
    return this.http.get<Array<Record<string, unknown>>>(
      this.url(`/api/smart-er/incidents/${incidentId}/recommendations`),
    );
  }

  // Analytics & Research Benchmark
  getAnalyticsDashboard() {
    return this.http.get<Record<string, unknown>>(this.url('/api/analytics/dashboard'));
  }

  getSmartErResearchComparison() {
    return this.http.get<Record<string, unknown>>(
      this.url('/api/analytics/research/smart-er-comparison'),
    );
  }

  // Hospitals, Fleet & AEDs
  getHospitals() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/hospitals'));
  }

  updateHospitalCapacity(hospitalId: string, estimatedCongestion: number, sourceNote: string) {
    return this.http.patch<Record<string, unknown>>(
      this.url(`/api/hospitals/${hospitalId}/capacity`),
      { estimatedCongestion, sourceNote },
    );
  }

  getAeds() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/aed-devices'));
  }

  getAmbulances() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/ambulances'));
  }

  // Smart Pharmacy & Medical Delivery (F09 + F13)
  getPharmacies() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/pharmacies'));
  }

  getPendingMedicineOrders() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/pharmacies/orders/pending'));
  }

  updateMedicineOrderStatus(orderId: string, status: string) {
    return this.http.patch<Record<string, unknown>>(
      this.url(`/api/pharmacies/orders/${orderId}/status`),
      { status },
    );
  }

  getDeliveries() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/medical-deliveries'));
  }

  updateDeliveryStatus(trackingCode: string, status: string) {
    return this.http.patch<Record<string, unknown>>(
      this.url(`/api/medical-deliveries/${encodeURIComponent(trackingCode)}/status`),
      { status },
    );
  }

  // Smart Blood Bank (F11)
  getBloodBanks() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/blood-banks'));
  }

  getBloodInventory() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/blood-banks/inventory'));
  }

  updateBloodInventory(bankId: string, bloodGroup: string, unitsAvailable: number) {
    return this.http.put<Record<string, unknown>>(
      this.url(`/api/blood-banks/${bankId}/inventory/${encodeURIComponent(bloodGroup)}`),
      { unitsAvailable },
    );
  }

  getBloodRequests() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/blood-requests'));
  }

  updateBloodRequestStatus(requestId: string, status: string) {
    return this.http.patch<Record<string, unknown>>(
      this.url(`/api/blood-requests/${requestId}/status`),
      { status },
    );
  }

  // Smart Lab & Medical Providers (F10 + F12)
  getLaboratories() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/laboratories'));
  }

  getAllLabAppointments() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/lab-appointments'));
  }

  publishLabResult(appId: string, resultSummary: string) {
    return this.http.put<Record<string, unknown>>(
      this.url(`/api/lab-appointments/${appId}/result`),
      { resultSummary },
    );
  }

  getMedicalProviders() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/medical-providers'));
  }

  getAllProviderAppointments() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/provider-appointments'));
  }

  updateProviderAppointmentStatus(appId: string, status: string) {
    return this.http.patch<Record<string, unknown>>(
      this.url(`/api/provider-appointments/${appId}/status`),
      { status },
    );
  }

  // Medical Handovers (F15)
  getPendingHandovers() {
    return this.http.get<Array<Record<string, unknown>>>(this.url('/api/handovers/pending'));
  }

  acknowledgeHandover(handoverId: string, receivingStaffName: string) {
    return this.http.post<Record<string, unknown>>(
      this.url(`/api/handovers/${handoverId}/acknowledge`),
      { receivingStaffName },
    );
  }
}

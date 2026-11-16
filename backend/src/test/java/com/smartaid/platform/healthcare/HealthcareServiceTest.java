package com.smartaid.platform.healthcare;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.exception.ApiException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class HealthcareServiceTest {
    private PharmacyRepository pharmacies;
    private MedicineRepository medicines;
    private PharmacyInventoryRepository pharmacyInventories;
    private MedicineOrderRepository medicineOrders;
    private BloodBankRepository bloodBanks;
    private BloodInventoryRepository bloodInventories;
    private BloodRequestRepository bloodRequests;
    private LaboratoryRepository laboratories;
    private LabServiceRepository labServices;
    private LabAppointmentRepository labAppointments;
    private MedicalProviderRepository medicalProviders;
    private ProviderAppointmentRepository providerAppointments;
    private MedicalDeliveryRepository medicalDeliveries;
    private MedicalHandoverRepository medicalHandovers;
    private AuditService audit;
    private HealthcareService service;

    @BeforeEach
    void setUp() {
        pharmacies = mock(PharmacyRepository.class);
        medicines = mock(MedicineRepository.class);
        pharmacyInventories = mock(PharmacyInventoryRepository.class);
        medicineOrders = mock(MedicineOrderRepository.class);
        bloodBanks = mock(BloodBankRepository.class);
        bloodInventories = mock(BloodInventoryRepository.class);
        bloodRequests = mock(BloodRequestRepository.class);
        laboratories = mock(LaboratoryRepository.class);
        labServices = mock(LabServiceRepository.class);
        labAppointments = mock(LabAppointmentRepository.class);
        medicalProviders = mock(MedicalProviderRepository.class);
        providerAppointments = mock(ProviderAppointmentRepository.class);
        medicalDeliveries = mock(MedicalDeliveryRepository.class);
        medicalHandovers = mock(MedicalHandoverRepository.class);
        audit = mock(AuditService.class);

        service = new HealthcareService(
                pharmacies, medicines, pharmacyInventories, medicineOrders,
                bloodBanks, bloodInventories, bloodRequests,
                laboratories, labServices, labAppointments,
                medicalProviders, providerAppointments,
                medicalDeliveries, medicalHandovers, audit
        );
    }

    @Test
    void placeMedicineOrder_blocks_prescription_only_medicines() {
        UUID userId = UUID.randomUUID();
        UUID pharmacyId = UUID.randomUUID();
        UUID medId = UUID.randomUUID();
        Pharmacy pharmacy = new Pharmacy("Test Pharmacy", "123 St", 30.0, 31.0, "123", "24/7", true, true);
        Medicine rxMed = new Medicine("Amoxicillin", "Amoxicillin", "Capsule", false, true);

        when(pharmacies.findById(pharmacyId)).thenReturn(Optional.of(pharmacy));
        when(medicines.findById(medId)).thenReturn(Optional.of(rxMed));

        ApiException ex = assertThrows(ApiException.class, () -> service.placeMedicineOrder(
                userId, new HealthcareDtos.CreateMedicineOrderRequest(pharmacyId, medId, 1, false, null)));
        assertEquals(HttpStatus.FORBIDDEN, ex.status());
        assertEquals("PRESCRIPTION_REQUIRED", ex.code());
    }

    @Test
    void placeMedicineOrder_deducts_stock_and_creates_delivery_when_requested() {
        UUID userId = UUID.randomUUID();
        UUID pharmacyId = UUID.randomUUID();
        UUID medId = UUID.randomUUID();
        Pharmacy pharmacy = new Pharmacy("Nile Pharmacy", "14 Tahrir", 30.0, 31.0, "123", "24/7", true, true);
        Medicine gauze = new Medicine("Compression Gauze", "Cotton", "Roll", true, false);
        PharmacyInventory inv = new PharmacyInventory(pharmacyId, medId, 10, BigDecimal.valueOf(45));

        when(pharmacies.findById(pharmacyId)).thenReturn(Optional.of(pharmacy));
        when(medicines.findById(medId)).thenReturn(Optional.of(gauze));
        when(pharmacyInventories.findByPharmacyIdAndMedicineId(pharmacyId, medId)).thenReturn(Optional.of(inv));
        when(medicineOrders.save(any(MedicineOrder.class))).thenAnswer(i -> {
            MedicineOrder order = i.getArgument(0);
            try {
                var idField = MedicineOrder.class.getDeclaredField("id");
                idField.setAccessible(true);
                idField.set(order, UUID.randomUUID());
            } catch (Exception ignored) { }
            return order;
        });

        MedicineOrder order = service.placeMedicineOrder(
                userId, new HealthcareDtos.CreateMedicineOrderRequest(pharmacyId, medId, 3, true, "Zamalek St 5"));

        assertEquals(7, inv.getStockQuantity());
        assertEquals("PLACED", order.getOrderStatus());
        verify(medicalDeliveries).save(any(MedicalDelivery.class));
        verify(audit).record(eq(userId), eq("MEDICINE_ORDER_PLACED"), eq("MEDICINE_ORDER"), any());
    }

    @Test
    void createBloodRequest_rejects_invalid_blood_group() {
        UUID userId = UUID.randomUUID();
        ApiException ex = assertThrows(ApiException.class, () -> service.createBloodRequest(
                userId, new HealthcareDtos.CreateBloodRequest(null, null, "Z+", 2, "URGENT")));
        assertEquals(HttpStatus.BAD_REQUEST, ex.status());
        assertEquals("INVALID_BLOOD_GROUP", ex.code());
    }

    @Test
    void updateBloodInventory_normalizes_blood_group_and_audits() {
        UUID staffId = UUID.randomUUID();
        UUID bankId = UUID.randomUUID();
        BloodBank bank = new BloodBank("Central Blood Bank", "Dokki", 30.0, 31.0, "555", true);
        when(bloodBanks.findById(bankId)).thenReturn(Optional.of(bank));
        when(bloodInventories.findByBloodBankIdAndBloodGroupIgnoreCase(bankId, "O-")).thenReturn(Optional.empty());
        when(bloodInventories.save(any(BloodInventory.class))).thenAnswer(i -> i.getArgument(0));

        BloodInventory saved = service.updateBloodInventory(staffId, bankId, " o- ", 15);
        assertEquals("O-", saved.getBloodGroup());
        assertEquals(15, saved.getUnitsAvailable());
        verify(audit).record(eq(staffId), eq("BLOOD_INVENTORY_UPDATED"), eq("BLOOD_INVENTORY"), any());
    }

    @Test
    void getLabAppointment_blocks_unauthorized_cross_patient_access() {
        UUID patientA = UUID.randomUUID();
        UUID patientB = UUID.randomUUID();
        UUID appId = UUID.randomUUID();
        LabAppointment app = new LabAppointment(patientA, UUID.randomUUID(), UUID.randomUUID(), Instant.now());
        when(labAppointments.findById(appId)).thenReturn(Optional.of(app));

        ApiException ex = assertThrows(ApiException.class, () -> service.getLabAppointment(appId, patientB, false));
        assertEquals(HttpStatus.FORBIDDEN, ex.status());
    }

    @Test
    void bookProviderAppointment_blocks_telemedicine_when_provider_disables_it() {
        UUID userId = UUID.randomUUID();
        UUID providerId = UUID.randomUUID();
        MedicalProvider radiology = new MedicalProvider("Rapid CT", "RADIOLOGY", "Imaging", "Maadi", 29.9, 31.2, "123", true, false);
        when(medicalProviders.findById(providerId)).thenReturn(Optional.of(radiology));

        ApiException ex = assertThrows(ApiException.class, () -> service.bookProviderAppointment(
                userId, new HealthcareDtos.CreateProviderAppointmentRequest(providerId, Instant.now(), "TELEMEDICINE", "Checkup")));
        assertEquals(HttpStatus.BAD_REQUEST, ex.status());
        assertEquals("TELEMEDICINE_UNAVAILABLE", ex.code());
    }

    @Test
    void updateDeliveryStatus_delivered_sets_eta_zero_and_timestamp() {
        UUID staffId = UUID.randomUUID();
        MedicalDelivery delivery = new MedicalDelivery(UUID.randomUUID(), "SA-DEL-12345678", "Courier", "123", 20, "A", "B");
        when(medicalDeliveries.findByTrackingCodeIgnoreCase("SA-DEL-12345678")).thenReturn(Optional.of(delivery));
        when(medicalDeliveries.save(any(MedicalDelivery.class))).thenAnswer(i -> i.getArgument(0));

        MedicalDelivery updated = service.updateDeliveryStatus(staffId, "SA-DEL-12345678", "DELIVERED", null);
        assertEquals("DELIVERED", updated.getDeliveryStatus());
        assertEquals(0, updated.getEtaMinutes());
        assertNotNull(updated.getDeliveredAt());
    }

    @Test
    void createAndAcknowledgeHandover_records_hospital_staff_and_timestamp() {
        UUID emsId = UUID.randomUUID();
        UUID hospitalStaffId = UUID.randomUUID();
        UUID handoverId = UUID.randomUUID();
        MedicalHandover handover = new MedicalHandover(
                UUID.randomUUID(), emsId, UUID.randomUUID(),
                "CRITICAL Cardiac", "BP 100/60, HR 115", "O2 4L + Aspirin", "Penicillin", "Beta-blocker"
        );
        when(medicalHandovers.save(any(MedicalHandover.class))).thenAnswer(i -> i.getArgument(0));
        when(medicalHandovers.findById(handoverId)).thenReturn(Optional.of(handover));

        MedicalHandover acked = service.acknowledgeHandover(hospitalStaffId, handoverId, "Dr. Tariq ER Lead");
        assertEquals("ACKNOWLEDGED", acked.getHandoverStatus());
        assertEquals("Dr. Tariq ER Lead", acked.getReceivingStaffName());
        assertNotNull(acked.getAcknowledgedAt());
        verify(audit).record(eq(hospitalStaffId), eq("MEDICAL_HANDOVER_ACKNOWLEDGED"), eq("MEDICAL_HANDOVER"), any());
    }
}

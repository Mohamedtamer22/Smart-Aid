package com.smartaid.platform.healthcare;

import com.smartaid.platform.audit.AuditService;
import com.smartaid.platform.exception.ApiException;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class HealthcareService {
    private static final Set<String> VALID_BLOOD_GROUPS = Set.of("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-");

    private final PharmacyRepository pharmacies;
    private final MedicineRepository medicines;
    private final PharmacyInventoryRepository pharmacyInventories;
    private final MedicineOrderRepository medicineOrders;
    private final BloodBankRepository bloodBanks;
    private final BloodInventoryRepository bloodInventories;
    private final BloodRequestRepository bloodRequests;
    private final LaboratoryRepository laboratories;
    private final LabServiceRepository labServices;
    private final LabAppointmentRepository labAppointments;
    private final MedicalProviderRepository medicalProviders;
    private final ProviderAppointmentRepository providerAppointments;
    private final MedicalDeliveryRepository medicalDeliveries;
    private final MedicalHandoverRepository medicalHandovers;
    private final AuditService audit;

    public HealthcareService(
            PharmacyRepository pharmacies,
            MedicineRepository medicines,
            PharmacyInventoryRepository pharmacyInventories,
            MedicineOrderRepository medicineOrders,
            BloodBankRepository bloodBanks,
            BloodInventoryRepository bloodInventories,
            BloodRequestRepository bloodRequests,
            LaboratoryRepository laboratories,
            LabServiceRepository labServices,
            LabAppointmentRepository labAppointments,
            MedicalProviderRepository medicalProviders,
            ProviderAppointmentRepository providerAppointments,
            MedicalDeliveryRepository medicalDeliveries,
            MedicalHandoverRepository medicalHandovers,
            AuditService audit
    ) {
        this.pharmacies = pharmacies;
        this.medicines = medicines;
        this.pharmacyInventories = pharmacyInventories;
        this.medicineOrders = medicineOrders;
        this.bloodBanks = bloodBanks;
        this.bloodInventories = bloodInventories;
        this.bloodRequests = bloodRequests;
        this.laboratories = laboratories;
        this.labServices = labServices;
        this.labAppointments = labAppointments;
        this.medicalProviders = medicalProviders;
        this.providerAppointments = providerAppointments;
        this.medicalDeliveries = medicalDeliveries;
        this.medicalHandovers = medicalHandovers;
        this.audit = audit;
    }

    // ==================== F09: SMART PHARMACY ====================

    @Transactional(readOnly = true)
    public List<Pharmacy> listPharmacies(boolean emergencySuppliesOnly) {
        return emergencySuppliesOnly
                ? pharmacies.findByVerifiedTrueAndEmergencySuppliesAvailableTrueOrderByNameAsc()
                : pharmacies.findByVerifiedTrueOrderByNameAsc();
    }

    @Transactional(readOnly = true)
    public Pharmacy getPharmacy(UUID id) {
        return pharmacies.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "PHARMACY_NOT_FOUND", "Pharmacy was not found"));
    }

    @Transactional
    public Pharmacy createPharmacy(UUID actorId, HealthcareDtos.CreatePharmacyRequest req) {
        Pharmacy saved = pharmacies.save(new Pharmacy(
                req.name().trim(),
                req.address().trim(),
                req.latitude(),
                req.longitude(),
                req.phone(),
                req.openingHours(),
                true,
                req.emergencySuppliesAvailable() == null || req.emergencySuppliesAvailable()
        ));
        audit.record(actorId, "PHARMACY_CREATED", "PHARMACY", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<Medicine> searchMedicines(String query, boolean emergencySuppliesOnly) {
        if (emergencySuppliesOnly) {
            List<Medicine> supplies = medicines.findByIsEmergencySupplyTrueOrderByNameAsc();
            if (query == null || query.isBlank()) return supplies;
            String q = query.trim().toLowerCase();
            return supplies.stream()
                    .filter(m -> m.getName().toLowerCase().contains(q)
                            || (m.getActiveIngredient() != null && m.getActiveIngredient().toLowerCase().contains(q)))
                    .toList();
        }
        if (query == null || query.isBlank()) {
            return medicines.findAll();
        }
        String trimmed = query.trim();
        return medicines.findByNameContainingIgnoreCaseOrActiveIngredientContainingIgnoreCase(trimmed, trimmed);
    }

    @Transactional(readOnly = true)
    public List<HealthcareDtos.PharmacyInventoryItemResponse> getPharmacyInventory(UUID pharmacyId) {
        getPharmacy(pharmacyId);
        List<PharmacyInventory> items = pharmacyInventories.findByPharmacyId(pharmacyId);
        Map<UUID, Medicine> medMap = medicines.findAllById(
                items.stream().map(PharmacyInventory::getMedicineId).toList()
        ).stream().collect(Collectors.toMap(Medicine::getId, Function.identity()));

        return items.stream().map(item -> {
            Medicine m = medMap.get(item.getMedicineId());
            return new HealthcareDtos.PharmacyInventoryItemResponse(
                    item.getId(),
                    item.getPharmacyId(),
                    item.getMedicineId(),
                    m != null ? m.getName() : "Unknown",
                    m != null ? m.getActiveIngredient() : null,
                    m != null ? m.getDosageForm() : null,
                    m != null && m.isEmergencySupply(),
                    m != null && m.isPrescriptionRequired(),
                    item.getStockQuantity(),
                    item.getUnitPrice(),
                    item.getUpdatedAt()
            );
        }).toList();
    }

    @Transactional
    public PharmacyInventory updatePharmacyInventory(UUID actorId, UUID pharmacyId, UUID medicineId, HealthcareDtos.UpdateInventoryRequest req) {
        getPharmacy(pharmacyId);
        medicines.findById(medicineId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "MEDICINE_NOT_FOUND", "Medicine was not found"));
        PharmacyInventory inv = pharmacyInventories.findByPharmacyIdAndMedicineId(pharmacyId, medicineId)
                .orElseGet(() -> new PharmacyInventory(pharmacyId, medicineId, req.stockQuantity(),
                        req.unitPrice() != null ? req.unitPrice() : BigDecimal.ZERO));
        inv.setStockQuantity(req.stockQuantity());
        if (req.unitPrice() != null) {
            inv.setUnitPrice(req.unitPrice());
        }
        PharmacyInventory saved = pharmacyInventories.save(inv);
        audit.record(actorId, "PHARMACY_INVENTORY_UPDATED", "PHARMACY_INVENTORY", saved.getId());
        return saved;
    }

    @Transactional
    public MedicineOrder placeMedicineOrder(UUID userId, HealthcareDtos.CreateMedicineOrderRequest req) {
        Pharmacy pharmacy = getPharmacy(req.pharmacyId());
        Medicine med = medicines.findById(req.medicineId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "MEDICINE_NOT_FOUND", "Medicine was not found"));
        if (med.isPrescriptionRequired()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "PRESCRIPTION_REQUIRED",
                    "Prescription-only medications cannot be ordered without authorized pharmacist verification");
        }
        PharmacyInventory inv = pharmacyInventories.findByPharmacyIdAndMedicineId(req.pharmacyId(), req.medicineId())
                .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "OUT_OF_STOCK", "Item is not stocked at this pharmacy"));
        if (inv.getStockQuantity() < req.quantity()) {
            throw new ApiException(HttpStatus.CONFLICT, "INSUFFICIENT_STOCK",
                    "Requested quantity exceeds currently verified stock (" + inv.getStockQuantity() + ")");
        }
        inv.setStockQuantity(inv.getStockQuantity() - req.quantity());
        pharmacyInventories.save(inv);

        boolean delivery = Boolean.TRUE.equals(req.deliveryRequested());
        MedicineOrder saved = medicineOrders.save(new MedicineOrder(
                userId, req.pharmacyId(), req.medicineId(), req.quantity(), delivery, req.deliveryAddress()
        ));
        if (delivery) {
            String trackingCode = "SA-DEL-" + saved.getId().toString().substring(0, 8).toUpperCase();
            medicalDeliveries.save(new MedicalDelivery(
                    saved.getId(), trackingCode, "Smart Aid Sandbox Courier", "+20-100-000-0100",
                    25, pharmacy.getAddress(),
                    req.deliveryAddress() != null ? req.deliveryAddress() : "Patient Address"
            ));
        }
        audit.record(userId, "MEDICINE_ORDER_PLACED", "MEDICINE_ORDER", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<MedicineOrder> myMedicineOrders(UUID userId) {
        return medicineOrders.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<MedicineOrder> pendingMedicineOrders() {
        return medicineOrders.findByOrderStatusOrderByCreatedAtDesc("PLACED");
    }

    @Transactional(readOnly = true)
    public MedicineOrder getMedicineOrder(UUID orderId, UUID actorId, boolean privileged) {
        MedicineOrder order = medicineOrders.findById(orderId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "ORDER_NOT_FOUND", "Order was not found"));
        if (!privileged && !order.getUserId().equals(actorId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You cannot view another user's order");
        }
        return order;
    }

    @Transactional
    public MedicineOrder updateMedicineOrderStatus(UUID actorId, UUID orderId, String status) {
        MedicineOrder order = medicineOrders.findById(orderId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "ORDER_NOT_FOUND", "Order was not found"));
        order.setOrderStatus(status.trim().toUpperCase());
        MedicineOrder saved = medicineOrders.save(order);
        audit.record(actorId, "MEDICINE_ORDER_STATUS_UPDATED", "MEDICINE_ORDER", saved.getId());
        return saved;
    }

    // ==================== F11: SMART BLOOD BANK ====================

    @Transactional(readOnly = true)
    public List<BloodBank> listBloodBanks() {
        return bloodBanks.findByVerifiedTrueOrderByNameAsc();
    }

    @Transactional(readOnly = true)
    public BloodBank getBloodBank(UUID bankId) {
        return bloodBanks.findById(bankId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "BLOOD_BANK_NOT_FOUND", "Blood bank was not found"));
    }

    @Transactional
    public BloodBank createBloodBank(UUID actorId, HealthcareDtos.CreateBloodBankRequest req) {
        BloodBank saved = bloodBanks.save(new BloodBank(
                req.name().trim(), req.address().trim(), req.latitude(), req.longitude(), req.phone(), true
        ));
        audit.record(actorId, "BLOOD_BANK_CREATED", "BLOOD_BANK", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<BloodInventory> getBloodBankInventory(UUID bankId) {
        getBloodBank(bankId);
        return bloodInventories.findByBloodBankIdOrderByBloodGroupAsc(bankId);
    }

    @Transactional(readOnly = true)
    public List<BloodInventory> searchBloodInventory(String bloodGroup) {
        if (bloodGroup == null || bloodGroup.isBlank()) {
            return bloodInventories.findAll();
        }
        String normalized = normalizeBloodGroup(bloodGroup);
        return bloodInventories.findByBloodGroupIgnoreCaseAndUnitsAvailableGreaterThan(normalized, 0);
    }

    @Transactional
    public BloodInventory updateBloodInventory(UUID actorId, UUID bankId, String bloodGroup, int unitsAvailable) {
        getBloodBank(bankId);
        String normalized = normalizeBloodGroup(bloodGroup);
        BloodInventory inv = bloodInventories.findByBloodBankIdAndBloodGroupIgnoreCase(bankId, normalized)
                .orElseGet(() -> new BloodInventory(bankId, normalized, unitsAvailable));
        inv.setUnitsAvailable(unitsAvailable);
        BloodInventory saved = bloodInventories.save(inv);
        audit.record(actorId, "BLOOD_INVENTORY_UPDATED", "BLOOD_INVENTORY", saved.getId());
        return saved;
    }

    @Transactional
    public BloodRequest createBloodRequest(UUID actorId, HealthcareDtos.CreateBloodRequest req) {
        String normalized = normalizeBloodGroup(req.bloodGroup());
        if (req.bloodBankId() != null) {
            getBloodBank(req.bloodBankId());
        }
        BloodRequest saved = bloodRequests.save(new BloodRequest(
                actorId, req.bloodBankId(), req.incidentId(), normalized, req.unitsRequested(), req.urgency()
        ));
        audit.record(actorId, "BLOOD_REQUEST_CREATED", "BLOOD_REQUEST", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<BloodRequest> listBloodRequests(UUID actorId, boolean privileged) {
        return privileged ? bloodRequests.findAllByOrderByCreatedAtDesc()
                : bloodRequests.findByRequesterIdOrderByCreatedAtDesc(actorId);
    }

    @Transactional(readOnly = true)
    public BloodRequest getBloodRequest(UUID reqId, UUID actorId, boolean privileged) {
        BloodRequest req = bloodRequests.findById(reqId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "BLOOD_REQUEST_NOT_FOUND", "Blood request was not found"));
        if (!privileged && !req.getRequesterId().equals(actorId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You cannot inspect another user's blood request");
        }
        return req;
    }

    @Transactional
    public BloodRequest updateBloodRequestStatus(UUID actorId, UUID reqId, String status) {
        BloodRequest req = bloodRequests.findById(reqId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "BLOOD_REQUEST_NOT_FOUND", "Blood request was not found"));
        req.setStatus(status.trim().toUpperCase());
        BloodRequest saved = bloodRequests.save(req);
        audit.record(actorId, "BLOOD_REQUEST_STATUS_UPDATED", "BLOOD_REQUEST", saved.getId());
        return saved;
    }

    // ==================== F10: SMART LAB ====================

    @Transactional(readOnly = true)
    public List<Laboratory> listLaboratories() {
        return laboratories.findByVerifiedTrueOrderByNameAsc();
    }

    @Transactional
    public Laboratory createLaboratory(UUID actorId, HealthcareDtos.CreateLaboratoryRequest req) {
        Laboratory saved = laboratories.save(new Laboratory(
                req.name().trim(), req.address().trim(), req.latitude(), req.longitude(), req.phone(), true
        ));
        audit.record(actorId, "LABORATORY_CREATED", "LABORATORY", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<LabServiceEntity> listLabServices(UUID labId) {
        laboratories.findById(labId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LABORATORY_NOT_FOUND", "Laboratory was not found"));
        return labServices.findByLaboratoryIdOrderByServiceNameAsc(labId);
    }

    @Transactional
    public LabServiceEntity createLabService(UUID actorId, UUID labId, HealthcareDtos.CreateLabServiceRequest req) {
        laboratories.findById(labId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LABORATORY_NOT_FOUND", "Laboratory was not found"));
        LabServiceEntity saved = labServices.save(new LabServiceEntity(
                labId, req.serviceName().trim(), req.category(), req.turnaroundHours(), req.price()
        ));
        audit.record(actorId, "LAB_SERVICE_CREATED", "LAB_SERVICE", saved.getId());
        return saved;
    }

    @Transactional
    public LabAppointment bookLabAppointment(UUID userId, HealthcareDtos.CreateLabAppointmentRequest req) {
        laboratories.findById(req.laboratoryId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LABORATORY_NOT_FOUND", "Laboratory was not found"));
        LabServiceEntity svc = labServices.findById(req.labServiceId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LAB_SERVICE_NOT_FOUND", "Laboratory service was not found"));
        if (!svc.getLaboratoryId().equals(req.laboratoryId())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "SERVICE_LAB_MISMATCH", "Service does not belong to this laboratory");
        }
        LabAppointment saved = labAppointments.save(new LabAppointment(
                userId, req.laboratoryId(), req.labServiceId(), req.scheduledAt()
        ));
        audit.record(userId, "LAB_APPOINTMENT_BOOKED", "LAB_APPOINTMENT", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<LabAppointment> myLabAppointments(UUID userId) {
        return labAppointments.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<LabAppointment> allLabAppointments() {
        return labAppointments.findAll();
    }

    @Transactional(readOnly = true)
    public LabAppointment getLabAppointment(UUID appId, UUID actorId, boolean privileged) {
        LabAppointment app = labAppointments.findById(appId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LAB_APPOINTMENT_NOT_FOUND", "Lab appointment was not found"));
        if (!privileged && !app.getUserId().equals(actorId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You cannot access another patient's lab record");
        }
        return app;
    }

    @Transactional
    public LabAppointment updateLabAppointmentStatus(UUID actorId, UUID appId, String status) {
        LabAppointment app = labAppointments.findById(appId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LAB_APPOINTMENT_NOT_FOUND", "Lab appointment was not found"));
        app.setStatus(status.trim().toUpperCase());
        LabAppointment saved = labAppointments.save(app);
        audit.record(actorId, "LAB_APPOINTMENT_STATUS_UPDATED", "LAB_APPOINTMENT", saved.getId());
        return saved;
    }

    @Transactional
    public LabAppointment submitLabResult(UUID actorId, UUID appId, String resultSummary) {
        LabAppointment app = labAppointments.findById(appId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "LAB_APPOINTMENT_NOT_FOUND", "Lab appointment was not found"));
        app.setResultSummary(resultSummary.trim());
        app.setStatus("COMPLETED");
        LabAppointment saved = labAppointments.save(app);
        audit.record(actorId, "LAB_RESULT_PUBLISHED", "LAB_APPOINTMENT", saved.getId());
        return saved;
    }

    // ==================== F12: SMART MEDICAL SERVICES ====================

    @Transactional(readOnly = true)
    public List<MedicalProvider> listMedicalProviders(String providerType) {
        if (providerType == null || providerType.isBlank()) {
            return medicalProviders.findByVerifiedTrueOrderByNameAsc();
        }
        return medicalProviders.findByVerifiedTrueAndProviderTypeIgnoreCaseOrderByNameAsc(providerType.trim());
    }

    @Transactional(readOnly = true)
    public MedicalProvider getMedicalProvider(UUID providerId) {
        return medicalProviders.findById(providerId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "PROVIDER_NOT_FOUND", "Medical provider was not found"));
    }

    @Transactional
    public MedicalProvider createMedicalProvider(UUID actorId, HealthcareDtos.CreateMedicalProviderRequest req) {
        MedicalProvider saved = medicalProviders.save(new MedicalProvider(
                req.name().trim(), req.providerType(), req.specialty(), req.address().trim(),
                req.latitude(), req.longitude(), req.phone(), true, Boolean.TRUE.equals(req.telemedicineEnabled())
        ));
        audit.record(actorId, "MEDICAL_PROVIDER_CREATED", "MEDICAL_PROVIDER", saved.getId());
        return saved;
    }

    @Transactional
    public ProviderAppointment bookProviderAppointment(UUID userId, HealthcareDtos.CreateProviderAppointmentRequest req) {
        MedicalProvider provider = getMedicalProvider(req.providerId());
        if ("TELEMEDICINE".equalsIgnoreCase(req.appointmentType()) && !provider.isTelemedicineEnabled()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "TELEMEDICINE_UNAVAILABLE", "This provider does not offer telemedicine");
        }
        ProviderAppointment saved = providerAppointments.save(new ProviderAppointment(
                userId, req.providerId(), req.scheduledAt(), req.appointmentType(), req.chiefComplaint()
        ));
        audit.record(userId, "PROVIDER_APPOINTMENT_BOOKED", "PROVIDER_APPOINTMENT", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<ProviderAppointment> myProviderAppointments(UUID userId) {
        return providerAppointments.findByUserIdOrderByScheduledAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<ProviderAppointment> allProviderAppointments() {
        return providerAppointments.findAll();
    }

    @Transactional(readOnly = true)
    public ProviderAppointment getProviderAppointment(UUID appId, UUID actorId, boolean privileged) {
        ProviderAppointment app = providerAppointments.findById(appId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "APPOINTMENT_NOT_FOUND", "Provider appointment was not found"));
        if (!privileged && !app.getUserId().equals(actorId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "You cannot access another patient's appointment");
        }
        return app;
    }

    @Transactional
    public ProviderAppointment updateProviderAppointmentStatus(UUID actorId, UUID appId, String status, boolean privileged) {
        ProviderAppointment app = getProviderAppointment(appId, actorId, privileged);
        app.setStatus(status.trim().toUpperCase());
        ProviderAppointment saved = providerAppointments.save(app);
        audit.record(actorId, "PROVIDER_APPOINTMENT_STATUS_UPDATED", "PROVIDER_APPOINTMENT", saved.getId());
        return saved;
    }

    // ==================== F13: SMART MEDICAL DELIVERY ====================

    @Transactional(readOnly = true)
    public List<MedicalDelivery> listDeliveries() {
        return medicalDeliveries.findAllByOrderByCreatedAtDesc();
    }

    @Transactional
    public MedicalDelivery createDelivery(UUID actorId, HealthcareDtos.CreateDeliveryRequest req) {
        medicineOrders.findById(req.orderId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "ORDER_NOT_FOUND", "Medicine order was not found"));
        String code = "SA-DEL-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        MedicalDelivery saved = medicalDeliveries.save(new MedicalDelivery(
                req.orderId(), code, req.courierName(), req.courierPhone(),
                req.etaMinutes(), req.pickupAddress(), req.deliveryAddress()
        ));
        audit.record(actorId, "MEDICAL_DELIVERY_CREATED", "MEDICAL_DELIVERY", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public MedicalDelivery trackDelivery(String trackingCode) {
        return medicalDeliveries.findByTrackingCodeIgnoreCase(trackingCode.trim())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "DELIVERY_NOT_FOUND", "Tracking code was not found"));
    }

    @Transactional
    public MedicalDelivery updateDeliveryStatus(UUID actorId, String trackingCode, String status, Integer etaMinutes) {
        MedicalDelivery delivery = trackDelivery(trackingCode);
        if (status != null && !status.isBlank()) {
            delivery.setDeliveryStatus(status.trim().toUpperCase());
        }
        if (etaMinutes != null && etaMinutes >= 0) {
            delivery.setEtaMinutes(etaMinutes);
        }
        MedicalDelivery saved = medicalDeliveries.save(delivery);
        audit.record(actorId, "MEDICAL_DELIVERY_UPDATED", "MEDICAL_DELIVERY", saved.getId());
        return saved;
    }

    // ==================== F15: SMART MEDICAL HANDOVER ====================

    @Transactional
    public MedicalHandover createHandover(UUID emsResponderId, HealthcareDtos.CreateHandoverRequest req) {
        MedicalHandover saved = medicalHandovers.save(new MedicalHandover(
                req.incidentId(),
                emsResponderId,
                req.receivingHospitalId(),
                req.triageSummary(),
                req.vitalSigns(),
                req.interventionsAdministered(),
                req.allergyAlerts(),
                req.medicationNotes()
        ));
        audit.record(emsResponderId, "MEDICAL_HANDOVER_CREATED", "MEDICAL_HANDOVER", saved.getId());
        return saved;
    }

    @Transactional(readOnly = true)
    public List<MedicalHandover> pendingHandovers() {
        return medicalHandovers.findByHandoverStatusOrderByCreatedAtDesc("TRANSFERRED");
    }

    @Transactional(readOnly = true)
    public MedicalHandover getHandover(UUID handoverId) {
        return medicalHandovers.findById(handoverId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "HANDOVER_NOT_FOUND", "Medical handover was not found"));
    }

    @Transactional(readOnly = true)
    public MedicalHandover getHandoverByIncident(UUID incidentId) {
        return medicalHandovers.findFirstByIncidentIdOrderByCreatedAtDesc(incidentId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "HANDOVER_NOT_FOUND", "No handover found for this incident"));
    }

    @Transactional
    public MedicalHandover acknowledgeHandover(UUID actorId, UUID handoverId, String receivingStaffName) {
        MedicalHandover handover = getHandover(handoverId);
        handover.acknowledge(receivingStaffName.trim());
        MedicalHandover saved = medicalHandovers.save(handover);
        audit.record(actorId, "MEDICAL_HANDOVER_ACKNOWLEDGED", "MEDICAL_HANDOVER", saved.getId());
        return saved;
    }

    private String normalizeBloodGroup(String raw) {
        String normalized = raw == null ? "" : raw.trim().toUpperCase().replace(" ", "");
        if (!VALID_BLOOD_GROUPS.contains(normalized)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "INVALID_BLOOD_GROUP",
                    "Blood group must be one of: A+, A-, B+, B-, AB+, AB-, O+, O-");
        }
        return normalized;
    }
}

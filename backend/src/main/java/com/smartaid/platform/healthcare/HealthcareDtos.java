package com.smartaid.platform.healthcare;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public final class HealthcareDtos {
    private HealthcareDtos() { }

    // --- F09 Smart Pharmacy & Emergency Supplies ---
    public record CreatePharmacyRequest(
            @NotBlank String name,
            @NotBlank String address,
            @NotNull Double latitude,
            @NotNull Double longitude,
            String phone,
            String openingHours,
            Boolean emergencySuppliesAvailable
    ) { }

    public record UpdateInventoryRequest(
            @NotNull @Min(0) Integer stockQuantity,
            @DecimalMin("0.00") BigDecimal unitPrice
    ) { }

    public record CreateMedicineOrderRequest(
            @NotNull UUID pharmacyId,
            @NotNull UUID medicineId,
            @NotNull @Min(1) Integer quantity,
            Boolean deliveryRequested,
            String deliveryAddress
    ) { }

    public record UpdateStatusRequest(@NotBlank String status, String note) { }

    public record PharmacyInventoryItemResponse(
            UUID inventoryId,
            UUID pharmacyId,
            UUID medicineId,
            String medicineName,
            String activeIngredient,
            String dosageForm,
            boolean isEmergencySupply,
            boolean prescriptionRequired,
            int stockQuantity,
            BigDecimal unitPrice,
            Instant updatedAt
    ) { }

    // --- F11 Smart Blood Bank ---
    public record CreateBloodBankRequest(
            @NotBlank String name,
            @NotBlank String address,
            @NotNull Double latitude,
            @NotNull Double longitude,
            String phone
    ) { }

    public record UpdateBloodInventoryRequest(@NotNull @Min(0) Integer unitsAvailable) { }

    public record CreateBloodRequest(
            UUID bloodBankId,
            UUID incidentId,
            @NotBlank String bloodGroup,
            @NotNull @Min(1) Integer unitsRequested,
            String urgency
    ) { }

    // --- F10 Smart Lab ---
    public record CreateLaboratoryRequest(
            @NotBlank String name,
            @NotBlank String address,
            @NotNull Double latitude,
            @NotNull Double longitude,
            String phone
    ) { }

    public record CreateLabServiceRequest(
            @NotBlank String serviceName,
            String category,
            Integer turnaroundHours,
            @DecimalMin("0.00") BigDecimal price
    ) { }

    public record CreateLabAppointmentRequest(
            @NotNull UUID laboratoryId,
            @NotNull UUID labServiceId,
            Instant scheduledAt
    ) { }

    public record SubmitLabResultRequest(@NotBlank String resultSummary) { }

    // --- F12 Smart Medical Services ---
    public record CreateMedicalProviderRequest(
            @NotBlank String name,
            @NotBlank String providerType,
            String specialty,
            @NotBlank String address,
            @NotNull Double latitude,
            @NotNull Double longitude,
            String phone,
            Boolean telemedicineEnabled
    ) { }

    public record CreateProviderAppointmentRequest(
            @NotNull UUID providerId,
            Instant scheduledAt,
            String appointmentType,
            String chiefComplaint
    ) { }

    // --- F13 Smart Medical Delivery ---
    public record CreateDeliveryRequest(
            @NotNull UUID orderId,
            String courierName,
            String courierPhone,
            Integer etaMinutes,
            String pickupAddress,
            String deliveryAddress
    ) { }

    public record DeliveryTelemetryRequest(
            Integer etaMinutes,
            String deliveryStatus
    ) { }

    // --- F15 Smart Medical Handover ---
    public record CreateHandoverRequest(
            @NotNull UUID incidentId,
            @NotNull UUID receivingHospitalId,
            String triageSummary,
            String vitalSigns,
            String interventionsAdministered,
            String allergyAlerts,
            String medicationNotes
    ) { }

    public record AcknowledgeHandoverRequest(@NotBlank String receivingStaffName) { }
}

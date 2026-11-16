package com.smartaid.platform.demo;

import com.smartaid.platform.auth.Role;
import com.smartaid.platform.auth.RoleRepository;
import com.smartaid.platform.auth.UserAccount;
import com.smartaid.platform.auth.UserAccountRepository;
import com.smartaid.platform.incident.EmergencyType;
import com.smartaid.platform.incident.EmergencyTypeRepository;
import com.smartaid.platform.incident.Incident;
import com.smartaid.platform.incident.IncidentRepository;
import com.smartaid.platform.incident.IncidentStatus;
import com.smartaid.platform.incident.IncidentStatusHistory;
import com.smartaid.platform.incident.IncidentStatusHistoryRepository;
import com.smartaid.platform.volunteer.VolunteerProfile;
import com.smartaid.platform.volunteer.VolunteerProfileRepository;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Seeds an explicitly opt-in, fictional local demonstration scenario. */
@Component
@ConditionalOnProperty(prefix = "smartaid.demo", name = "seed", havingValue = "true")
public class SmartAidDemoSeeder implements ApplicationRunner {
    public static final String USER_EMAIL = "demo.user@smartaid.local";
    public static final String VOLUNTEER_EMAIL = "demo.volunteer@smartaid.local";
    public static final String EMS_EMAIL = "demo.ems@smartaid.local";
    public static final String ADMIN_EMAIL = "demo.admin@smartaid.local";
    public static final String HOSPITAL_EMAIL = "demo.hospital@smartaid.local";
    public static final String PHARMACIST_EMAIL = "demo.pharmacist@smartaid.local";
    public static final String LAB_EMAIL = "demo.lab@smartaid.local";
    public static final String BLOOD_BANK_EMAIL = "demo.bloodbank@smartaid.local";
    public static final String DOCTOR_EMAIL = "demo.doctor@smartaid.local";
    public static final String PASSWORD = "SmartAidDemo2026!";
    private static final String CARDIAC_SCENARIO = "DEMO_SCENARIO_CARDIAC_2026";
    private static final String MEDICAL_SCENARIO = "DEMO_SCENARIO_MEDICAL_2026";
    private static final Logger log = LoggerFactory.getLogger(SmartAidDemoSeeder.class);

    private final UserAccountRepository users;
    private final RoleRepository roles;
    private final VolunteerProfileRepository volunteers;
    private final EmergencyTypeRepository emergencyTypes;
    private final IncidentRepository incidents;
    private final IncidentStatusHistoryRepository history;
    private final JdbcTemplate jdbc;
    private final PasswordEncoder passwords;

    public SmartAidDemoSeeder(UserAccountRepository users, RoleRepository roles, VolunteerProfileRepository volunteers,
            EmergencyTypeRepository emergencyTypes, IncidentRepository incidents, IncidentStatusHistoryRepository history,
            JdbcTemplate jdbc, PasswordEncoder passwords) {
        this.users = users;
        this.roles = roles;
        this.volunteers = volunteers;
        this.emergencyTypes = emergencyTypes;
        this.incidents = incidents;
        this.history = history;
        this.jdbc = jdbc;
        this.passwords = passwords;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments arguments) {
        Role userRole = role("USER");
        UserAccount user = account(USER_EMAIL, "Demo Citizen", userRole);
        UserAccount volunteer = account(VOLUNTEER_EMAIL, "Demo Responder", userRole, role("VOLUNTEER"));
        account(EMS_EMAIL, "Demo EMS Coordinator", userRole, role("EMS"));
        account(ADMIN_EMAIL, "Demo Administrator", userRole, role("ADMIN"));
        account(HOSPITAL_EMAIL, "Demo Hospital Staff", userRole, role("HOSPITAL"));
        account(PHARMACIST_EMAIL, "Demo Pharmacist", userRole, role("PHARMACIST"));
        account(LAB_EMAIL, "Demo Lab Staff", userRole, role("LAB_STAFF"));
        account(BLOOD_BANK_EMAIL, "Demo Blood Bank Staff", userRole, role("BLOOD_BANK_STAFF"));
        account(DOCTOR_EMAIL, "Demo Physician", userRole, role("DOCTOR"));
        readyVolunteer(volunteer);
        seedHospitalData();
        seedResources();
        seedHealthcareNetwork();
        seedScenarios(user);
        log.warn("Smart Aid DEMO MODE is active. Only fictional local accounts and simulated coordination data were seeded.");
        log.info("All 9 role demo accounts are ready (USER, VOLUNTEER, EMS, HOSPITAL, PHARMACIST, LAB_STAFF, BLOOD_BANK_STAFF, DOCTOR, ADMIN).");
    }

    private void seedResources() {
        jdbc.update("""
            INSERT INTO aed_devices (label, resource_type, latitude, longitude, availability_status, verified)
            VALUES
              ('Nile City Tower AED #1', 'AED', 30.0715, 31.2285, 'AVAILABLE', true),
              ('Tahrir Metro Station AED #2', 'AED', 30.0444, 31.2357, 'AVAILABLE', true),
              ('Cairo Opera House Medical Station', 'FIRST_AID', 30.0426, 31.2241, 'AVAILABLE', true)
            ON CONFLICT DO NOTHING
            """);

        jdbc.update("""
            INSERT INTO ambulances (call_sign, status, latitude, longitude)
            VALUES
              ('MEDIC-01', 'AVAILABLE', 30.0480, 31.2390),
              ('MEDIC-02', 'AVAILABLE', 30.0380, 31.2250),
              ('MEDIC-03', 'ASSIGNED', 30.0550, 31.2450)
            ON CONFLICT (call_sign) DO NOTHING
            """);
    }

    private void seedHealthcareNetwork() {
        // Pharmacies & Emergency First-Aid Supplies (F09)
        UUID ph1 = queryOrInsertId("pharmacies", "DEMO • Nile 24/7 Emergency Pharmacy",
                "INSERT INTO pharmacies(id, name, address, latitude, longitude, phone, opening_hours, verified, emergency_supplies_available) VALUES (?, ?, ?, ?, ?, ?, ?, true, true)",
                "14 Tahrir Sq, Cairo", 30.0450, 31.2360, "+20-2-2500-1001", "24/7");
        UUID ph2 = queryOrInsertId("pharmacies", "DEMO • Zamalek Care Pharmacy",
                "INSERT INTO pharmacies(id, name, address, latitude, longitude, phone, opening_hours, verified, emergency_supplies_available) VALUES (?, ?, ?, ?, ?, ?, ?, true, true)",
                "26 July Corridor, Zamalek", 30.0609, 31.2197, "+20-2-2500-1002", "08:00-23:00");

        UUID medGauze = queryOrInsertId("medicines", "Sterile Compression Gauze Roll",
                "INSERT INTO medicines(id, name, active_ingredient, dosage_form, is_emergency_supply, prescription_required) VALUES (?, ?, ?, ?, true, false)",
                "Cotton Gauze 4in", "Bandage Roll");
        UUID medKit = queryOrInsertId("medicines", "Trauma Bleeding-Control First-Aid Kit",
                "INSERT INTO medicines(id, name, active_ingredient, dosage_form, is_emergency_supply, prescription_required) VALUES (?, ?, ?, ?, true, false)",
                "Hemostatic Dressing + Tourniquet", "Emergency Kit");
        UUID medParacetamol = queryOrInsertId("medicines", "Paracetamol 500mg",
                "INSERT INTO medicines(id, name, active_ingredient, dosage_form, is_emergency_supply, prescription_required) VALUES (?, ?, ?, ?, false, false)",
                "Acetaminophen", "Tablet");
        UUID medAntibiotic = queryOrInsertId("medicines", "Amoxicillin 500mg (Rx Only)",
                "INSERT INTO medicines(id, name, active_ingredient, dosage_form, is_emergency_supply, prescription_required) VALUES (?, ?, ?, ?, false, true)",
                "Amoxicillin", "Capsule");

        jdbc.update("INSERT INTO pharmacy_inventory(pharmacy_id, medicine_id, stock_quantity, unit_price) VALUES (?, ?, 50, 45.00) ON CONFLICT (pharmacy_id, medicine_id) DO NOTHING", ph1, medGauze);
        jdbc.update("INSERT INTO pharmacy_inventory(pharmacy_id, medicine_id, stock_quantity, unit_price) VALUES (?, ?, 20, 320.00) ON CONFLICT (pharmacy_id, medicine_id) DO NOTHING", ph1, medKit);
        jdbc.update("INSERT INTO pharmacy_inventory(pharmacy_id, medicine_id, stock_quantity, unit_price) VALUES (?, ?, 100, 25.00) ON CONFLICT (pharmacy_id, medicine_id) DO NOTHING", ph1, medParacetamol);
        jdbc.update("INSERT INTO pharmacy_inventory(pharmacy_id, medicine_id, stock_quantity, unit_price) VALUES (?, ?, 30, 80.00) ON CONFLICT (pharmacy_id, medicine_id) DO NOTHING", ph1, medAntibiotic);
        jdbc.update("INSERT INTO pharmacy_inventory(pharmacy_id, medicine_id, stock_quantity, unit_price) VALUES (?, ?, 35, 48.00) ON CONFLICT (pharmacy_id, medicine_id) DO NOTHING", ph2, medGauze);

        // Blood Banks (F11)
        UUID bb1 = queryOrInsertId("blood_banks", "DEMO • National Central Blood Bank",
                "INSERT INTO blood_banks(id, name, address, latitude, longitude, phone, verified) VALUES (?, ?, ?, ?, ?, ?, true)",
                "51 Wezaret El Zeraa, Dokki", 30.0442, 31.2091, "+20-2-3761-2001");
        String[][] bloodStock = { {"O-", "12"}, {"O+", "28"}, {"A+", "22"}, {"A-", "8"}, {"B+", "15"}, {"AB+", "6"} };
        for (String[] row : bloodStock) {
            jdbc.update("INSERT INTO blood_inventory(blood_bank_id, blood_group, units_available) VALUES (?, ?, ?) ON CONFLICT (blood_bank_id, blood_group) DO NOTHING",
                    bb1, row[0], Integer.parseInt(row[1]));
        }

        // Laboratories (F10)
        UUID lab1 = queryOrInsertId("laboratories", "DEMO • Cairo Diagnostics & Pathology Lab",
                "INSERT INTO laboratories(id, name, address, latitude, longitude, phone, verified) VALUES (?, ?, ?, ?, ?, ?, true)",
                "22 El-Tahrir St, Dokki", 30.0385, 31.2135, "+20-2-3760-3001");
        Integer svcCount = jdbc.queryForObject("SELECT count(*) FROM lab_services WHERE laboratory_id = ?", Integer.class, lab1);
        if (svcCount == null || svcCount == 0) {
            jdbc.update("INSERT INTO lab_services(laboratory_id, service_name, category, turnaround_hours, price) VALUES (?, 'Complete Blood Count (CBC)', 'Hematology', 4, 150.00)", lab1);
            jdbc.update("INSERT INTO lab_services(laboratory_id, service_name, category, turnaround_hours, price) VALUES (?, 'Cardiac Troponin-I Rapid Panel', 'Cardiology', 2, 420.00)", lab1);
        }

        // Medical Providers (F12)
        queryOrInsertId("medical_providers", "DEMO • Dr. Amina Hassan (Cardiology)",
                "INSERT INTO medical_providers(id, name, provider_type, specialty, address, latitude, longitude, phone, verified, telemedicine_enabled) VALUES (?, ?, 'DOCTOR', 'Cardiology', ?, ?, ?, ?, true, true)",
                "Cairo Heart Clinic, Mohandessin", 30.0566, 31.2010, "+20-2-3300-4001");
        queryOrInsertId("medical_providers", "DEMO • Nile Rapid Radiology Center",
                "INSERT INTO medical_providers(id, name, provider_type, specialty, address, latitude, longitude, phone, verified, telemedicine_enabled) VALUES (?, ?, 'RADIOLOGY', 'CT & MRI Imaging', ?, ?, ?, ?, true, false)",
                "88 Corniche El Nil, Maadi", 29.9620, 31.2500, "+20-2-2525-4002");
        queryOrInsertId("medical_providers", "DEMO • FirstLine Home Healthcare Unit",
                "INSERT INTO medical_providers(id, name, provider_type, specialty, address, latitude, longitude, phone, verified, telemedicine_enabled) VALUES (?, ?, 'HOME_HEALTHCARE', 'Post-Op Nursing', ?, ?, ?, ?, true, true)",
                "Central Cairo Dispatch", 30.0444, 31.2357, "+20-2-2525-4003");
    }

    private UUID queryOrInsertId(String table, String name, String insertSql, Object... extraArgs) {
        UUID existing = jdbc.query("SELECT id FROM " + table + " WHERE name = ?",
                rs -> rs.next() ? rs.getObject(1, UUID.class) : null, name);
        if (existing != null) {
            return existing;
        }
        UUID id = UUID.randomUUID();
        Object[] args = new Object[extraArgs.length + 2];
        args[0] = id;
        args[1] = name;
        System.arraycopy(extraArgs, 0, args, 2, extraArgs.length);
        jdbc.update(insertSql, args);
        return id;
    }

    private Role role(String code) {
        return roles.findByCode(code).orElseThrow(() -> new IllegalStateException("Required role missing: " + code));
    }

    private UserAccount account(String email, String displayName, Role initialRole, Role... additionalRoles) {
        UserAccount account = users.findByEmailIgnoreCase(email)
                .orElseGet(() -> new UserAccount(email, passwords.encode(PASSWORD), displayName, initialRole));
        account.grantRole(initialRole);
        for (Role role : additionalRoles) {
            account.grantRole(role);
        }
        return users.save(account);
    }

    private void readyVolunteer(UserAccount volunteer) {
        VolunteerProfile profile = volunteers.findById(volunteer.getId()).orElseGet(() -> new VolunteerProfile(volunteer.getId()));
        profile.setVerified(true);
        profile.setAvailable(true);
        profile.updateLocation(30.0444, 31.2357);
        // JDBC inserts below reference this profile immediately, so force the JPA insert
        // before using the foreign key within the same seeding transaction.
        volunteers.saveAndFlush(profile);

        jdbc.update("insert into skills(code, label) values (?, ?) on conflict (code) do nothing", "CPR", "CPR");
        jdbc.update("insert into skills(code, label) values (?, ?) on conflict (code) do nothing", "AED", "AED");
        jdbc.update("insert into certifications(code, label) values (?, ?) on conflict (code) do nothing", "BLS", "Basic Life Support");
        jdbc.update("insert into volunteer_skills(volunteer_id, skill_id) select ?, id from skills where code in ('CPR', 'AED') on conflict do nothing", volunteer.getId());
        Timestamp verifiedAt = Timestamp.from(Instant.now());
        Timestamp expiresAt = Timestamp.from(Instant.now().plus(365, ChronoUnit.DAYS));
        jdbc.update("insert into volunteer_certifications(volunteer_id, certification_id, verified_at, expires_at) "
                + "select ?, id, ?, ? from certifications where code = 'BLS' on conflict (volunteer_id, certification_id) do update "
                + "set verified_at = excluded.verified_at, expires_at = excluded.expires_at", volunteer.getId(), verifiedAt, expiresAt);
    }

    private void seedHospitalData() {
        UUID cardiacCenter = hospital("DEMO • Nile Cardiac Center", 30.0502, 31.2401, 24);
        UUID cardiacFallback = hospital("DEMO • Cairo Cardiac Unit", 30.0362, 31.2201, 65);
        UUID generalCenter = hospital("DEMO • Cairo General Center", 30.0398, 31.2295, 48);
        capability(cardiacCenter, "CARDIOLOGY", "CATH_LAB");
        capability(cardiacFallback, "CARDIOLOGY", "CATH_LAB");
        capability(generalCenter, "EMERGENCY", "RESUSCITATION");
    }

    private UUID hospital(String name, double latitude, double longitude, int congestion) {
        UUID existing = jdbc.query("select id from hospitals where name = ?", resultSet -> resultSet.next() ? resultSet.getObject(1, UUID.class) : null, name);
        if (existing != null) {
            return existing;
        }
        UUID id = UUID.randomUUID();
        jdbc.update("insert into hospitals(id, name, latitude, longitude, verified, estimated_congestion) values (?, ?, ?, ?, true, ?)",
                id, name, latitude, longitude, congestion);
        return id;
    }

    private void capability(UUID hospitalId, String specialty, String resource) {
        jdbc.update("insert into hospital_specialties(hospital_id, specialty, verified) values (?, ?, true) on conflict do nothing", hospitalId, specialty);
        jdbc.update("insert into hospital_resources(hospital_id, resource_code, available, verified_at) values (?, ?, true, ?) on conflict (hospital_id, resource_code) "
                + "do update set available = true, verified_at = excluded.verified_at", hospitalId, resource, Timestamp.from(Instant.now()));
    }

    private void seedScenarios(UserAccount user) {
        EmergencyType cardiac = emergencyTypes.findByCode("CARDIAC")
                .orElseThrow(() -> new IllegalStateException("CARDIAC emergency type missing"));
        EmergencyType medical = emergencyTypes.findByCode("MEDICAL")
                .orElseThrow(() -> new IllegalStateException("MEDICAL emergency type missing"));
        scenario(user, cardiac, CARDIAC_SCENARIO, 30.0478, 31.2388, "CRITICAL", IncidentStatus.SEARCHING);
        scenario(user, medical, MEDICAL_SCENARIO, 30.0421, 31.2319, "HIGH", IncidentStatus.EMS_ASSIGNED);
    }

    private void scenario(UserAccount reporter, EmergencyType type, String notes, double latitude, double longitude, String priority,
            IncidentStatus currentStatus) {
        if (incidents.existsByNotes(notes)) {
            return;
        }
        Incident incident = new Incident(reporter.getId(), type, latitude, longitude, notes, priority);
        incident.moveTo(currentStatus);
        incidents.save(incident);
        history.save(new IncidentStatusHistory(incident.getId(), null, IncidentStatus.NEW, reporter.getId(), "Demo scenario created"));
        history.save(new IncidentStatusHistory(incident.getId(), IncidentStatus.NEW, currentStatus, reporter.getId(),
                "Fictional local demonstration data"));
    }
}

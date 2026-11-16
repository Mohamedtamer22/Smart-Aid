package com.smartaid.platform.incident;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "emergency_types")
public class EmergencyType {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Short id;
    private String code;
    private String label;
    public EmergencyType() { }
    public EmergencyType(String code, String label) { this.code = code; this.label = label; }
    public String getCode() { return code; }
    public String getLabel() { return label; }
}

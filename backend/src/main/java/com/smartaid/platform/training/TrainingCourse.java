package com.smartaid.platform.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "training_courses")
public class TrainingCourse {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(nullable = false, length = 160)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_mock_content", nullable = false)
    private boolean mockContent;

    public TrainingCourse() {}

    public TrainingCourse(String title, String description, boolean mockContent) {
        this.title = title;
        this.description = description;
        this.mockContent = mockContent;
    }

    public UUID getId() { return id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public boolean isMockContent() { return mockContent; }
    public void setMockContent(boolean mockContent) { this.mockContent = mockContent; }
}

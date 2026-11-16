package com.smartaid.platform.resource;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AedDeviceRepository extends JpaRepository<AedDevice, UUID> {
    List<AedDevice> findByVerifiedTrue();

    @Query(value = """
        SELECT a.* FROM aed_devices a
        WHERE a.verified = true
          AND a.location IS NOT NULL
          AND ST_DWithin(a.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radiusMeters)
        ORDER BY ST_Distance(a.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) ASC
        LIMIT :limit
        """, nativeQuery = true)
    List<AedDevice> findNearbyAeds(
        @Param("lat") double latitude,
        @Param("lng") double longitude,
        @Param("radiusMeters") double radiusMeters,
        @Param("limit") int limit
    );
}

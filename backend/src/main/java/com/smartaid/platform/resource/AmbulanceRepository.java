package com.smartaid.platform.resource;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AmbulanceRepository extends JpaRepository<Ambulance, UUID> {
    Optional<Ambulance> findByCallSign(String callSign);
    List<Ambulance> findByStatus(String status);

    @Query(value = """
        SELECT a.* FROM ambulances a
        WHERE a.status = 'AVAILABLE'
          AND a.location IS NOT NULL
          AND ST_DWithin(a.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radiusMeters)
        ORDER BY ST_Distance(a.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) ASC
        LIMIT :limit
        """, nativeQuery = true)
    List<Ambulance> findNearbyAvailable(
        @Param("lat") double latitude,
        @Param("lng") double longitude,
        @Param("radiusMeters") double radiusMeters,
        @Param("limit") int limit
    );
}

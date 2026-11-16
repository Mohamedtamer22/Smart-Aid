package com.smartaid.platform.incident;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface IncidentIdempotencyKeyRepository extends JpaRepository<IncidentIdempotencyKey, UUID> {
    Optional<IncidentIdempotencyKey> findByReporterIdAndRequestKey(UUID reporterId, String requestKey);

    /**
     * PostgreSQL transaction locks make duplicate mobile retries deterministic
     * without holding application-level locks across API instances.
     */
    @Query(value = "select count(*) from (select pg_advisory_xact_lock(hashtext(cast(:reporterId as text) || ':' || :requestKey)::bigint)) locks", nativeQuery = true)
    long lockForRequest(@Param("reporterId") UUID reporterId, @Param("requestKey") String requestKey);
}

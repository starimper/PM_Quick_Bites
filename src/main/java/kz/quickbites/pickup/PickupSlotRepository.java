package kz.quickbites.pickup;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PickupSlotRepository extends JpaRepository<PickupSlot, UUID> {
    List<PickupSlot> findByBuffetIdAndSlotTimeAfterOrderBySlotTime(UUID buffetId, Instant after);
    boolean existsByBuffetIdAndSlotTime(UUID buffetId, Instant slotTime);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from PickupSlot s where s.id = :id")
    Optional<PickupSlot> findLockedById(@Param("id") UUID id);
}

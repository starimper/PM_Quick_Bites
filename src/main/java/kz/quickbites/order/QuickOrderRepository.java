
package kz.quickbites.order;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;

public interface QuickOrderRepository
        extends JpaRepository<QuickOrder, UUID> {

    List<QuickOrder> findByStudentEmailIgnoreCaseOrderByOrderedAtDesc(
            String email
    );

    Page<QuickOrder> findByBuffetId(
            UUID buffetId,
            Pageable pageable
    );

    Page<QuickOrder> findByBuffetIdAndStatus(
            UUID buffetId,
            OrderStatus status,
            Pageable pageable
    );

    boolean existsByStudentIdAndPickupSlotIdAndStatusNot(
            UUID studentId,
            UUID pickupSlotId,
            OrderStatus status
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from QuickOrder o where o.id = :id")
    Optional<QuickOrder> findLockedById(
            @Param("id") UUID id
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
        select o from QuickOrder o
        where o.id = :id
        and lower(o.student.email) = lower(:email)
        """)
    Optional<QuickOrder> findLockedByIdAndStudentEmailIgnoreCase(
            @Param("id") UUID id,
            @Param("email") String email
    );

    @Query("""
        select coalesce(max(o.queueNumber), 0)
        from QuickOrder o
        where o.buffet.id = :buffetId
        and o.orderedAt >= :start
        and o.orderedAt < :end
        """)
    int findMaxQueueNumberForDay(
            @Param("buffetId") UUID buffetId,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

    @Query("""
        select count(o)
        from QuickOrder o
        where o.buffet.id = :buffetId
        and o.orderedAt >= :start
        and o.orderedAt < :end
        """)
    long countOrdersForDay(
            @Param("buffetId") UUID buffetId,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

    
    @Query("""
        select count(o)
        from QuickOrder o
        where o.buffet.id = :buffetId
        and o.status = :status
        and o.orderedAt >= :start
        and o.orderedAt < :end
        """)
    long countOrdersByStatus(
            @Param("buffetId") UUID buffetId,
            @Param("status") OrderStatus status,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

    @Query("""
        select count(o)
        from QuickOrder o
        where o.buffet.id = :buffetId
        and o.orderedAt >= :start
        and o.orderedAt < :end
        """)
    long countOrdersInPeriod(
            @Param("buffetId") UUID buffetId,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

    @Query("""
        select coalesce(sum(i.quantity), 0)
        from OrderItem i
        where i.order.buffet.id = :buffetId
        and i.order.status = :status
        and i.order.orderedAt >= :start
        and i.order.orderedAt < :end
        """)
    long countSoldItems(
            @Param("buffetId") UUID buffetId,
            @Param("status") OrderStatus status,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

}

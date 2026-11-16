
package kz.quickbites.order;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PaymentRepository
        extends JpaRepository<Payment, UUID> {

    Optional<Payment> findByOrderId(UUID orderId);

    @Query("""
        select coalesce(sum(p.amount), 0)
        from Payment p
        where p.order.buffet.id = :buffetId
          and p.status = :status
          and p.paidAt >= :start
          and p.paidAt < :end
        """)
    BigDecimal sumRevenue(
            @Param("buffetId") UUID buffetId,
            @Param("status") PaymentStatus status,
            @Param("start") Instant start,
            @Param("end") Instant end
    );

    @Query("""
        select count(p)
        from Payment p
        where p.order.buffet.id = :buffetId
          and p.status = :status
          and p.paidAt >= :start
          and p.paidAt < :end
        """)
    long countPaidOrders(
            @Param("buffetId") UUID buffetId,
            @Param("status") PaymentStatus status,
            @Param("start") Instant start,
            @Param("end") Instant end
    );
}

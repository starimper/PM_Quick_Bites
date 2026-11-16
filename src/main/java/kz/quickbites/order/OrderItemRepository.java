package kz.quickbites.order;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderItemRepository extends JpaRepository<OrderItem, UUID> {
    @Query("select i from OrderItem i join fetch i.meal where i.order.id = :orderId")
    List<OrderItem> findItemsWithMealByOrderId(@Param("orderId") UUID orderId);
    List<OrderItem> findByOrderId(UUID orderId);
    boolean existsByMealId(UUID mealId);
}


package kz.quickbites.order;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public final class OrderDtos {

    private OrderDtos() {}

    public record ItemRequest(
            @NotNull UUID mealId,
            @Min(1) @Max(20) int quantity
    ) {}

    public record CreateOrderRequest(
            @NotNull UUID pickupSlotId,
            @NotEmpty List<@Valid ItemRequest> items,
            @NotNull PaymentMethod paymentMethod
    ) {}

    public record StatusRequest(
            @NotNull OrderStatus status
    ) {}

    public record ItemResponse(
            UUID mealId,
            String mealName,
            int quantity,
            BigDecimal unitPrice,
            BigDecimal lineTotal
    ) {}

    public record OrderResponse(
            UUID id,
            UUID buffetId,
            String buffetName,
            int queueNumber,
            String pickupCode,
            String customerName,
            String customerEmail,
            Instant pickupTime,
            OrderStatus status,
            PaymentMethod paymentMethod,
            PaymentStatus paymentStatus,
            BigDecimal total,
            Instant orderedAt,
            List<ItemResponse> items
    ) {}

    public record OrderPageResponse(
            List<OrderResponse> content,
            int page,
            int size,
            long totalElements,
            int totalPages
    ) {}
}

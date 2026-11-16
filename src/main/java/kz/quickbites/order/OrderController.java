package kz.quickbites.order;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class OrderController {
    private final OrderService orders;
    public OrderController(OrderService orders) { this.orders = orders; }

    @PostMapping("/orders")
    public OrderDtos.OrderResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody OrderDtos.CreateOrderRequest request) {
        return orders.create(jwt.getSubject(), request);
    }

    @GetMapping("/orders/mine")
    public List<OrderDtos.OrderResponse> mine(@AuthenticationPrincipal Jwt jwt) { return orders.mine(jwt.getSubject()); }

    @PostMapping("/orders/{orderId}/cancel")
    public OrderDtos.OrderResponse cancel(@PathVariable UUID orderId, @AuthenticationPrincipal Jwt jwt) {
        return orders.cancel(orderId, jwt.getSubject());
    }

    @PostMapping("/orders/{orderId}/staff-cancel")
    public OrderDtos.OrderResponse staffCancel(@PathVariable UUID orderId, @AuthenticationPrincipal Jwt jwt) {
        return orders.cancelByStaff(orderId, jwt.getSubject());
    }

    @GetMapping("/buffets/{buffetId}/orders")
    public OrderDtos.OrderPageResponse buffetOrders(@PathVariable UUID buffetId, @RequestParam(required = false) OrderStatus status,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "20") int size,
                                                    @AuthenticationPrincipal Jwt jwt) {
        return orders.buffetOrders(buffetId, jwt.getSubject(), status, page, size);
    }

    @PatchMapping("/orders/{orderId}/status")
    public OrderDtos.OrderResponse updateStatus(@PathVariable UUID orderId, @AuthenticationPrincipal Jwt jwt,
                                                @Valid @RequestBody OrderDtos.StatusRequest request) {
        return orders.updateStatus(orderId, jwt.getSubject(), request.status());
    }
}

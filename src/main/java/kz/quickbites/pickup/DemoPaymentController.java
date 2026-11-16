
package kz.quickbites.pickup;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import kz.quickbites.common.ApiException;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;

@RestController
@RequestMapping("/api/demo-payments")
public class DemoPaymentController {

    private final UserRepository users;

    public DemoPaymentController(UserRepository users) {
        this.users = users;
    }

    public record DemoItem(
            UUID mealId,
            int quantity
    ) {}

    public record PreviewRequest(
            UUID pickupSlotId,
            List<DemoItem> items
    ) {}

    public record PreviewResponse(
            String mode,
            String status,
            String message
    ) {}

    @PostMapping("/preview")
    @ResponseStatus(HttpStatus.OK)
    public PreviewResponse preview(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody PreviewRequest request
    ) {
        if (jwt == null) {
            throw ApiException.forbidden(
                    "Authentication is required"
            );
        }

        AppUser user = users
                .findByEmailIgnoreCase(jwt.getSubject())
                .orElseThrow(() ->
                        ApiException.notFound("User not found")
                );

        if (!user.isActive() ||
                user.getRole() != UserRole.STUDENT) {
            throw ApiException.forbidden(
                    "Only active students can use demo checkout"
            );
        }

        if (request == null ||
                request.pickupSlotId() == null ||
                request.items() == null ||
                request.items().isEmpty()) {
            throw ApiException.badRequest(
                    "A pickup slot and order items are required"
            );
        }

        if (request.items().size() > 20) {
            throw ApiException.badRequest(
                    "Too many order items"
            );
        }

        for (DemoItem item : request.items()) {
            if (item == null ||
                    item.mealId() == null ||
                    item.quantity() < 1 ||
                    item.quantity() > 20) {
                throw ApiException.badRequest(
                        "Invalid order item"
                );
            }
        }

        return new PreviewResponse(
                "DEMO_APPLE_PAY",
                "READY",
                "Demo checkout is available. No payment will be charged."
        );
    }
}

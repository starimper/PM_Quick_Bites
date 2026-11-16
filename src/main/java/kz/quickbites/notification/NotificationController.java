package kz.quickbites.notification;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    private final NotificationService notifications;
    public NotificationController(NotificationService notifications) { this.notifications = notifications; }
    @GetMapping
    public List<NotificationDtos.NotificationResponse> list(@AuthenticationPrincipal Jwt jwt) { return notifications.list(jwt.getSubject()); }
    @PatchMapping("/{id}/read")
    public NotificationDtos.NotificationResponse markRead(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return notifications.markRead(jwt.getSubject(), id);
    }

    @GetMapping("/unread-count")
    public java.util.Map<String, Long> unreadCount(
            @AuthenticationPrincipal Jwt jwt
    ) {
        return java.util.Map.of(
                "count",
                notifications.unreadCount(jwt.getSubject())
        );
    }

    @PatchMapping("/read-all")
    public org.springframework.http.ResponseEntity<Void> markAllRead(
            @AuthenticationPrincipal Jwt jwt
    ) {
        notifications.markAllRead(jwt.getSubject());

        return org.springframework.http.ResponseEntity.noContent().build();
    }

}



package kz.quickbites.notification;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kz.quickbites.common.ApiException;
import kz.quickbites.user.AppUser;

@Service
public class NotificationService {

    private final NotificationRepository notifications;

    public NotificationService(
            NotificationRepository notifications
    ) {
        this.notifications = notifications;
    }

    @Transactional(readOnly = true)
    public List<NotificationDtos.NotificationResponse> list(
            String email
    ) {
        return notifications
                .findByUserEmailIgnoreCaseOrderByCreatedAtDesc(email)
                .stream()
                .map(NotificationService::toResponse)
                .toList();
    }

    @Transactional
    public NotificationDtos.NotificationResponse markRead(
            String email,
            UUID id
    ) {
        Notification notification = notifications
                .findByIdAndUserEmailIgnoreCase(id, email)
                .orElseThrow(() ->
                        ApiException.notFound("Notification not found")
                );

        notification.markRead();

        return toResponse(notification);
    }

    @Transactional
    public void orderReady(
            AppUser student,
            AppUser staff,
            int queueNumber
    ) {
        notifications.save(
                new Notification(
                        student,
                        staff,
                        "ORDER_READY",
                        "Your order is ready for pickup. Order #"
                                + String.format("%03d", queueNumber)
                                + "."
                )
        );
    }

    @Transactional
    public void newOrder(
            AppUser staff,
            AppUser student,
            int queueNumber
    ) {
        notifications.save(
                new Notification(
                        staff,
                        student,
                        "NEW_ORDER",
                        "New Order #"
                                + String.format("%03d", queueNumber)
                                + " has been placed."
                )
        );
    }

    @Transactional
    public void orderCancelled(
            AppUser staff,
            AppUser student,
            int queueNumber
    ) {
        notifications.save(
                new Notification(
                        staff,
                        student,
                        "ORDER_CANCELLED",
                        "Order #"
                                + String.format("%03d", queueNumber)
                                + " was cancelled by the customer."
                )
        );
    }

    @Transactional
    public void newFeedback(
            AppUser staff,
            AppUser student,
            int queueNumber
    ) {
        notifications.save(
                new Notification(
                        staff,
                        student,
                        "NEW_FEEDBACK",
                        "New customer feedback for Order #"
                                + String.format("%03d", queueNumber)
                                + "."
                )
        );
    }


    @Transactional(readOnly = true)
    public long unreadCount(String email) {
        return notifications
                .countByUserEmailIgnoreCaseAndReadFalse(email);
    }

    @Transactional
    public void markAllRead(String email) {
        notifications.markAllRead(email);
    }


    private static NotificationDtos.NotificationResponse toResponse(
            Notification notification
    ) {
        return new NotificationDtos.NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getMessage(),
                notification.isRead(),
                notification.getCreatedAt()
        );
    }
}

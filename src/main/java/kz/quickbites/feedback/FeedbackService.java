
package kz.quickbites.feedback;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.common.ApiException;
import kz.quickbites.notification.NotificationService;
import kz.quickbites.order.OrderStatus;
import kz.quickbites.order.QuickOrder;
import kz.quickbites.order.QuickOrderRepository;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;

@Service
public class FeedbackService {

    private final FeedbackRepository feedback;
    private final QuickOrderRepository orders;
    private final UserRepository users;
    private final BuffetRepository buffets;
    private final NotificationService notifications;

    public FeedbackService(
            FeedbackRepository feedback,
            QuickOrderRepository orders,
            UserRepository users,
            BuffetRepository buffets,
            NotificationService notifications
    ) {
        this.feedback = feedback;
        this.orders = orders;
        this.users = users;
        this.buffets = buffets;
        this.notifications = notifications;
    }

    @Transactional
    public FeedbackDtos.Response create(
            UUID orderId,
            String email,
            FeedbackDtos.CreateRequest request
    ) {
        AppUser student = users.findByEmailIgnoreCase(email)
                .orElseThrow(() ->
                        ApiException.notFound("User not found")
                );

        QuickOrder order = orders.findById(orderId)
                .orElseThrow(() ->
                        ApiException.notFound("Order not found")
                );

        if (!order.getStudent().getId().equals(student.getId())) {
            throw ApiException.notFound("Order not found");
        }

        if (order.getStatus() != OrderStatus.COMPLETED) {
            throw ApiException.conflict(
                    "Feedback is available after order completion"
            );
        }

        if (feedback.existsByOrderId(orderId)) {
            throw ApiException.conflict(
                    "Feedback already exists for this order"
            );
        }

        Feedback savedFeedback = feedback.save(
                new Feedback(
                        order,
                        student,
                        request.emojiRating(),
                        request.comment()
                )
        );

        notifications.newFeedback(
                order.getBuffet().getOwner(),
                student,
                order.getQueueNumber()
        );

        return toResponse(savedFeedback);
    }

    @Transactional(readOnly = true)
    public FeedbackDtos.Response get(
            UUID orderId,
            String email
    ) {
        Feedback item = feedback.findByOrderId(orderId)
                .orElseThrow(() ->
                        ApiException.notFound("Feedback not found")
                );

        if (!item.getStudent()
                .getEmail()
                .equalsIgnoreCase(email)) {
            throw ApiException.notFound("Feedback not found");
        }

        return toResponse(item);
    }

    @Transactional(readOnly = true)
    public List<FeedbackDtos.Response> listForBuffet(
            UUID buffetId,
            String email
    ) {
        authorizeManager(buffetId, email);

        return feedback
                .findByOrderBuffetIdOrderByCreatedAtDesc(buffetId)
                .stream()
                .map(FeedbackService::toResponse)
                .toList();
    }

    @Transactional
    public FeedbackDtos.Response flag(
            UUID feedbackId,
            String email,
            boolean flagged
    ) {
        Feedback item = feedback.findById(feedbackId)
                .orElseThrow(() ->
                        ApiException.notFound("Feedback not found")
                );

        authorizeManager(
                item.getOrder().getBuffet().getId(),
                email
        );

        item.setFlagged(flagged);

        return toResponse(item);
    }

    private void authorizeManager(
            UUID buffetId,
            String email
    ) {
        Buffet buffet = buffets.findById(buffetId)
                .orElseThrow(() ->
                        ApiException.notFound("Buffet not found")
                );

        AppUser user = users.findByEmailIgnoreCase(email)
                .orElseThrow(() ->
                        ApiException.notFound("User not found")
                );

        if (!user.isActive() ||
                (user.getRole() != UserRole.CAMPUS_ADMIN &&
                (user.getRole() != UserRole.BUFFET_STAFF ||
                !buffet.getOwner()
                        .getEmail()
                        .equalsIgnoreCase(email)))) {
            throw ApiException.forbidden(
                    "You do not manage this buffet"
            );
        }
    }

    private static FeedbackDtos.Response toResponse(
            Feedback item
    ) {
        return new FeedbackDtos.Response(
                item.getId(),
                item.getOrder().getId(),
                item.getEmojiRating(),
                item.getComment(),
                item.isFlagged(),
                item.getCreatedAt()
        );
    }
}

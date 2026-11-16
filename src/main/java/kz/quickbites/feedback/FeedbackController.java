package kz.quickbites.feedback;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import kz.quickbites.order.OrderService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class FeedbackController {
    private final FeedbackService feedback;
    public FeedbackController(FeedbackService feedback) { this.feedback = feedback; }

    @PostMapping("/orders/{orderId}/feedback")
    public FeedbackDtos.Response create(@PathVariable UUID orderId, @AuthenticationPrincipal Jwt jwt,
                                        @Valid @RequestBody FeedbackDtos.CreateRequest request) {
        return feedback.create(orderId, jwt.getSubject(), request);
    }

    @GetMapping("/orders/{orderId}/feedback")
    public FeedbackDtos.Response get(@PathVariable UUID orderId, @AuthenticationPrincipal Jwt jwt) {
        return feedback.get(orderId, jwt.getSubject());
    }

    @GetMapping("/buffets/{buffetId}/feedback")
    public List<FeedbackDtos.Response> listForBuffet(@PathVariable UUID buffetId, @AuthenticationPrincipal Jwt jwt) {
        return feedback.listForBuffet(buffetId, jwt.getSubject());
    }

    @PatchMapping("/feedback/{feedbackId}/flag")
    public FeedbackDtos.Response flag(@PathVariable UUID feedbackId, @AuthenticationPrincipal Jwt jwt,
                                      @Valid @RequestBody FeedbackDtos.FlagRequest request) {
        return feedback.flag(feedbackId, jwt.getSubject(), request.flagged());
    }
}

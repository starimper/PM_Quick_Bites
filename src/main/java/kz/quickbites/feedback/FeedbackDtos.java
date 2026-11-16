package kz.quickbites.feedback;

import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

public final class FeedbackDtos {
    private FeedbackDtos() {}
    public record CreateRequest(@NotNull EmojiRating emojiRating, @Size(max = 2000) String comment) {}
    public record FlagRequest(boolean flagged) {}
    public record Response(UUID id, UUID orderId, EmojiRating emojiRating, String comment,
                           boolean flagged, Instant createdAt) {}
}

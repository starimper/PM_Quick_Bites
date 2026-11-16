package kz.quickbites.feedback;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import kz.quickbites.order.QuickOrder;
import kz.quickbites.user.AppUser;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "feedback")
public class Feedback {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @OneToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "order_id", nullable = false, unique = true)
    private QuickOrder order;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "student_id", nullable = false)
    private AppUser student;
    @Enumerated(EnumType.STRING) @Column(name = "emoji_rating", nullable = false, length = 20)
    private EmojiRating emojiRating;
    @Column(columnDefinition = "text")
    private String comment;
    @Column(name = "is_flagged", nullable = false)
    private boolean flagged;
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected Feedback() {}
    public Feedback(QuickOrder order, AppUser student, EmojiRating emojiRating, String comment) {
        this.order = order; this.student = student; this.emojiRating = emojiRating; this.comment = comment;
    }
    public UUID getId() { return id; }
    public QuickOrder getOrder() { return order; }
    public AppUser getStudent() { return student; }
    public EmojiRating getEmojiRating() { return emojiRating; }
    public String getComment() { return comment; }
    public boolean isFlagged() { return flagged; }
    public Instant getCreatedAt() { return createdAt; }
    public void setFlagged(boolean flagged) { this.flagged = flagged; }
}

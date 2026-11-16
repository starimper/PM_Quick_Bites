package kz.quickbites.notification;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import kz.quickbites.user.AppUser;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "notifications")
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "sender_id")
    private AppUser sender;
    @Column(nullable = false, length = 40)
    private String type;
    @Column(nullable = false, columnDefinition = "text")
    private String message;
    @Column(name = "is_read", nullable = false)
    private boolean read;
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    protected Notification() {}
    public Notification(AppUser user, AppUser sender, String type, String message) {
        this.user = user; this.sender = sender; this.type = type; this.message = message;
    }
    public UUID getId() { return id; }
    public AppUser getUser() { return user; }
    public String getType() { return type; }
    public String getMessage() { return message; }
    public boolean isRead() { return read; }
    public Instant getCreatedAt() { return createdAt; }
    public void markRead() { this.read = true; }
}

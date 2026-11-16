package kz.quickbites.buffet;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import kz.quickbites.user.AppUser;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "buffets")
public class Buffet {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(nullable = false, length = 120)
    private String name;
    @Column(nullable = false, length = 240)
    private String location;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "owner_id", nullable = false)
    private AppUser owner;
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    protected Buffet() {}
    public Buffet(String name, String location, AppUser owner) { this.name = name; this.location = location; this.owner = owner; }
    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getLocation() { return location; }
    public AppUser getOwner() { return owner; }
}

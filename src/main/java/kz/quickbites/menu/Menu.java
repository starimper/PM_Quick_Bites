package kz.quickbites.menu;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.user.AppUser;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "menus", uniqueConstraints = @UniqueConstraint(columnNames = {"buffet_id", "menu_date"}))
public class Menu {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "buffet_id", nullable = false)
    private Buffet buffet;
    @Column(name = "menu_date", nullable = false)
    private LocalDate menuDate;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "created_by")
    private AppUser createdBy;
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    protected Menu() {}
    public Menu(Buffet buffet, LocalDate menuDate, AppUser createdBy) { this.buffet = buffet; this.menuDate = menuDate; this.createdBy = createdBy; }
    public UUID getId() { return id; }
    public Buffet getBuffet() { return buffet; }
    public LocalDate getMenuDate() { return menuDate; }
}

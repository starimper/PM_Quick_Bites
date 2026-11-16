
package kz.quickbites.order;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.pickup.PickupSlot;
import kz.quickbites.user.AppUser;

@Entity
@Table(name = "orders")
public class QuickOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private AppUser student;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buffet_id", nullable = false)
    private Buffet buffet;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "pickup_slot_id", nullable = false)
    private PickupSlot pickupSlot;

    @Column(name = "queue_number", nullable = false)
    private int queueNumber;

    @Column(name = "pickup_code", length = 4)
    private String pickupCode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private OrderStatus status = OrderStatus.PENDING;

    @CreationTimestamp
    @Column(name = "ordered_at", nullable = false, updatable = false)
    private Instant orderedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    @Column(nullable = false)
    private int version;

    protected QuickOrder() {}

    public QuickOrder(
            AppUser student,
            Buffet buffet,
            PickupSlot pickupSlot,
            int queueNumber
    ) {
        this.student = student;
        this.buffet = buffet;
        this.pickupSlot = pickupSlot;
        this.queueNumber = queueNumber;
    }

    public UUID getId() {
        return id;
    }

    public AppUser getStudent() {
        return student;
    }

    public Buffet getBuffet() {
        return buffet;
    }

    public PickupSlot getPickupSlot() {
        return pickupSlot;
    }

    public int getQueueNumber() {
        return queueNumber;
    }

    public String getPickupCode() {
        return pickupCode;
    }

    public OrderStatus getStatus() {
        return status;
    }

    public Instant getOrderedAt() {
        return orderedAt;
    }

    public void setPickupCode(String pickupCode) {
        this.pickupCode = pickupCode;
    }

    public void setStatus(OrderStatus status) {
        this.status = status;
    }
}

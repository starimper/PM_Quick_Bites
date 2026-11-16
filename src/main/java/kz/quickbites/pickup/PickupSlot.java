
package kz.quickbites.pickup;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import kz.quickbites.buffet.Buffet;

@Entity
@Table(
    name = "pickup_slots",
    uniqueConstraints = @UniqueConstraint(
        columnNames = {"buffet_id", "slot_time"}
    )
)
public class PickupSlot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buffet_id", nullable = false)
    private Buffet buffet;

    @Column(name = "slot_time", nullable = false)
    private Instant slotTime;

    @Column(nullable = false)
    private int capacity;

    @Column(name = "current_count", nullable = false)
    private int currentCount;

    @Column(name = "next_queue_number", nullable = false)
    private int nextQueueNumber = 1;

    protected PickupSlot() {}

    public PickupSlot(
            Buffet buffet,
            Instant slotTime,
            int capacity
    ) {
        this.buffet = buffet;
        this.slotTime = slotTime;
        this.capacity = capacity;
    }

    public UUID getId() {
        return id;
    }

    public Buffet getBuffet() {
        return buffet;
    }

    public Instant getSlotTime() {
        return slotTime;
    }

    public int getCapacity() {
        return capacity;
    }

    public int getCurrentCount() {
        return currentCount;
    }

    public int reserve() {
        if (currentCount >= capacity) {
            throw new IllegalStateException(
                "Pickup slot is full"
            );
        }

        currentCount++;
        return nextQueueNumber++;
    }

    public void release() {
        if (currentCount > 0) {
            currentCount--;
        }
    }
}

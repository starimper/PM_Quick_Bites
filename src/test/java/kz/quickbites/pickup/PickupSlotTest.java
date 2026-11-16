package kz.quickbites.pickup;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class PickupSlotTest {
    @Test
    void queueNumbersAreNeverReusedAfterCancellation() {
        PickupSlot slot = new PickupSlot(null, Instant.now().plusSeconds(3600), 3);

        assertEquals(1, slot.reserve());
        assertEquals(2, slot.reserve());
        slot.release();
        assertEquals(3, slot.reserve());
    }

    @Test
    void reservationCannotExceedCapacity() {
        PickupSlot slot = new PickupSlot(null, Instant.now().plusSeconds(3600), 1);

        slot.reserve();

        assertThrows(IllegalStateException.class, slot::reserve);
    }
}

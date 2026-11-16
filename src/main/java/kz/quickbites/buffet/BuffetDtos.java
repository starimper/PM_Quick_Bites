package kz.quickbites.buffet;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.UUID;

public final class BuffetDtos {
    private BuffetDtos() {}
    public record BuffetResponse(UUID id, String name, String location, UUID ownerId) {}
    public record CreateBuffetRequest(@NotBlank @Size(max = 120) String name,
                                      @NotBlank @Size(max = 240) String location,
                                      UUID ownerId) {}
    public record PickupSlotResponse(UUID id, Instant slotTime, int capacity, int remaining) {}
    public record CreatePickupSlotRequest(Instant slotTime, int capacity) {}
}

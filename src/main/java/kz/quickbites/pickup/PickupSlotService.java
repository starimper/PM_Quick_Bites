package kz.quickbites.pickup;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetDtos;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.common.ApiException;
import kz.quickbites.menu.MenuService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PickupSlotService {
    private final PickupSlotRepository slots;
    private final MenuService menus;
    private final BuffetRepository buffets;
    public PickupSlotService(PickupSlotRepository slots, MenuService menus, BuffetRepository buffets) {
        this.slots = slots; this.menus = menus; this.buffets = buffets;
    }

    @Transactional(readOnly = true)
    public List<BuffetDtos.PickupSlotResponse> list(UUID buffetId) {
        if (!buffets.existsById(buffetId)) throw ApiException.notFound("Buffet not found");
        return slots.findByBuffetIdAndSlotTimeAfterOrderBySlotTime(buffetId, Instant.now()).stream()
                .filter(slot -> slot.getCurrentCount() < slot.getCapacity()).map(PickupSlotService::toResponse).toList();
    }

    @Transactional
    public BuffetDtos.PickupSlotResponse create(UUID buffetId, String email, BuffetDtos.CreatePickupSlotRequest request) {
        Buffet buffet = menus.ownedBuffet(buffetId, email);
        if (request.slotTime() == null || !request.slotTime().isAfter(Instant.now())) throw ApiException.badRequest("Pickup time must be in the future");
        if (request.capacity() < 1 || request.capacity() > 500) throw ApiException.badRequest("Capacity must be between 1 and 500");
        if (slots.existsByBuffetIdAndSlotTime(buffetId, request.slotTime())) throw ApiException.conflict("A pickup slot already exists at this time");
        return toResponse(slots.save(new PickupSlot(buffet, request.slotTime(), request.capacity())));
    }

    public static BuffetDtos.PickupSlotResponse toResponse(PickupSlot slot) {
        return new BuffetDtos.PickupSlotResponse(slot.getId(), slot.getSlotTime(), slot.getCapacity(), slot.getCapacity() - slot.getCurrentCount());
    }
}

package kz.quickbites.buffet;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import kz.quickbites.menu.MenuDtos;
import kz.quickbites.menu.MenuService;
import kz.quickbites.pickup.PickupSlotService;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/buffets")
public class BuffetController {
    private final BuffetRepository buffets;
    private final MenuService menus;
    private final PickupSlotService slots;
    private final UserRepository users;
    public BuffetController(BuffetRepository buffets, MenuService menus, PickupSlotService slots, UserRepository users) {
        this.buffets = buffets; this.menus = menus; this.slots = slots; this.users = users;
    }

    @GetMapping
    public List<BuffetDtos.BuffetResponse> list() {
        return buffets.findAllByOrderByNameAsc().stream().map(BuffetController::toResponse).toList();
    }

    @GetMapping("/mine")
    public List<BuffetDtos.BuffetResponse> mine(@AuthenticationPrincipal Jwt jwt) {
        var source = isAdmin(jwt) ? buffets.findAllByOrderByNameAsc()
                : buffets.findByOwnerEmailIgnoreCase(jwt.getSubject());
        return source.stream().map(BuffetController::toResponse).toList();
    }

    @GetMapping("/{buffetId}/menu")
    public MenuDtos.MenuResponse menu(@PathVariable UUID buffetId,
                                      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return menus.getMenu(buffetId, date == null ? LocalDate.now(menus.zoneId()) : date);
    }

    @GetMapping("/{buffetId}/pickup-slots")
    public List<BuffetDtos.PickupSlotResponse> pickupSlots(@PathVariable UUID buffetId) { return slots.list(buffetId); }

    @PostMapping("/{buffetId}/meals")
    public MenuDtos.MealResponse addMeal(@PathVariable UUID buffetId, @AuthenticationPrincipal Jwt jwt,
                                         @RequestBody @jakarta.validation.Valid MenuDtos.CreateMealRequest request) {
        return menus.addMeal(buffetId, jwt.getSubject(), request);
    }

    @PatchMapping("/meals/{mealId}/availability")
    public MenuDtos.MealResponse availability(@PathVariable UUID mealId, @AuthenticationPrincipal Jwt jwt,
                                               @RequestBody @jakarta.validation.Valid MenuDtos.AvailabilityRequest request) {
        return menus.setAvailability(mealId, jwt.getSubject(), request.available());
    }

    @PatchMapping("/meals/{mealId}")
    public MenuDtos.MealResponse updateMeal(@PathVariable UUID mealId, @AuthenticationPrincipal Jwt jwt,
                                            @RequestBody @jakarta.validation.Valid MenuDtos.UpdateMealRequest request) {
        return menus.updateMeal(mealId, jwt.getSubject(), request);
    }

    @DeleteMapping("/meals/{mealId}")
    @ResponseStatus(org.springframework.http.HttpStatus.NO_CONTENT)
    public void deleteMeal(@PathVariable UUID mealId, @AuthenticationPrincipal Jwt jwt) {
        menus.deleteMeal(mealId, jwt.getSubject());
    }

    @PostMapping("/{buffetId}/pickup-slots")
    public BuffetDtos.PickupSlotResponse createSlot(@PathVariable UUID buffetId, @AuthenticationPrincipal Jwt jwt,
                                                     @RequestBody BuffetDtos.CreatePickupSlotRequest request) {
        return slots.create(buffetId, jwt.getSubject(), request);
    }

    private boolean isAdmin(Jwt jwt) {
        return users.findByEmailIgnoreCase(jwt.getSubject()).map(user -> user.getRole() == UserRole.CAMPUS_ADMIN).orElse(false);
    }
    private static BuffetDtos.BuffetResponse toResponse(Buffet buffet) {
        return new BuffetDtos.BuffetResponse(buffet.getId(), buffet.getName(), buffet.getLocation(), buffet.getOwner().getId());
    }
}

package kz.quickbites.menu;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.common.ApiException;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;
import kz.quickbites.order.OrderItemRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MenuService {
    private final BuffetRepository buffets;
    private final MenuRepository menus;
    private final MealRepository meals;
    private final UserRepository users;
    private final OrderItemRepository orderItems;
    private final ZoneId zoneId;
    public MenuService(BuffetRepository buffets, MenuRepository menus, MealRepository meals, UserRepository users,
                       OrderItemRepository orderItems,
                       @Value("${app.time-zone:Asia/Almaty}") String timeZone) {
        this.buffets = buffets; this.menus = menus; this.meals = meals; this.users = users; this.orderItems = orderItems;
        this.zoneId = ZoneId.of(timeZone);
    }

    @Transactional(readOnly = true)
    public MenuDtos.MenuResponse getMenu(UUID buffetId, LocalDate date) {
        Buffet buffet = buffets.findById(buffetId).orElseThrow(() -> ApiException.notFound("Buffet not found"));
        List<MenuDtos.MealResponse> items = menus.findByBuffetIdAndMenuDate(buffetId, date)
                .map(menu -> meals.findByMenuIdOrderByNameAsc(menu.getId()).stream().map(MenuService::toResponse).toList())
                .orElseGet(List::of);
        return new MenuDtos.MenuResponse(buffet.getId(), buffet.getName(), date, items);
    }

    @Transactional
    public MenuDtos.MealResponse addMeal(UUID buffetId, String email, MenuDtos.CreateMealRequest request) {
        Buffet buffet = ownedBuffet(buffetId, email);
        AppUser actor = users.findByEmailIgnoreCase(email).orElseThrow(() -> ApiException.notFound("User not found"));
        LocalDate today = LocalDate.now(zoneId);
        Menu menu = menus.findByBuffetIdAndMenuDate(buffetId, today).orElseGet(() -> menus.save(new Menu(buffet, today, actor)));
        return toResponse(meals.save(new Meal(menu, request.name().trim(), request.description(), request.photoUrl(),
                request.nutritionInfo(), request.price(), request.capacity())));
    }

    @Transactional
    public MenuDtos.MealResponse setAvailability(UUID mealId, String email, boolean available) {
        Meal meal = meals.findById(mealId).orElseThrow(() -> ApiException.notFound("Meal not found"));
        authorize(meal.getMenu().getBuffet(), email);
        meal.setAvailable(available);
        return toResponse(meal);
    }

    @Transactional
    public MenuDtos.MealResponse updateMeal(UUID mealId, String email, MenuDtos.UpdateMealRequest request) {
        Meal meal = meals.findById(mealId).orElseThrow(() -> ApiException.notFound("Meal not found"));
        authorize(meal.getMenu().getBuffet(), email);
        if (request.name() != null) meal.setName(request.name().trim());
        if (request.description() != null) meal.setDescription(request.description());
        if (request.photoUrl() != null) meal.setPhotoUrl(request.photoUrl());
        if (request.nutritionInfo() != null) meal.setNutritionInfo(request.nutritionInfo());
        if (request.price() != null) meal.setPrice(request.price());
        if (request.capacity() != null) {
            if (request.capacity() < meal.getReservedCount())
                throw ApiException.conflict("Capacity cannot be lower than reserved portions");
            meal.setCapacity(request.capacity());
        }
        return toResponse(meal);
    }

    @Transactional
    public void deleteMeal(UUID mealId, String email) {
        Meal meal = meals.findById(mealId).orElseThrow(() -> ApiException.notFound("Meal not found"));
        authorize(meal.getMenu().getBuffet(), email);
        if (meal.getReservedCount() > 0 || orderItems.existsByMealId(mealId))
            throw ApiException.conflict("A meal used by an order or with reserved portions cannot be deleted");
        meals.delete(meal);
    }

    @Transactional(readOnly = true)
    public Buffet ownedBuffet(UUID buffetId, String email) {
        Buffet buffet = buffets.findById(buffetId).orElseThrow(() -> ApiException.notFound("Buffet not found"));
        authorize(buffet, email);
        return buffet;
    }

    private void authorize(Buffet buffet, String email) {
        AppUser actor = users.findByEmailIgnoreCase(email).orElseThrow(() -> ApiException.notFound("User not found"));
        if (!actor.isActive()) throw ApiException.forbidden("This account is inactive");
        boolean admin = actor.getRole() == UserRole.CAMPUS_ADMIN;
        if (!admin && !buffet.getOwner().getEmail().equalsIgnoreCase(email))
            throw ApiException.forbidden("You do not manage this buffet");
    }

    public ZoneId zoneId() { return zoneId; }

    private static MenuDtos.MealResponse toResponse(Meal meal) {
        return new MenuDtos.MealResponse(meal.getId(), meal.getName(), meal.getDescription(), meal.getPhotoUrl(),
                meal.getNutritionInfo(), meal.getPrice(), meal.getCapacity(), meal.getReservedCount(), meal.isAvailable());
    }
}

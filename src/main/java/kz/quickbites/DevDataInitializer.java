package kz.quickbites;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Locale;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.menu.Meal;
import kz.quickbites.menu.MealRepository;
import kz.quickbites.menu.Menu;
import kz.quickbites.menu.MenuRepository;
import kz.quickbites.pickup.PickupSlot;
import kz.quickbites.pickup.PickupSlotRepository;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DevDataInitializer {
    @Bean
    CommandLineRunner quickBitesBootstrap(UserRepository users, BuffetRepository buffets, MenuRepository menus,
                                          MealRepository meals, PickupSlotRepository slots, PasswordEncoder encoder,
                                          @Value("${app.bootstrap.admin-email:}") String adminEmail,
                                          @Value("${app.bootstrap.admin-password:}") String adminPassword,
                                          @Value("${app.time-zone:Asia/Almaty}") String timeZone,
                                          @Value("${app.demo-data.enabled:false}") boolean demoEnabled) {
        return args -> {
            if (!adminEmail.isBlank() && !adminPassword.isBlank()) {
                String email = adminEmail.trim().toLowerCase(Locale.ROOT);
                if (!users.existsByEmailIgnoreCase(email))
                    users.save(new AppUser("Campus Admin", email, encoder.encode(adminPassword), UserRole.CAMPUS_ADMIN));
            }
            if (!demoEnabled) return;
            AppUser staff = demoUser(users, encoder, "Demo Staff", "demo.staff@kbtu.kz", "QuickBites123!", UserRole.BUFFET_STAFF);
            demoUser(users, encoder, "Demo Student", "demo.student@kbtu.kz", "QuickBites123!", UserRole.STUDENT);
            Buffet buffet = buffets.findAllByOrderByNameAsc().stream().filter(b -> b.getName().equals("Quick Bites Demo Buffet"))
                    .findFirst().orElseGet(() -> buffets.save(new Buffet("Quick Bites Demo Buffet", "KBTU campus", staff)));
            LocalDate today = LocalDate.now(ZoneId.of(timeZone));
            Menu menu = menus.findByBuffetIdAndMenuDate(buffet.getId(), today)
                    .orElseGet(() -> menus.save(new Menu(buffet, today, staff)));
            if (meals.findByMenuIdOrderByNameAsc(menu.getId()).isEmpty()) {
                meals.saveAll(List.of(
                        new Meal(menu, "Chicken rice bowl", "Chicken, rice, and vegetables", null, java.util.Map.of(), new java.math.BigDecimal("1800.00"), 30),
                        new Meal(menu, "Cheese pastry", "Fresh baked pastry", null, java.util.Map.of(), new java.math.BigDecimal("650.00"), 40)));
            }
            Instant nextSlot = Instant.now().plusSeconds(3600).truncatedTo(java.time.temporal.ChronoUnit.MINUTES);
            if (!slots.existsByBuffetIdAndSlotTime(buffet.getId(), nextSlot)) slots.save(new PickupSlot(buffet, nextSlot, 12));
        };
    }

    private AppUser demoUser(UserRepository users, PasswordEncoder encoder, String username, String email, String password, UserRole role) {
        return users.findByEmailIgnoreCase(email).orElseGet(() -> users.save(new AppUser(username, email, encoder.encode(password), role)));
    }
}

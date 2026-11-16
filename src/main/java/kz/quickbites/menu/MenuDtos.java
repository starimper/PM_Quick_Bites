package kz.quickbites.menu;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;
import java.util.Map;

public final class MenuDtos {
    private MenuDtos() {}
    public record MealResponse(UUID id, String name, String description, String photoUrl, Map<String, Object> nutritionInfo,
                               BigDecimal price, Integer capacity, int reservedCount, boolean available) {}
    public record MenuResponse(UUID buffetId, String buffetName, LocalDate date, java.util.List<MealResponse> meals) {}
    public record CreateMealRequest(@NotBlank @Size(max = 140) String name,
                                    @Size(max = 2000) String description,
                                    @Size(max = 2000) String photoUrl,
                                    Map<String, Object> nutritionInfo,
                                    @NotNull @DecimalMin("0.00") BigDecimal price,
                                    @PositiveOrZero Integer capacity) {}
    public record UpdateMealRequest(@Size(min = 1, max = 140) String name,
                                    @Size(max = 2000) String description,
                                    @Size(max = 2000) String photoUrl,
                                    Map<String, Object> nutritionInfo,
                                    @DecimalMin("0.00") BigDecimal price,
                                    @PositiveOrZero Integer capacity) {}
    public record AvailabilityRequest(boolean available) {}
}

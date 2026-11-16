package kz.quickbites.menu;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "meals")
public class Meal {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "menu_id", nullable = false)
    private Menu menu;
    @Column(nullable = false, length = 140)
    private String name;
    @Column(columnDefinition = "text")
    private String description;
    @Column(name = "photo_url", columnDefinition = "text")
    private String photoUrl;
    @JdbcTypeCode(SqlTypes.JSON) @Column(name = "nutrition_info", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> nutritionInfo = Map.of();
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
    private Integer capacity;
    @Column(name = "reserved_count", nullable = false)
    private int reservedCount;
    @Column(name = "is_available", nullable = false)
    private boolean available = true;
    @CreationTimestamp @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected Meal() {}
    public Meal(Menu menu, String name, String description, String photoUrl, Map<String, Object> nutritionInfo,
                BigDecimal price, Integer capacity) {
        this.menu = menu; this.name = name; this.description = description; this.photoUrl = photoUrl;
        this.nutritionInfo = nutritionInfo == null ? Map.of() : nutritionInfo;
        this.price = price; this.capacity = capacity;
    }
    public UUID getId() { return id; }
    public Menu getMenu() { return menu; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public String getPhotoUrl() { return photoUrl; }
    public Map<String, Object> getNutritionInfo() { return nutritionInfo; }
    public BigDecimal getPrice() { return price; }
    public Integer getCapacity() { return capacity; }
    public int getReservedCount() { return reservedCount; }
    public boolean isAvailable() { return available && (capacity == null || reservedCount < capacity); }
    public void reserve(int quantity) { this.reservedCount += quantity; }
    public void release(int quantity) { this.reservedCount = Math.max(0, this.reservedCount - quantity); }
    public void setAvailable(boolean available) { this.available = available; }
    public void setName(String name) { this.name = name; }
    public void setDescription(String description) { this.description = description; }
    public void setPhotoUrl(String photoUrl) { this.photoUrl = photoUrl; }
    public void setNutritionInfo(Map<String, Object> nutritionInfo) { this.nutritionInfo = nutritionInfo == null ? Map.of() : nutritionInfo; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public void setCapacity(Integer capacity) { this.capacity = capacity; }
}

package kz.quickbites.order;

import java.math.BigDecimal;
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
import kz.quickbites.menu.Meal;

@Entity
@Table(name = "order_items")
public class OrderItem {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "order_id", nullable = false)
    private QuickOrder order;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "meal_id", nullable = false)
    private Meal meal;
    @Column(name = "meal_name", nullable = false, length = 140)
    private String mealName;
    @Column(nullable = false)
    private int quantity;
    @Column(name = "unit_price", nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice;
    protected OrderItem() {}
    public OrderItem(QuickOrder order, Meal meal, int quantity) {
        this.order = order; this.meal = meal; this.mealName = meal.getName(); this.quantity = quantity; this.unitPrice = meal.getPrice();
    }
    public Meal getMeal() { return meal; }
    public String getMealName() { return mealName; }
    public int getQuantity() { return quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
}

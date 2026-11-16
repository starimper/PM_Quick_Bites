
package kz.quickbites.order;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import kz.quickbites.user.AppUser;

@Entity
@Table(name = "payments")
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private AppUser student;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private QuickOrder order;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PaymentMethod method;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private PaymentStatus status;

    @Column(name = "paid_at")
    private Instant paidAt;

    protected Payment() {}

    public Payment(
            AppUser student,
            QuickOrder order,
            BigDecimal amount,
            PaymentMethod method
    ) {
        this.student = student;
        this.order = order;
        this.amount = amount;
        this.method = method;
        this.status = PaymentStatus.PENDING;
    }

    public UUID getId() {
        return id;
    }

    public AppUser getStudent() {
        return student;
    }

    public QuickOrder getOrder() {
        return order;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public PaymentMethod getMethod() {
        return method;
    }

    public PaymentStatus getStatus() {
        return status;
    }

    public Instant getPaidAt() {
        return paidAt;
    }

    public void markPaid() {
        this.status = PaymentStatus.PAID;
        this.paidAt = Instant.now();
    }

    public void markCancelled() {
        if (this.status == PaymentStatus.PENDING) {
            this.status = PaymentStatus.CANCELLED;
        }
    }

    public void markRefunded() {
        this.status = PaymentStatus.REFUNDED;
    }
}

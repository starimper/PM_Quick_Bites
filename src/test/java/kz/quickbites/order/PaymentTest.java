package kz.quickbites.order;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class PaymentTest {
    @Test
    void pendingPayAtPickupPaymentBecomesPaidWhenCollected() {
        Payment payment = new Payment(null, null, BigDecimal.TEN, PaymentMethod.PAY_AT_PICKUP);

        payment.markPaid();

        assertEquals(PaymentStatus.PAID, payment.getStatus());
    }

    @Test
    void pendingPaymentBecomesCancelledWhenOrderIsCancelled() {
        Payment payment = new Payment(null, null, BigDecimal.TEN, PaymentMethod.PAY_AT_PICKUP);

        payment.markCancelled();

        assertEquals(PaymentStatus.CANCELLED, payment.getStatus());
    }
}

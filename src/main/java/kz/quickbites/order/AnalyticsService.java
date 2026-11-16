
package kz.quickbites.order;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.common.ApiException;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;

@Service
public class AnalyticsService {

    private final QuickOrderRepository orders;
    private final PaymentRepository payments;
    private final BuffetRepository buffets;
    private final UserRepository users;
    private final ZoneId zoneId;

    public AnalyticsService(
            QuickOrderRepository orders,
            PaymentRepository payments,
            BuffetRepository buffets,
            UserRepository users,
            @Value("${app.time-zone:Asia/Almaty}") String timeZone
    ) {
        this.orders = orders;
        this.payments = payments;
        this.buffets = buffets;
        this.users = users;
        this.zoneId = ZoneId.of(timeZone);
    }

    public record DailyStatistics(
            String date,
            long orders,
            BigDecimal revenue
    ) {}

    public record AnalyticsResponse(
            UUID buffetId,
            String buffetName,
            String startDate,
            String endDate,
            long totalOrders,
            long pendingOrders,
            long confirmedOrders,
            long preparingOrders,
            long readyOrders,
            long completedOrders,
            long cancelledOrders,
            long paidOrders,
            long soldItems,
            BigDecimal revenue,
            BigDecimal averageOrderValue,
            List<DailyStatistics> dailyStatistics
    ) {}

    @Transactional(readOnly = true)
    public AnalyticsResponse getAnalytics(
            UUID buffetId,
            String email,
            int days
    ) {
        if (days != 1 && days != 7 && days != 30) {
            throw ApiException.badRequest(
                    "Days must be 1, 7, or 30"
            );
        }

        Buffet buffet = buffets.findById(buffetId)
                .orElseThrow(() ->
                        ApiException.notFound("Buffet not found")
                );

        authorize(buffet, email);

        LocalDate today = LocalDate.now(zoneId);
        LocalDate firstDay = today.minusDays(days - 1L);

        Instant start = firstDay
                .atStartOfDay(zoneId)
                .toInstant();

        Instant end = today
                .plusDays(1)
                .atStartOfDay(zoneId)
                .toInstant();

        long totalOrders = orders.countOrdersInPeriod(
                buffetId, start, end
        );

        long pending = countStatus(
                buffetId, OrderStatus.PENDING, start, end
        );

        long confirmed = countStatus(
                buffetId, OrderStatus.CONFIRMED, start, end
        );

        long preparing = countStatus(
                buffetId, OrderStatus.PREPARING, start, end
        );

        long ready = countStatus(
                buffetId, OrderStatus.READY, start, end
        );

        long completed = countStatus(
                buffetId, OrderStatus.COMPLETED, start, end
        );

        long cancelled = countStatus(
                buffetId, OrderStatus.CANCELLED, start, end
        );

        long paidOrders = payments.countPaidOrders(
                buffetId, PaymentStatus.PAID, start, end
        );

        BigDecimal revenue = payments.sumRevenue(
                buffetId, PaymentStatus.PAID, start, end
        );

        BigDecimal averageOrderValue = paidOrders == 0
                ? BigDecimal.ZERO
                : revenue.divide(
                        BigDecimal.valueOf(paidOrders),
                        2,
                        RoundingMode.HALF_UP
                );

        long soldItems = orders.countSoldItems(
                buffetId,
                OrderStatus.COMPLETED,
                start,
                end
        );

        List<DailyStatistics> daily = new ArrayList<>();

        for (int i = 0; i < days; i++) {
            LocalDate date = firstDay.plusDays(i);

            Instant dayStart = date
                    .atStartOfDay(zoneId)
                    .toInstant();

            Instant dayEnd = date
                    .plusDays(1)
                    .atStartOfDay(zoneId)
                    .toInstant();

            long dayOrders = orders.countOrdersInPeriod(
                    buffetId, dayStart, dayEnd
            );

            BigDecimal dayRevenue = payments.sumRevenue(
                    buffetId,
                    PaymentStatus.PAID,
                    dayStart,
                    dayEnd
            );

            daily.add(
                    new DailyStatistics(
                            date.toString(),
                            dayOrders,
                            dayRevenue
                    )
            );
        }

        return new AnalyticsResponse(
                buffetId,
                buffet.getName(),
                firstDay.toString(),
                today.toString(),
                totalOrders,
                pending,
                confirmed,
                preparing,
                ready,
                completed,
                cancelled,
                paidOrders,
                soldItems,
                revenue,
                averageOrderValue,
                daily
        );
    }

    private long countStatus(
            UUID buffetId,
            OrderStatus status,
            Instant start,
            Instant end
    ) {
        return orders.countOrdersByStatus(
                buffetId,
                status,
                start,
                end
        );
    }

    private void authorize(
            Buffet buffet,
            String email
    ) {
        AppUser actor = users.findByEmailIgnoreCase(email)
                .orElseThrow(() ->
                        ApiException.notFound("User not found")
                );

        if (!actor.isActive() ||
                (actor.getRole() != UserRole.CAMPUS_ADMIN &&
                (actor.getRole() != UserRole.BUFFET_STAFF ||
                !buffet.getOwner()
                        .getEmail()
                        .equalsIgnoreCase(email)))) {
            throw ApiException.forbidden(
                    "You do not manage this buffet"
            );
        }
    }
}

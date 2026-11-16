
package kz.quickbites.order;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import kz.quickbites.buffet.Buffet;
import kz.quickbites.buffet.BuffetRepository;
import kz.quickbites.common.ApiException;
import kz.quickbites.menu.Meal;
import kz.quickbites.menu.MealRepository;
import kz.quickbites.notification.NotificationService;
import kz.quickbites.pickup.PickupSlot;
import kz.quickbites.pickup.PickupSlotRepository;
import kz.quickbites.user.AppUser;
import kz.quickbites.user.UserRepository;
import kz.quickbites.user.UserRole;

@Service
public class OrderService {

    private final UserRepository users;
    private final PickupSlotRepository slots;
    private final MealRepository meals;
    private final QuickOrderRepository orders;
    private final OrderItemRepository items;
    private final PaymentRepository payments;
    private final NotificationService notifications;
    private final BuffetRepository buffets;
    private final EntityManager entityManager;
    private final ZoneId zoneId;

    public OrderService(
            UserRepository users,
            PickupSlotRepository slots,
            MealRepository meals,
            QuickOrderRepository orders,
            OrderItemRepository items,
            PaymentRepository payments,
            NotificationService notifications,
            BuffetRepository buffets,
            EntityManager entityManager,
            @Value("${app.time-zone:Asia/Almaty}") String timeZone
    ) {
        this.users = users;
        this.slots = slots;
        this.meals = meals;
        this.orders = orders;
        this.items = items;
        this.payments = payments;
        this.notifications = notifications;
        this.buffets = buffets;
        this.entityManager = entityManager;
        this.zoneId = ZoneId.of(timeZone);
    }

    @Transactional
    public OrderDtos.OrderResponse create(
            String email,
            OrderDtos.CreateOrderRequest request
    ) {
        if (request.paymentMethod() != PaymentMethod.PAY_AT_PICKUP) {
            throw ApiException.badRequest(
                    "Online card and QR payments are not enabled yet; choose pay at pickup"
            );
        }

        AppUser student = users.findByEmailIgnoreCase(email)
                .orElseThrow(() ->
                        ApiException.notFound("User not found")
                );

        if (!student.isActive() ||
                student.getRole() != UserRole.STUDENT) {
            throw ApiException.forbidden(
                    "Only active student accounts can place orders"
            );
        }

        if (request.items() == null || request.items().isEmpty()) {
            throw ApiException.badRequest(
                    "Order must contain at least one item"
            );
        }

        request.items().forEach(item -> {
            if (item == null ||
                    item.mealId() == null ||
                    item.quantity() <= 0) {
                throw ApiException.badRequest(
                        "Each order item must include a valid meal and a positive quantity"
                );
            }
        });

        UUID buffetId = slots.findById(request.pickupSlotId())
                .orElseThrow(() ->
                        ApiException.notFound("Pickup slot not found")
                )
                .getBuffet()
                .getId();

        // Serialize order creation for the same buffet.
        Buffet lockedBuffet = entityManager.find(
                Buffet.class,
                buffetId,
                LockModeType.PESSIMISTIC_WRITE
        );

        if (lockedBuffet == null) {
            throw ApiException.notFound("Buffet not found");
        }

        PickupSlot slot = slots.findLockedById(
                request.pickupSlotId()
        ).orElseThrow(() ->
                ApiException.notFound("Pickup slot not found")
        );

        if (!slot.getBuffet().getId().equals(buffetId)) {
            throw ApiException.conflict(
                    "Pickup slot buffet has changed"
            );
        }

        if (!slot.getSlotTime().isAfter(Instant.now())) {
            throw ApiException.badRequest(
                    "Pickup slot has already passed"
            );
        }

        LocalDate slotDate = slot.getSlotTime()
                .atZone(zoneId)
                .toLocalDate();

        Map<UUID, Integer> quantities = new LinkedHashMap<>();

        request.items().forEach(item ->
                quantities.merge(
                        item.mealId(),
                        item.quantity(),
                        Integer::sum
                )
        );

        if (quantities.size() > 20 ||
                quantities.values().stream().anyMatch(q -> q > 20)) {
            throw ApiException.badRequest(
                    "An order can contain at most 20 distinct meals and 20 of each meal"
            );
        }

        List<Meal> selectedMeals = new ArrayList<>();

        for (UUID mealId : quantities.keySet()
                .stream()
                .sorted(Comparator.comparing(UUID::toString))
                .toList()) {

            Meal meal = meals.findLockedById(mealId)
                    .orElseThrow(() ->
                            ApiException.notFound(
                                    "One or more meals were not found"
                            )
                    );

            if (!meal.getMenu()
                    .getBuffet()
                    .getId()
                    .equals(buffetId)) {
                throw ApiException.badRequest(
                        "All meals must come from the selected buffet"
                );
            }

            if (!meal.getMenu().getMenuDate().equals(slotDate)) {
                throw ApiException.badRequest(
                        "Meals must belong to the pickup slot date"
                );
            }

            if (!meal.isAvailable()) {
                throw ApiException.conflict(
                        "Meal is unavailable: " + meal.getName()
                );
            }

            if (meal.getCapacity() != null &&
                    meal.getReservedCount() + quantities.get(mealId)
                            > meal.getCapacity()) {
                throw ApiException.conflict(
                        "Not enough portions remain for: " + meal.getName()
                );
            }

            selectedMeals.add(meal);
        }

        // Each order reserves capacity in its pickup slot.
        if (slot.getCurrentCount() >= slot.getCapacity()) {
            throw ApiException.conflict(
                    "Pickup slot is full"
            );
        }

        String pickupCode = generatePickupCode(buffetId);

        // Keep pickup slot capacity tracking separate.
        slot.reserve();

        // Generate one queue sequence per buffet per day.
        int queueNumber = generateDailyQueueNumber(buffetId);

        BigDecimal total = selectedMeals.stream()
                .map(meal ->
                        meal.getPrice().multiply(
                                BigDecimal.valueOf(
                                        quantities.get(meal.getId())
                                )
                        )
                )
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        QuickOrder newOrder = new QuickOrder(
                student,
                slot.getBuffet(),
                slot,
                queueNumber
        );

        newOrder.setPickupCode(pickupCode);

        QuickOrder order = orders.save(newOrder);
        notifications.newOrder(
        order.getBuffet().getOwner(),
        student,
        queueNumber
        );

        for (Meal meal : selectedMeals) {
            int quantity = quantities.get(meal.getId());

            meal.reserve(quantity);

            items.save(
                    new OrderItem(order, meal, quantity)
            );
        }

        Payment payment = payments.save(
                new Payment(
                        student,
                        order,
                        total,
                        request.paymentMethod()
                )
        );

        List<OrderItem> responseItems = selectedMeals.stream()
                .map(meal -> new OrderItem(
                        order,
                        meal,
                        quantities.get(meal.getId())
                ))
                .toList();

        return toResponse(
                order,
                responseItems,
                payment
        );
    }

    private int generateDailyQueueNumber(UUID buffetId) {
        LocalDate today = LocalDate.now(zoneId);

        Instant start = today
                .atStartOfDay(zoneId)
                .toInstant();

        Instant end = today
                .plusDays(1)
                .atStartOfDay(zoneId)
                .toInstant();

        int maxQueueNumber = orders.findMaxQueueNumberForDay(
                buffetId,
                start,
                end
        );

        return maxQueueNumber + 1;
    }

    private String generatePickupCode(UUID buffetId) {
        Set<OrderStatus> activeStatuses = EnumSet.of(
                OrderStatus.PENDING,
                OrderStatus.CONFIRMED,
                OrderStatus.PREPARING,
                OrderStatus.READY
        );

        Set<String> usedCodes = new HashSet<>(
                entityManager.createQuery(
                        """
                        select o.pickupCode
                        from QuickOrder o
                        where o.buffet.id = :buffetId
                          and o.status in :statuses
                          and o.pickupCode is not null
                        """,
                        String.class
                )
                .setParameter("buffetId", buffetId)
                .setParameter("statuses", activeStatuses)
                .getResultList()
        );

        if (usedCodes.size() >= 10000) {
            throw ApiException.conflict(
                    "No pickup codes are available"
            );
        }

        int start = ThreadLocalRandom.current().nextInt(10000);

        for (int offset = 0; offset < 10000; offset++) {
            int candidate = (start + offset) % 10000;
            String code = String.format("%04d", candidate);

            if (!usedCodes.contains(code)) {
                return code;
            }
        }

        throw ApiException.conflict(
                "No pickup codes are available"
        );
    }

    @Transactional(readOnly = true)
    public List<OrderDtos.OrderResponse> mine(String email) {
        return orders
                .findByStudentEmailIgnoreCaseOrderByOrderedAtDesc(email)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public OrderDtos.OrderPageResponse buffetOrders(
            UUID buffetId,
            String email,
            OrderStatus status,
            int page,
            int size
    ) {
        Buffet buffet = buffets.findById(buffetId)
                .orElseThrow(() ->
                        ApiException.notFound("Buffet not found")
                );

        authorize(buffet, email);

        if (page < 0 || size < 1 || size > 100) {
            throw ApiException.badRequest(
                    "Page must be non-negative and size must be between 1 and 100"
            );
        }

        Pageable pageable = PageRequest.of(
                page,
                size,
                Sort.by(Sort.Direction.ASC, "orderedAt")
                        .and(Sort.by(Sort.Direction.ASC, "id"))
        );

        Page<QuickOrder> result = status == null
                ? orders.findByBuffetId(buffetId, pageable)
                : orders.findByBuffetIdAndStatus(
                        buffetId,
                        status,
                        pageable
                );

        return new OrderDtos.OrderPageResponse(
                result.map(this::toResponse).getContent(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }

    @Transactional
    public OrderDtos.OrderResponse updateStatus(
            UUID orderId,
            String email,
            OrderStatus nextStatus
    ) {
        QuickOrder order = orders.findLockedById(orderId)
                .orElseThrow(() ->
                        ApiException.notFound("Order not found")
                );

        authorize(order.getBuffet(), email);

        boolean valid = switch (order.getStatus()) {
            case PENDING ->
                    nextStatus == OrderStatus.CONFIRMED;

            case CONFIRMED ->
                    nextStatus == OrderStatus.PREPARING;

            case PREPARING ->
                    nextStatus == OrderStatus.READY;

            case READY ->
                    nextStatus == OrderStatus.COMPLETED;

            case COMPLETED, CANCELLED -> false;
        };

        if (!valid) {
            throw ApiException.conflict(
                    "Order cannot move from "
                            + order.getStatus()
                            + " to "
                            + nextStatus
            );
        }

        order.setStatus(nextStatus);

        if (nextStatus == OrderStatus.READY) {
            notifications.orderReady(
                    order.getStudent(),
                    order.getBuffet().getOwner(),
                    order.getQueueNumber()
            );
        }

        if (nextStatus == OrderStatus.COMPLETED) {
            payments.findByOrderId(orderId)
                    .ifPresent(Payment::markPaid);
        }

        return toResponse(order);
    }

    @Transactional
    public OrderDtos.OrderResponse cancel(
            UUID orderId,
            String email
    ) {
        QuickOrder order = orders
                .findLockedByIdAndStudentEmailIgnoreCase(
                        orderId,
                        email
                )
                .orElseThrow(() ->
                        ApiException.notFound("Order not found")
                );

        if (order.getStatus() != OrderStatus.PENDING) {
            throw ApiException.conflict(
                    "Only pending orders can be cancelled"
            );
        }

        order.setStatus(OrderStatus.CANCELLED);
        notifications.orderCancelled(
        order.getBuffet().getOwner(),
        order.getStudent(),
        order.getQueueNumber()
        );

        PickupSlot slot = slots.findLockedById(
                order.getPickupSlot().getId()
        ).orElseThrow();

        slot.release();

        releaseMealReservations(orderId);

        payments.findByOrderId(orderId)
                .ifPresent(Payment::markCancelled);

        return toResponse(order);
    }

    @Transactional
    public OrderDtos.OrderResponse cancelByStaff(
            UUID orderId,
            String email
    ) {
        QuickOrder order = orders.findLockedById(orderId)
                .orElseThrow(() ->
                        ApiException.notFound("Order not found")
                );

        authorize(order.getBuffet(), email);

        if (order.getStatus() == OrderStatus.COMPLETED ||
                order.getStatus() == OrderStatus.CANCELLED) {
            throw ApiException.conflict(
                    "This order can no longer be cancelled"
            );
        }

        order.setStatus(OrderStatus.CANCELLED);

        PickupSlot slot = slots.findLockedById(
                order.getPickupSlot().getId()
        ).orElseThrow();

        slot.release();

        releaseMealReservations(orderId);

        payments.findByOrderId(orderId).ifPresent(payment -> {
            if (payment.getStatus() == PaymentStatus.PAID) {
                payment.markRefunded();
            } else {
                payment.markCancelled();
            }
        });

        return toResponse(order);
    }

    private OrderDtos.OrderResponse toResponse(
            QuickOrder order
    ) {
        return toResponse(
                order,
                items.findByOrderId(order.getId()),
                payments.findByOrderId(order.getId())
                        .orElseThrow()
        );
    }

    private OrderDtos.OrderResponse toResponse(
            QuickOrder order,
            List<OrderItem> orderItems,
            Payment payment
    ) {
        List<OrderDtos.ItemResponse> lines = orderItems.stream()
                .map(item -> new OrderDtos.ItemResponse(
                        item.getMeal().getId(),
                        item.getMealName(),
                        item.getQuantity(),
                        item.getUnitPrice(),
                        item.getUnitPrice().multiply(
                                BigDecimal.valueOf(item.getQuantity())
                        )
                ))
                .toList();

        BigDecimal total = lines.stream()
                .map(OrderDtos.ItemResponse::lineTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new OrderDtos.OrderResponse(
                order.getId(),
                order.getBuffet().getId(),
                order.getBuffet().getName(),
                order.getQueueNumber(),
                order.getPickupCode(),
                order.getStudent().getUsername(),
                order.getStudent().getEmail(),
                order.getPickupSlot().getSlotTime(),
                order.getStatus(),
                payment.getMethod(),
                payment.getStatus(),
                total,
                order.getOrderedAt(),
                lines
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

    private void releaseMealReservations(UUID orderId) {
        items.findItemsWithMealByOrderId(orderId)
                .stream()
                .sorted(Comparator.comparing(
                        item -> item.getMeal()
                                .getId()
                                .toString()
                ))
                .forEach(item -> {
                    Meal meal = meals.findLockedById(
                            item.getMeal().getId()
                    ).orElseThrow();

                    meal.release(item.getQuantity());
                });
    }
}

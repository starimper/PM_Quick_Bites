-- Repair duplicate queue numbers that could have been produced by the old
-- current_count-based allocator before adding a permanent queue counter.
WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY pickup_slot_id ORDER BY ordered_at, id) AS new_queue_number
    FROM orders
)
UPDATE orders o
SET queue_number = r.new_queue_number
FROM ranked r
WHERE o.id = r.id;

ALTER TABLE pickup_slots
    ADD COLUMN next_queue_number INTEGER NOT NULL DEFAULT 1;

UPDATE pickup_slots s
SET next_queue_number = COALESCE((
    SELECT MAX(o.queue_number) + 1
    FROM orders o
    WHERE o.pickup_slot_id = s.id
), 1);

ALTER TABLE pickup_slots
    ADD CONSTRAINT ck_pickup_slots_next_queue_number_positive CHECK (next_queue_number > 0);

ALTER TABLE orders
    ADD COLUMN version INTEGER NOT NULL DEFAULT 0;

ALTER TABLE orders
    ADD CONSTRAINT uq_orders_pickup_slot_queue UNIQUE (pickup_slot_id, queue_number);

-- Keep the oldest active order when upgrading databases created by the old
-- implementation, then rebuild reservation counters from the surviving data.
WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY student_id, pickup_slot_id ORDER BY ordered_at, id) AS duplicate_rank
    FROM orders
    WHERE status <> 'CANCELLED'
)
UPDATE orders o
SET status = 'CANCELLED'
FROM ranked r
WHERE o.id = r.id AND r.duplicate_rank > 1;

UPDATE pickup_slots s
SET current_count = COALESCE((
    SELECT COUNT(*)::INTEGER
    FROM orders o
    WHERE o.pickup_slot_id = s.id AND o.status <> 'CANCELLED'
), 0);

UPDATE meals m
SET reserved_count = COALESCE((
    SELECT SUM(i.quantity)::INTEGER
    FROM order_items i
    JOIN orders o ON o.id = i.order_id
    WHERE i.meal_id = m.id AND o.status <> 'CANCELLED'
), 0);

-- A student may have one active order per pickup slot. Cancelled orders do
-- not block a new order and retain their original queue number.
CREATE UNIQUE INDEX uq_orders_active_student_slot
    ON orders(student_id, pickup_slot_id)
    WHERE status <> 'CANCELLED';

ALTER TABLE payments
    DROP CONSTRAINT IF EXISTS payments_status_check;

ALTER TABLE payments
    ADD CONSTRAINT payments_status_check
    CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED', 'CANCELLED'));

UPDATE payments p
SET status = 'CANCELLED'
FROM orders o
WHERE p.order_id = o.id
  AND o.status = 'CANCELLED'
  AND p.status = 'PENDING';

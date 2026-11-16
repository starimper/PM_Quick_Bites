
ALTER TABLE orders
ADD COLUMN pickup_code VARCHAR(4);

CREATE UNIQUE INDEX uq_orders_active_pickup_code
ON orders (buffet_id, pickup_code)
WHERE status IN (
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'READY'
)
AND pickup_code IS NOT NULL;

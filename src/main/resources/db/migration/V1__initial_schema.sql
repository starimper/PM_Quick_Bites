CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(80) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('STUDENT', 'BUFFET_STAFF', 'CAMPUS_ADMIN')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE buffets (
    id UUID PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    location VARCHAR(240) NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE menus (
    id UUID PRIMARY KEY,
    buffet_id UUID NOT NULL REFERENCES buffets(id) ON DELETE CASCADE,
    menu_date DATE NOT NULL,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (buffet_id, menu_date)
);

CREATE TABLE meals (
    id UUID PRIMARY KEY,
    menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    name VARCHAR(140) NOT NULL,
    description TEXT,
    photo_url TEXT,
    nutrition_info JSONB NOT NULL DEFAULT '{}'::jsonb,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    capacity INTEGER CHECK (capacity IS NULL OR capacity >= 0),
    reserved_count INTEGER NOT NULL DEFAULT 0 CHECK (reserved_count >= 0),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_meals_menu_available ON meals(menu_id, is_available);

CREATE TABLE pickup_slots (
    id UUID PRIMARY KEY,
    buffet_id UUID NOT NULL REFERENCES buffets(id) ON DELETE CASCADE,
    slot_time TIMESTAMPTZ NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    current_count INTEGER NOT NULL DEFAULT 0 CHECK (current_count >= 0),
    UNIQUE (buffet_id, slot_time)
);
CREATE INDEX ix_pickup_slots_buffet_time ON pickup_slots(buffet_id, slot_time);

CREATE TABLE orders (
    id UUID PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES users(id),
    buffet_id UUID NOT NULL REFERENCES buffets(id),
    pickup_slot_id UUID NOT NULL REFERENCES pickup_slots(id),
    queue_number INTEGER NOT NULL CHECK (queue_number > 0),
    status VARCHAR(30) NOT NULL CHECK (status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED')),
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_orders_student_ordered ON orders(student_id, ordered_at DESC);
CREATE INDEX ix_orders_buffet_status_ordered ON orders(buffet_id, status, ordered_at);

CREATE TABLE order_items (
    id UUID PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    meal_id UUID NOT NULL REFERENCES meals(id),
    meal_name VARCHAR(140) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE payments (
    id UUID PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES users(id),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    method VARCHAR(30) NOT NULL CHECK (method IN ('PAY_AT_PICKUP', 'CARD', 'QR')),
    status VARCHAR(30) NOT NULL CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
    paid_at TIMESTAMPTZ
);

CREATE TABLE feedback (
    id UUID PRIMARY KEY,
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id),
    student_id UUID NOT NULL REFERENCES users(id),
    emoji_rating VARCHAR(20) NOT NULL CHECK (emoji_rating IN ('HAPPY', 'NEUTRAL', 'SAD')),
    comment TEXT,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    sender_id UUID REFERENCES users(id),
    type VARCHAR(40) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8개 ENUM 타입 생성
CREATE TYPE part_category AS ENUM ('cpu', 'gpu', 'ram', 'ssd', 'mainboard', 'power', 'case', 'cooler');
CREATE TYPE listing_status AS ENUM ('draft', 'active', 'reserved', 'sold', 'expired', 'deleted');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipping', 'delivered', 'cancelled', 'refunded');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'cancelled', 'refunded');
CREATE TYPE shipping_status AS ENUM ('preparing', 'shipped', 'in_transit', 'delivered', 'returned');
CREATE TYPE sell_request_status AS ENUM ('pending', 'reviewing', 'approved', 'rejected', 'completed');
CREATE TYPE dragon_ball_status AS ENUM ('active', 'used', 'expired');
CREATE TYPE settlement_status AS ENUM ('pending', 'processing', 'completed', 'failed');

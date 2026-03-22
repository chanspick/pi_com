-- 성능 인덱스
CREATE INDEX idx_listings_category ON listings(category);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_seller_id ON listings(seller_id);
CREATE INDEX idx_listings_base_part_id ON listings(base_part_id);
CREATE INDEX idx_listings_price ON listings(price);
CREATE INDEX idx_listings_created_at ON listings(created_at DESC);

CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_seller_id ON orders(seller_id);
CREATE INDEX idx_orders_listing_id ON orders(listing_id);
CREATE INDEX idx_orders_status ON orders(status);

CREATE INDEX idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_listing_id ON favorites(listing_id);

CREATE INDEX idx_price_history_base_part_id ON price_history(base_part_id);
CREATE INDEX idx_price_history_recorded_at ON price_history(recorded_at DESC);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);

CREATE INDEX idx_sell_requests_user_id ON sell_requests(user_id);
CREATE INDEX idx_sell_requests_status ON sell_requests(status);

CREATE INDEX idx_base_parts_category ON base_parts(category);
CREATE INDEX idx_base_parts_name ON base_parts(name);

CREATE INDEX idx_toss_payments_order_id ON toss_payments(order_id);
CREATE INDEX idx_toss_payments_payment_key ON toss_payments(payment_key);

CREATE INDEX idx_invoices_order_id ON invoices(order_id);
CREATE INDEX idx_settlements_seller_id ON settlements(seller_id);
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_dragon_balls_user_id ON dragon_balls(user_id);

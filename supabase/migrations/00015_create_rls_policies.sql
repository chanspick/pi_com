-- RLS 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE base_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE toss_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE sell_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE dragon_balls ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE account_deletions ENABLE ROW LEVEL SECURITY;

-- profiles: 본인 프로필 읽기/수정, 다른 사용자 프로필 읽기
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- base_parts: 모든 사용자 읽기, 관리자만 수정
CREATE POLICY "base_parts_select" ON base_parts FOR SELECT USING (true);
CREATE POLICY "base_parts_insert" ON base_parts FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
);
CREATE POLICY "base_parts_update" ON base_parts FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
);

-- listings: 모든 사용자 읽기, 판매자 본인 수정
CREATE POLICY "listings_select" ON listings FOR SELECT USING (true);
CREATE POLICY "listings_insert" ON listings FOR INSERT WITH CHECK (auth.uid() = seller_id);
CREATE POLICY "listings_update" ON listings FOR UPDATE USING (auth.uid() = seller_id);
CREATE POLICY "listings_delete" ON listings FOR DELETE USING (auth.uid() = seller_id);

-- orders: 구매자/판매자만 접근
CREATE POLICY "orders_select" ON orders FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "orders_insert" ON orders FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "orders_update" ON orders FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- toss_payments: 주문 관련자만 접근
CREATE POLICY "payments_select" ON toss_payments FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = toss_payments.order_id AND (orders.buyer_id = auth.uid() OR orders.seller_id = auth.uid()))
);
CREATE POLICY "payments_insert" ON toss_payments FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = toss_payments.order_id AND orders.buyer_id = auth.uid())
);

-- sell_requests: 본인만 접근
CREATE POLICY "sell_requests_select" ON sell_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "sell_requests_insert" ON sell_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sell_requests_update" ON sell_requests FOR UPDATE USING (auth.uid() = user_id);

-- cart_items: 본인만 접근
CREATE POLICY "cart_items_select" ON cart_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "cart_items_insert" ON cart_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cart_items_delete" ON cart_items FOR DELETE USING (auth.uid() = user_id);

-- favorites: 본인만 접근
CREATE POLICY "favorites_select" ON favorites FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "favorites_insert" ON favorites FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "favorites_delete" ON favorites FOR DELETE USING (auth.uid() = user_id);

-- price_history: 모든 사용자 읽기
CREATE POLICY "price_history_select" ON price_history FOR SELECT USING (true);

-- price_alerts: 본인만 접근
CREATE POLICY "price_alerts_select" ON price_alerts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "price_alerts_insert" ON price_alerts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "price_alerts_update" ON price_alerts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "price_alerts_delete" ON price_alerts FOR DELETE USING (auth.uid() = user_id);

-- notifications: 본인만 접근
CREATE POLICY "notifications_select" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- dragon_balls: 본인만 접근
CREATE POLICY "dragon_balls_select" ON dragon_balls FOR SELECT USING (auth.uid() = user_id);

-- invoices: 본인만 접근
CREATE POLICY "invoices_select" ON invoices FOR SELECT USING (auth.uid() = user_id);

-- settlements: 판매자만 접근
CREATE POLICY "settlements_select" ON settlements FOR SELECT USING (auth.uid() = seller_id);

-- addresses: 본인만 접근
CREATE POLICY "addresses_select" ON addresses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "addresses_insert" ON addresses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "addresses_update" ON addresses FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "addresses_delete" ON addresses FOR DELETE USING (auth.uid() = user_id);

-- account_deletions: 본인만 접근
CREATE POLICY "account_deletions_select" ON account_deletions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "account_deletions_insert" ON account_deletions FOR INSERT WITH CHECK (auth.uid() = user_id);

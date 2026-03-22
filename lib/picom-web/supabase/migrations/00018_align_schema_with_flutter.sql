-- Migration: 00018_align_schema_with_flutter.sql
-- Purpose: Flutter 모델과 Supabase 스키마 정합성 확보
-- Date: 2026-03-21

-- ============================================================
-- 1. price_alerts: 누락 필드 추가
-- ============================================================
ALTER TABLE price_alerts
  ADD COLUMN IF NOT EXISTS part_name TEXT,
  ADD COLUMN IF NOT EXISTS price_at_creation INTEGER,
  ADD COLUMN IF NOT EXISTS last_checked_at TIMESTAMPTZ;

-- ============================================================
-- 2. notifications: 관련 엔티티 ID + readAt 추가
-- ============================================================
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS related_order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_listing_id UUID REFERENCES listings(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_sell_request_id UUID REFERENCES sell_requests(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_refund_id UUID,
  ADD COLUMN IF NOT EXISTS related_dragon_ball_id UUID REFERENCES dragon_balls(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- ============================================================
-- 3. sell_requests: 상태/보증 필드 추가
-- ============================================================
ALTER TABLE sell_requests
  ADD COLUMN IF NOT EXISTS is_secondhand BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS has_warranty BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS warranty_months_left INTEGER;

-- ============================================================
-- 4. dragon_balls: 보관/위탁 관련 필드 추가
-- ============================================================
ALTER TABLE dragon_balls
  ADD COLUMN IF NOT EXISTS storage_type TEXT DEFAULT 'general' CHECK (storage_type IN ('general', 'rental')),
  ADD COLUMN IF NOT EXISTS accumulated_fee INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS agreed_to_terms BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS agreed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS sale_price INTEGER,
  ADD COLUMN IF NOT EXISTS consignment_converted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS revenue_returned BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS batch_shipment_id UUID;

-- ============================================================
-- 5. profiles: 인증 제공자 + 마지막 로그인
-- ============================================================
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS provider TEXT,
  ADD COLUMN IF NOT EXISTS providers TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- ============================================================
-- 6. batch_shipments: 새 테이블 생성
-- ============================================================
CREATE TABLE IF NOT EXISTS batch_shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  dragon_ball_ids UUID[] DEFAULT '{}',
  recipient_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  shipping_address JSONB NOT NULL DEFAULT '{}',
  shipping_cost INTEGER DEFAULT 0,
  additional_services JSONB DEFAULT '[]',
  tracking_number TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- dragon_balls FK → batch_shipments (deferred because table didn't exist)
ALTER TABLE dragon_balls
  ADD CONSTRAINT fk_dragon_balls_batch_shipment
  FOREIGN KEY (batch_shipment_id) REFERENCES batch_shipments(id) ON DELETE SET NULL;

-- ============================================================
-- 7. refunds: 새 테이블 생성 (Flutter notification에서 참조)
-- ============================================================
CREATE TABLE IF NOT EXISTS refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  approved_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- notifications FK → refunds
ALTER TABLE notifications
  ADD CONSTRAINT fk_notifications_refund
  FOREIGN KEY (related_refund_id) REFERENCES refunds(id) ON DELETE SET NULL;

-- ============================================================
-- 8. RLS 정책 (새 테이블)
-- ============================================================
ALTER TABLE batch_shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;

-- batch_shipments: 본인 데이터만
CREATE POLICY "Users can view own batch shipments"
  ON batch_shipments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own batch shipments"
  ON batch_shipments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own batch shipments"
  ON batch_shipments FOR UPDATE
  USING (auth.uid() = user_id);

-- refunds: 본인 데이터만 (주문의 buyer/seller 모두)
CREATE POLICY "Users can view own refunds"
  ON refunds FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own refunds"
  ON refunds FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 9. 인덱스
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_batch_shipments_user_id ON batch_shipments(user_id);
CREATE INDEX IF NOT EXISTS idx_batch_shipments_status ON batch_shipments(status);
CREATE INDEX IF NOT EXISTS idx_refunds_order_id ON refunds(order_id);
CREATE INDEX IF NOT EXISTS idx_refunds_user_id ON refunds(user_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON refunds(status);
CREATE INDEX IF NOT EXISTS idx_notifications_related_order ON notifications(related_order_id);
CREATE INDEX IF NOT EXISTS idx_notifications_related_listing ON notifications(related_listing_id);
CREATE INDEX IF NOT EXISTS idx_price_alerts_last_checked ON price_alerts(last_checked_at);
CREATE INDEX IF NOT EXISTS idx_dragon_balls_batch_shipment ON dragon_balls(batch_shipment_id);
CREATE INDEX IF NOT EXISTS idx_dragon_balls_storage_type ON dragon_balls(storage_type);

CREATE TABLE toss_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id),
  payment_key TEXT UNIQUE,
  order_name TEXT,
  amount INTEGER NOT NULL,
  status payment_status DEFAULT 'pending',
  method TEXT,
  requested_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  receipt_url TEXT,
  raw_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER toss_payments_updated_at
  BEFORE UPDATE ON toss_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

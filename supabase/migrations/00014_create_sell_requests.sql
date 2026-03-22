CREATE TABLE sell_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category part_category NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  desired_price INTEGER,
  images TEXT[] DEFAULT '{}',
  specs JSONB DEFAULT '{}',
  status sell_request_status DEFAULT 'pending',
  admin_note TEXT,
  listing_id UUID REFERENCES listings(id),
  reviewed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER sell_requests_updated_at
  BEFORE UPDATE ON sell_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

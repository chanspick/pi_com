CREATE TABLE base_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category part_category NOT NULL,
  name TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  specs JSONB DEFAULT '{}',
  image_url TEXT,
  description TEXT,
  average_price INTEGER DEFAULT 0,
  listing_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER base_parts_updated_at
  BEFORE UPDATE ON base_parts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

CREATE TABLE listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  base_part_id UUID REFERENCES base_parts(id),
  title TEXT NOT NULL,
  description TEXT,
  price INTEGER NOT NULL,
  original_price INTEGER,
  category part_category NOT NULL,
  status listing_status DEFAULT 'draft',
  condition TEXT,
  condition_score INTEGER,
  images TEXT[] DEFAULT '{}',
  specs JSONB DEFAULT '{}',
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER listings_updated_at
  BEFORE UPDATE ON listings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

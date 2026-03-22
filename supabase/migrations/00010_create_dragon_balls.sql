CREATE TABLE dragon_balls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  reason TEXT,
  status dragon_ball_status DEFAULT 'active',
  expires_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER dragon_balls_updated_at
  BEFORE UPDATE ON dragon_balls
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

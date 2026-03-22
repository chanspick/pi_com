-- ============================================================================
-- P0-1: base_parts에 lowest_price 컬럼 추가 + listings 트리거
-- Flutter Cloud Functions의 recalculateBasePartStats + addPriceHistoryPoint 이식
-- ============================================================================

-- 1. base_parts에 lowest_price 컬럼 추가
ALTER TABLE base_parts ADD COLUMN IF NOT EXISTS lowest_price INTEGER DEFAULT 0;

-- 2. price_history에 lowest_price, average_price, listing_count 컬럼 추가
-- 기존 price 컬럼은 lowest_price와 동일하게 유지 (하위 호환)
ALTER TABLE price_history ADD COLUMN IF NOT EXISTS lowest_price INTEGER;
ALTER TABLE price_history ADD COLUMN IF NOT EXISTS average_price INTEGER;
ALTER TABLE price_history ADD COLUMN IF NOT EXISTS listing_count INTEGER;

-- 3. BasePart 통계 재계산 함수
-- Flutter의 recalculateBasePartStats 이식
CREATE OR REPLACE FUNCTION recalculate_base_part_stats(p_base_part_id UUID)
RETURNS VOID AS $$
DECLARE
  v_lowest INTEGER;
  v_average INTEGER;
  v_count INTEGER;
  v_prev_lowest INTEGER;
  v_prev_average INTEGER;
  v_prev_count INTEGER;
BEGIN
  -- 이전 stats 저장 (가격 변경 감지용)
  SELECT lowest_price, average_price, listing_count
  INTO v_prev_lowest, v_prev_average, v_prev_count
  FROM base_parts
  WHERE id = p_base_part_id;

  -- active listings만 대상으로 통계 계산
  -- Flutter에서는 status='available', Supabase에서는 status='active'
  SELECT
    COALESCE(MIN(price), 0),
    COALESCE(ROUND(AVG(price))::INTEGER, 0),
    COUNT(*)::INTEGER
  INTO v_lowest, v_average, v_count
  FROM listings
  WHERE base_part_id = p_base_part_id
    AND status = 'active';

  -- base_parts 업데이트
  UPDATE base_parts
  SET
    lowest_price = v_lowest,
    average_price = v_average,
    listing_count = v_count
  WHERE id = p_base_part_id;

  -- 가격 변경 감지: 이전과 다르면 price_history에 기록
  IF v_prev_lowest IS DISTINCT FROM v_lowest
     OR v_prev_average IS DISTINCT FROM v_average
     OR v_prev_count IS DISTINCT FROM v_count
  THEN
    INSERT INTO price_history (base_part_id, price, lowest_price, average_price, listing_count, source)
    VALUES (p_base_part_id, v_lowest, v_lowest, v_average, v_count, 'trigger');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Listings 변경 시 자동으로 base_parts stats 재계산하는 트리거 함수
CREATE OR REPLACE FUNCTION on_listing_change()
RETURNS TRIGGER AS $$
DECLARE
  v_base_part_id UUID;
BEGIN
  -- INSERT: 새 매물의 base_part_id
  IF TG_OP = 'INSERT' THEN
    v_base_part_id := NEW.base_part_id;
    IF v_base_part_id IS NOT NULL AND NEW.status = 'active' THEN
      PERFORM recalculate_base_part_stats(v_base_part_id);
    END IF;
    RETURN NEW;

  -- UPDATE: status 변경 또는 price 변경 감지
  ELSIF TG_OP = 'UPDATE' THEN
    -- status가 변경된 경우
    IF OLD.status IS DISTINCT FROM NEW.status AND NEW.base_part_id IS NOT NULL THEN
      PERFORM recalculate_base_part_stats(NEW.base_part_id);
    -- price가 변경된 경우 (active 상태일 때만)
    ELSIF OLD.price IS DISTINCT FROM NEW.price AND NEW.status = 'active' AND NEW.base_part_id IS NOT NULL THEN
      PERFORM recalculate_base_part_stats(NEW.base_part_id);
    END IF;

    -- base_part_id가 변경된 경우: 이전 base_part도 재계산
    IF OLD.base_part_id IS DISTINCT FROM NEW.base_part_id THEN
      IF OLD.base_part_id IS NOT NULL THEN
        PERFORM recalculate_base_part_stats(OLD.base_part_id);
      END IF;
    END IF;
    RETURN NEW;

  -- DELETE: 삭제된 매물의 base_part_id 재계산
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.base_part_id IS NOT NULL THEN
      PERFORM recalculate_base_part_stats(OLD.base_part_id);
    END IF;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 트리거 생성 (기존 있으면 교체)
DROP TRIGGER IF EXISTS listings_stats_trigger ON listings;
CREATE TRIGGER listings_stats_trigger
  AFTER INSERT OR UPDATE OR DELETE ON listings
  FOR EACH ROW
  EXECUTE FUNCTION on_listing_change();

-- 6. 기존 데이터 정합성: 모든 base_parts의 stats를 재계산
-- (마이그레이션 후 한번만 실행)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT DISTINCT id FROM base_parts LOOP
    PERFORM recalculate_base_part_stats(r.id);
  END LOOP;
END;
$$;

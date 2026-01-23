// functions/src/middleware/rate_limiter.ts
// Rate Limiter 미들웨어 - TDD GREEN 단계 구현

import { Request, Response, NextFunction } from 'express';

/**
 * Rate Limiter 설정 인터페이스
 */
export interface RateLimiterConfig {
  windowMs: number;      // 제한 윈도우 시간 (밀리초)
  maxRequests: number;   // 윈도우 내 최대 요청 수
  store?: RateLimiterStore; // 커스텀 Store (선택)
}

/**
 * Rate Limiter Store 인터페이스
 * 커스텀 스토리지 구현을 위한 인터페이스
 */
export interface RateLimiterStore {
  increment: (key: string) => { count: number; resetTime: number };
  decrement: (key: string) => void;
  resetKey: (key: string) => void;
}

/**
 * 내부 요청 추적 데이터
 */
interface RequestRecord {
  count: number;
  resetTime: number;
}

/**
 * 기본 메모리 Store 구현
 */
class MemoryStore implements RateLimiterStore {
  private records: Map<string, RequestRecord> = new Map();
  private windowMs: number;

  constructor(windowMs: number) {
    this.windowMs = windowMs;
  }

  increment(key: string): { count: number; resetTime: number } {
    const now = Date.now();
    const record = this.records.get(key);

    // 기존 레코드가 있고 윈도우가 아직 유효한 경우
    if (record && now < record.resetTime) {
      record.count += 1;
      return { count: record.count, resetTime: record.resetTime };
    }

    // 새 윈도우 시작
    const newRecord: RequestRecord = {
      count: 1,
      resetTime: now + this.windowMs,
    };
    this.records.set(key, newRecord);
    return { count: newRecord.count, resetTime: newRecord.resetTime };
  }

  decrement(key: string): void {
    const record = this.records.get(key);
    if (record && record.count > 0) {
      record.count -= 1;
    }
  }

  resetKey(key: string): void {
    this.records.delete(key);
  }
}

/**
 * Rate Limiter 미들웨어 생성 함수
 *
 * @param config - Rate Limiter 설정
 * @returns Express 미들웨어 함수
 */
export function createRateLimiter(
  config: RateLimiterConfig
): (req: Request, res: Response, next: NextFunction) => void {
  const { windowMs, maxRequests, store: customStore } = config;

  // 커스텀 Store가 제공되지 않으면 기본 메모리 Store 사용
  const store: RateLimiterStore = customStore || new MemoryStore(windowMs);

  return (req: Request, res: Response, next: NextFunction): void => {
    // IP 주소를 키로 사용
    const key = req.ip || 'unknown';

    // 요청 카운트 증가
    const { count } = store.increment(key);

    // 남은 요청 횟수 계산
    const remaining = Math.max(0, maxRequests - count);

    // 응답 헤더 설정
    res.setHeader('X-RateLimit-Limit', maxRequests);
    res.setHeader('X-RateLimit-Remaining', remaining);

    // 제한 초과 체크
    if (count > maxRequests) {
      res.status(429).json({
        error: 'Too many requests',
        message: `Rate limit exceeded. Please try again later.`,
      });
      return;
    }

    // 제한 내 요청은 다음 미들웨어로 전달
    next();
  };
}

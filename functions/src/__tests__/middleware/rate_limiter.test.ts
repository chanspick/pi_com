// functions/src/__tests__/middleware/rate_limiter.test.ts
// Rate Limiter 미들웨어 테스트 - TDD RED 단계

import { Request, Response, NextFunction } from 'express';
import { createRateLimiter, RateLimiterConfig, RateLimiterStore } from '../../middleware/rate_limiter';

// 테스트용 Request 인터페이스 (ip를 쓰기 가능하도록)
interface MockRequest {
  ip: string;
  path: string;
}

describe('RateLimiter Middleware', () => {
  let mockRequest: MockRequest;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;

  beforeEach(() => {
    jest.useFakeTimers();

    mockRequest = {
      ip: '127.0.0.1',
      path: '/payment/approve',
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      setHeader: jest.fn(),
    };

    nextFunction = jest.fn();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('기본 동작', () => {
    it('첫 번째 요청은 통과되어야 한다', () => {
      // Given: Rate limiter 설정 (분당 5회)
      const config: RateLimiterConfig = {
        windowMs: 60000, // 1분
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      // When: 첫 번째 요청
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);

      // Then: next()가 호출되어야 함
      expect(nextFunction).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('제한 내의 요청은 모두 통과되어야 한다', () => {
      // Given: Rate limiter 설정 (분당 5회)
      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      // When: 5번의 요청
      for (let i = 0; i < 5; i++) {
        rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      }

      // Then: 모든 요청이 통과 (next()가 5번 호출됨)
      expect(nextFunction).toHaveBeenCalledTimes(5);
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('제한을 초과한 요청은 429 상태를 반환해야 한다', () => {
      // Given: Rate limiter 설정 (분당 5회)
      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      // When: 6번의 요청 (제한 초과)
      for (let i = 0; i < 6; i++) {
        rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      }

      // Then: 마지막 요청은 429로 거부됨
      expect(nextFunction).toHaveBeenCalledTimes(5);
      expect(mockResponse.status).toHaveBeenCalledWith(429);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          error: 'Too many requests',
        })
      );
    });
  });

  describe('IP 기반 제한', () => {
    it('서로 다른 IP는 별도로 제한되어야 한다', () => {
      // Given: Rate limiter 설정 (분당 5회)
      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      // When: IP1에서 5번 요청
      const mockRequest1: MockRequest = { ip: '192.168.1.1', path: '/payment/approve' };
      for (let i = 0; i < 5; i++) {
        rateLimiter(mockRequest1 as unknown as Request, mockResponse as Response, nextFunction);
      }

      // When: IP2에서 5번 요청
      const mockRequest2: MockRequest = { ip: '192.168.1.2', path: '/payment/approve' };
      for (let i = 0; i < 5; i++) {
        rateLimiter(mockRequest2 as unknown as Request, mockResponse as Response, nextFunction);
      }

      // Then: 모든 요청이 통과 (총 10번)
      expect(nextFunction).toHaveBeenCalledTimes(10);
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('동일 IP에서 다른 IP로 변경해도 이전 IP의 제한은 유지되어야 한다', () => {
      // Given: Rate limiter 설정 (분당 5회)
      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      // When: IP1에서 5번 요청
      const mockRequest1: MockRequest = { ip: '192.168.1.1', path: '/payment/approve' };
      for (let i = 0; i < 5; i++) {
        rateLimiter(mockRequest1 as unknown as Request, mockResponse as Response, nextFunction);
      }

      // When: IP2에서 1번 요청
      const mockRequest2: MockRequest = { ip: '192.168.1.2', path: '/payment/approve' };
      rateLimiter(mockRequest2 as unknown as Request, mockResponse as Response, nextFunction);

      // When: IP1에서 다시 요청 (제한 초과)
      rateLimiter(mockRequest1 as unknown as Request, mockResponse as Response, nextFunction);

      // Then: IP1의 마지막 요청은 거부됨
      expect(nextFunction).toHaveBeenCalledTimes(6);
      expect(mockResponse.status).toHaveBeenCalledWith(429);
    });
  });

  describe('시간 기반 리셋', () => {
    it('윈도우 시간이 지나면 제한이 리셋되어야 한다', () => {
      // Given: Rate limiter 설정 (1분 윈도우)
      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      // When: 5번 요청 (제한에 도달)
      for (let i = 0; i < 5; i++) {
        rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      }

      // Then: 6번째 요청은 거부됨
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      expect(mockResponse.status).toHaveBeenCalledWith(429);

      // When: 1분 경과
      jest.advanceTimersByTime(60001);

      // Clear mocks for clean assertion
      jest.clearAllMocks();
      nextFunction = jest.fn();
      mockResponse.status = jest.fn().mockReturnThis();

      // Then: 새로운 요청은 통과
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalled();
    });
  });

  describe('응답 헤더', () => {
    it('남은 요청 횟수를 응답 헤더에 포함해야 한다', () => {
      // Given: Rate limiter 설정
      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
      };
      const rateLimiter = createRateLimiter(config);

      mockResponse.setHeader = jest.fn();

      // When: 첫 번째 요청
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);

      // Then: 헤더에 남은 횟수 포함
      expect(mockResponse.setHeader).toHaveBeenCalledWith('X-RateLimit-Limit', 5);
      expect(mockResponse.setHeader).toHaveBeenCalledWith('X-RateLimit-Remaining', 4);
    });
  });

  describe('커스텀 설정', () => {
    it('다른 윈도우 시간으로 설정할 수 있어야 한다', () => {
      // Given: Rate limiter 설정 (30초 윈도우)
      const config: RateLimiterConfig = {
        windowMs: 30000, // 30초
        maxRequests: 3,
      };
      const rateLimiter = createRateLimiter(config);

      // When: 3번 요청 후 30초 경과
      for (let i = 0; i < 3; i++) {
        rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      }

      // 4번째 요청 거부
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      expect(mockResponse.status).toHaveBeenCalledWith(429);

      // When: 30초 경과
      jest.advanceTimersByTime(30001);

      jest.clearAllMocks();
      nextFunction = jest.fn();
      mockResponse.status = jest.fn().mockReturnThis();

      // Then: 새로운 요청은 통과
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalled();
    });
  });

  describe('Store 인터페이스', () => {
    it('커스텀 Store를 사용할 수 있어야 한다', () => {
      // Given: 커스텀 메모리 Store
      const customStore: RateLimiterStore = {
        increment: jest.fn().mockReturnValue({ count: 1, resetTime: Date.now() + 60000 }),
        decrement: jest.fn(),
        resetKey: jest.fn(),
      };

      const config: RateLimiterConfig = {
        windowMs: 60000,
        maxRequests: 5,
        store: customStore,
      };
      const rateLimiter = createRateLimiter(config);

      // When: 요청 처리
      rateLimiter(mockRequest as unknown as Request, mockResponse as Response, nextFunction);

      // Then: 커스텀 Store가 사용됨
      expect(customStore.increment).toHaveBeenCalledWith('127.0.0.1');
      expect(nextFunction).toHaveBeenCalled();
    });
  });
});

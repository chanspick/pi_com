// functions/src/logging/error_logger.ts
// 에러 모니터링 시스템 - 에러 기록 및 심각도 분류

import * as admin from 'firebase-admin';

/**
 * 에러 심각도 분류
 * - critical: 서비스 중단 (예: 결제 API 장애)
 * - high: 핵심 기능 장애 (예: 트랜잭션 실패)
 * - medium: 부분 기능 장애 (예: 스케줄러 오류)
 * - low: 경미한 오류 (예: 로깅 실패)
 */
export type ErrorSeverity = 'critical' | 'high' | 'medium' | 'low';

/**
 * 에러 로그 엔트리 인터페이스
 */
export interface ErrorLogEntry {
  /** 에러 로그 ID (조회 시에만 포함) */
  id?: string;
  /** 에러 심각도 */
  severity: ErrorSeverity;
  /** 에러 발생 소스 (모듈/함수) */
  source: string;
  /** 에러 메시지 */
  message: string;
  /** 스택 트레이스 (선택적) */
  stack?: string;
  /** 추가 컨텍스트 정보 */
  context: Record<string, any>;
  /** 타임스탬프 */
  timestamp: FirebaseFirestore.Timestamp;
  /** 해결 여부 */
  resolved: boolean;
  /** 해결 시간 (선택적) */
  resolvedAt?: FirebaseFirestore.Timestamp;
  /** 해결자 ID (선택적) */
  resolvedBy?: string;
}

/**
 * 에러 조회 필터
 */
export interface ErrorQueryFilters {
  /** 심각도 필터 */
  severity?: ErrorSeverity;
  /** 소스 필터 */
  source?: string;
  /** 해결 상태 필터 */
  resolved?: boolean;
  /** 시작 날짜 필터 */
  startDate?: Date;
  /** 종료 날짜 필터 */
  endDate?: Date;
  /** 조회 제한 */
  limit?: number;
}

/**
 * 시간 범위
 */
export interface TimeRange {
  /** 시작 시간 */
  start: Date;
  /** 종료 시간 */
  end: Date;
}

/**
 * 에러 통계
 */
export interface ErrorStats {
  /** 총 에러 수 */
  total: number;
  /** 심각도별 에러 수 */
  bySeverity: {
    critical: number;
    high: number;
    medium: number;
    low: number;
  };
  /** 해결된 에러 수 */
  resolved: number;
  /** 미해결 에러 수 */
  unresolved: number;
}

/**
 * 에러를 errorLogs 컬렉션에 기록
 *
 * @param error - Error 객체 또는 에러 메시지 문자열
 * @param severity - 에러 심각도
 * @param source - 에러 발생 소스
 * @param context - 추가 컨텍스트 정보 (선택적)
 * @returns 생성된 로그 ID
 * @throws Error - Firestore 작업 실패 시
 *
 * @example
 * // Error 객체로 로깅
 * const logId = await logError(
 *   new Error('Payment API failed'),
 *   'critical',
 *   'payment/kakaopay',
 *   { orderId: 'order_123' }
 * );
 *
 * // 문자열로 로깅
 * const logId = await logError(
 *   'Connection timeout',
 *   'high',
 *   'api/handler'
 * );
 */
export async function logError(
  error: Error | string,
  severity: ErrorSeverity,
  source: string,
  context: Record<string, any> = {}
): Promise<string> {
  const db = admin.firestore();
  const errorLogsRef = db.collection('errorLogs');

  // Error 객체인지 문자열인지에 따라 처리
  const isErrorObject = error instanceof Error;
  const message = isErrorObject ? error.message : error;
  const stack = isErrorObject ? error.stack : undefined;

  const logEntry = {
    severity,
    source,
    message,
    stack,
    context,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    resolved: false,
  };

  const docRef = await errorLogsRef.add(logEntry);

  console.log(
    `[ErrorLogger] 에러 기록: severity=${severity}, source=${source}, ` +
    `message=${message.substring(0, 100)}`
  );

  return docRef.id;
}

/**
 * 에러를 해결됨으로 표시
 *
 * @param errorId - 에러 로그 ID
 * @param resolvedBy - 해결자 ID
 * @throws Error - Firestore 작업 실패 시
 *
 * @example
 * await markErrorResolved('error_log_001', 'admin_001');
 */
export async function markErrorResolved(
  errorId: string,
  resolvedBy: string
): Promise<void> {
  const db = admin.firestore();
  const docRef = db.collection('errorLogs').doc(errorId);

  await docRef.update({
    resolved: true,
    resolvedBy,
    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`[ErrorLogger] 에러 해결됨: errorId=${errorId}, resolvedBy=${resolvedBy}`);
}

/**
 * 에러 로그 조회
 *
 * @param filters - 조회 필터
 * @returns 에러 로그 목록
 *
 * @example
 * // 미해결 critical 에러 조회
 * const errors = await queryErrors({
 *   severity: 'critical',
 *   resolved: false,
 *   limit: 50
 * });
 */
export async function queryErrors(
  filters: ErrorQueryFilters
): Promise<ErrorLogEntry[]> {
  const db = admin.firestore();
  let query: FirebaseFirestore.Query = db.collection('errorLogs');

  // 필터 적용
  if (filters.severity) {
    query = query.where('severity', '==', filters.severity);
  }

  if (filters.source) {
    query = query.where('source', '==', filters.source);
  }

  if (filters.resolved !== undefined) {
    query = query.where('resolved', '==', filters.resolved);
  }

  if (filters.startDate) {
    const startTimestamp = admin.firestore.Timestamp.fromDate(filters.startDate);
    query = query.where('timestamp', '>=', startTimestamp);
  }

  if (filters.endDate) {
    const endTimestamp = admin.firestore.Timestamp.fromDate(filters.endDate);
    query = query.where('timestamp', '<=', endTimestamp);
  }

  // 정렬 및 제한
  query = query.orderBy('timestamp', 'desc');

  if (filters.limit) {
    query = query.limit(filters.limit);
  }

  const snapshot = await query.get();

  if (snapshot.empty) {
    return [];
  }

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      severity: data.severity as ErrorSeverity,
      source: data.source,
      message: data.message,
      stack: data.stack,
      context: data.context,
      timestamp: data.timestamp,
      resolved: data.resolved,
      resolvedAt: data.resolvedAt,
      resolvedBy: data.resolvedBy,
    };
  });
}

/**
 * 시간 범위 내 에러 통계 조회
 *
 * @param timeRange - 시간 범위
 * @returns 에러 통계
 *
 * @example
 * const stats = await getErrorStats({
 *   start: new Date('2024-01-01'),
 *   end: new Date('2024-01-31')
 * });
 * console.log(`Critical: ${stats.bySeverity.critical}`);
 */
export async function getErrorStats(timeRange: TimeRange): Promise<ErrorStats> {
  const db = admin.firestore();
  const startTimestamp = admin.firestore.Timestamp.fromDate(timeRange.start);
  const endTimestamp = admin.firestore.Timestamp.fromDate(timeRange.end);

  const query = db
    .collection('errorLogs')
    .where('timestamp', '>=', startTimestamp)
    .where('timestamp', '<=', endTimestamp);

  const snapshot = await query.get();

  // 초기 통계 객체
  const stats: ErrorStats = {
    total: 0,
    bySeverity: {
      critical: 0,
      high: 0,
      medium: 0,
      low: 0,
    },
    resolved: 0,
    unresolved: 0,
  };

  if (snapshot.empty) {
    return stats;
  }

  // 통계 계산
  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    stats.total++;

    // 심각도별 카운트
    const severity = data.severity as ErrorSeverity;
    if (severity in stats.bySeverity) {
      stats.bySeverity[severity]++;
    }

    // 해결 상태 카운트
    if (data.resolved) {
      stats.resolved++;
    } else {
      stats.unresolved++;
    }
  });

  return stats;
}

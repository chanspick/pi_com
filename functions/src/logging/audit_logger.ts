// functions/src/logging/audit_logger.ts
// 감사 로그 시스템 - 중요한 비즈니스 이벤트 기록

import * as admin from 'firebase-admin';

/**
 * 감사 로그 액션 유형
 * 결제, 환불, 관리자 승인, 매물/주문 관련 이벤트
 */
export type AuditAction =
  | 'PAYMENT_APPROVED'
  | 'PAYMENT_CANCELLED'
  | 'REFUND_REQUESTED'
  | 'REFUND_APPROVED'
  | 'ADMIN_APPROVED'
  | 'LISTING_CREATED'
  | 'LISTING_UPDATED'
  | 'ORDER_CREATED'
  | 'ORDER_CANCELLED';

/**
 * 감사 로그 엔트리 인터페이스
 */
export interface AuditLogEntry {
  /** 감사 로그 ID (조회 시에만 포함) */
  id?: string;
  /** 액션 유형 */
  action: AuditAction;
  /** 액션을 수행한 사용자 ID */
  userId: string;
  /** 대상 리소스 ID */
  targetId: string;
  /** 대상 리소스 유형 (order, listing, refund 등) */
  targetType: string;
  /** 액션 세부 정보 */
  details: Record<string, any>;
  /** 타임스탬프 */
  timestamp: FirebaseFirestore.Timestamp;
  /** 요청 IP 주소 (선택적) */
  ip?: string;
  /** 사용자 에이전트 (선택적) */
  userAgent?: string;
}

/**
 * 감사 로그 조회 필터
 */
export interface AuditQueryFilters {
  /** 액션 유형 필터 */
  action?: AuditAction;
  /** 사용자 ID 필터 */
  userId?: string;
  /** 대상 리소스 ID 필터 */
  targetId?: string;
  /** 시작 날짜 필터 */
  startDate?: Date;
  /** 종료 날짜 필터 */
  endDate?: Date;
  /** 조회 제한 */
  limit?: number;
}

/**
 * 감사 이벤트를 auditLogs 컬렉션에 기록
 *
 * @param entry - 감사 로그 엔트리 (timestamp 제외)
 * @returns 생성된 로그 ID
 * @throws Error - Firestore 작업 실패 시
 *
 * @example
 * // 결제 승인 이벤트 기록
 * const logId = await logAuditEvent({
 *   action: 'PAYMENT_APPROVED',
 *   userId: 'user_123',
 *   targetId: 'order_456',
 *   targetType: 'order',
 *   details: { amount: 150000, paymentMethod: 'kakaopay' }
 * });
 */
export async function logAuditEvent(
  entry: Omit<AuditLogEntry, 'timestamp'>
): Promise<string> {
  const db = admin.firestore();
  const auditLogsRef = db.collection('auditLogs');

  const logEntry = {
    action: entry.action,
    userId: entry.userId,
    targetId: entry.targetId,
    targetType: entry.targetType,
    details: entry.details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    ...(entry.ip && { ip: entry.ip }),
    ...(entry.userAgent && { userAgent: entry.userAgent }),
  };

  const docRef = await auditLogsRef.add(logEntry);

  console.log(
    `[AuditLogger] 감사 로그 기록: action=${entry.action}, ` +
    `userId=${entry.userId}, targetId=${entry.targetId}`
  );

  return docRef.id;
}

/**
 * 감사 로그 조회
 *
 * @param filters - 조회 필터
 * @returns 감사 로그 목록
 *
 * @example
 * // 결제 승인 이벤트 조회
 * const logs = await queryAuditLogs({
 *   action: 'PAYMENT_APPROVED',
 *   limit: 50
 * });
 */
export async function queryAuditLogs(
  filters: AuditQueryFilters
): Promise<AuditLogEntry[]> {
  const db = admin.firestore();
  let query: FirebaseFirestore.Query = db.collection('auditLogs');

  // 필터 적용
  if (filters.action) {
    query = query.where('action', '==', filters.action);
  }

  if (filters.userId) {
    query = query.where('userId', '==', filters.userId);
  }

  if (filters.targetId) {
    query = query.where('targetId', '==', filters.targetId);
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
      action: data.action as AuditAction,
      userId: data.userId,
      targetId: data.targetId,
      targetType: data.targetType,
      details: data.details,
      timestamp: data.timestamp,
      ip: data.ip,
      userAgent: data.userAgent,
    };
  });
}

/**
 * ID로 감사 로그 조회
 *
 * @param logId - 감사 로그 ID
 * @returns 감사 로그 또는 null
 *
 * @example
 * const log = await getAuditLogById('audit_log_001');
 */
export async function getAuditLogById(
  logId: string
): Promise<AuditLogEntry | null> {
  const db = admin.firestore();
  const docRef = db.collection('auditLogs').doc(logId);

  const doc = await docRef.get();

  if (!doc.exists) {
    return null;
  }

  const data = doc.data()!;
  return {
    id: doc.id,
    action: data.action as AuditAction,
    userId: data.userId,
    targetId: data.targetId,
    targetType: data.targetType,
    details: data.details,
    timestamp: data.timestamp,
    ip: data.ip,
    userAgent: data.userAgent,
  };
}

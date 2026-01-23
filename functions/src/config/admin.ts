// functions/src/config/admin.ts

import * as functions from "firebase-functions/v1";

/**
 * 환경 변수에서 관리자 UID 목록을 가져옵니다.
 * Firebase config에 admin.user_ids가 "uid1,uid2,uid3" 형식으로 설정되어 있어야 합니다.
 *
 * 설정 방법:
 * firebase functions:config:set admin.user_ids="UID1,UID2,UID3"
 */
export function getAdminUserIds(): string[] {
  const config = functions.config();
  const adminIds = config.admin?.user_ids;

  if (!adminIds) {
    console.warn("[Admin Config] admin.user_ids가 설정되지 않았습니다. 빈 배열을 반환합니다.");
    console.warn("[Admin Config] 설정 방법: firebase functions:config:set admin.user_ids=\"UID1,UID2\"");
    return [];
  }

  const userIds = adminIds
    .split(",")
    .map((id: string) => id.trim())
    .filter((id: string) => id.length > 0);

  console.log(`[Admin Config] ${userIds.length}명의 관리자 UID 로드됨`);
  return userIds;
}

/**
 * 주어진 userId가 관리자인지 확인합니다.
 * @param userId 확인할 사용자 UID
 * @returns 관리자 여부
 */
export function isAdmin(userId: string): boolean {
  const adminIds = getAdminUserIds();
  return adminIds.includes(userId);
}

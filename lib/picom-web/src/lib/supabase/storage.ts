import { createClient } from "./client";

// 버킷 이름 상수
const BUCKETS = {
  SELL_IMAGES: "sell-images",
  PROFILE_AVATARS: "profile-avatars",
} as const;

type BucketName = (typeof BUCKETS)[keyof typeof BUCKETS];

/**
 * 고유 파일명 생성 (타임스탬프 + 랜덤 문자열)
 * 충돌 방지를 위해 사용
 */
function generateUniqueFileName(originalName: string): string {
  const timestamp = Date.now();
  const randomStr = Math.random().toString(36).substring(2, 10);
  const extension = originalName.split(".").pop()?.toLowerCase() || "jpg";
  return `${timestamp}-${randomStr}.${extension}`;
}

/**
 * 이미지를 업로드 전에 Canvas API로 압축
 * @param file - 원본 이미지 파일
 * @param maxWidth - 최대 너비 (기본값: 1200px)
 * @param quality - JPEG 압축 품질 0~1 (기본값: 0.8)
 * @returns 압축된 Blob
 */
async function compressImage(
  file: File,
  maxWidth = 1200,
  quality = 0.8
): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(url);

      // 원본 크기가 maxWidth 이하이면 리사이즈 불필요
      let { width, height } = img;
      if (width > maxWidth) {
        height = Math.round((height * maxWidth) / width);
        width = maxWidth;
      }

      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;

      const ctx = canvas.getContext("2d");
      if (!ctx) {
        reject(new Error("Canvas 2D context를 가져올 수 없습니다."));
        return;
      }

      ctx.drawImage(img, 0, 0, width, height);

      // MIME 타입 결정: PNG는 무손실 유지, 그 외 JPEG로 변환
      const mimeType = file.type === "image/png" ? "image/png" : "image/jpeg";
      const outputQuality = file.type === "image/png" ? undefined : quality;

      canvas.toBlob(
        (blob) => {
          if (!blob) {
            reject(new Error("이미지 압축에 실패했습니다."));
            return;
          }
          resolve(blob);
        },
        mimeType,
        outputQuality
      );
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("이미지를 로드할 수 없습니다."));
    };

    img.src = url;
  });
}

/**
 * 단일 이미지 업로드
 * @param bucket - 스토리지 버킷 이름
 * @param file - 업로드할 파일
 * @param path - 저장 경로 (예: "user-id/filename.jpg")
 * @param options - 압축 옵션
 * @returns 공개 URL과 저장 경로
 */
async function uploadImage(
  bucket: BucketName,
  file: File,
  path: string,
  options?: { compress?: boolean; maxWidth?: number; quality?: number }
): Promise<{ url: string; path: string }> {
  const supabase = createClient();

  // 고유 파일명 생성
  const uniqueFileName = generateUniqueFileName(file.name);
  const fullPath = `${path}/${uniqueFileName}`;

  // 압축 처리
  let uploadData: Blob | File = file;
  if (options?.compress !== false) {
    try {
      uploadData = await compressImage(
        file,
        options?.maxWidth ?? 1200,
        options?.quality ?? 0.8
      );
    } catch {
      // 압축 실패 시 원본 파일 사용
      uploadData = file;
    }
  }

  // Supabase Storage에 업로드
  const { error } = await supabase.storage.from(bucket).upload(fullPath, uploadData, {
    contentType: file.type || "image/jpeg",
    upsert: false,
  });

  if (error) {
    throw new Error(`이미지 업로드 실패: ${error.message}`);
  }

  // 공개 URL 가져오기
  const url = getPublicUrl(bucket, fullPath);

  return { url, path: fullPath };
}

/**
 * 다수 이미지 순차 업로드 (진행 상황 콜백 포함)
 * @param bucket - 스토리지 버킷 이름
 * @param files - 업로드할 파일 배열
 * @param basePath - 기본 저장 경로 (예: "user-id/sell-request-id")
 * @param onProgress - 진행 상황 콜백 (완료 수, 전체 수)
 * @param options - 압축 옵션
 * @returns URL과 경로 배열
 */
async function uploadImages(
  bucket: BucketName,
  files: File[],
  basePath: string,
  onProgress?: (completed: number, total: number) => void,
  options?: { compress?: boolean; maxWidth?: number; quality?: number }
): Promise<{ url: string; path: string }[]> {
  const results: { url: string; path: string }[] = [];
  const total = files.length;

  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    const result = await uploadImage(bucket, file, basePath, options);
    results.push(result);
    onProgress?.(i + 1, total);
  }

  return results;
}

/**
 * 단일 이미지 삭제
 * @param bucket - 스토리지 버킷 이름
 * @param path - 삭제할 파일 경로
 */
async function deleteImage(bucket: BucketName, path: string): Promise<void> {
  const supabase = createClient();

  const { error } = await supabase.storage.from(bucket).remove([path]);

  if (error) {
    throw new Error(`이미지 삭제 실패: ${error.message}`);
  }
}

/**
 * 다수 이미지 삭제
 * @param bucket - 스토리지 버킷 이름
 * @param paths - 삭제할 파일 경로 배열
 */
async function deleteImages(
  bucket: BucketName,
  paths: string[]
): Promise<void> {
  if (paths.length === 0) return;

  const supabase = createClient();

  const { error } = await supabase.storage.from(bucket).remove(paths);

  if (error) {
    throw new Error(`이미지 일괄 삭제 실패: ${error.message}`);
  }
}

/**
 * 이미지의 공개 URL 반환
 * @param bucket - 스토리지 버킷 이름
 * @param path - 파일 경로
 * @returns 공개 접근 가능한 URL
 */
function getPublicUrl(bucket: BucketName, path: string): string {
  const supabase = createClient();

  const {
    data: { publicUrl },
  } = supabase.storage.from(bucket).getPublicUrl(path);

  return publicUrl;
}

export {
  BUCKETS,
  uploadImage,
  uploadImages,
  deleteImage,
  deleteImages,
  getPublicUrl,
  compressImage,
};
export type { BucketName };

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

function generateCpuKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.generation) keywords.add(part.generation.toLowerCase());
  if (part.codename) keywords.add(part.codename.toLowerCase());
  if (part.cores) keywords.add(`${part.cores}코어`);
  if (part.socket) keywords.add(part.socket.toLowerCase());
  return Array.from(keywords);
}

function generateGpuKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.chipset?.model) keywords.add(part.chipset.model.toLowerCase());
  if (part.chipset?.series) keywords.add(part.chipset.series.toLowerCase());
  if (part.chipset?.vendor) keywords.add(part.chipset.vendor.toLowerCase());
  if (part.memory?.sizeGb) keywords.add(`${part.memory.sizeGb}gb`);
  return Array.from(keywords);
}

function generateMainboardKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.chipset) keywords.add(part.chipset.toLowerCase());
  if (part.socket) keywords.add(part.socket.toLowerCase());
  if (part.formFactor) keywords.add(part.formFactor.toLowerCase());
  if (part.platform) keywords.add(part.platform.toLowerCase());
  return Array.from(keywords);
}

function generateSimpleKeywords(part: Record<string, any>): string[] {
  const keywords = new Set<string>();
  if (part.basePartId) {
    part.basePartId.split("-").forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  if (part.brand) keywords.add(part.brand.toLowerCase());
  if (part.modelName) {
    part.modelName.split(/\s+/).forEach((k: string) => keywords.add(k.toLowerCase()));
  }
  const category = part.category?.toLowerCase();
  if (category === "ram") {
    if (part.capacity) keywords.add(`${part.capacity}gb`);
    if (part.memoryType) keywords.add(part.memoryType.toLowerCase());
  } else if (category === "ssd") {
    if (part.capacity) {
      keywords.add(`${part.capacity}gb`);
      if (part.capacity >= 1000) {
        keywords.add(`${Math.floor(part.capacity / 1000)}tb`);
      }
    }
  } else if (category === "psu") {
    if (part.wattage) keywords.add(`${part.wattage}w`);
  }
  return Array.from(keywords);
}

function generateSearchKeywords(part: Record<string, any>): string[] {
  const category = part.category?.toLowerCase();
  switch (category) {
    case "cpu": return generateCpuKeywords(part);
    case "gpu": return generateGpuKeywords(part);
    case "mainboard": return generateMainboardKeywords(part);
    case "ram":
    case "ssd":
    case "psu": return generateSimpleKeywords(part);
    default: return generateSimpleKeywords(part);
  }
}

export const addSearchKeywordsToParts = functions.region("asia-northeast3").https.onCall(async (data: any) => {
  const {startAfter, batchSize = 500} = data;
  try {
    let query = admin.firestore().collection("parts").orderBy("partId").limit(batchSize);
    if (startAfter) query = query.startAfter(startAfter);
    const snapshot = await query.get();
    if (snapshot.empty) {
      return {success: true, updatedCount: 0, hasMore: false, message: "더 이상 업데이트할 Part가 없습니다."};
    }
    const batch = admin.firestore().batch();
    let updatedCount = 0;
    snapshot.docs.forEach((doc) => {
      const partData = doc.data();
      const searchKeywords = generateSearchKeywords(partData);
      batch.update(doc.ref, {searchKeywords});
      updatedCount++;
    });
    await batch.commit();
    const lastDoc = snapshot.docs[snapshot.docs.length - 1];
    const lastPartId = lastDoc.data().partId;
    return {success: true, updatedCount, hasMore: snapshot.docs.length === batchSize, lastPartId, message: `${updatedCount}개 Part에 searchKeywords 추가 완료`};
  } catch (error: any) {
    console.error("Error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

export const searchParts = functions.region("asia-northeast3").https.onCall(async (data: any) => {
  const {category, query} = data;
  if (!category || !query) {
    throw new functions.https.HttpsError("invalid-argument", "category and query required");
  }
  const lowerQuery = query.toLowerCase().trim();
  const snapshot = await admin.firestore().collection("parts").where("category", "==", category).where("searchKeywords", "array-contains", lowerQuery).limit(50).get();
  return snapshot.docs.map((doc) => ({partId: doc.id, ...doc.data()}));
});

export const onPartCreated = functions.region("asia-northeast3").firestore.document("parts/{partId}").onCreate(async (snap: admin.firestore.QueryDocumentSnapshot) => {
  const partData = snap.data();
  const searchKeywords = generateSearchKeywords(partData);
  return snap.ref.update({searchKeywords});
});

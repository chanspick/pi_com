"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { GRADE_THRESHOLDS, ConditionGrade } from "@/types/warranty";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://asia-northeast3-picom-team.cloudfunctions.net/api";

type TransactionType = "single" | "bundle";

interface BundleItem {
  partCategory: string;
  brand: string;
  modelName: string;
  benchmarkScore?: number;
  purchaseCost: number;
}

const PART_CATEGORIES = [
  "CPU", "GPU", "Mainboard", "RAM", "SSD", "HDD", "PSU", "Case", "Cooler", "Other"
];

const BENCHMARK_CONFIG: Record<string, { max: number; min: number; unit: string; label: string }> = {
  cpu: { max: 40000, min: 10000, unit: "PassMark", label: "CPU PassMark" },
  gpu: { max: 20000, min: 5000, unit: "3DMark", label: "GPU 3DMark" },
  storage: { max: 7000, min: 500, unit: "MB/s", label: "Storage Speed" },
  memory: { max: 50000, min: 20000, unit: "MB/s", label: "Memory Bandwidth" },
};

function benchmarkToScore(category: string, value: number): number {
  const config = BENCHMARK_CONFIG[category.toLowerCase()];
  if (!config) return 50;
  if (value >= config.max) return 100;
  if (value <= config.min) return Math.round((value / config.min) * 50);
  return Math.round(50 + ((value - config.min) / (config.max - config.min)) * 50);
}

function calculateOverallScore(benchmarks: { cpu?: number; gpu?: number; storage?: number; memory?: number }): number {
  const weights = { cpu: 0.35, gpu: 0.35, storage: 0.15, memory: 0.15 };
  let totalWeight = 0;
  let weightedSum = 0;

  if (benchmarks.cpu) {
    const score = benchmarkToScore("cpu", benchmarks.cpu);
    weightedSum += score * weights.cpu;
    totalWeight += weights.cpu;
  }
  if (benchmarks.gpu) {
    const score = benchmarkToScore("gpu", benchmarks.gpu);
    weightedSum += score * weights.gpu;
    totalWeight += weights.gpu;
  }
  if (benchmarks.storage) {
    const score = benchmarkToScore("storage", benchmarks.storage);
    weightedSum += score * weights.storage;
    totalWeight += weights.storage;
  }
  if (benchmarks.memory) {
    const score = benchmarkToScore("memory", benchmarks.memory);
    weightedSum += score * weights.memory;
    totalWeight += weights.memory;
  }

  return totalWeight > 0 ? Math.round(weightedSum / totalWeight) : 50;
}

function determineGrade(score: number): ConditionGrade {
  if (score >= 90) return "S";
  if (score >= 80) return "A";
  if (score >= 70) return "B";
  if (score >= 60) return "C";
  return "D";
}

export default function RegisterPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [transactionType, setTransactionType] = useState<TransactionType>("single");

  // Single part
  const [partCategory, setPartCategory] = useState("CPU");
  const [brand, setBrand] = useState("");
  const [modelName, setModelName] = useState("");
  const [serialNumber, setSerialNumber] = useState("");

  // Bundle
  const [bundleName, setBundleName] = useState("");
  const [bundleItems, setBundleItems] = useState<BundleItem[]>([]);

  // Benchmarks
  const [cpuBenchmark, setCpuBenchmark] = useState<string>("");
  const [gpuBenchmark, setGpuBenchmark] = useState<string>("");
  const [storageBenchmark, setStorageBenchmark] = useState<string>("");
  const [memoryBenchmark, setMemoryBenchmark] = useState<string>("");

  // Price
  const [purchaseCost, setPurchaseCost] = useState<string>("");
  const [salePrice, setSalePrice] = useState<string>("");

  // Inspector
  const [inspectorName, setInspectorName] = useState("");
  const [inspectionNote, setInspectionNote] = useState("");

  // Buyer (optional)
  const [buyerCompanyName, setBuyerCompanyName] = useState("");
  const [buyerContactName, setBuyerContactName] = useState("");
  const [buyerContactPhone, setBuyerContactPhone] = useState("");

  // Calculated
  const [scoreResult, setScoreResult] = useState<{
    score: number;
    grade: ConditionGrade;
    warrantyMonths: number;
  } | null>(null);

  // Calculate score on benchmark change
  useEffect(() => {
    const benchmarks = {
      cpu: cpuBenchmark ? parseInt(cpuBenchmark) : undefined,
      gpu: gpuBenchmark ? parseInt(gpuBenchmark) : undefined,
      storage: storageBenchmark ? parseInt(storageBenchmark) : undefined,
      memory: memoryBenchmark ? parseInt(memoryBenchmark) : undefined,
    };

    if (benchmarks.cpu || benchmarks.gpu) {
      const score = calculateOverallScore(benchmarks);
      const grade = determineGrade(score);
      const warrantyMonths = GRADE_THRESHOLDS[grade].baseWarrantyMonths;
      setScoreResult({ score, grade, warrantyMonths });
    } else {
      setScoreResult(null);
    }
  }, [cpuBenchmark, gpuBenchmark, storageBenchmark, memoryBenchmark]);

  // Calculate profit margin
  const purchaseCostNum = parseInt(purchaseCost.replace(/,/g, "")) || 0;
  const salePriceNum = parseInt(salePrice.replace(/,/g, "")) || 0;
  const profitMargin = salePriceNum > 0 ? ((salePriceNum - purchaseCostNum) / salePriceNum * 100).toFixed(1) : "0";

  // Bundle total cost
  const bundleTotalCost = bundleItems.reduce((sum, item) => sum + item.purchaseCost, 0);

  function addBundleItem() {
    setBundleItems([...bundleItems, {
      partCategory: "CPU",
      brand: "",
      modelName: "",
      purchaseCost: 0,
    }]);
  }

  function updateBundleItem(index: number, updates: Partial<BundleItem>) {
    const newItems = [...bundleItems];
    newItems[index] = { ...newItems[index], ...updates };
    setBundleItems(newItems);

    // Update total purchase cost
    const total = newItems.reduce((sum, item) => sum + item.purchaseCost, 0);
    setPurchaseCost(total.toLocaleString());
  }

  function removeBundleItem(index: number) {
    setBundleItems(bundleItems.filter((_, i) => i !== index));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    try {
      const body: any = {
        transactionType,
        inspectorId: "admin",
        inspectorName: inspectorName || "관리자",
        inspectionNote,
        purchaseCost: purchaseCostNum,
        salePrice: salePriceNum,
        buyerCompanyName: buyerCompanyName || undefined,
        buyerContactName: buyerContactName || undefined,
        buyerContactPhone: buyerContactPhone || undefined,
      };

      if (transactionType === "single") {
        body.partCategory = partCategory;
        body.brand = brand;
        body.modelName = modelName;
        body.serialNumber = serialNumber || undefined;
      } else {
        body.bundleName = bundleName;
        body.items = bundleItems;
      }

      // Benchmarks
      const benchmarks: any = {};
      if (cpuBenchmark) benchmarks.cpu = parseInt(cpuBenchmark);
      if (gpuBenchmark) benchmarks.gpu = parseInt(gpuBenchmark);
      if (storageBenchmark) benchmarks.storage = parseInt(storageBenchmark);
      if (memoryBenchmark) benchmarks.memory = parseInt(memoryBenchmark);
      if (Object.keys(benchmarks).length > 0) {
        body.benchmarkScores = benchmarks;
      }

      const res = await fetch(`${API_URL}/warranty/transaction`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "등록 실패");
      }

      const result = await res.json();
      alert(`거래가 등록되었습니다!\n등급: ${result.conditionGrade}\n기본 AS: ${result.baseWarrantyMonths}개월`);
      router.push("/admin/transactions");
    } catch (err: any) {
      alert(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-3xl mx-auto">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">거래 등록</h1>
        <p className="text-gray-500 mt-1">새로운 B2B 거래를 등록합니다.</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Transaction Type */}
        <div className="bg-white rounded-xl border p-4">
          <h2 className="font-semibold text-gray-900 mb-4">거래 유형</h2>
          <div className="flex gap-4">
            <label className="flex-1">
              <input
                type="radio"
                name="type"
                checked={transactionType === "single"}
                onChange={() => setTransactionType("single")}
                className="sr-only"
              />
              <div className={`p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                transactionType === "single" ? "border-blue-600 bg-blue-50" : "border-gray-200"
              }`}>
                <div className="text-center">
                  <span className="text-2xl">🔧</span>
                  <p className="font-medium mt-2">단일 부품</p>
                </div>
              </div>
            </label>
            <label className="flex-1">
              <input
                type="radio"
                name="type"
                checked={transactionType === "bundle"}
                onChange={() => setTransactionType("bundle")}
                className="sr-only"
              />
              <div className={`p-4 rounded-lg border-2 cursor-pointer transition-colors ${
                transactionType === "bundle" ? "border-blue-600 bg-blue-50" : "border-gray-200"
              }`}>
                <div className="text-center">
                  <span className="text-2xl">🖥️</span>
                  <p className="font-medium mt-2">풀세트 (조립PC)</p>
                </div>
              </div>
            </label>
          </div>
        </div>

        {/* Product Info */}
        <div className="bg-white rounded-xl border p-4">
          <h2 className="font-semibold text-gray-900 mb-4">제품 정보</h2>

          {transactionType === "single" ? (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">카테고리</label>
                <select
                  value={partCategory}
                  onChange={(e) => setPartCategory(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2"
                >
                  {PART_CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">브랜드 *</label>
                  <input
                    type="text"
                    value={brand}
                    onChange={(e) => setBrand(e.target.value)}
                    placeholder="Intel, AMD, NVIDIA..."
                    className="w-full border rounded-lg px-3 py-2"
                    required
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">모델명 *</label>
                  <input
                    type="text"
                    value={modelName}
                    onChange={(e) => setModelName(e.target.value)}
                    placeholder="i7-13700K, RTX 4070..."
                    className="w-full border rounded-lg px-3 py-2"
                    required
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">시리얼 번호</label>
                <input
                  type="text"
                  value={serialNumber}
                  onChange={(e) => setSerialNumber(e.target.value)}
                  placeholder="선택 사항"
                  className="w-full border rounded-lg px-3 py-2"
                />
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">세트명 *</label>
                <input
                  type="text"
                  value={bundleName}
                  onChange={(e) => setBundleName(e.target.value)}
                  placeholder="게이밍 PC 세트, 사무용 PC..."
                  className="w-full border rounded-lg px-3 py-2"
                  required
                />
              </div>

              {/* Bundle Items */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="text-sm font-medium text-gray-700">
                    부품 목록 ({bundleItems.length}개)
                  </label>
                  <button
                    type="button"
                    onClick={addBundleItem}
                    className="text-blue-600 text-sm hover:underline"
                  >
                    + 부품 추가
                  </button>
                </div>

                {bundleItems.length === 0 ? (
                  <div className="text-center py-8 bg-gray-50 rounded-lg text-gray-500">
                    부품을 추가해주세요
                  </div>
                ) : (
                  <div className="space-y-3">
                    {bundleItems.map((item, index) => (
                      <div key={index} className="p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-sm font-medium">#{index + 1}</span>
                          <button
                            type="button"
                            onClick={() => removeBundleItem(index)}
                            className="text-red-500 text-sm"
                          >
                            삭제
                          </button>
                        </div>
                        <div className="grid grid-cols-4 gap-2">
                          <select
                            value={item.partCategory}
                            onChange={(e) => updateBundleItem(index, { partCategory: e.target.value })}
                            className="border rounded px-2 py-1 text-sm"
                          >
                            {PART_CATEGORIES.map((cat) => (
                              <option key={cat} value={cat}>{cat}</option>
                            ))}
                          </select>
                          <input
                            type="text"
                            value={item.brand}
                            onChange={(e) => updateBundleItem(index, { brand: e.target.value })}
                            placeholder="브랜드"
                            className="border rounded px-2 py-1 text-sm"
                          />
                          <input
                            type="text"
                            value={item.modelName}
                            onChange={(e) => updateBundleItem(index, { modelName: e.target.value })}
                            placeholder="모델명"
                            className="border rounded px-2 py-1 text-sm"
                          />
                          <input
                            type="number"
                            value={item.purchaseCost || ""}
                            onChange={(e) => updateBundleItem(index, { purchaseCost: parseInt(e.target.value) || 0 })}
                            placeholder="원가"
                            className="border rounded px-2 py-1 text-sm"
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                )}

                {bundleItems.length > 0 && (
                  <div className="mt-2 text-right text-sm text-gray-600">
                    총 매입원가: <strong>₩{bundleTotalCost.toLocaleString()}</strong>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Benchmark */}
        <div className="bg-white rounded-xl border p-4">
          <h2 className="font-semibold text-gray-900 mb-4">벤치마크 점수</h2>
          <p className="text-sm text-gray-500 mb-4">벤치마크 점수를 입력하면 자동으로 등급이 계산됩니다.</p>

          <div className="grid grid-cols-2 gap-4">
            {(transactionType === "bundle" || partCategory === "CPU") && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">CPU PassMark</label>
                <input
                  type="number"
                  value={cpuBenchmark}
                  onChange={(e) => setCpuBenchmark(e.target.value)}
                  placeholder="예: 38000"
                  className="w-full border rounded-lg px-3 py-2"
                />
                <p className="text-xs text-gray-400 mt-1">100점 기준: 40,000점</p>
              </div>
            )}
            {(transactionType === "bundle" || partCategory === "GPU") && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">GPU 3DMark</label>
                <input
                  type="number"
                  value={gpuBenchmark}
                  onChange={(e) => setGpuBenchmark(e.target.value)}
                  placeholder="예: 21000"
                  className="w-full border rounded-lg px-3 py-2"
                />
                <p className="text-xs text-gray-400 mt-1">100점 기준: 20,000점</p>
              </div>
            )}
            {transactionType === "bundle" && (
              <>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Storage Speed (MB/s)</label>
                  <input
                    type="number"
                    value={storageBenchmark}
                    onChange={(e) => setStorageBenchmark(e.target.value)}
                    placeholder="예: 5000"
                    className="w-full border rounded-lg px-3 py-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Memory Bandwidth (MB/s)</label>
                  <input
                    type="number"
                    value={memoryBenchmark}
                    onChange={(e) => setMemoryBenchmark(e.target.value)}
                    placeholder="예: 45000"
                    className="w-full border rounded-lg px-3 py-2"
                  />
                </div>
              </>
            )}
          </div>
        </div>

        {/* Score Preview */}
        {scoreResult && (
          <div className="bg-gradient-to-r from-blue-50 to-white rounded-xl border p-4">
            <h2 className="font-semibold text-gray-900 mb-4">자동 산정 결과</h2>
            <div className="flex items-center gap-6">
              <div className={`w-20 h-20 rounded-xl flex flex-col items-center justify-center text-white ${
                scoreResult.grade === "S" ? "bg-indigo-500" :
                scoreResult.grade === "A" ? "bg-green-500" :
                scoreResult.grade === "B" ? "bg-yellow-500" :
                scoreResult.grade === "C" ? "bg-orange-500" : "bg-gray-500"
              }`}>
                <span className="text-3xl font-bold">{scoreResult.grade}</span>
                <span className="text-xs opacity-80">{GRADE_THRESHOLDS[scoreResult.grade].label}</span>
              </div>
              <div>
                <p className="text-gray-600">종합 스코어: <strong>{scoreResult.score}점</strong></p>
                <p className="text-gray-600">기본 AS: <strong className="text-green-600">{scoreResult.warrantyMonths}개월</strong></p>
              </div>
            </div>
          </div>
        )}

        {/* Price */}
        <div className="bg-white rounded-xl border p-4">
          <h2 className="font-semibold text-gray-900 mb-4">가격 정보</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">매입원가 *</label>
              <input
                type="text"
                value={purchaseCost}
                onChange={(e) => setPurchaseCost(e.target.value.replace(/[^0-9,]/g, ""))}
                placeholder="₩ 0"
                className="w-full border rounded-lg px-3 py-2"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">판매가 *</label>
              <input
                type="text"
                value={salePrice}
                onChange={(e) => setSalePrice(e.target.value.replace(/[^0-9,]/g, ""))}
                placeholder="₩ 0"
                className="w-full border rounded-lg px-3 py-2"
                required
              />
            </div>
          </div>
          <div className={`mt-3 p-3 rounded-lg ${parseFloat(profitMargin) > 0 ? "bg-green-50" : "bg-red-50"}`}>
            <span className="text-sm">마진율: </span>
            <strong className={parseFloat(profitMargin) > 0 ? "text-green-600" : "text-red-600"}>
              {profitMargin}%
            </strong>
          </div>
        </div>

        {/* Inspector */}
        <div className="bg-white rounded-xl border p-4">
          <h2 className="font-semibold text-gray-900 mb-4">검수 정보</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">검수자명</label>
              <input
                type="text"
                value={inspectorName}
                onChange={(e) => setInspectorName(e.target.value)}
                placeholder="관리자"
                className="w-full border rounded-lg px-3 py-2"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">검수 소견</label>
              <textarea
                value={inspectionNote}
                onChange={(e) => setInspectionNote(e.target.value)}
                placeholder="외관 상태, 테스트 결과 등"
                rows={3}
                className="w-full border rounded-lg px-3 py-2"
              />
            </div>
          </div>
        </div>

        {/* Buyer (Optional) */}
        <div className="bg-white rounded-xl border p-4">
          <h2 className="font-semibold text-gray-900 mb-4">구매자 정보 (선택)</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">구매 업체명</label>
              <input
                type="text"
                value={buyerCompanyName}
                onChange={(e) => setBuyerCompanyName(e.target.value)}
                className="w-full border rounded-lg px-3 py-2"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">담당자명</label>
                <input
                  type="text"
                  value={buyerContactName}
                  onChange={(e) => setBuyerContactName(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">연락처</label>
                <input
                  type="tel"
                  value={buyerContactPhone}
                  onChange={(e) => setBuyerContactPhone(e.target.value)}
                  className="w-full border rounded-lg px-3 py-2"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={loading}
          className="w-full py-4 bg-blue-600 text-white rounded-xl font-semibold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loading ? "등록 중..." : "등록 및 보증서 생성"}
        </button>
      </form>
    </div>
  );
}

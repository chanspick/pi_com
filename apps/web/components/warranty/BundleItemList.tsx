"use client";

import { TransactionItem } from "@/types/warranty";
import { Cpu, HardDrive, MemoryStick, MonitorPlay, Box } from "lucide-react";

interface BundleItemListProps {
  items: TransactionItem[];
  showScores?: boolean;
}

export function BundleItemList({ items, showScores = false }: BundleItemListProps) {
  const getCategoryIcon = (category: string) => {
    const cat = category.toLowerCase();
    if (cat.includes("cpu")) return <Cpu className="h-4 w-4" />;
    if (cat.includes("gpu") || cat.includes("video")) return <MonitorPlay className="h-4 w-4" />;
    if (cat.includes("ram") || cat.includes("memory")) return <MemoryStick className="h-4 w-4" />;
    if (cat.includes("ssd") || cat.includes("hdd") || cat.includes("storage")) return <HardDrive className="h-4 w-4" />;
    return <Box className="h-4 w-4" />;
  };

  return (
    <div className="bg-white rounded-xl border overflow-hidden">
      <div className="px-4 py-3 bg-gray-50 border-b">
        <h3 className="font-semibold text-sm">구성 부품 ({items.length}개)</h3>
      </div>
      <ul className="divide-y">
        {items.map((item, index) => (
          <li key={item.itemId || index} className="px-4 py-3 flex items-center gap-3">
            <div className="w-8 h-8 bg-blue-50 rounded-lg flex items-center justify-center text-blue-600">
              {getCategoryIcon(item.partCategory)}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-medium text-sm truncate">
                {item.brand} {item.modelName}
              </p>
              <p className="text-xs text-gray-500">{item.partCategory}</p>
            </div>
            {showScores && (
              <div className="text-right">
                <p className="text-sm font-medium">{item.conditionScore}점</p>
                {item.benchmarkScore && (
                  <p className="text-xs text-gray-400">벤치: {item.benchmarkScore}</p>
                )}
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}

"use client";

import { ConditionGrade, GRADE_THRESHOLDS } from "@/types/warranty";
import { cn } from "@/lib/utils";

interface GradeBadgeProps {
  grade: ConditionGrade;
  size?: "sm" | "md" | "lg";
  showLabel?: boolean;
}

export function GradeBadge({ grade, size = "md", showLabel = true }: GradeBadgeProps) {
  const config = GRADE_THRESHOLDS[grade];

  const sizeClasses = {
    sm: "w-8 h-8 text-sm",
    md: "w-12 h-12 text-lg",
    lg: "w-16 h-16 text-2xl",
  };

  return (
    <div className="flex flex-col items-center gap-1">
      <div
        className={cn(
          "rounded-lg flex items-center justify-center font-bold",
          sizeClasses[size]
        )}
        style={{
          backgroundColor: config.bgColor,
          color: config.color,
        }}
      >
        {grade}
      </div>
      {showLabel && (
        <span
          className="text-xs font-medium"
          style={{ color: config.color }}
        >
          {config.labelKo}
        </span>
      )}
    </div>
  );
}

// 인라인 등급 표시
export function GradeInline({ grade }: { grade: ConditionGrade }) {
  const config = GRADE_THRESHOLDS[grade];

  return (
    <span
      className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
      style={{
        backgroundColor: config.bgColor,
        color: config.color,
      }}
    >
      <span className="font-bold">{grade}</span>
      <span>{config.labelKo}</span>
    </span>
  );
}

import Link from "next/link";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { TrendingUp, ImageIcon } from "lucide-react";
import type { BasePartRow } from "@/lib/supabase/queries";

const categoryLabels: Record<string, string> = {
  cpu: "CPU",
  gpu: "GPU",
  ram: "RAM",
  ssd: "SSD",
  mainboard: "메인보드",
  power: "파워",
  case: "케이스",
  cooler: "쿨러",
};

function formatPrice(price: number): string {
  if (price >= 10000) {
    return Math.round(price / 10000) + "만";
  }
  return new Intl.NumberFormat("ko-KR").format(price);
}

interface BasePartCardProps {
  part: BasePartRow;
}

export function BasePartCard({ part }: BasePartCardProps) {
  return (
    <Link
      href={"/parts/" + part.id}
      className="group block rounded-xl border bg-card overflow-hidden hover:border-primary/30 hover:shadow-md transition-all"
    >
      <div className="relative aspect-[4/3] bg-muted overflow-hidden">
        {part.image_url ? (
          <Image
            src={part.image_url}
            alt={part.name}
            fill
            className="object-contain p-4 group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center text-muted-foreground">
            <ImageIcon className="h-8 w-8" />
          </div>
        )}
        <div className="absolute top-2 left-2">
          <Badge variant="secondary" className="text-[11px] font-semibold bg-white/90 backdrop-blur-sm border-0 shadow-sm">
            {categoryLabels[part.category] ?? part.category}
          </Badge>
        </div>
      </div>

      <div className="p-3.5">
        {part.brand && (
          <p className="text-[11px] font-medium text-muted-foreground mb-0.5 truncate">
            {part.brand}
          </p>
        )}
        <h3 className="text-[14px] font-semibold leading-snug line-clamp-2 mb-2 group-hover:text-primary transition-colors">
          {part.name}
        </h3>

        <div className="flex items-center justify-between">
          <div className="flex items-baseline gap-1">
            <TrendingUp className="h-3 w-3 text-[hsl(var(--success))]" />
            <span className="text-[15px] font-bold text-foreground">
              {part.average_price > 0 ? formatPrice(part.average_price) + "원" : "-"}
            </span>
          </div>
          <div className="flex items-center gap-1 text-[11px] text-muted-foreground">
            <span className="font-medium">매물 {part.listing_count}</span>
          </div>
        </div>
      </div>
    </Link>
  );
}

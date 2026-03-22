import Link from "next/link";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { Heart, Eye, ImageIcon } from "lucide-react";
import type { ListingWithBasePart } from "@/lib/supabase/queries";

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
  return new Intl.NumberFormat("ko-KR").format(price);
}

function getRelativeTime(dateStr: string): string {
  const now = new Date();
  const date = new Date(dateStr);
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  if (diffMin < 1) return "방금";
  if (diffMin < 60) return `${diffMin}분 전`;
  if (diffHour < 24) return `${diffHour}시간 전`;
  if (diffDay < 30) return `${diffDay}일 전`;
  return date.toLocaleDateString("ko-KR");
}

interface ListingCardProps {
  listing: ListingWithBasePart;
}

export function ListingCard({ listing }: ListingCardProps) {
  const imageUrl = listing.images?.[0];
  const partName = listing.base_parts?.name ?? listing.title;
  const brand = listing.base_parts?.brand;

  return (
    <Link
      href={`/listings/${listing.id}`}
      className="group block rounded-xl border bg-card overflow-hidden hover:border-primary/30 hover:shadow-md transition-all"
    >
      <div className="relative aspect-[4/3] bg-muted overflow-hidden">
        {imageUrl ? (
          <Image
            src={imageUrl}
            alt={listing.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center text-muted-foreground">
            <ImageIcon className="h-8 w-8" />
          </div>
        )}
        <div className="absolute top-2 left-2">
          <Badge variant="secondary" className="text-[11px] font-semibold bg-white/90 backdrop-blur-sm border-0 shadow-sm">
            {categoryLabels[listing.category] ?? listing.category}
          </Badge>
        </div>
      </div>

      <div className="p-3.5">
        {brand && (
          <p className="text-[11px] font-medium text-muted-foreground mb-0.5 truncate">
            {brand}
          </p>
        )}
        <h3 className="text-[14px] font-semibold leading-snug line-clamp-2 mb-2 group-hover:text-primary transition-colors">
          {partName}
        </h3>

        <div className="flex items-baseline gap-1.5 mb-2">
          <span className="text-[18px] font-bold text-foreground">
            {formatPrice(listing.price)}
          </span>
          <span className="text-[13px] text-muted-foreground">원</span>
        </div>

        <div className="flex items-center justify-between text-[11px] text-muted-foreground">
          <span>{getRelativeTime(listing.created_at)}</span>
          <div className="flex items-center gap-2.5">
            <span className="flex items-center gap-0.5">
              <Eye className="h-3 w-3" />
              {listing.view_count}
            </span>
            <span className="flex items-center gap-0.5">
              <Heart className="h-3 w-3" />
              {listing.favorite_count}
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}

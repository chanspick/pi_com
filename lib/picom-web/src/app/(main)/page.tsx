import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import Link from "next/link";
import Image from "next/image";
import {
  ChevronRight,
  Cpu,
  Monitor,
  MemoryStick,
  HardDrive,
  CircuitBoard,
  Plug,
  Box,
  Fan,
  Eye,
} from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { formatPrice, formatRelativeTime, getCategoryLabel } from "@/lib/utils";
import type { ListingWithBasePart } from "@/lib/supabase/queries";

// 카테고리 목록 (아이콘 + 라벨 + 링크)
const categories = [
  { key: "cpu", label: "CPU", icon: Cpu },
  { key: "gpu", label: "GPU", icon: Monitor },
  { key: "ram", label: "RAM", icon: MemoryStick },
  { key: "ssd", label: "SSD", icon: HardDrive },
  { key: "mainboard", label: "메인보드", icon: CircuitBoard },
  { key: "power", label: "파워", icon: Plug },
  { key: "case", label: "케이스", icon: Box },
  { key: "cooler", label: "쿨러", icon: Fan },
];

// 매물 카드 컴포넌트
function ListingCard({ listing }: { listing: ListingWithBasePart }) {
  const imageUrl =
    listing.images && listing.images.length > 0
      ? listing.images[0]
      : null;

  return (
    <Link
      href={`/listings/${listing.id}`}
      className="group block rounded-[10px] border bg-card overflow-hidden hover:shadow-md transition-shadow"
    >
      {/* 이미지 영역 */}
      <div className="relative aspect-[4/3] bg-muted overflow-hidden">
        {imageUrl ? (
          <Image
            src={imageUrl}
            alt={listing.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
            sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw"
          />
        ) : (
          <div className="flex items-center justify-center h-full text-muted-foreground">
            <Box className="h-10 w-10" />
          </div>
        )}
      </div>

      {/* 정보 영역 */}
      <div className="p-3 space-y-1.5">
        {/* 카테고리 배지 */}
        <Badge variant="secondary" className="text-[11px] px-1.5 py-0">
          {getCategoryLabel(listing.category)}
        </Badge>

        {/* 제목 */}
        <h3 className="text-[14px] font-medium leading-snug line-clamp-2 group-hover:text-primary transition-colors">
          {listing.title}
        </h3>

        {/* 브랜드 / 모델 */}
        {listing.base_parts && (
          <p className="text-[12px] text-muted-foreground truncate">
            {listing.base_parts.brand} {listing.base_parts.model}
          </p>
        )}

        {/* 가격 + 조회수/시간 */}
        <div className="flex items-center justify-between pt-1">
          <span className="text-[15px] font-bold">
            {formatPrice(listing.price)}
          </span>
          <div className="flex items-center gap-2 text-[11px] text-muted-foreground">
            <span className="flex items-center gap-0.5">
              <Eye className="h-3 w-3" />
              {listing.view_count}
            </span>
            <span>{formatRelativeTime(listing.created_at)}</span>
          </div>
        </div>
      </div>
    </Link>
  );
}

// 섹션 헤더 컴포넌트
function SectionHeader({
  title,
  href,
  linkText = "전체보기",
}: {
  title: string;
  href: string;
  linkText?: string;
}) {
  return (
    <div className="flex items-center justify-between mb-5">
      <h2 className="text-[20px] font-bold">{title}</h2>
      <Link
        href={href}
        className="text-[13px] font-medium text-primary hover:text-primary/80 flex items-center gap-0.5"
      >
        {linkText}
        <ChevronRight className="h-3.5 w-3.5" />
      </Link>
    </div>
  );
}

export default async function HomePage() {
  const supabase = await createClient();

  // 인기 매물 (조회수 높은 순 6개)과 최근 매물 (최신순 6개) 병렬 조회
  const [popularResult, recentResult] = await Promise.all([
    supabase
      .from("listings")
      .select("*, base_parts (name, brand, model, category)")
      .eq("status", "active")
      .order("view_count", { ascending: false })
      .limit(6),
    supabase
      .from("listings")
      .select("*, base_parts (name, brand, model, category)")
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(6),
  ]);

  const popularListings = (popularResult.data as ListingWithBasePart[] | null) ?? [];
  const recentListings = (recentResult.data as ListingWithBasePart[] | null) ?? [];

  return (
    <div>
      {/* 히어로 섹션 */}
      <section className="bg-gradient-to-br from-blue-900 to-blue-700">
        <div className="container mx-auto max-w-7xl px-4 py-16 md:py-24 text-center">
          <div className="text-[72px] md:text-[96px] font-extrabold text-white leading-none select-none mb-4">
            &pi;
          </div>
          <h1 className="text-2xl font-bold text-white mb-3">
            검증된 중고 PC 부품 마켓플레이스
          </h1>
          <p className="text-[15px] text-white/70 mb-8 max-w-md mx-auto">
            PiCom에서 믿을 수 있는 중고 부품을 만나보세요
          </p>
          <div className="flex items-center justify-center gap-3">
            <Link href="/listings">
              <Button
                size="lg"
                className="bg-white text-blue-700 hover:bg-white/90 font-semibold h-11 px-6 rounded-[10px]"
              >
                매물 둘러보기
              </Button>
            </Link>
            <Link href="/parts">
              <Button
                variant="outline"
                size="lg"
                className="border-white/40 text-white hover:bg-white/10 font-semibold h-11 px-6 rounded-[10px] bg-transparent"
              >
                시세 확인
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* 카테고리 바로가기 */}
      <section className="container mx-auto max-w-7xl px-4 py-12">
        <h2 className="text-[20px] font-bold mb-5">카테고리</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {categories.map((cat) => (
            <Link
              key={cat.key}
              href={`/listings?category=${cat.key}`}
              className="group flex flex-col items-center gap-2.5 p-5 rounded-[10px] border bg-card hover:border-primary/30 hover:shadow-md transition-all"
            >
              <div className="w-11 h-11 rounded-[10px] bg-primary/5 group-hover:bg-primary/10 flex items-center justify-center transition-colors">
                <cat.icon className="h-5 w-5 text-primary/70 group-hover:text-primary transition-colors" />
              </div>
              <span className="font-semibold text-[14px]">{cat.label}</span>
            </Link>
          ))}
        </div>
      </section>

      {/* 인기 매물 */}
      {popularListings.length > 0 && (
        <section className="container mx-auto max-w-7xl px-4 pb-12">
          <SectionHeader title="인기 매물" href="/listings?sort=popular" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {popularListings.map((listing) => (
              <ListingCard key={listing.id} listing={listing} />
            ))}
          </div>
        </section>
      )}

      {/* 최근 등록 매물 */}
      {recentListings.length > 0 && (
        <section className="container mx-auto max-w-7xl px-4 pb-16">
          <SectionHeader title="최근 등록" href="/listings" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {recentListings.map((listing) => (
              <ListingCard key={listing.id} listing={listing} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

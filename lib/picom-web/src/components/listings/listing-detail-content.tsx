"use client";

import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { ImageGallery } from "@/components/listings/image-gallery";
import {
  ArrowLeft,
  Heart,
  Share2,
  ShoppingCart,
  Shield,
  Eye,
  Clock,
  Loader2,
} from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { useAddToCart } from "@/hooks/use-cart";
import { useToggleFavorite } from "@/hooks/use-favorites";
import { useRouter } from "next/navigation";

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

const conditionLabels: Record<string, string> = {
  new: "미개봉",
  like_new: "거의 새것",
  excellent: "상태 좋음",
  good: "상태 양호",
  fair: "사용감 있음",
};

function formatPrice(price: number): string {
  return new Intl.NumberFormat("ko-KR").format(price);
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

interface ListingDetailContentProps {
  listing: any;
}

export function ListingDetailContent({ listing }: ListingDetailContentProps) {
  const { user } = useAuth();
  const router = useRouter();
  const addToCart = useAddToCart();
  const toggleFavorite = useToggleFavorite();

  const partName = listing.base_parts?.name ?? listing.title;
  const brand = listing.base_parts?.brand;
  const model = listing.base_parts?.model;
  const specs = listing.specs as Record<string, string> | null;

  const handleAddToCart = () => {
    if (!user) {
      router.push("/login");
      return;
    }
    addToCart.mutate(
      { userId: user.id, listingId: listing.id },
      {
        onSuccess: () => alert("장바구니에 담았습니다"),
        onError: () => alert("장바구니 추가에 실패했습니다"),
      }
    );
  };

  const handleToggleFavorite = () => {
    if (!user) {
      router.push("/login");
      return;
    }
    toggleFavorite.mutate(
      { userId: user.id, listingId: listing.id },
      {
        onError: () => alert("찜 처리에 실패했습니다"),
      }
    );
  };

  return (
    <div className="container mx-auto max-w-7xl px-4 py-6">
      <div className="mb-6">
        <Link
          href="/listings"
          className="inline-flex items-center gap-1 text-[13px] text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          매물 목록으로
        </Link>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <ImageGallery images={listing.images ?? []} alt={partName} />

        <div className="space-y-5">
          <div className="flex items-center gap-2">
            <Badge variant="secondary" className="text-[12px] font-semibold">
              {categoryLabels[listing.category] ?? listing.category}
            </Badge>
            {listing.condition && (
              <Badge variant="outline" className="text-[12px]">
                {conditionLabels[listing.condition] ?? listing.condition}
              </Badge>
            )}
            {listing.is_featured && (
              <Badge className="text-[12px] bg-amber-500/10 text-amber-600 border-amber-500/20">
                추천
              </Badge>
            )}
          </div>

          {brand && (
            <p className="text-[13px] text-muted-foreground">{brand}</p>
          )}
          <h1 className="text-[24px] font-bold leading-tight">{partName}</h1>

          <div className="flex items-baseline gap-2">
            <span className="text-[32px] font-extrabold text-foreground">
              {formatPrice(listing.price)}
            </span>
            <span className="text-[16px] text-muted-foreground">원</span>
            {listing.original_price && listing.original_price > listing.price && (
              <span className="text-[14px] text-muted-foreground line-through ml-2">
                {formatPrice(listing.original_price)}원
              </span>
            )}
          </div>

          <Separator />

          <div className="grid grid-cols-2 gap-3 text-[13px]">
            <div className="flex items-center gap-2 text-muted-foreground">
              <Clock className="h-4 w-4" />
              <span>{formatDate(listing.created_at)}</span>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <Eye className="h-4 w-4" />
              <span>조회 {listing.view_count}</span>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <Heart className="h-4 w-4" />
              <span>관심 {listing.favorite_count}</span>
            </div>
            {listing.condition_score && (
              <div className="flex items-center gap-2 text-muted-foreground">
                <Shield className="h-4 w-4" />
                <span>상태점수 {listing.condition_score}/100</span>
              </div>
            )}
          </div>

          <Separator />

          <div className="flex gap-3">
            <Button
              size="lg"
              className="flex-1 h-12 text-[15px] font-semibold bg-gradient-to-r from-[#2563EB] to-[#3B82F6] hover:from-[#1D4ED8] hover:to-[#2563EB] shadow-[0_1px_3px_rgba(37,99,235,0.3)]"
              onClick={() => {
                if (!user) { alert("로그인이 필요합니다."); router.push("/login"); return; }
                router.push(`/checkout?listing_id=${listing.id}`);
              }}
            >
              바로 구매
            </Button>
            <Button
              variant="outline"
              size="lg"
              className="h-12 px-4"
              onClick={handleAddToCart}
              disabled={addToCart.isPending}
            >
              {addToCart.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <ShoppingCart className="h-4 w-4" />
              )}
            </Button>
            <Button
              variant="outline"
              size="lg"
              className="h-12 w-12 p-0"
              onClick={handleToggleFavorite}
              disabled={toggleFavorite.isPending}
            >
              <Heart className={`h-5 w-5 ${toggleFavorite.isPending ? "animate-pulse" : ""}`} />
            </Button>
            <Button
              variant="outline"
              size="lg"
              className="h-12 w-12 p-0"
              onClick={() => {
                navigator.clipboard.writeText(window.location.href);
                alert("링크가 복사되었습니다");
              }}
            >
              <Share2 className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>

      <div className="mt-10 grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="md:col-span-2 space-y-4">
          <h2 className="text-[18px] font-bold">상품 설명</h2>
          <div className="text-[14px] text-muted-foreground leading-relaxed whitespace-pre-wrap rounded-xl border bg-card p-5">
            {listing.description || "등록된 설명이 없습니다."}
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="text-[18px] font-bold">사양 정보</h2>
          <div className="rounded-xl border bg-card overflow-hidden">
            <table className="w-full text-[13px]">
              <tbody>
                {brand && (
                  <tr className="border-b last:border-0">
                    <td className="px-4 py-2.5 font-medium bg-muted/30 w-24">브랜드</td>
                    <td className="px-4 py-2.5">{brand}</td>
                  </tr>
                )}
                {model && (
                  <tr className="border-b last:border-0">
                    <td className="px-4 py-2.5 font-medium bg-muted/30 w-24">모델</td>
                    <td className="px-4 py-2.5">{model}</td>
                  </tr>
                )}
                {listing.category && (
                  <tr className="border-b last:border-0">
                    <td className="px-4 py-2.5 font-medium bg-muted/30 w-24">카테고리</td>
                    <td className="px-4 py-2.5">{categoryLabels[listing.category]}</td>
                  </tr>
                )}
                {specs && Object.entries(specs).map(([key, val]) => (
                  <tr key={key} className="border-b last:border-0">
                    <td className="px-4 py-2.5 font-medium bg-muted/30 w-24">{key}</td>
                    <td className="px-4 py-2.5">{String(val)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}

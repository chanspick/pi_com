"use client";

import Link from "next/link";
import Image from "next/image";
import { Heart, ArrowLeft, ImageIcon } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/hooks/use-auth";
import { useFavorites, useToggleFavorite } from "@/hooks/use-favorites";
import {
  formatPrice,
  formatRelativeTime,
  getCategoryLabel,
} from "@/lib/utils";

export default function FavoritesPage() {
  const { user, loading: authLoading } = useAuth();
  const { favorites, isLoading } = useFavorites(user?.id);
  const toggleFavoriteMutation = useToggleFavorite();

  const handleUnfavorite = (listingId: string) => {
    if (!user?.id) return;
    toggleFavoriteMutation.mutate({ userId: user.id, listingId });
  };

  // 로딩 상태
  if (authLoading || isLoading) {
    return (
      <div className="mx-auto max-w-5xl px-4 py-8">
        <div className="mb-6 flex items-center gap-3">
          <Skeleton className="h-9 w-9 rounded-lg" />
          <Skeleton className="h-7 w-32" />
        </div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="rounded-xl border bg-card overflow-hidden">
              <Skeleton className="aspect-[4/3] w-full" />
              <div className="p-3.5 space-y-2">
                <Skeleton className="h-3 w-16" />
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-5 w-24" />
                <Skeleton className="h-3 w-20" />
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  // 로그인 필요
  if (!user) {
    return (
      <div className="mx-auto max-w-5xl px-4 py-8">
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Heart className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">
            로그인이 필요한 서비스입니다.
          </p>
          <Link href="/login">
            <Button>로그인</Button>
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-5xl px-4 py-8">
      {/* 헤더 */}
      <div className="mb-6 flex items-center gap-3">
        <Link href="/my">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <h1 className="text-xl font-bold">즐겨찾기</h1>
        {favorites.length > 0 && (
          <span className="text-sm text-muted-foreground">
            {favorites.length}개
          </span>
        )}
      </div>

      {/* 빈 상태 */}
      {favorites.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-4 py-20">
          <Heart className="h-12 w-12 text-muted-foreground" />
          <p className="text-muted-foreground">
            즐겨찾기한 매물이 없습니다
          </p>
          <Link href="/listings">
            <Button>매물 둘러보기</Button>
          </Link>
        </div>
      ) : (
        /* 즐겨찾기 그리드 */
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          {favorites.map((fav: Record<string, unknown>) => {
            const listing = fav.listings as Record<string, unknown> | null;
            if (!listing) return null;

            const baseParts = listing.base_parts as Record<
              string,
              unknown
            > | null;
            const imageUrl = (listing.images as string[] | null)?.[0];
            const title =
              (listing.title as string) ||
              [baseParts?.name, baseParts?.brand, baseParts?.model]
                .filter(Boolean)
                .join(" ") ||
              "제목 없음";
            const category =
              (listing.category as string) ||
              (baseParts?.category as string) ||
              "";
            const price = (listing.price as number) ?? 0;
            const createdAt = listing.created_at as string;
            const listingId = listing.id as string;

            return (
              <div
                key={fav.id as string}
                className="group relative rounded-xl border bg-card overflow-hidden hover:border-primary/30 hover:shadow-md transition-all"
              >
                {/* 즐겨찾기 해제 버튼 */}
                <button
                  type="button"
                  onClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    handleUnfavorite(listingId);
                  }}
                  className="absolute right-2 top-2 z-10 flex h-8 w-8 items-center justify-center rounded-full bg-white/90 backdrop-blur-sm shadow-sm hover:bg-white transition-colors"
                  aria-label="즐겨찾기 해제"
                >
                  <Heart className="h-4 w-4 fill-red-500 text-red-500" />
                </button>

                <Link href={`/listings/${listingId}`}>
                  {/* 이미지 */}
                  <div className="relative aspect-[4/3] bg-muted overflow-hidden">
                    {imageUrl ? (
                      <Image
                        src={imageUrl}
                        alt={title}
                        fill
                        className="object-cover group-hover:scale-105 transition-transform duration-300"
                        sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                      />
                    ) : (
                      <div className="absolute inset-0 flex items-center justify-center text-muted-foreground">
                        <ImageIcon className="h-8 w-8" />
                      </div>
                    )}
                    {category && (
                      <div className="absolute top-2 left-2">
                        <Badge
                          variant="secondary"
                          className="text-[11px] font-semibold bg-white/90 backdrop-blur-sm border-0 shadow-sm"
                        >
                          {getCategoryLabel(category)}
                        </Badge>
                      </div>
                    )}
                  </div>

                  {/* 정보 */}
                  <div className="p-3.5">
                    <h3 className="text-[14px] font-semibold leading-snug line-clamp-2 mb-2 group-hover:text-primary transition-colors">
                      {title}
                    </h3>
                    <div className="flex items-baseline gap-1.5 mb-2">
                      <span className="text-[18px] font-bold text-foreground">
                        {formatPrice(price)}
                      </span>
                    </div>
                    {createdAt && (
                      <p className="text-[11px] text-muted-foreground">
                        {formatRelativeTime(createdAt)}
                      </p>
                    )}
                  </div>
                </Link>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

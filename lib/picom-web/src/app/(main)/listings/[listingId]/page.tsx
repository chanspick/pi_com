import { createClient } from "@/lib/supabase/server";
import { fetchListingById, ListingWithFullBasePart } from "@/lib/supabase/queries";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { ListingDetailContent } from "@/components/listings/listing-detail-content";

interface Props {
  params: Promise<{ listingId: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { listingId } = await params;
  const supabase = await createClient();
  const { listing } = await fetchListingById(supabase, listingId);

  if (!listing) {
    return { title: "매물을 찾을 수 없습니다 - PiCom" };
  }

  const title = listing.base_parts?.name ?? listing.title;
  return {
    title: title + " - PiCom",
    description: listing.description ?? title + " 중고 부품을 PiCom에서 만나보세요.",
    openGraph: {
      title: title + " - PiCom",
      images: listing.images?.[0] ? [listing.images[0]] : [],
    },
  };
}

export default async function ListingDetailPage({ params }: Props) {
  const { listingId } = await params;
  const supabase = await createClient();
  const { listing, error } = await fetchListingById(supabase, listingId);

  if (error || !listing) {
    notFound();
  }

  return <ListingDetailContent listing={listing} />;
}

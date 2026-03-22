import { SupabaseClient } from "@supabase/supabase-js";
import { Database } from "@/types/database.types";

export type ListingRow = Database["public"]["Tables"]["listings"]["Row"];
export type BasePartRow = Database["public"]["Tables"]["base_parts"]["Row"];

export type ListingWithBasePart = ListingRow & {
  base_parts: Pick<BasePartRow, "name" | "brand" | "model" | "category"> | null;
};


export type ListingWithFullBasePart = ListingRow & {
  base_parts: BasePartRow | null;
};

export interface ListingsQueryParams {
  category?: string;
  sort?: string;
  minPrice?: number;
  maxPrice?: number;
  status?: string;
  cursor?: string;
  limit?: number;
}

export async function fetchListings(
  supabase: SupabaseClient<Database>,
  params: ListingsQueryParams = {}
) {
  const {
    category,
    sort = "newest",
    minPrice,
    maxPrice,
    status = "active",
    cursor,
    limit = 20,
  } = params;

  let query = supabase
    .from("listings")
    .select(
      "*, base_parts (name, brand, model, category)",
      { count: "exact" }
    )
    .eq("status", status)
    .limit(limit);

  if (category) {
    query = query.eq("category", category);
  }

  if (minPrice !== undefined) {
    query = query.gte("price", minPrice);
  }

  if (maxPrice !== undefined) {
    query = query.lte("price", maxPrice);
  }

  // 정렬
  switch (sort) {
    case "price_asc":
      query = query.order("price", { ascending: true });
      break;
    case "price_desc":
      query = query.order("price", { ascending: false });
      break;
    case "popular":
      query = query.order("view_count", { ascending: false });
      break;
    case "newest":
    default:
      query = query.order("created_at", { ascending: false });
      break;
  }

  // 커서 기반 페이지네이션
  if (cursor) {
    query = query.lt("created_at", cursor);
  }

  const { data, error, count } = await query;

  return {
    listings: (data as ListingWithBasePart[] | null) ?? [],
    error,
    count: count ?? 0,
  };
}

export async function fetchListingById(
  supabase: SupabaseClient<Database>,
  listingId: string
) {
  const { data, error } = await supabase
    .from("listings")
    .select("*, base_parts (*)")
    .eq("id", listingId)
    .single();

  return { listing: data as ListingWithFullBasePart | null, error };
}

// M5: Base parts by category
export type PriceHistoryRow = Database["public"]["Tables"]["price_history"]["Row"];

export async function fetchBasePartsByCategory(
  supabase: SupabaseClient<Database>,
  category: string,
  search?: string
) {
  let query = supabase
    .from("base_parts")
    .select("*", { count: "exact" })
    .eq("category", category)
    .gt("listing_count", 0)
    .order("listing_count", { ascending: false });

  if (search) {
    query = query.or("name.ilike.%"+search+"%,brand.ilike.%"+search+"%,model.ilike.%"+search+"%");
  }

  const { data, error, count } = await query;
  return { parts: (data as BasePartRow[] | null) ?? [], error, count: count ?? 0 };
}

// M6: Price history
export async function fetchPriceHistory(
  supabase: SupabaseClient<Database>,
  basePartId: string,
  days: number = 30
) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const { data, error } = await supabase
    .from("price_history")
    .select("*")
    .eq("base_part_id", basePartId)
    .gte("recorded_at", since.toISOString())
    .order("recorded_at", { ascending: true });

  return { history: (data as PriceHistoryRow[] | null) ?? [], error };
}

// M7: Search (unified)
export async function searchAll(
  supabase: SupabaseClient<Database>,
  query: string,
  limit: number = 20
) {
  const searchPattern = "%" + query + "%";

  const [partsResult, listingsResult] = await Promise.all([
    supabase
      .from("base_parts")
      .select("*")
      .or("name.ilike."+searchPattern+",brand.ilike."+searchPattern+",model.ilike."+searchPattern)
      .gt("listing_count", 0)
      .order("listing_count", { ascending: false })
      .limit(limit),
    supabase
      .from("listings")
      .select("*, base_parts (name, brand, model, category)")
      .eq("status", "active")
      .or("title.ilike."+searchPattern)
      .order("created_at", { ascending: false })
      .limit(limit),
  ]);

  return {
    parts: (partsResult.data as BasePartRow[] | null) ?? [],
    listings: (listingsResult.data as ListingWithBasePart[] | null) ?? [],
    partsError: partsResult.error,
    listingsError: listingsResult.error,
  };
}

// P1: BasePart의 active 매물 목록 (basePartId 필터)
export async function fetchListingsByBasePart(
  supabase: SupabaseClient<Database>,
  basePartId: string,
  params: { sort?: string; cursor?: string; limit?: number } = {}
) {
  const { sort = "newest", cursor, limit = 20 } = params;

  let query = supabase
    .from("listings")
    .select("*, base_parts (name, brand, model, category)", { count: "exact" })
    .eq("base_part_id", basePartId)
    .eq("status", "active")
    .limit(limit);

  switch (sort) {
    case "price_asc":
      query = query.order("price", { ascending: true });
      break;
    case "price_desc":
      query = query.order("price", { ascending: false });
      break;
    case "newest":
    default:
      query = query.order("created_at", { ascending: false });
      break;
  }

  if (cursor) {
    query = query.lt("created_at", cursor);
  }

  const { data, error, count } = await query;
  return {
    listings: (data as ListingWithBasePart[] | null) ?? [],
    error,
    count: count ?? 0,
  };
}
// P0: 확장된 PriceHistory (90일, lowest_price + average_price 포함)
export async function fetchPriceHistoryExtended(
  supabase: SupabaseClient<Database>,
  basePartId: string,
  days: number = 90
) {
  const since = new Date();
  since.setDate(since.getDate() - days);

  const { data, error } = await supabase
    .from("price_history")
    .select("*")
    .eq("base_part_id", basePartId)
    .gte("recorded_at", since.toISOString())
    .order("recorded_at", { ascending: true });

  return { history: (data as PriceHistoryRow[] | null) ?? [], error };
}

// P2: 즐겨찾기
export type FavoriteRow = Database["public"]["Tables"]["favorites"]["Row"];

export async function fetchFavorites(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("favorites")
    .select("*, listings (*, base_parts (name, brand, model, category))")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  return { favorites: data ?? [], error };
}

export async function toggleFavorite(
  supabase: SupabaseClient<Database>,
  userId: string,
  listingId: string
) {
  const { data: existing } = await supabase
    .from("favorites")
    .select("id")
    .eq("user_id", userId)
    .eq("listing_id", listingId)
    .single();

  if (existing) {
    const { error } = await supabase.from("favorites").delete().eq("id", (existing as any).id);
    return { isFavorited: false, error };
  } else {
    const { error } = await supabase.from("favorites").insert({ user_id: userId, listing_id: listingId } as any);
    return { isFavorited: true, error };
  }
}
// P4: 장바구니
export type CartItemRow = Database["public"]["Tables"]["cart_items"]["Row"];

export async function fetchCartItems(
  supabase: SupabaseClient<Database>,
  userId: string
) {
  const { data, error } = await supabase
    .from("cart_items")
    .select("*, listings (*, base_parts (name, brand, model, category))")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  return { items: data ?? [], error };
}

export async function addToCart(
  supabase: SupabaseClient<Database>,
  userId: string,
  listingId: string
) {
  const { data, error } = await supabase
    .from("cart_items")
    .insert({ user_id: userId, listing_id: listingId } as any)
    .select()
    .single();
  return { item: data, error };
}

export async function removeFromCart(
  supabase: SupabaseClient<Database>,
  cartItemId: string
) {
  const { error } = await supabase.from("cart_items").delete().eq("id", cartItemId);
  return { error };
}

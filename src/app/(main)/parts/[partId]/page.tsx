import { createClient } from "@/lib/supabase/server";
import type { BasePartRow } from "@/lib/supabase/queries";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { PartDetailContent } from "@/components/parts/part-detail-content";

interface Props {
  params: Promise<{ partId: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { partId } = await params;
  const supabase = await createClient();
  const { data } = await supabase.from("base_parts").select("*").eq("id", partId).single() as { data: BasePartRow | null };

  if (!data) {
    return { title: "부품을 찾을 수 없습니다 - PiCom" };
  }

  return {
    title: data.name + " 시세 - PiCom",
    description: data.name + " 중고 시세를 PiCom에서 확인하세요.",
  };
}

export default async function PartDetailPage({ params }: Props) {
  const { partId } = await params;
  const supabase = await createClient();
  const { data, error } = await supabase.from("base_parts").select("*").eq("id", partId).single() as { data: BasePartRow | null; error: unknown };

  if (error || !data) {
    notFound();
  }

  return <PartDetailContent part={data} />;
}

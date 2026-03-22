import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "마이페이지 | PiCom",
  description: "내 프로필, 주문내역, 즐겨찾기 등을 관리하세요.",
};

export default function MyPageLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}

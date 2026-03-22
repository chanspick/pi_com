import Link from "next/link";
import { Separator } from "@/components/ui/separator";

export function Footer() {
  return (
    <footer className="border-t bg-card">
      <div className="container px-4 py-10 mx-auto max-w-7xl">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* 회사 정보 */}
          <div className="space-y-3">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-[#3B82F6] to-[#60A5FA] flex items-center justify-center">
                <span className="text-white text-xs font-extrabold">π</span>
              </div>
              <span className="font-bold text-lg">PiCom</span>
            </div>
            <p className="text-sm text-muted-foreground">
              AI 기반 하드웨어 검증으로
              안전한 중고 PC 부품 거래
            </p>
          </div>

          {/* 카테고리 */}
          <div className="space-y-3">
            <h4 className="font-semibold text-[13px] text-foreground/80 uppercase tracking-wider">카테고리</h4>
            <nav className="flex flex-col gap-1.5">
              <Link href="/listings?category=cpu" className="text-sm text-muted-foreground hover:text-foreground">CPU</Link>
              <Link href="/listings?category=gpu" className="text-sm text-muted-foreground hover:text-foreground">GPU</Link>
              <Link href="/listings?category=ram" className="text-sm text-muted-foreground hover:text-foreground">RAM</Link>
              <Link href="/listings?category=ssd" className="text-sm text-muted-foreground hover:text-foreground">SSD</Link>
              <Link href="/listings?category=mainboard" className="text-sm text-muted-foreground hover:text-foreground">메인보드</Link>
            </nav>
          </div>

          {/* 고객지원 */}
          <div className="space-y-3">
            <h4 className="font-semibold text-[13px] text-foreground/80 uppercase tracking-wider">고객지원</h4>
            <nav className="flex flex-col gap-1.5">
              <Link href="/about" className="text-sm text-muted-foreground hover:text-foreground">회사 소개</Link>
              <Link href="/terms" className="text-sm text-muted-foreground hover:text-foreground">이용약관</Link>
              <Link href="/privacy" className="text-sm text-muted-foreground hover:text-foreground">개인정보처리방침</Link>
            </nav>
          </div>

          {/* 연락처 */}
          <div className="space-y-3">
            <h4 className="font-semibold text-[13px] text-foreground/80 uppercase tracking-wider">고객센터</h4>
            <p className="text-sm text-muted-foreground">
              문의: support@picom.app
            </p>
            <p className="text-sm text-muted-foreground">
              운영시간: 평일 10:00 - 18:00
            </p>
          </div>
        </div>

        <Separator className="my-8" />

        <div className="flex flex-col sm:flex-row items-center justify-between gap-2 text-[12px] text-muted-foreground">
          <p>&copy; {new Date().getFullYear()} PiCom. All rights reserved.</p>
          <p>중고 PC 부품 검증·거래 플랫폼</p>
        </div>
      </div>
    </footer>
  );
}

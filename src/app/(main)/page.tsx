import { Button } from "@/components/ui/button";
import Link from "next/link";
import {
  Shield,
  Zap,
  TrendingUp,
  ChevronRight,
  Cpu,
  Monitor,
  MemoryStick,
  HardDrive,
  CircuitBoard,
  Plug,
  Box,
  Fan,
} from "lucide-react";

const categories = [
  { name: "CPU", href: "/listings?category=cpu", icon: Cpu, desc: "프로세서" },
  { name: "GPU", href: "/listings?category=gpu", icon: Monitor, desc: "그래픽카드" },
  { name: "RAM", href: "/listings?category=ram", icon: MemoryStick, desc: "메모리" },
  { name: "SSD", href: "/listings?category=ssd", icon: HardDrive, desc: "저장장치" },
  { name: "메인보드", href: "/listings?category=mainboard", icon: CircuitBoard, desc: "메인보드" },
  { name: "파워", href: "/listings?category=power", icon: Plug, desc: "파워서플라이" },
  { name: "케이스", href: "/listings?category=case", icon: Box, desc: "PC 케이스" },
  { name: "쿨러", href: "/listings?category=cooler", icon: Fan, desc: "쿨링 시스템" },
];

const features = [
  {
    icon: Shield,
    title: "검증된 부품",
    desc: "AI 기반 하드웨어 검증으로 부품 상태를 확인합니다",
  },
  {
    icon: Zap,
    title: "빠른 거래",
    desc: "간편한 등록과 안전한 결제로 빠르게 거래하세요",
  },
  {
    icon: TrendingUp,
    title: "시세 추적",
    desc: "실시간 중고 부품 시세로 합리적인 가격에 거래하세요",
  },
];

export default function HomePage() {
  return (
    <div>
      {/* Hero Section */}
      <section className="relative overflow-hidden bg-gradient-to-br from-[#0F172A] via-[#1E3A5F] to-[#1D4ED8]">
        <div className="absolute top-[-60px] right-[-40px] w-[300px] h-[300px] rounded-full bg-[rgba(59,130,246,0.15)]" />
        <div className="absolute bottom-[-30px] right-[120px] w-[180px] h-[180px] rounded-full bg-[rgba(59,130,246,0.1)]" />
        <div className="absolute top-[40%] left-[-80px] w-[200px] h-[200px] rounded-full bg-[rgba(96,165,250,0.08)]" />

        <div className="relative container mx-auto max-w-7xl px-4 py-20 md:py-28">
          <div className="max-w-2xl space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/10 border border-white/20 text-white/80 text-[13px] font-medium backdrop-blur-sm">
              <Shield className="h-3.5 w-3.5" />
              AI 기반 하드웨어 검증 플랫폼
            </div>
            <h1 className="text-4xl md:text-5xl lg:text-[56px] font-extrabold tracking-tight text-white leading-[1.15]">
              검증된 부품,{" "}
              <br className="hidden sm:block" />
              합리적 거래
            </h1>
            <p className="text-[15px] md:text-base text-white/60 leading-relaxed max-w-lg">
              판매자가 업로드한 벤치마크 결과를 AI가 자동 분석하여
              부품 상태를 검증합니다. 안전한 중고 PC 부품 거래를 경험하세요.
            </p>
            <div className="flex gap-3 pt-2">
              <Link href="/listings">
                <Button
                  size="lg"
                  className="text-[14px] font-semibold bg-white text-[#1D4ED8] hover:bg-white/90 shadow-lg h-12 px-6 rounded-lg"
                >
                  매물 보기
                  <ChevronRight className="h-4 w-4 ml-1" />
                </Button>
              </Link>
              <Link href="/sell">
                <Button
                  variant="outline"
                  size="lg"
                  className="text-[14px] font-semibold border-white/30 text-white hover:bg-white/10 h-12 px-6 rounded-lg bg-transparent"
                >
                  판매하기
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="container mx-auto max-w-7xl px-4 py-16">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {features.map((f) => (
            <div
              key={f.title}
              className="flex items-start gap-4 p-6 rounded-xl border bg-card hover:shadow-md transition-shadow"
            >
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
                <f.icon className="h-5 w-5 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold text-[15px] mb-1">{f.title}</h3>
                <p className="text-[13px] text-muted-foreground leading-relaxed">
                  {f.desc}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Categories */}
      <section className="container mx-auto max-w-7xl px-4 pb-20">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-[22px] font-bold">카테고리</h2>
            <p className="text-[13px] text-muted-foreground mt-1">
              원하는 부품을 카테고리별로 찾아보세요
            </p>
          </div>
          <Link
            href="/listings"
            className="text-[13px] font-medium text-primary hover:text-primary/80 flex items-center gap-1"
          >
            전체보기
            <ChevronRight className="h-3.5 w-3.5" />
          </Link>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {categories.map((cat) => (
            <Link
              key={cat.name}
              href={cat.href}
              className="group flex flex-col items-center gap-3 p-5 rounded-xl border bg-card hover:border-primary/30 hover:shadow-md transition-all"
            >
              <div className="w-12 h-12 rounded-xl bg-primary/5 group-hover:bg-primary/10 flex items-center justify-center transition-colors">
                <cat.icon className="h-6 w-6 text-primary/70 group-hover:text-primary transition-colors" />
              </div>
              <div className="text-center">
                <span className="font-semibold text-[14px] block">{cat.name}</span>
                <span className="text-[12px] text-muted-foreground">{cat.desc}</span>
              </div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}

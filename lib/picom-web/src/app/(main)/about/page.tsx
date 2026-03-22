import type { Metadata } from "next";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";

export const metadata: Metadata = {
  title: "회사 소개 | PiCom",
  description:
    "(주)파이컴퓨터가 운영하는 PiCom - AI 기반 하드웨어 검증으로 안전한 중고 PC 부품 거래 플랫폼",
};

export default function AboutPage() {
  return (
    <div className="container mx-auto max-w-3xl px-4 py-12 md:py-16">
      <h1 className="text-3xl font-bold tracking-tight text-foreground mb-2">
        회사 소개
      </h1>
      <p className="text-[15px] text-muted-foreground mb-8">
        AI 기반 하드웨어 검증으로 안전한 중고 PC 부품 거래
      </p>

      <div className="space-y-10 text-[15px] leading-relaxed text-foreground/90">
        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            PiCom이란?
          </h2>
          <p>
            PiCom은 (주)파이컴퓨터가 운영하는 중고 PC 부품 거래 플랫폼입니다.
            AI 기반 하드웨어 검증 시스템을 통해 부품의 실제 상태를 객관적으로
            평가하고, 구매자와 판매자 모두에게 신뢰할 수 있는 거래 환경을
            제공합니다.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            핵심 서비스
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Card>
              <CardContent className="pt-5">
                <h3 className="font-semibold mb-1">AI 하드웨어 검증</h3>
                <p className="text-[13px] text-muted-foreground">
                  벤치마크 결과를 AI가 분석하여 부품의 성능과 상태를 객관적으로
                  평가합니다.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-5">
                <h3 className="font-semibold mb-1">실시간 시세 정보</h3>
                <p className="text-[13px] text-muted-foreground">
                  카테고리별 부품 시세를 실시간으로 추적하여 합리적인 가격
                  판단을 돕습니다.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-5">
                <h3 className="font-semibold mb-1">안전 거래 시스템</h3>
                <p className="text-[13px] text-muted-foreground">
                  검수 후 배송, 홀로그램 봉인 씰 부착으로 거래 안전성을
                  보장합니다.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-5">
                <h3 className="font-semibold mb-1">유료 보증 서비스</h3>
                <p className="text-[13px] text-muted-foreground">
                  등급별 보증 기간 연장 서비스로 구매 후에도 안심할 수
                  있습니다.
                </p>
              </CardContent>
            </Card>
          </div>
        </section>

        <Separator />

        <section className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            사업자 정보
          </h2>
          <Card className="bg-muted/30">
            <CardContent className="pt-5">
              <dl className="grid grid-cols-[auto_1fr] gap-x-6 gap-y-2 text-[14px]">
                <dt className="text-muted-foreground">상호</dt>
                <dd className="font-medium">(주) 파이컴퓨터</dd>
                <dt className="text-muted-foreground">대표자</dt>
                <dd>최진규</dd>
                <dt className="text-muted-foreground">사업자등록번호</dt>
                <dd>207-87-03690</dd>
                <dt className="text-muted-foreground">통신판매업 신고번호</dt>
                <dd>2025-서울서대문-1006</dd>
                <dt className="text-muted-foreground">주소</dt>
                <dd>서울특별시 서대문구 연세로2나길 61</dd>
                <dt className="text-muted-foreground">대표전화</dt>
                <dd>02-6402-0025</dd>
                <dt className="text-muted-foreground">이메일</dt>
                <dd>wlsrb00g@gmail.com</dd>
              </dl>
            </CardContent>
          </Card>
        </section>
      </div>
    </div>
  );
}

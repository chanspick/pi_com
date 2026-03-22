import type { Metadata } from "next";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export const metadata: Metadata = {
  title: "환불 정책 | PiCom",
  description:
    "(주)파이컴퓨터 PiCom 플랫폼의 청약철회, 반품, 환불 정책입니다. 중고 PC 부품 거래의 반품 및 환불 절차를 안내합니다.",
};

export default function RefundPolicyPage() {
  return (
    <div className="container mx-auto max-w-3xl px-4 py-12 md:py-16">
      <p className="text-sm text-muted-foreground mb-6">
        시행일: 2025년 12월 1일
      </p>

      <h1 className="text-3xl font-bold tracking-tight text-foreground mb-2">
        환불 정책
      </h1>
      <p className="text-amber-600 font-medium mb-8">
        (주)파이컴퓨터 PiCom 플랫폼 청약철회 / 반품 / 환불 규정
      </p>

      {/* 목차 */}
      <nav className="bg-muted/50 rounded-xl p-6 mb-10">
        <h2 className="text-lg font-semibold text-foreground mb-4">목차</h2>
        <ol className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm text-foreground/80">
          <li>
            <a href="#article-1" className="hover:text-primary transition-colors">
              제1조 - 정책의 목적 및 적용 범위
            </a>
          </li>
          <li>
            <a href="#article-2" className="hover:text-primary transition-colors">
              제2조 - 구매자의 청약철회
            </a>
          </li>
          <li>
            <a href="#article-3" className="hover:text-primary transition-colors">
              제3조 - 청약철회 제한 사항
            </a>
          </li>
          <li>
            <a href="#article-4" className="hover:text-primary transition-colors">
              제4조 - 반품 절차
            </a>
          </li>
          <li>
            <a href="#article-5" className="hover:text-primary transition-colors">
              제5조 - 환불 처리
            </a>
          </li>
          <li>
            <a href="#article-6" className="hover:text-primary transition-colors">
              제6조 - 판매자의 청약철회 제한
            </a>
          </li>
          <li>
            <a href="#article-7" className="hover:text-primary transition-colors">
              제7조 - 배송비 부담
            </a>
          </li>
          <li>
            <a href="#article-8" className="hover:text-primary transition-colors">
              제8조 - 책임 및 손해배상
            </a>
          </li>
          <li>
            <a href="#article-9" className="hover:text-primary transition-colors">
              제9조 - 유료 보증 서비스 이용
            </a>
          </li>
          <li>
            <a href="#article-10" className="hover:text-primary transition-colors">
              제10조 - 보증 서비스 수수료 환불 특례
            </a>
          </li>
          <li>
            <a href="#article-11" className="hover:text-primary transition-colors">
              제11조 - 보관 서비스 및 물품 인도
            </a>
          </li>
          <li>
            <a href="#article-12" className="hover:text-primary transition-colors">
              제12조 - 보관 서비스 수수료 환불 특례
            </a>
          </li>
        </ol>
      </nav>

      <div className="space-y-10 text-[15px] leading-relaxed text-foreground/90">
        {/* 제1조 */}
        <section id="article-1" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제1조 (정책의 목적 및 적용 범위)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">목적:</span> 본
              정책은 PiCom 플랫폼(이하 &apos;플랫폼&apos;)에서 이루어지는 중고
              PC 부품 거래와 관련하여 구매자 및 판매자의 청약철회, 반품, 환불
              절차를 명확히 규정함으로써 소비자의 권익을 보호하고 공정한 거래
              질서를 확립하는 것을 목적으로 합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">적용 범위:</span>{" "}
              본 정책은 (주)파이컴퓨터(이하 &apos;회사&apos;)가 운영하는 PiCom
              플랫폼에서 거래되는 모든 중고 PC 부품에 적용됩니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                법령과의 관계:
              </span>{" "}
              본 정책은 「전자상거래 등에서의 소비자보호에 관한 법률」, 「약관의
              규제에 관한 법률」 등 관련 법령을 준수하며, 법령과 본 정책이
              상충하는 경우 법령이 우선합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                변경 및 통지:
              </span>{" "}
              회사는 관련 법령 개정, 정책 변경 등의 사유로 본 정책을 개정할 수
              있으며, 개정 시 최소 7일 전에 플랫폼 공지사항을 통해 고지합니다.
            </li>
          </ol>
        </section>

        {/* 제2조 */}
        <section id="article-2" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제2조 (구매자의 청약철회)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">
                청약철회 기간:
              </span>{" "}
              구매자는 물품 수령일로부터 7일 이내에 청약철회(반품)를 신청할 수
              있습니다. 물품 수령일은 택배사 배송 완료 시점 또는 구매자가 직접
              수령한 날짜로 합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                청약철회 사유:
              </span>
              <ul className="list-disc list-inside ml-6 mt-2 space-y-1.5">
                <li>제품의 기능 불량 또는 성능 미달</li>
                <li>주문한 제품과 다른 제품이 배송된 경우</li>
                <li>제품 설명과 실제 상태가 현저히 다른 경우</li>
                <li>
                  단순 변심 (단, 제3조의 제한 사항에 해당하지 않는 경우에 한함)
                </li>
              </ul>
            </li>
            <li>
              <span className="font-medium text-foreground">
                청약철회 효과:
              </span>{" "}
              청약철회가 승인되면 구매자는 제품을 회사에 반품하고, 회사는
              제5조에 따라 환불 처리를 진행합니다.
            </li>
          </ol>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <p className="text-sm text-foreground/80">
              <span className="font-medium text-foreground">안내:</span> 물품
              수령 후 7일 이내에 PiCom 앱/웹에서 반품을 신청해 주세요.
            </p>
          </div>
        </section>

        {/* 제3조 */}
        <section id="article-3" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제3조 (청약철회 제한 사항)
          </h2>
          <div className="bg-destructive/10 border-l-4 border-destructive p-4 rounded-r-lg mb-3">
            <p className="text-sm text-foreground/80">
              <span className="font-medium text-foreground">주의:</span> 아래
              사항에 해당하는 경우 청약철회가 제한될 수 있습니다.
            </p>
          </div>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">
                봉인 씰 훼손:
              </span>{" "}
              회사가 부착한 홀로그램 봉인 씰이 파손 또는 훼손된 경우 (단,
              제품의 기능 불량 확인을 위해 불가피하게 개봉한 경우는 예외로 하며,
              이 경우 개봉 즉시 회사에 신고해야 합니다)
            </li>
            <li>
              <span className="font-medium text-foreground">사용 흔적:</span>{" "}
              제품에 명백한 사용 흔적(스크래치, 오염, 먼지 축적 등)이 있는 경우
            </li>
            <li>
              <span className="font-medium text-foreground">구성품 누락:</span>{" "}
              제품과 함께 제공된 구성품이 누락된 경우
            </li>
            <li>
              <span className="font-medium text-foreground">
                구매자 귀책 사유:
              </span>{" "}
              구매자의 보관 부주의로 제품이 훼손되거나 가치가 현저히 감소한 경우
            </li>
            <li>
              <span className="font-medium text-foreground">기간 경과:</span>{" "}
              청약철회 가능 기간(7일)이 경과한 경우
            </li>
          </ol>
        </section>

        {/* 제4조 */}
        <section id="article-4" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제4조 (반품 절차)
          </h2>
          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-foreground mb-1">
                1. 반품 신청
              </h3>
              <p className="text-foreground/80">
                PiCom 앱/웹에서 반품 신청, 반품 사유/사진/연락처 등 필수 정보
                입력
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                2. 회사의 승인
              </h3>
              <p className="text-foreground/80">
                영업일 기준 1~2일 이내에 승인 또는 거부 통보
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                3. 물품 발송
              </h3>
              <p className="text-foreground/80">
                승인 후 7일 이내에 회사가 지정한 주소로 발송, 송장번호 등록
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                4. 회사의 검수
              </h3>
              <p className="text-foreground/80 mb-2">
                물품 수령 후 3영업일 이내에 다음 사항을 검수합니다:
              </p>
              <ul className="list-disc list-inside ml-4 space-y-1 text-foreground/80">
                <li>봉인 씰 상태 확인</li>
                <li>물품 외관 및 기능 이상 유무</li>
                <li>구성품 누락 여부</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                5. 검수 불합격
              </h3>
              <div className="bg-destructive/10 border-l-4 border-destructive p-4 rounded-r-lg">
                <p className="text-sm text-foreground/80">
                  봉인 씰 파손, 사용 흔적, 구성품 누락, 신청 내용과 실제 상태
                  불일치 시 반품이 거부되며, 이 경우{" "}
                  <span className="font-medium text-foreground">
                    왕복 배송비는 구매자 부담
                  </span>
                  입니다.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* 제5조 */}
        <section id="article-5" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제5조 (환불 처리)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">환불 시기:</span>{" "}
              검수 완료일로부터 3영업일 이내. 결제 수단에 따라 실제 입금까지 추가
              2~5영업일 소요될 수 있습니다.
            </li>
            <li>
              <span className="font-medium text-foreground">환불 방법:</span>
              <ul className="list-disc list-inside ml-6 mt-2 space-y-1.5">
                <li>신용카드: 승인취소</li>
                <li>계좌이체: 지정 계좌로 환불</li>
                <li>간편결제: 잔액 환불</li>
              </ul>
            </li>
            <li>
              <span className="font-medium text-foreground">환불 금액:</span>
              <ul className="list-disc list-inside ml-6 mt-2 space-y-1.5">
                <li>
                  판매자/제품 귀책 → 결제 금액 전액 + 왕복 배송비 회사 부담
                </li>
                <li>
                  구매자 귀책(단순 변심) → 결제 금액 - 왕복 배송비 공제
                </li>
              </ul>
            </li>
            <li>
              <span className="font-medium text-foreground">부분 환불:</span>{" "}
              여러 상품을 동시에 구매한 경우 일부 상품만 반품하여 부분 환불을
              받을 수 있습니다.
            </li>
          </ol>
        </section>

        {/* 제6조 */}
        <section id="article-6" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제6조 (판매자의 청약철회 제한)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">
                철회 가능 시기:
              </span>{" "}
              물품 발송 후 검수가 시작되기 전까지 판매 의사 철회가 가능하며,
              검수 시작 이후에는 임의 취소가 불가합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                검수 시작 기준:
              </span>{" "}
              검수 센터에 물품 도착 후 박스 개봉 영상 촬영 시점을 기준으로
              합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                부득이한 취소:
              </span>{" "}
              검수 시작 후 취소 시 기본 위약금(판매 희망가의 5%)이 부과됩니다.
            </li>
            <li>
              <span className="font-medium text-foreground">예외 사항:</span>{" "}
              천재지변, 사망/중대한 질병 등 불가피한 사유 시 협의를 통해 감면이
              가능합니다.
            </li>
          </ol>
          <div className="bg-amber-50 dark:bg-amber-950/20 border-l-4 border-amber-500 p-4 rounded-r-lg">
            <p className="text-sm text-foreground/80">
              <span className="font-medium text-foreground">참고:</span> 검수
              시작 이후 취소 시 판매 희망가의 5%에 해당하는 위약금이
              부과됩니다. 불가피한 사유는 증빙 서류를 통해 확인합니다.
            </p>
          </div>
        </section>

        {/* 제7조 */}
        <section id="article-7" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제7조 (배송비 부담)
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-3 px-4 font-semibold text-foreground bg-muted/50">
                    사유
                  </th>
                  <th className="text-left py-3 px-4 font-semibold text-foreground bg-muted/50">
                    부담 주체
                  </th>
                  <th className="text-left py-3 px-4 font-semibold text-foreground bg-muted/50">
                    비고
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-b border-border">
                  <td className="py-3 px-4 text-foreground/80">단순 변심</td>
                  <td className="py-3 px-4 text-foreground/80">구매자 부담</td>
                  <td className="py-3 px-4 text-foreground/80">
                    왕복 배송비 약 6,000~10,000원
                  </td>
                </tr>
                <tr className="border-b border-border bg-muted/30">
                  <td className="py-3 px-4 text-foreground/80">기능 불량</td>
                  <td className="py-3 px-4 text-foreground/80">판매자 부담</td>
                  <td className="py-3 px-4 text-foreground/80">
                    회사가 먼저 부담 후 판매자에게 청구
                  </td>
                </tr>
                <tr className="border-b border-border">
                  <td className="py-3 px-4 text-foreground/80">오배송</td>
                  <td className="py-3 px-4 text-foreground/80">회사 부담</td>
                  <td className="py-3 px-4 text-foreground/80">
                    회사의 실수로 인한 경우
                  </td>
                </tr>
                <tr className="border-b border-border bg-muted/30">
                  <td className="py-3 px-4 text-foreground/80">검수 오류</td>
                  <td className="py-3 px-4 text-foreground/80">회사 부담</td>
                  <td className="py-3 px-4 text-foreground/80">
                    회사의 검수 실수로 인한 경우
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        {/* 제8조 */}
        <section id="article-8" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제8조 (책임 및 손해배상)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">
                회사의 책임:
              </span>{" "}
              반품/환불 절차를 신속하고 정확하게 처리할 의무가 있습니다.
              고의/과실로 인한 지연 또는 오류 시 손해를 배상합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                판매자의 책임:
              </span>{" "}
              정확한 상품 정보를 등록해야 합니다. 기능 불량/허위 정보로 인한
              반품 시 왕복 배송비 및 위약금을 부담합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                구매자의 책임:
              </span>{" "}
              물품 수령 즉시 상태를 확인할 의무가 있습니다. 부주의로 인한 훼손
              시 반품이 거부되거나 배상 책임이 발생할 수 있습니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                손해배상 범위:
              </span>{" "}
              손해배상의 범위는 통상적인 손해 범위 내로 제한됩니다.
            </li>
          </ol>
        </section>

        {/* 제9조 */}
        <section id="article-9" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제9조 (유료 보증 서비스 이용)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">
                보증 서비스의 목적 및 적용:
              </span>{" "}
              PiCom 유료 보증 기간 연장 서비스에 한하여 적용됩니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                중도 해지 및 위약금:
              </span>
              <ul className="list-disc list-inside ml-6 mt-2 space-y-1.5">
                <li>(a) 유효 기간 중 해지 신청이 가능합니다.</li>
                <li>
                  (b) 잔여 기간 비례 환불이 적용되며, 총 결제 금액의 10% 이내
                  위약금이 공제됩니다.
                </li>
                <li>
                  (c) 수리/교환을 1회 이상 이용한 경우 환불이 불가합니다.
                </li>
              </ul>
            </li>
          </ol>
          <div className="bg-amber-50 dark:bg-amber-950/20 border-l-4 border-amber-500 p-4 rounded-r-lg">
            <p className="text-sm text-foreground/80">
              <span className="font-medium text-foreground">참고:</span> 수리 또는
              교환 서비스를 1회 이상 이용한 경우, 보증 서비스 환불이 불가합니다.
            </p>
          </div>
        </section>

        {/* 제10조 */}
        <section id="article-10" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제10조 (보증 서비스 수수료 환불 특례)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              상품 청약철회 시 보증 서비스 금액은 전액 환불됩니다.
            </li>
            <li>
              서비스 미개시 시 7일 이내 해지하면 전액 환불됩니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                환불 신청 및 처리 절차:
              </span>{" "}
              3영업일 이내 산정 후 통보하며, 통보일로부터 3영업일 이내에 환불
              처리를 완료합니다.
            </li>
          </ol>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <p className="text-sm text-foreground/80">
              <span className="font-medium text-foreground">안내:</span> 상품
              자체의 청약철회가 이루어지면 보증 서비스 금액도 함께 전액
              환불됩니다.
            </p>
          </div>
        </section>

        {/* 제11조 */}
        <section id="article-11" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제11조 (보관 서비스 및 물품 인도)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">보관 기간:</span>{" "}
              최대 30일까지 보관이 가능하며, 기간 경과 시 강제 배송 처리됩니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                보관 수수료:
              </span>{" "}
              보관 종료 시점에 청구되며, 7일 이내 납부 의무가 있습니다. 37일이
              최종 정산 기한입니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                미납 시 조치:
              </span>
              <ul className="list-disc list-inside ml-6 mt-2 space-y-1.5">
                <li>유치권 행사 (민법 제320조)</li>
                <li>37일 강제 종결 및 물품 매각</li>
              </ul>
            </li>
          </ol>
          <div className="bg-destructive/10 border-l-4 border-destructive p-4 rounded-r-lg">
            <p className="text-sm text-foreground/80">
              <span className="font-medium text-foreground">주의:</span> 보관
              수수료 미납 시 민법 제320조에 따라 유치권이 행사되며, 37일 경과 후
              물품이 강제 매각될 수 있습니다.
            </p>
          </div>
        </section>

        {/* 제12조 */}
        <section id="article-12" className="space-y-3 scroll-mt-20">
          <h2 className="text-xl font-semibold text-foreground">
            제12조 (보관 서비스 수수료 환불 특례)
          </h2>
          <ol className="list-decimal list-inside space-y-3 text-foreground/80">
            <li>
              <span className="font-medium text-foreground">청구 기준:</span>{" "}
              보관 수수료는 7일 초과 시 발생합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">환불 원칙:</span>{" "}
              이미 이용된 기간에 대한 수수료는 환불이 불가합니다.
            </li>
            <li>
              <span className="font-medium text-foreground">
                상품 청약철회 시:
              </span>
              <ul className="list-disc list-inside ml-6 mt-2 space-y-1.5">
                <li>
                  판매자/제품 귀책 → 보관 수수료 전액 환불 또는 취소
                </li>
                <li>구매자 귀책(단순 변심) → 보관 수수료 환불 불가</li>
              </ul>
            </li>
            <li>
              <span className="font-medium text-foreground">
                긴급 처분 시:
              </span>{" "}
              매각 대금에서 비용, 수수료, 채권액 순으로 정산되며, 잔액이 있을
              경우 반환됩니다.
            </li>
          </ol>
        </section>

        {/* 부칙 */}
        <section className="pt-6 border-t border-border space-y-4">
          <h2 className="text-xl font-semibold text-foreground">부칙</h2>
          <p className="text-foreground/80">
            본 정책은 2025년 12월 1일부터 시행됩니다.
          </p>
        </section>

        {/* 사업자 정보 */}
        <Card>
          <CardHeader>
            <CardTitle>사업자 정보</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm text-foreground/80">
              <div>
                <span className="font-medium text-foreground">상호:</span>{" "}
                (주)파이컴퓨터
              </div>
              <div>
                <span className="font-medium text-foreground">대표:</span>{" "}
                최진규
              </div>
              <div>
                <span className="font-medium text-foreground">
                  사업자등록번호:
                </span>{" "}
                207-87-03690
              </div>
              <div>
                <span className="font-medium text-foreground">
                  통신판매업신고:
                </span>{" "}
                2025-서울서대문-1006
              </div>
              <div className="sm:col-span-2">
                <span className="font-medium text-foreground">주소:</span>{" "}
                서울특별시 서대문구 연세로2나길 61
              </div>
              <div>
                <span className="font-medium text-foreground">전화:</span>{" "}
                02-6402-0025
              </div>
              <div>
                <span className="font-medium text-foreground">이메일:</span>{" "}
                wlsrb00g@gmail.com
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 고객센터 */}
        <Card>
          <CardHeader>
            <CardTitle>고객센터</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 text-sm text-foreground/80">
              <div className="flex items-start gap-2">
                <span className="font-medium text-foreground min-w-[60px]">
                  전화:
                </span>
                <span>02-6402-0025 (평일 09:00~18:00)</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="font-medium text-foreground min-w-[60px]">
                  이메일:
                </span>
                <span>wlsrb00g@gmail.com</span>
              </div>
              <div className="flex items-start gap-2">
                <span className="font-medium text-foreground min-w-[60px]">
                  카카오톡:
                </span>
                <span>PiCom 고객센터</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

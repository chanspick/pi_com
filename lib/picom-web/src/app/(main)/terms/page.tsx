import type { Metadata } from "next";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export const metadata: Metadata = {
  title: "이용약관 | PiCom",
  description:
    "(주)파이컴퓨터가 제공하는 중고 컴퓨터 부품 거래 플랫폼 PiCom 서비스 이용약관입니다. 서비스 이용 전 반드시 확인해 주세요.",
};

const articles = [
  { id: "article-1", number: "제1조", title: "목적 및 적용 범위" },
  { id: "article-2", number: "제2조", title: "용어의 정의" },
  { id: "article-3", number: "제3조", title: "서비스의 성격 및 회사의 책임" },
  { id: "article-4", number: "제4조", title: "물품의 발송 및 위험 부담" },
  { id: "article-5", number: "제5조", title: "검수 절차 및 데이터 삭제" },
  { id: "article-6", number: "제6조", title: "검수 중 손상에 대한 책임" },
  { id: "article-7", number: "제7조", title: "검수 불합격 및 위약금" },
  { id: "article-8", number: "제8조", title: "정산 및 대금 지급" },
  { id: "article-9", number: "제9조", title: "수수료" },
  { id: "article-10", number: "제10조", title: "유료 보증 서비스" },
  { id: "article-11", number: "제11조", title: "보관 서비스 및 물품 인도" },
  { id: "article-12", number: "제12조", title: "거래 제한 및 금지 물품" },
  { id: "article-13", number: "제13조", title: "분쟁 해결" },
  { id: "article-14", number: "제14조", title: "개인정보보호" },
  { id: "article-15", number: "제15조", title: "면책 조항" },
  { id: "article-16", number: "제16조", title: "약관의 변경" },
  { id: "article-17", number: "제17조", title: "준거법" },
];

export default function TermsPage() {
  return (
    <div className="container mx-auto max-w-4xl px-4 py-12 md:py-16">
      {/* 헤더 */}
      <div className="mb-10 text-center">
        <h1 className="text-3xl font-bold tracking-tight text-foreground md:text-4xl">
          (주)파이컴퓨터 서비스 이용약관
        </h1>
        <p className="mt-3 text-[15px] text-muted-foreground">
          중고 컴퓨터 부품 거래 플랫폼{" "}
          <span className="font-semibold text-primary">PiCom</span> 서비스
          이용에 관한 약관
        </p>
        <p className="mt-1 text-sm text-muted-foreground">
          시행일: 2025년 12월 1일
        </p>
      </div>

      {/* 목차 */}
      <nav className="mb-12 rounded-xl bg-muted/50 p-6">
        <h2 className="mb-4 text-lg font-semibold text-foreground">목차</h2>
        <ol className="grid gap-1.5 sm:grid-cols-2">
          {articles.map((article) => (
            <li key={article.id}>
              <a
                href={`#${article.id}`}
                className="inline-flex text-sm text-muted-foreground transition-colors hover:text-primary"
              >
                <span className="mr-2 font-medium text-foreground">
                  {article.number}
                </span>
                {article.title}
              </a>
            </li>
          ))}
        </ol>
      </nav>

      {/* 본문 */}
      <div className="space-y-10 text-[15px] leading-relaxed text-foreground/90">
        {/* 제1조 */}
        <section id="article-1" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제1조 (목적 및 적용 범위)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">목적:</span> 본
              약관은 주식회사 파이컴퓨터(이하 &apos;회사&apos;)가 제공하는 중고
              컴퓨터 부품 거래 플랫폼 &apos;PiCom&apos;(이하
              &apos;플랫폼&apos;)의 이용과 관련하여 회사와 이용자의 권리, 의무,
              책임 사항을 규정함을 목적으로 합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">적용 범위:</span> 본
              약관은 플랫폼을 통해 이루어지는 모든 서비스 이용에 적용되며, 회사가
              운영하는 웹사이트, 모바일 애플리케이션(앱) 등 모든 채널을
              포함합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">관련 법령:</span> 본
              약관은 「전자상거래 등에서의 소비자보호에 관한 법률」, 「약관의
              규제에 관한 법률」, 「정보통신망 이용촉진 및 정보보호 등에 관한
              법률」 등 관련 법령을 준수합니다.
            </li>
          </ol>
        </section>

        {/* 제2조 */}
        <section id="article-2" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제2조 (용어의 정의)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              &quot;이용자&quot;란 회사가 제공하는 서비스를 이용하는 모든 자를
              말하며, 물품을 판매하는 자(판매자)와 구매하는 자(구매자)를
              포함합니다.
            </li>
            <li>
              &quot;플랫폼&quot;이란 회사가 중고 부품 거래를 중개하기 위해
              제공하는 웹사이트, 모바일 앱 등 온라인 서비스를 말합니다.
            </li>
            <li>
              &quot;물품&quot;이란 거래의 대상이 되는 중고 컴퓨터 부품(CPU, GPU,
              RAM, 메인보드, 저장장치 등)을 말합니다.
            </li>
            <li>
              &quot;검수&quot;란 회사가 물품의 외관 상태, 기능 작동 여부, 스펙
              일치 여부 등을 확인하여 판매 적합성을 판정하는 절차를 말합니다.
            </li>
            <li>
              &quot;위약금&quot;이란 검수 불합격 또는 판매자의 귀책사유로 거래가
              취소될 경우 판매자가 회사에 지불해야 하는 비용을 말합니다.
            </li>
          </ol>
        </section>

        {/* 제3조 */}
        <section id="article-3" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제3조 (서비스의 성격 및 회사의 책임)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              회사는 중고 물품 거래를 위한 시스템을 제공하고 검수, 보관, 배송을
              대행하는{" "}
              <span className="font-semibold text-primary">중개자</span>입니다.
            </li>
            <li>
              회사는 판매자가 등록한 상품 정보의 부정확성이나 구매자의 단순 변심
              등 회사의 고의·과실이 없는 사유로 인한 손해에 대해서는 책임을 지지
              않습니다.
            </li>
            <li>
              단, 회사가 직접 수행한 검수 결과의 명백한 오류, 배송 중
              파손(회사가 지정한 택배사 이용 시)에 대해서는 회사가 책임을
              부담합니다.
            </li>
          </ol>
        </section>

        {/* 제4조 */}
        <section id="article-4" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제4조 (물품의 발송 및 위험 부담)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">발송 의무:</span>{" "}
              판매자는 거래 체결 통지를 받은 후 회사가 정한 기한 내에 물품을
              발송해야 합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">위험 부담:</span>{" "}
              물품이 회사의 검수 센터에 도달하기 전까지 발생한 파손, 분실 등의
              위험은 판매자가 부담합니다. 회사는 물품 수령 시 박스 개봉 영상을
              촬영하여 이를 입증 자료로 활용합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">배송비:</span> 검수
              입고를 위한 배송비는 판매자 부담을 원칙으로 합니다. 착불 발송 시
              판매자의 사전 동의를 받아 정산금에서 차감됩니다.
            </li>
          </ol>
        </section>

        {/* 제5조 */}
        <section id="article-5" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제5조 (검수 절차 및 데이터 삭제)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">검수 기준:</span>{" "}
              회사는 사전에 공지된 &apos;PiCom 검수 가이드라인&apos;에 따라
              합격/불합격을 판정합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">
                데이터 삭제 및 면책:
              </span>{" "}
              저장장치(HDD, SSD 등)의 경우, 회사는 개인정보 보호를 위해 입고 즉시
              로우 레벨 포맷(Low Level Format) 등 복구 불가능한 방법으로 데이터를
              영구 삭제합니다. 판매자는 물품 등록 시 데이터 백업은 판매자 본인의
              책임임을 확인하고, 다음 사항에 동의해야 합니다:
              <div className="mt-3 rounded-r-lg border-l-4 border-destructive bg-destructive/10 p-4">
                <ul className="list-disc space-y-1.5 pl-5">
                  <li>저장장치 내 모든 데이터가 영구 삭제됨</li>
                  <li>데이터 복구가 불가능함</li>
                  <li>데이터 삭제로 인한 손해배상을 청구하지 않음</li>
                </ul>
              </div>
              <p className="mt-2">
                회사는 물품 등록 단계에서 최소 3회 이상 데이터 삭제 안내를
                제공하며, 판매자는 별도 체크박스를 통해 이에 동의합니다.
              </p>
            </li>
            <li>
              <span className="font-semibold text-primary">소모품 간주:</span>{" "}
              써멀구리스 재도포, 먼지 제거 등은 상품화 과정의 일부로 보며, 이로
              인한 기존 상태와의 차이는 훼손으로 보지 않습니다.
            </li>
          </ol>
        </section>

        {/* 제6조 */}
        <section id="article-6" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제6조 (검수 중 손상에 대한 책임)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              판매자는 중고 부품의 특성상, 회사의 정상적인 기능 테스트(부하
              테스트, 스트레스 테스트 등) 과정에서 잠재된 불량이 발현될 수 있음을
              인지합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">
                기준점 설정:
              </span>{" "}
              회사는 물품 수령 시 개봉 영상 및 사진을 촬영하여 입고 당시의 물품
              상태를 기록합니다. 이를 검수 중 손상 판단의 기준점으로 삼습니다.
            </li>
            <li>
              <span className="font-semibold text-primary">
                회사의 책임 범위:
              </span>
              <div className="mt-3 rounded-r-lg border-l-4 border-primary bg-primary/5 p-4">
                <ul className="list-disc space-y-2 pl-5">
                  <li>
                    <span className="font-semibold text-primary">
                      고의 또는 중과실
                    </span>
                    (물품 낙하, 침수, 과전압 인가 등)로 인한 손상 →{" "}
                    <span className="font-semibold text-primary">
                      전액 배상
                    </span>
                  </li>
                  <li>
                    <span className="font-semibold text-primary">경과실</span>로
                    인한 손상 → 감가상각을 고려한 시가의{" "}
                    <span className="font-semibold text-primary">
                      70% 배상
                    </span>{" "}
                    (단, 제조일로부터 5년 경과 제품은 30% 한도)
                  </li>
                  <li>
                    정상적인 테스트 과정에서 발생한 잠재 불량의 발현 → 회사는
                    책임을 지지 않음
                  </li>
                </ul>
              </div>
              <p className="mt-3">
                <span className="font-semibold text-primary">
                  경과실 배상 제외 사항:
                </span>
              </p>
              <ul className="mt-1 list-disc space-y-1.5 pl-5">
                <li>미세한 스크래치·먼지 부착 등 외관상 경미한 변화</li>
                <li>자연적인 감모·변색·산화</li>
                <li>정상적인 작동 과정에서의 발열·소음 증가</li>
                <li>기타 중고 제품의 일반적 사용에서 예상되는 변화</li>
              </ul>
            </li>
            <li>
              <span className="font-semibold text-primary">입증 책임:</span>{" "}
              회사의 고의·과실로 인한 손상임을 주장하는 판매자는 이를
              입증해야 하며, 회사가 촬영한 입고 영상·사진과 검수 과정 기록을
              근거로 판단합니다.
            </li>
          </ol>
        </section>

        {/* 제7조 */}
        <section id="article-7" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제7조 (검수 불합격 및 위약금)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">거래 취소:</span>{" "}
              검수 불합격 시 거래는 자동 취소되며 구매자에게는 결제 대금이 전액
              환불됩니다.
            </li>
            <li>
              <span className="font-semibold text-primary">
                위약금 부과:
              </span>{" "}
              검수 불합격의 원인이 판매자에게 있는 경우(스펙 불일치, 기능 불량,
              가품 등), 판매자는 다음의 위약금을 납부해야 합니다:
              <div className="mt-3 rounded-r-lg border-l-4 border-destructive bg-destructive/10 p-4">
                <ul className="list-disc space-y-2 pl-5">
                  <li>
                    <span className="font-semibold text-primary">
                      기본 위약금:
                    </span>{" "}
                    판매 희망가의 5% 또는 실제 발생 비용(검수 인건비, 재포장비 등)
                    중 큰 금액
                  </li>
                  <li>
                    <span className="font-semibold text-primary">
                      중대 위반(가품, 허위 정보 등록):
                    </span>{" "}
                    판매 희망가의 10% (형사고발 시 별도 법적 조치)
                  </li>
                </ul>
              </div>
            </li>
            <li>
              <span className="font-semibold text-primary">반송 절차:</span>{" "}
              판매자는 검수 결과 통보일로부터{" "}
              <span className="font-semibold text-primary">60일 이내</span>에
              반송 주소를 등록하고, 위약금 및 반송 배송비를 결제해야 합니다. 60일
              이내 반송 주소를 등록하지 않은 경우, 해당 물품은 본 약관 제11조
              (보관 서비스 및 물품 인도)에 따라 처리됩니다.
            </li>
            <li>
              <span className="font-semibold text-primary">
                상계권 행사:
              </span>{" "}
              회사는 판매자에게 지급할 정산금(다른 물품의 판매 대금 등)이 있는
              경우, 판매자의 사전 동의를 받아 미납된 위약금 및 제반 비용을 우선
              차감(상계)할 수 있습니다.
            </li>
          </ol>
        </section>

        {/* 제8조 */}
        <section id="article-8" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제8조 (정산 및 대금 지급)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">정산 주기:</span>{" "}
              판매 대금은 구매자의 &apos;구매 확정&apos;일(또는 배송 완료 후 7일
              경과 시 자동 확정)로부터{" "}
              <span className="font-semibold text-primary">
                2영업일(D+2) 이내
              </span>
              에 지급합니다.
            </li>
            <li>
              <span className="font-semibold text-primary">차감 지급:</span>{" "}
              정산 시 판매 수수료, 배송비(선불 대납 시), 미납 위약금 등을 차감한
              잔액을 지급합니다.
            </li>
          </ol>
        </section>

        {/* 제9조 */}
        <section id="article-9" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제9조 (수수료)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              판매/구매 수수료는 회사의 수수료 정책에 따르며, 서비스 화면에
              명시된 요율을 적용합니다.
            </li>
            <li>
              회사는 프로모션 등에 따라 수수료를 한시적으로 감면하거나 조정할 수
              있으며, 변경 시{" "}
              <span className="font-semibold text-primary">
                30일 전 사전 고지
              </span>
              합니다.
            </li>
          </ol>
        </section>

        {/* 제10조 */}
        <section id="article-10" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제10조 (유료 보증 서비스)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">
                보증 서비스의 목적 및 적용:
              </span>{" "}
              회사는 구매자에게 유료 보증 기간 연장 서비스(&apos;보증
              서비스&apos;)를 제공할 수 있으며, 서비스의 유효 기간, 보상 범위 등
              상세한 내용은 별도의 [보증 서비스 약정]에 따릅니다.
            </li>
            <li>
              <span className="font-semibold text-primary">
                보증 서비스의 중도 해지 및 위약금:
              </span>
              <ol className="mt-2 list-[lower-alpha] space-y-2 pl-5">
                <li>
                  <span className="font-semibold text-primary">
                    해지 가능 시점:
                  </span>{" "}
                  구매자는 보증 서비스 유효 기간 중에 서비스를 중도 해지하고자
                  하는 경우, 회사에 해지를 신청할 수 있습니다.
                </li>
                <li>
                  <span className="font-semibold text-primary">
                    위약금 기준:
                  </span>{" "}
                  중도 해지 시, 회사는 서비스 이용 기간을 제외한 잔여 기간에
                  비례하여 환불하며, 환불 금액은 총 결제 금액에서 (기이용 기간에
                  해당하는 금액 + 총 결제 금액의 10% 이내의 위약금)을 공제하여
                  산정합니다.
                </li>
                <li>
                  <span className="font-semibold text-primary">
                    혜택 이용 시 해지 제한:
                  </span>{" "}
                  보증 서비스를 이미 이용하여 수리 또는 교환 서비스를 1회 이상
                  제공받은 경우에는 원칙적으로 중도 해지로 인한 환불이 불가합니다.
                </li>
              </ol>
            </li>
            <li>
              <span className="font-semibold text-primary">
                보증 서비스의 환불:
              </span>{" "}
              보증 서비스의 환불에 관한 세부 사항은 [환불 및 반품 정책] 제10조를
              따릅니다.
            </li>
          </ol>
        </section>

        {/* 제11조 */}
        <section id="article-11" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제11조 (보관 서비스 및 물품 인도)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">
                보관 기간 및 종료:
              </span>
              <ol className="mt-2 list-[lower-alpha] space-y-2 pl-5">
                <li>
                  물품의 보관 기간은 구매 결제 완료일 또는 보관 시작일로부터{" "}
                  <span className="font-semibold text-primary">최대 30일</span>
                  로 합니다.
                </li>
                <li>
                  30일 경과 시, 회사는 보관 서비스 계약을 종료하고 구매자에게 해당
                  물품을 강제 배송하며, 구매자는 이에 따른 배송 및 보관 수수료를
                  즉시 정산해야 합니다.
                </li>
              </ol>
            </li>
            <li>
              <span className="font-semibold text-primary">
                보관 수수료의 청구 및 납부 의무:
              </span>
              <ol className="mt-2 list-[lower-alpha] space-y-2 pl-5">
                <li>
                  보관 서비스 종료 시점에 회사는 최종 보관 수수료를 산정하여
                  구매자에게 청구하며, 구매자는 청구일로부터{" "}
                  <span className="font-semibold text-primary">
                    7일 이내에 전액을 납부
                  </span>
                  할 의무가 있습니다.
                </li>
                <li>
                  <span className="font-semibold text-primary">
                    거래 및 물품 최종 정산 기한:
                  </span>{" "}
                  물품 구매 결제일로부터 37일을 해당 거래 및 물품 인도의 최종 정산
                  및 종결 마감 기한으로 설정합니다.
                </li>
              </ol>
            </li>
            <li>
              <span className="font-semibold text-primary">
                수수료 미납 시 물품 인도 거절 및 긴급 처분 조치:
              </span>
              <ol className="mt-2 list-[lower-alpha] space-y-2 pl-5">
                <li>
                  <span className="font-semibold text-primary">
                    인도 거절 (유치권 행사):
                  </span>{" "}
                  미납 시 민법 제320조에 따른 유치권에 근거하여 물품의 배송 및
                  인도를 거절할 수 있습니다.
                </li>
                <li>
                  <span className="font-semibold text-primary">
                    긴급 처분 (37일 강제 종결):
                  </span>{" "}
                  최종 통지 기한까지 미납액을 변제하지 않을 경우, 회사는 물품을
                  매각(처분)할 수 있으며, 매각 후 잔액은 구매자에게 반환됩니다.
                </li>
              </ol>
            </li>
            <li>
              <span className="font-semibold text-primary">
                보관 수수료의 환불:
              </span>{" "}
              보관 수수료의 환불 및 정산에 관한 세부 사항은 [환불 및 반품 정책]
              제12조를 따릅니다.
            </li>
          </ol>
        </section>

        {/* 제12조 */}
        <section id="article-12" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제12조 (거래 제한 및 금지 물품)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              <span className="font-semibold text-primary">
                미성년자 거래:
              </span>{" "}
              만 19세 미만의 미성년자는 법정대리인의 동의 없이 거래할 수 없으며,
              동의 없이 체결된 계약은 법정대리인이 취소할 수 있습니다.
            </li>
            <li>
              <span className="font-semibold text-primary">금지 물품:</span>
              <ul className="mt-2 list-disc space-y-1.5 pl-5">
                <li>불법 복제품·도난품·위조품</li>
                <li>법령에 의해 거래가 금지된 물품</li>
                <li>타인의 지적재산권을 침해하는 물품</li>
                <li>기타 회사가 거래 부적합으로 판단한 물품</li>
              </ul>
            </li>
          </ol>
        </section>

        {/* 제13조 */}
        <section id="article-13" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제13조 (분쟁 해결)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              회사와 이용자 간에 발생한 분쟁은 상호 협의하여 해결함을 원칙으로
              합니다.
            </li>
            <li>
              협의가 되지 않을 경우, 한국소비자원 또는
              전자거래분쟁조정위원회에 조정을 신청할 수 있습니다.
            </li>
            <li>
              조정으로도 해결되지 않아 소송이 제기되는 경우,{" "}
              <span className="font-semibold text-primary">
                서울중앙지방법원
              </span>{" "}
              또는 민사소송법상의 관할 법원을 1심 관할 법원으로 합니다.
            </li>
          </ol>
        </section>

        {/* 제14조 */}
        <section id="article-14" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제14조 (개인정보보호)
          </h2>
          <p className="text-foreground/80">
            회사는 &apos;개인정보보호법&apos; 등 관계 법령이 정하는 바에 따라
            이용자의 개인정보를 보호합니다. 개인정보의 수집, 이용, 제공 등에 관한
            세부 사항은 회사의 웹사이트에 게시된 [개인정보처리방침]에 따릅니다.
          </p>
        </section>

        {/* 제15조 */}
        <section id="article-15" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제15조 (면책 조항)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              회사는 천재지변, 전쟁, 디도스(DDoS) 공격, 기간통신사업자의 서비스
              중지 등 불가항력적인 사유로 서비스를 제공할 수 없는 경우 책임이
              면제됩니다.
            </li>
            <li>
              회사는 이용자 간의 직거래(회사의 결제 시스템을 통하지 않은 거래)로
              인해 발생한 문제에 대해서는 일체의 책임을 지지 않습니다.
            </li>
          </ol>
        </section>

        {/* 제16조 */}
        <section id="article-16" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제16조 (약관의 변경)
          </h2>
          <ol className="list-decimal space-y-3 pl-5 text-foreground/80">
            <li>
              회사는 필요한 경우 관계 법령을 위배하지 않는 범위에서 본 약관을
              변경할 수 있습니다.
            </li>
            <li>
              약관이 변경되는 경우, 회사는 변경사항을 적용일자{" "}
              <span className="font-semibold text-primary">30일 전</span>부터
              서비스 초기화면 또는 공지사항을 통해 공지합니다.
            </li>
            <li>
              이용자가 변경된 약관에 동의하지 않을 경우, 서비스 이용을 중단하고
              이용계약을 해지할 수 있습니다.
            </li>
          </ol>
        </section>

        {/* 제17조 */}
        <section id="article-17" className="scroll-mt-24 space-y-4">
          <h2 className="text-xl font-semibold text-foreground">
            제17조 (준거법)
          </h2>
          <p className="text-foreground/80">
            본 약관은 대한민국 법령에 따라 규율되고 해석됩니다.
          </p>
        </section>

        {/* 부칙 */}
        <section className="border-t border-border pt-6">
          <div className="rounded-r-lg border-l-4 border-primary bg-primary/5 p-4">
            <p className="font-semibold text-foreground">부칙</p>
            <p className="mt-1 text-foreground/80">
              본 약관은{" "}
              <span className="font-semibold text-primary">
                2025년 12월 1일
              </span>
              부터 시행됩니다.
            </p>
          </div>
        </section>

        {/* 사업자 정보 */}
        <section className="pt-4">
          <Card className="bg-muted/50">
            <CardHeader>
              <CardTitle className="text-lg">사업자 정보</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid gap-3 sm:grid-cols-2">
                <div>
                  <dt className="text-sm font-medium text-muted-foreground">
                    상호
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    (주) 파이컴퓨터
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-muted-foreground">
                    대표자
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    최진규
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-muted-foreground">
                    사업자등록번호
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    207-87-03690
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-muted-foreground">
                    통신판매업 신고번호
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    2025-서울서대문-1006
                  </dd>
                </div>
                <div className="sm:col-span-2">
                  <dt className="text-sm font-medium text-muted-foreground">
                    주소
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    서울특별시 서대문구 연세로2나길 61
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-muted-foreground">
                    대표전화
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    02-6402-0025
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-muted-foreground">
                    이메일
                  </dt>
                  <dd className="mt-0.5 text-[15px] text-foreground">
                    wlsrb00g@gmail.com
                  </dd>
                </div>
              </dl>
            </CardContent>
          </Card>
        </section>
      </div>
    </div>
  );
}

import type { Metadata } from "next";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export const metadata: Metadata = {
  title: "개인정보처리방침 | PiCom",
  description:
    "PiCom의 개인정보처리방침입니다. 이용자의 개인정보가 어떻게 수집, 이용, 보호되는지 안내합니다.",
};

export default function PrivacyPage() {
  return (
    <div className="container mx-auto max-w-3xl px-4 py-12 md:py-16">
      <p className="text-sm text-muted-foreground mb-6">
        시행일: 2025년 12월 1일
      </p>

      <h1 className="text-3xl font-bold tracking-tight text-foreground mb-2">
        개인정보처리방침
      </h1>
      <p className="text-lg text-emerald-600 font-medium mb-8">
        (주)파이컴퓨터 개인정보처리방침
      </p>

      {/* 목차 */}
      <nav className="bg-muted/50 rounded-xl p-6 mb-10">
        <h2 className="text-lg font-semibold text-foreground mb-4">목차</h2>
        <ol className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm text-foreground/80">
          <li>
            <a href="#article-1" className="hover:text-primary transition-colors">
              제1조 개인정보의 처리 목적
            </a>
          </li>
          <li>
            <a href="#article-2" className="hover:text-primary transition-colors">
              제2조 처리하는 개인정보 항목
            </a>
          </li>
          <li>
            <a href="#article-3" className="hover:text-primary transition-colors">
              제3조 개인정보의 처리 및 보유기간
            </a>
          </li>
          <li>
            <a href="#article-4" className="hover:text-primary transition-colors">
              제4조 개인정보의 제3자 제공
            </a>
          </li>
          <li>
            <a href="#article-5" className="hover:text-primary transition-colors">
              제5조 개인정보처리의 위탁
            </a>
          </li>
          <li>
            <a href="#article-6" className="hover:text-primary transition-colors">
              제6조 이용자 및 법정대리인의 권리와 그 행사방법
            </a>
          </li>
          <li>
            <a href="#article-7" className="hover:text-primary transition-colors">
              제7조 개인정보의 파기
            </a>
          </li>
          <li>
            <a href="#article-8" className="hover:text-primary transition-colors">
              제8조 개인정보의 안전성 확보 조치
            </a>
          </li>
          <li>
            <a href="#article-9" className="hover:text-primary transition-colors">
              제9조 개인정보 자동 수집 장치의 설치·운영 및 거부
            </a>
          </li>
          <li>
            <a href="#article-10" className="hover:text-primary transition-colors">
              제10조 개인정보 보호책임자
            </a>
          </li>
          <li>
            <a href="#article-11" className="hover:text-primary transition-colors">
              제11조 개인정보 처리방침의 변경
            </a>
          </li>
          <li>
            <a href="#article-12" className="hover:text-primary transition-colors">
              제12조 이용자의 의무
            </a>
          </li>
        </ol>
      </nav>

      <div className="space-y-10 text-[15px] leading-relaxed text-foreground/90">
        {/* 제1조 */}
        <section id="article-1" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제1조 (개인정보의 처리 목적)
          </h2>
          <p>
            회사는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는
            개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이
            변경되는 경우에는 「개인정보 보호법」 제18조에 따라 별도의 동의를 받는
            등 필요한 조치를 이행할 예정입니다.
          </p>
          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-foreground mb-1">
                1. 회원 가입 및 관리
              </h3>
              <p className="text-foreground/80 ml-4">
                회원 가입의사 확인, 회원자격 유지 및 관리, 본인확인 및 본인인증,
                부정이용 방지 및 비인가 사용 방지, 만 14세 미만 아동의 개인정보
                처리 시 법정대리인의 동의 여부 확인, 각종 고지 및 통지
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                2. 서비스 제공
              </h3>
              <p className="text-foreground/80 ml-4">
                컴퓨터 부품 시세 조회 서비스 제공, 부품 판매·구매 중개 서비스
                제공, 완성PC 판매 요청 및 매칭 서비스 제공, 보관 및 배송 서비스
                제공, 가격 알림 및 맞춤형 서비스 제공, 본인인증 및 연령확인
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                3. 대금 결제, 배송 및 환불
              </h3>
              <p className="text-foreground/80 ml-4">
                상품 구매에 대한 요금 결제 및 정산, 상품 및 부품 배송, 환불 처리
                및 본인 확인, 결제 및 환불 관련 분쟁 해결
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                4. 거래 안전성 확보
              </h3>
              <p className="text-foreground/80 ml-4">
                부정거래 방지 및 거래 분쟁 조정, 판매자/구매자 평가 및 신뢰도
                관리, 서비스 부정이용 방지
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                5. 고충처리 및 민원처리
              </h3>
              <p className="text-foreground/80 ml-4">
                민원인의 신원 확인, 민원사항 확인 및 사실조사, 처리결과 통보
              </p>
            </div>
          </div>
        </section>

        {/* 제2조 */}
        <section id="article-2" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제2조 (처리하는 개인정보 항목)
          </h2>
          <p>
            회사는 서비스 제공을 위하여 다음과 같은 개인정보 항목을 처리하고
            있습니다.
          </p>
          <div className="overflow-x-auto">
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="bg-muted/70">
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    구분
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    수집 항목
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    수집 목적
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    보유기간
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">
                    필수항목 (이메일 가입)
                  </td>
                  <td className="border border-border px-3 py-2">
                    이메일, 비밀번호, 닉네임
                  </td>
                  <td className="border border-border px-3 py-2">
                    회원 가입 및 본인확인, 서비스 제공, 고지사항 전달
                  </td>
                  <td className="border border-border px-3 py-2">
                    회원 탈퇴 시까지
                  </td>
                </tr>
                <tr className="bg-muted/30">
                  <td className="border border-border px-3 py-2">
                    필수항목 (카카오 로그인)
                  </td>
                  <td className="border border-border px-3 py-2">
                    카카오 계정 이메일, 닉네임, 프로필 사진
                  </td>
                  <td className="border border-border px-3 py-2">
                    간편 로그인, 회원 가입 및 본인확인, 서비스 제공
                  </td>
                  <td className="border border-border px-3 py-2">
                    회원 탈퇴 시까지
                  </td>
                </tr>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">선택항목</td>
                  <td className="border border-border px-3 py-2">
                    배송지 주소, 수령인 이름, 전화번호
                  </td>
                  <td className="border border-border px-3 py-2">
                    상품 배송, 배송 관련 연락
                  </td>
                  <td className="border border-border px-3 py-2">
                    회원 탈퇴 시 또는 삭제 요청 시까지
                  </td>
                </tr>
                <tr className="bg-muted/30">
                  <td className="border border-border px-3 py-2">거래 시</td>
                  <td className="border border-border px-3 py-2">
                    상품 이미지, 판매/구매 내역, 거래 정보
                  </td>
                  <td className="border border-border px-3 py-2">
                    중개 서비스 제공, 거래 안전성 확보
                  </td>
                  <td className="border border-border px-3 py-2">
                    거래 완료 후 5년 (전자상거래법)
                  </td>
                </tr>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">환불 시</td>
                  <td className="border border-border px-3 py-2">
                    환불 계좌번호, 예금주명
                  </td>
                  <td className="border border-border px-3 py-2">
                    환불 처리
                  </td>
                  <td className="border border-border px-3 py-2">
                    환불 완료 후 5년 (전자상거래법)
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <h3 className="font-medium text-foreground mb-2">
              자동 수집 정보
            </h3>
            <ul className="list-disc list-inside space-y-1 text-foreground/80">
              <li>
                서비스 이용 기록: 접속 로그, 접속 IP 정보, 쿠키, 서비스 이용
                기록, 방문 기록
              </li>
              <li>기기 정보: 기기 식별번호, OS 버전, 앱 버전</li>
              <li>보유기간: 수집일로부터 3년</li>
            </ul>
          </div>
        </section>

        {/* 제3조 */}
        <section id="article-3" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제3조 (개인정보의 처리 및 보유기간)
          </h2>
          <p>
            회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터
            개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서
            개인정보를 처리·보유합니다. 각각의 개인정보 처리 및 보유 기간은
            다음과 같습니다.
          </p>
          <div className="overflow-x-auto">
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="bg-muted/70">
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    보존 항목
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    근거 법령
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    보존 기간
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">
                    계약 또는 청약철회 등에 관한 기록
                  </td>
                  <td className="border border-border px-3 py-2">
                    전자상거래법
                  </td>
                  <td className="border border-border px-3 py-2">5년</td>
                </tr>
                <tr className="bg-muted/30">
                  <td className="border border-border px-3 py-2">
                    대금결제 및 재화 등의 공급에 관한 기록
                  </td>
                  <td className="border border-border px-3 py-2">
                    전자상거래법
                  </td>
                  <td className="border border-border px-3 py-2">5년</td>
                </tr>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">
                    소비자 불만 또는 분쟁처리에 관한 기록
                  </td>
                  <td className="border border-border px-3 py-2">
                    전자상거래법
                  </td>
                  <td className="border border-border px-3 py-2">3년</td>
                </tr>
                <tr className="bg-muted/30">
                  <td className="border border-border px-3 py-2">
                    표시·광고에 관한 기록
                  </td>
                  <td className="border border-border px-3 py-2">
                    전자상거래법
                  </td>
                  <td className="border border-border px-3 py-2">6개월</td>
                </tr>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">
                    서비스 방문 기록
                  </td>
                  <td className="border border-border px-3 py-2">
                    통신비밀보호법
                  </td>
                  <td className="border border-border px-3 py-2">3개월</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        {/* 제4조 */}
        <section id="article-4" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제4조 (개인정보의 제3자 제공)
          </h2>
          <p>
            회사는 정보주체의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한
            범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등
            「개인정보 보호법」 제17조 및 제18조에 해당하는 경우에만 개인정보를
            제3자에게 제공합니다.
          </p>
          <div className="overflow-x-auto">
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="bg-muted/70">
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    제공받는 자
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    제공 목적
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    제공 항목
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    보유기간
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">카카오페이</td>
                  <td className="border border-border px-3 py-2">
                    결제 처리 및 정산
                  </td>
                  <td className="border border-border px-3 py-2">
                    결제 정보 (상품명, 금액, 구매자 정보 등)
                  </td>
                  <td className="border border-border px-3 py-2">
                    거래 완료 후 5년
                  </td>
                </tr>
                <tr className="bg-muted/30">
                  <td className="border border-border px-3 py-2">
                    토스페이먼츠
                  </td>
                  <td className="border border-border px-3 py-2">
                    결제 처리 및 정산
                  </td>
                  <td className="border border-border px-3 py-2">
                    결제 정보 (상품명, 금액, 구매자 정보 등)
                  </td>
                  <td className="border border-border px-3 py-2">
                    거래 완료 후 5년
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        {/* 제5조 */}
        <section id="article-5" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제5조 (개인정보처리의 위탁)
          </h2>
          <p>
            회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보
            처리업무를 위탁하고 있습니다.
          </p>
          <div className="overflow-x-auto">
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="bg-muted/70">
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    수탁업체
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    위탁 업무 내용
                  </th>
                  <th className="border border-border px-3 py-2 text-left font-semibold">
                    보유기간
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">
                    Google LLC (Firebase)
                  </td>
                  <td className="border border-border px-3 py-2">
                    회원 인증 (Firebase Auth), 데이터베이스 관리 (Firestore),
                    파일 저장 (Firebase Storage), 서버 인프라 제공
                  </td>
                  <td className="border border-border px-3 py-2">
                    위탁계약 종료 시 또는 회원 탈퇴 시까지
                  </td>
                </tr>
                <tr className="bg-muted/30">
                  <td className="border border-border px-3 py-2">카카오페이</td>
                  <td className="border border-border px-3 py-2">
                    결제 처리 및 정산
                  </td>
                  <td className="border border-border px-3 py-2">
                    거래 완료 후 5년
                  </td>
                </tr>
                <tr className="bg-background">
                  <td className="border border-border px-3 py-2">
                    토스페이먼츠
                  </td>
                  <td className="border border-border px-3 py-2">
                    결제 처리 및 정산
                  </td>
                  <td className="border border-border px-3 py-2">
                    거래 완료 후 5년
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <p className="text-foreground/80">
              위탁계약 시 개인정보보호 관련 법규의 준수, 개인정보에 관한 비밀유지,
              제3자 제공 금지 및 사고 시의 책임부담, 위탁기간, 처리 종료 후의
              개인정보의 반환 또는 파기 등을 명확히 규정하고 있으며, 수탁업체가
              개인정보를 안전하게 처리하는지를 감독하고 있습니다.
            </p>
          </div>
        </section>

        {/* 제6조 */}
        <section id="article-6" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제6조 (이용자 및 법정대리인의 권리와 그 행사방법)
          </h2>
          <p>
            이용자(만 14세 미만인 경우에는 법정대리인을 말합니다)는 회사에 대해
            언제든지 개인정보 보호 관련 권리를 행사할 수 있습니다.
          </p>
          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-foreground mb-2">
                권리의 종류
              </h3>
              <ul className="list-disc list-inside space-y-1.5 text-foreground/80 ml-2">
                <li>개인정보 열람 요구</li>
                <li>개인정보 정정·삭제 요구</li>
                <li>개인정보 처리정지 요구</li>
                <li>개인정보 전송 요구</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-2">
                권리 행사 방법
              </h3>
              <ul className="list-disc list-inside space-y-1.5 text-foreground/80 ml-2">
                <li>서면 요청</li>
                <li>
                  이메일:{" "}
                  <a
                    href="mailto:wlsrb00g@gmail.com"
                    className="text-primary hover:underline"
                  >
                    wlsrb00g@gmail.com
                  </a>
                </li>
                <li>
                  전화:{" "}
                  <a
                    href="tel:02-6402-0025"
                    className="text-primary hover:underline"
                  >
                    02-6402-0025
                  </a>
                </li>
                <li>앱 내 마이페이지 &gt; 설정 메뉴</li>
              </ul>
            </div>
          </div>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <p className="text-foreground/80">
              권리 행사는 「개인정보 보호법」 시행령 제41조 제1항에 따라
              서면, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며,
              회사는 이에 대해 지체 없이 조치하겠습니다. 정보주체가 개인정보의
              오류 등에 대한 정정 또는 삭제를 요구한 경우에는 정정 또는 삭제를
              완료할 때까지 당해 개인정보를 이용하거나 제공하지 않습니다.
            </p>
          </div>
        </section>

        {/* 제7조 */}
        <section id="article-7" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제7조 (개인정보의 파기)
          </h2>
          <p>
            회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가
            불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.
          </p>
          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-foreground mb-1">
                1. 파기 절차
              </h3>
              <p className="text-foreground/80 ml-4">
                이용자가 입력한 정보는 목적 달성 후 별도의 DB에 옮겨져(종이의
                경우 별도의 서류) 내부 방침 및 기타 관련 법령에 따라 일정기간
                저장된 후 혹은 즉시 파기됩니다. 이때, DB로 옮겨진 개인정보는
                법률에 의한 경우가 아니고서는 다른 목적으로 이용되지 않습니다.
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                2. 파기 기한
              </h3>
              <p className="text-foreground/80 ml-4">
                이용자의 개인정보는 개인정보의 보유기간이 경과된 경우에는
                보유기간의 종료일로부터 5일 이내에, 개인정보의 처리 목적 달성,
                해당 서비스의 폐지, 사업의 종료 등 그 개인정보가 불필요하게 된
                경우에는 개인정보의 처리가 불필요한 것으로 인정되는 날로부터 5일
                이내에 그 개인정보를 파기합니다.
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                3. 파기 방법
              </h3>
              <ul className="list-disc list-inside space-y-1.5 text-foreground/80 ml-4">
                <li>
                  전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을
                  사용하여 복구 불가능하게 삭제합니다.
                </li>
                <li>
                  종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각을 통하여
                  파기합니다.
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* 제8조 */}
        <section id="article-8" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제8조 (개인정보의 안전성 확보 조치)
          </h2>
          <p>
            회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고
            있습니다.
          </p>
          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-foreground mb-1">
                1. 관리적 조치
              </h3>
              <ul className="list-disc list-inside space-y-1 text-foreground/80 ml-4">
                <li>내부 관리계획 수립 및 시행</li>
                <li>개인정보 취급 직원의 최소화 및 교육</li>
                <li>정기적인 자체 감사 실시</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                2. 기술적 조치
              </h3>
              <ul className="list-disc list-inside space-y-1 text-foreground/80 ml-4">
                <li>개인정보의 암호화 (비밀번호 등 중요 정보 암호화 저장)</li>
                <li>해킹 등에 대비한 기술적 대책 (보안프로그램 설치 및 갱신)</li>
                <li>개인정보에 대한 접근 권한 제한 및 관리</li>
                <li>접근통제시스템 설치 및 접속기록의 보관 및 위변조 방지</li>
              </ul>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                3. 물리적 조치
              </h3>
              <ul className="list-disc list-inside space-y-1 text-foreground/80 ml-4">
                <li>
                  전산실, 자료보관실 등에 대한 접근 통제 및 출입 관리 절차 수립·
                  운영
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* 제9조 */}
        <section id="article-9" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제9조 (개인정보 자동 수집 장치의 설치·운영 및 거부)
          </h2>
          <p>
            회사는 이용자에게 개별적인 맞춤 서비스를 제공하기 위해 이용 정보를
            저장하고 수시로 불러오는 &apos;쿠키(Cookie)&apos;를 사용합니다.
          </p>
          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-foreground mb-1">
                1. 쿠키 사용 목적
              </h3>
              <p className="text-foreground/80 ml-4">
                이용자가 방문한 각 서비스와 웹사이트들에 대한 방문 및 이용 형태,
                인기 검색어, 보안접속 여부 등을 파악하여 이용자에게 최적화된 정보
                제공을 위해 사용됩니다.
              </p>
            </div>
            <div>
              <h3 className="font-medium text-foreground mb-1">
                2. 쿠키 설치·운영 및 거부 방법
              </h3>
              <p className="text-foreground/80 ml-4 mb-2">
                이용자는 쿠키 설치에 대한 선택권을 가지고 있습니다. 웹 브라우저
                옵션에서 쿠키 허용, 쿠키 차단 등의 설정을 할 수 있습니다.
              </p>
              <ul className="list-disc list-inside space-y-1 text-foreground/80 ml-4">
                <li>Chrome: 설정 &gt; 개인정보 및 보안 &gt; 쿠키 및 기타 사이트 데이터</li>
                <li>Safari: 환경설정 &gt; 개인정보 보호 &gt; 쿠키 및 웹사이트 데이터 관리</li>
                <li>Firefox: 설정 &gt; 개인정보 및 보안 &gt; 쿠키 및 사이트 데이터</li>
                <li>Edge: 설정 &gt; 쿠키 및 사이트 권한 &gt; 쿠키 및 사이트 데이터</li>
              </ul>
            </div>
          </div>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <p className="text-foreground/80">
              쿠키 저장을 거부할 경우 맞춤형 서비스 이용에 어려움이 발생할 수
              있습니다.
            </p>
          </div>
        </section>

        {/* 제10조 */}
        <section id="article-10" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제10조 (개인정보 보호책임자)
          </h2>
          <p>
            회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보
            처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와
            같이 개인정보 보호책임자를 지정하고 있습니다.
          </p>

          <Card>
            <CardHeader>
              <CardTitle>개인정보 보호책임자</CardTitle>
            </CardHeader>
            <CardContent className="space-y-1 text-sm text-foreground/80">
              <p>성명: 최진규</p>
              <p>직책: 대표이사</p>
              <p>
                연락처: 02-6402-0025 /{" "}
                <a
                  href="mailto:wlsrb00g@gmail.com"
                  className="text-primary hover:underline"
                >
                  wlsrb00g@gmail.com
                </a>
              </p>
              <p className="pt-2">담당부서: 고객지원팀</p>
            </CardContent>
          </Card>

          <p className="text-foreground/80">
            정보주체는 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호
            관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자
            및 담당부서로 문의하실 수 있습니다. 회사는 정보주체의 문의에 대해
            지체 없이 답변 및 처리해 드리겠습니다.
          </p>

          <Card>
            <CardHeader>
              <CardTitle>개인정보 침해 관련 외부 기관</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm text-foreground/80">
              <div>
                <p className="font-medium text-foreground">
                  개인정보침해신고센터 (한국인터넷진흥원 운영)
                </p>
                <p>전화: 118 (국번없이)</p>
                <p>
                  홈페이지:{" "}
                  <a
                    href="https://privacy.kisa.or.kr"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    privacy.kisa.or.kr
                  </a>
                </p>
              </div>
              <div>
                <p className="font-medium text-foreground">
                  대검찰청 사이버범죄수사단
                </p>
                <p>전화: 1301 (국번없이)</p>
                <p>
                  홈페이지:{" "}
                  <a
                    href="https://www.spo.go.kr"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    www.spo.go.kr
                  </a>
                </p>
              </div>
              <div>
                <p className="font-medium text-foreground">
                  경찰청 사이버안전국
                </p>
                <p>전화: 182 (국번없이)</p>
                <p>
                  홈페이지:{" "}
                  <a
                    href="https://cyberbureau.police.go.kr"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    cyberbureau.police.go.kr
                  </a>
                </p>
              </div>
            </CardContent>
          </Card>
        </section>

        {/* 제11조 */}
        <section id="article-11" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제11조 (개인정보 처리방침의 변경)
          </h2>
          <p>
            이 개인정보처리방침은 2025년 12월 1일부터 적용됩니다.
          </p>
          <div className="bg-primary/5 border-l-4 border-primary p-4 rounded-r-lg">
            <p className="text-foreground/80">
              개인정보처리방침 내용의 추가, 삭제 및 수정이 있을 경우에는 변경사항의
              시행 7일 전부터 서비스 공지사항을 통하여 고지할 것입니다. 다만,
              개인정보의 수집 및 활용, 제3자 제공 등과 같이 이용자 권리의 중요한
              변경이 있을 경우에는 최소 30일 전에 고지합니다.
            </p>
          </div>
        </section>

        {/* 제12조 */}
        <section id="article-12" className="space-y-3">
          <h2 className="text-xl font-semibold text-foreground">
            제12조 (이용자의 의무)
          </h2>
          <p>
            이용자는 자신의 개인정보를 보호할 의무가 있으며, 회사의 귀책사유가
            없이 이용자 본인의 부주의나 인터넷상의 문제로 개인정보가 유출되어
            발생한 문제에 대해 회사는 일체의 책임을 지지 않습니다.
          </p>
          <ul className="list-disc list-inside space-y-1.5 text-foreground/80 ml-2">
            <li>
              이용자는 자신의 개인정보를 최신의 상태로 유지해야 하며, 부정확한
              정보 입력으로 발생하는 문제의 책임은 이용자 자신에게 있습니다.
            </li>
            <li>
              이용자는 아이디 및 비밀번호 등에 대한 보안을 유지할 책임이 있으며,
              제3자에게 이를 양도하거나 대여할 수 없습니다.
            </li>
            <li>
              이용자는 회사의 개인정보 보호정책에 따라 보안을 위한 주기적인
              활동에 협조할 의무가 있습니다.
            </li>
            <li>
              이용자는 「개인정보 보호법」 등 관계 법령을 준수하여야 합니다.
            </li>
          </ul>
        </section>

        {/* 부칙 */}
        <section className="pt-4 border-t border-border space-y-3">
          <h2 className="text-xl font-semibold text-foreground">부칙</h2>
          <p className="text-foreground/80">
            이 개인정보처리방침은 2025년 12월 1일부터 시행합니다.
          </p>
        </section>

        {/* 사업자 정보 */}
        <Card className="bg-muted/30">
          <CardHeader>
            <CardTitle>사업자 정보</CardTitle>
          </CardHeader>
          <CardContent className="space-y-1 text-sm text-foreground/80">
            <p>상호: (주)파이컴퓨터</p>
            <p>대표이사: 최진규</p>
            <p>사업자등록번호: 207-87-03690</p>
            <p>통신판매업신고번호: 2025-서울서대문-1006</p>
            <p>주소: 서울특별시 서대문구 연세로2나길 61</p>
            <p>
              전화:{" "}
              <a
                href="tel:02-6402-0025"
                className="text-primary hover:underline"
              >
                02-6402-0025
              </a>
            </p>
            <p>
              이메일:{" "}
              <a
                href="mailto:wlsrb00g@gmail.com"
                className="text-primary hover:underline"
              >
                wlsrb00g@gmail.com
              </a>
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

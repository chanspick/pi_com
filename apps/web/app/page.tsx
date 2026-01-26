import { Shield, QrCode, Wrench, CheckCircle } from "lucide-react";

export default function HomePage() {
  return (
    <div className="container mx-auto px-4 py-12">
      {/* Hero Section */}
      <div className="text-center mb-16">
        <Shield className="h-16 w-16 text-blue-600 mx-auto mb-4" />
        <h1 className="text-3xl font-bold mb-4">
          PiComputer AS 보증 서비스
        </h1>
        <p className="text-lg text-gray-500 max-w-xl mx-auto">
          검증된 부품의 안심 보증 서비스를 제공합니다.
          QR 코드를 스캔하여 간편하게 AS 보증에 가입하세요.
        </p>
      </div>

      {/* Features */}
      <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
        <div className="text-center p-6">
          <div className="w-12 h-12 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
            <QrCode className="h-6 w-6 text-blue-600" />
          </div>
          <h3 className="font-semibold mb-2">QR 코드 스캔</h3>
          <p className="text-sm text-gray-500">
            부품에 포함된 QR 코드를 스캔하여 검증 정보를 확인하세요.
          </p>
        </div>

        <div className="text-center p-6">
          <div className="w-12 h-12 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
            <Shield className="h-6 w-6 text-blue-600" />
          </div>
          <h3 className="font-semibold mb-2">보증 가입</h3>
          <p className="text-sm text-gray-500">
            1년 또는 2년 보증 플랜을 선택하고 간편하게 결제하세요.
          </p>
        </div>

        <div className="text-center p-6">
          <div className="w-12 h-12 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
            <Wrench className="h-6 w-6 text-blue-600" />
          </div>
          <h3 className="font-semibold mb-2">AS 신청</h3>
          <p className="text-sm text-gray-500">
            문제 발생 시 온라인으로 쉽게 AS를 신청하세요.
          </p>
        </div>
      </div>

      {/* Benefits */}
      <div className="mt-16 bg-gray-50 rounded-2xl p-8 max-w-2xl mx-auto">
        <h2 className="text-xl font-semibold mb-6 text-center">보증 혜택</h2>
        <div className="space-y-4">
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-green-500 mt-0.5" />
            <div>
              <h4 className="font-medium">무상 수리 서비스</h4>
              <p className="text-sm text-gray-500">
                보증 기간 내 고장 시 무상으로 수리해 드립니다.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-green-500 mt-0.5" />
            <div>
              <h4 className="font-medium">부품 교환 서비스</h4>
              <p className="text-sm text-gray-500">
                수리가 불가능한 경우 동급 부품으로 교환해 드립니다.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-green-500 mt-0.5" />
            <div>
              <h4 className="font-medium">우선 점검 서비스</h4>
              <p className="text-sm text-gray-500">
                보증 가입 고객에게 우선적으로 점검 서비스를 제공합니다.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* CTA */}
      <div className="mt-16 text-center">
        <p className="text-gray-500">
          부품과 함께 제공된 검증 레포트의 QR 코드를 스캔하여 시작하세요.
        </p>
      </div>
    </div>
  );
}

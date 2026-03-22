import { useState } from "react";

const colors = {
  primary: {
    50: "#EFF6FF",
    100: "#DBEAFE",
    200: "#BFDBFE",
    300: "#93C5FD",
    400: "#60A5FA",
    500: "#3B82F6",
    600: "#2563EB",
    700: "#1D4ED8",
    800: "#1E3A5F",
    900: "#0F172A",
  },
  success: { light: "#ECFDF5", main: "#059669", dark: "#047857" },
  warning: { light: "#FFFBEB", main: "#D97706", dark: "#B45309" },
  error: { light: "#FEF2F2", main: "#DC2626", dark: "#B91C1C" },
  gray: {
    50: "#F8FAFC",
    100: "#F1F5F9",
    200: "#E2E8F0",
    300: "#CBD5E1",
    400: "#94A3B8",
    500: "#64748B",
    600: "#475569",
    700: "#334155",
    800: "#1E293B",
    900: "#0F172A",
  },
};

const Section = ({ title, subtitle, children }) => (
  <section style={{ marginBottom: 56 }}>
    <div style={{ marginBottom: 24 }}>
      <h2
        style={{
          fontSize: 13,
          fontWeight: 600,
          letterSpacing: "0.08em",
          textTransform: "uppercase",
          color: colors.primary[600],
          marginBottom: 4,
          fontFamily: "'Pretendard', sans-serif",
        }}
      >
        {title}
      </h2>
      {subtitle && (
        <p
          style={{
            fontSize: 14,
            color: colors.gray[400],
            fontFamily: "'Pretendard', sans-serif",
          }}
        >
          {subtitle}
        </p>
      )}
    </div>
    {children}
  </section>
);

const Swatch = ({ color, name, hex, large }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
    <div
      style={{
        width: large ? 80 : 56,
        height: large ? 56 : 40,
        borderRadius: 10,
        backgroundColor: hex,
        border: hex === "#F8FAFC" || hex === "#F1F5F9" || hex === "#FFFFFF" ? "1px solid #E2E8F0" : "none",
        boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
      }}
    />
    <div>
      <div
        style={{
          fontSize: 11,
          fontWeight: 600,
          color: colors.gray[700],
          fontFamily: "'Pretendard', sans-serif",
        }}
      >
        {name}
      </div>
      <div
        style={{
          fontSize: 10,
          color: colors.gray[400],
          fontFamily: "'JetBrains Mono', monospace",
        }}
      >
        {hex}
      </div>
    </div>
  </div>
);

const TypeSample = ({ size, weight, label, sample }) => (
  <div
    style={{
      display: "flex",
      alignItems: "baseline",
      gap: 24,
      padding: "12px 0",
      borderBottom: `1px solid ${colors.gray[100]}`,
    }}
  >
    <div
      style={{
        width: 140,
        flexShrink: 0,
        display: "flex",
        flexDirection: "column",
        gap: 2,
      }}
    >
      <span
        style={{
          fontSize: 12,
          fontWeight: 600,
          color: colors.gray[700],
          fontFamily: "'Pretendard', sans-serif",
        }}
      >
        {label}
      </span>
      <span
        style={{
          fontSize: 10,
          color: colors.gray[400],
          fontFamily: "'JetBrains Mono', monospace",
        }}
      >
        {size}px / {weight}
      </span>
    </div>
    <span
      style={{
        fontSize: size,
        fontWeight: weight,
        color: colors.gray[900],
        fontFamily: "'Pretendard', sans-serif",
        lineHeight: 1.4,
      }}
    >
      {sample}
    </span>
  </div>
);

const Badge = ({ children, variant = "default" }) => {
  const styles = {
    verified: { bg: colors.success.light, color: colors.success.main, border: "1px solid #D1FAE5" },
    warning: { bg: colors.warning.light, color: colors.warning.dark, border: "1px solid #FEF3C7" },
    error: { bg: colors.error.light, color: colors.error.main, border: "1px solid #FECACA" },
    default: { bg: colors.gray[100], color: colors.gray[600], border: `1px solid ${colors.gray[200]}` },
    primary: { bg: colors.primary[50], color: colors.primary[700], border: `1px solid ${colors.primary[200]}` },
  };
  const s = styles[variant];
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        padding: "3px 10px",
        borderRadius: 6,
        fontSize: 12,
        fontWeight: 600,
        backgroundColor: s.bg,
        color: s.color,
        border: s.border,
        fontFamily: "'Pretendard', sans-serif",
      }}
    >
      {children}
    </span>
  );
};

export default function PiComDesignSystem() {
  const [activeTab, setActiveTab] = useState("colors");

  const tabs = [
    { id: "colors", label: "컬러" },
    { id: "typography", label: "타이포" },
    { id: "components", label: "컴포넌트" },
    { id: "cards", label: "카드" },
    { id: "tokens", label: "CSS 토큰" },
  ];

  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#FAFBFC",
        fontFamily: "'Pretendard', -apple-system, BlinkMacSystemFont, sans-serif",
      }}
    >
      <link
        href="https://cdnjs.cloudflare.com/ajax/libs/pretendard/1.3.9/static/pretendard.min.css"
        rel="stylesheet"
      />
      <link
        href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&display=swap"
        rel="stylesheet"
      />

      {/* Header */}
      <div
        style={{
          background: `linear-gradient(135deg, ${colors.primary[900]} 0%, ${colors.primary[800]} 50%, ${colors.primary[700]} 100%)`,
          padding: "40px 32px 32px",
          color: "white",
          position: "relative",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: -60,
            right: -40,
            width: 200,
            height: 200,
            borderRadius: "50%",
            background: "rgba(59,130,246,0.15)",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: -30,
            right: 80,
            width: 120,
            height: 120,
            borderRadius: "50%",
            background: "rgba(59,130,246,0.1)",
          }}
        />
        <div style={{ position: "relative", zIndex: 1 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              marginBottom: 8,
            }}
          >
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                background: "linear-gradient(135deg, #3B82F6, #60A5FA)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 16,
                fontWeight: 800,
                boxShadow: "0 2px 8px rgba(59,130,246,0.4)",
              }}
            >
              π
            </div>
            <span
              style={{
                fontSize: 22,
                fontWeight: 800,
                letterSpacing: "-0.02em",
              }}
            >
              PiCom
            </span>
          </div>
          <p
            style={{
              fontSize: 14,
              color: "rgba(255,255,255,0.6)",
              fontWeight: 400,
              marginTop: 4,
            }}
          >
            Design System v1.0 — 중고 PC 하드웨어 검증·거래 플랫폼
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div
        style={{
          display: "flex",
          gap: 2,
          padding: "0 32px",
          borderBottom: `1px solid ${colors.gray[200]}`,
          backgroundColor: "white",
        }}
      >
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              padding: "12px 16px",
              fontSize: 13,
              fontWeight: activeTab === tab.id ? 700 : 500,
              color: activeTab === tab.id ? colors.primary[600] : colors.gray[500],
              background: "none",
              border: "none",
              borderBottom: activeTab === tab.id ? `2px solid ${colors.primary[600]}` : "2px solid transparent",
              cursor: "pointer",
              fontFamily: "'Pretendard', sans-serif",
              transition: "all 0.15s",
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div style={{ padding: "32px 32px 48px", maxWidth: 840 }}>
        {/* Colors Tab */}
        {activeTab === "colors" && (
          <>
            <Section title="Brand Primary" subtitle="신뢰감 + 기술적 전문성. 기존 앱 블루를 정제">
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
                {Object.entries(colors.primary).map(([k, v]) => (
                  <Swatch key={k} name={k} hex={v} large />
                ))}
              </div>
              <div
                style={{
                  marginTop: 16,
                  padding: "12px 16px",
                  borderRadius: 10,
                  backgroundColor: colors.primary[50],
                  border: `1px solid ${colors.primary[100]}`,
                  fontSize: 13,
                  color: colors.primary[800],
                  lineHeight: 1.6,
                }}
              >
                <strong>사용 가이드:</strong> Primary 600이 메인 액션 컬러. 900/800은 헤더·텍스트, 50~200은 배경·호버에 사용
              </div>
            </Section>

            <Section title="Semantic Colors" subtitle="상태 표현용. 검증 결과·거래 상태에 적극 활용">
              <div style={{ display: "flex", gap: 32, flexWrap: "wrap" }}>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 600, color: colors.gray[600], marginBottom: 8 }}>
                    ✓ 검증 완료 / 정상
                  </div>
                  <div style={{ display: "flex", gap: 8 }}>
                    <Swatch name="Light" hex={colors.success.light} />
                    <Swatch name="Main" hex={colors.success.main} />
                    <Swatch name="Dark" hex={colors.success.dark} />
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 600, color: colors.gray[600], marginBottom: 8 }}>
                    ⚠ 주의 / 미검증
                  </div>
                  <div style={{ display: "flex", gap: 8 }}>
                    <Swatch name="Light" hex={colors.warning.light} />
                    <Swatch name="Main" hex={colors.warning.main} />
                    <Swatch name="Dark" hex={colors.warning.dark} />
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 600, color: colors.gray[600], marginBottom: 8 }}>
                    ✕ 불량 / 에러
                  </div>
                  <div style={{ display: "flex", gap: 8 }}>
                    <Swatch name="Light" hex={colors.error.light} />
                    <Swatch name="Main" hex={colors.error.main} />
                    <Swatch name="Dark" hex={colors.error.dark} />
                  </div>
                </div>
              </div>
            </Section>

            <Section title="Neutral Gray" subtitle="텍스트·보더·배경 전반에 사용하는 뉴트럴 팔레트">
              <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
                {Object.entries(colors.gray).map(([k, v]) => (
                  <Swatch key={k} name={k} hex={v} />
                ))}
              </div>
            </Section>
          </>
        )}

        {/* Typography Tab */}
        {activeTab === "typography" && (
          <>
            <Section title="Font Stack" subtitle="Pretendard — 한글 최적화, 가독성과 현대적 느낌의 균형">
              <div
                style={{
                  padding: 16,
                  borderRadius: 10,
                  backgroundColor: "white",
                  border: `1px solid ${colors.gray[200]}`,
                  fontFamily: "'JetBrains Mono', monospace",
                  fontSize: 12,
                  color: colors.gray[600],
                  lineHeight: 1.8,
                }}
              >
                <span style={{ color: colors.primary[600] }}>--font-sans:</span> 'Pretendard', -apple-system, sans-serif;
                <br />
                <span style={{ color: colors.primary[600] }}>--font-mono:</span> 'JetBrains Mono', monospace;
              </div>
            </Section>

            <Section title="Type Scale" subtitle="모듈식 스케일. 각 단계별 용도가 명확">
              <div
                style={{
                  backgroundColor: "white",
                  borderRadius: 12,
                  border: `1px solid ${colors.gray[200]}`,
                  padding: "4px 20px",
                }}
              >
                <TypeSample size={28} weight={800} label="H1 · 페이지 제목" sample="검증된 부품, 합리적 거래" />
                <TypeSample size={22} weight={700} label="H2 · 섹션 제목" sample="인기 그래픽카드 목록" />
                <TypeSample size={17} weight={600} label="H3 · 카드 제목" sample="RTX 4070 Ti SUPER" />
                <TypeSample size={15} weight={500} label="Body Large" sample="AI 기반 하드웨어 검증으로 안전한 중고 거래를 경험하세요" />
                <TypeSample size={14} weight={400} label="Body · 본문" sample="판매자가 업로드한 벤치마크 결과를 자동 분석하여 부품 상태를 검증합니다" />
                <TypeSample size={13} weight={500} label="Caption · 보조" sample="등록일 2026.03.15 · 조회 234" />
                <TypeSample size={11} weight={600} label="Overline · 라벨" sample="검증 완료 · VERIFIED" />
              </div>
            </Section>
          </>
        )}

        {/* Components Tab */}
        {activeTab === "components" && (
          <>
            <Section title="Buttons" subtitle="명확한 위계. Primary → Secondary → Ghost">
              <div style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
                {/* Primary */}
                <button
                  style={{
                    padding: "10px 20px",
                    borderRadius: 8,
                    border: "none",
                    background: `linear-gradient(135deg, ${colors.primary[600]}, ${colors.primary[500]})`,
                    color: "white",
                    fontSize: 14,
                    fontWeight: 600,
                    cursor: "pointer",
                    boxShadow: "0 1px 3px rgba(37,99,235,0.3), 0 1px 2px rgba(37,99,235,0.2)",
                    fontFamily: "'Pretendard', sans-serif",
                  }}
                >
                  판매 등록하기
                </button>
                {/* Secondary */}
                <button
                  style={{
                    padding: "10px 20px",
                    borderRadius: 8,
                    border: `1.5px solid ${colors.primary[200]}`,
                    background: "white",
                    color: colors.primary[600],
                    fontSize: 14,
                    fontWeight: 600,
                    cursor: "pointer",
                    fontFamily: "'Pretendard', sans-serif",
                  }}
                >
                  검증 요청
                </button>
                {/* Ghost */}
                <button
                  style={{
                    padding: "10px 20px",
                    borderRadius: 8,
                    border: `1.5px solid ${colors.gray[200]}`,
                    background: "white",
                    color: colors.gray[700],
                    fontSize: 14,
                    fontWeight: 500,
                    cursor: "pointer",
                    fontFamily: "'Pretendard', sans-serif",
                  }}
                >
                  필터
                </button>
                {/* Danger */}
                <button
                  style={{
                    padding: "10px 20px",
                    borderRadius: 8,
                    border: "none",
                    background: colors.error.light,
                    color: colors.error.main,
                    fontSize: 14,
                    fontWeight: 600,
                    cursor: "pointer",
                    fontFamily: "'Pretendard', sans-serif",
                    border: `1px solid #FECACA`,
                  }}
                >
                  삭제
                </button>
                {/* Small */}
                <button
                  style={{
                    padding: "6px 14px",
                    borderRadius: 6,
                    border: "none",
                    background: colors.primary[600],
                    color: "white",
                    fontSize: 12,
                    fontWeight: 600,
                    cursor: "pointer",
                    fontFamily: "'Pretendard', sans-serif",
                  }}
                >
                  Small
                </button>
              </div>
            </Section>

            <Section title="Badges" subtitle="검증 상태·부품 카테고리·거래 상태 표시">
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                <Badge variant="verified">✓ 검증 완료</Badge>
                <Badge variant="warning">⏳ 검증 중</Badge>
                <Badge variant="error">✕ 불량 의심</Badge>
                <Badge variant="primary">GPU</Badge>
                <Badge variant="primary">CPU</Badge>
                <Badge variant="default">중고</Badge>
                <Badge variant="default">택배 가능</Badge>
              </div>
            </Section>

            <Section title="Input" subtitle="깔끔한 보더 스타일. 포커스 시 Primary 링">
              <div style={{ display: "flex", flexDirection: "column", gap: 12, maxWidth: 400 }}>
                <div>
                  <label
                    style={{
                      fontSize: 13,
                      fontWeight: 600,
                      color: colors.gray[700],
                      display: "block",
                      marginBottom: 6,
                      fontFamily: "'Pretendard', sans-serif",
                    }}
                  >
                    검색
                  </label>
                  <div style={{ position: "relative" }}>
                    <input
                      placeholder="부품명, 모델명으로 검색"
                      style={{
                        width: "100%",
                        padding: "10px 14px 10px 36px",
                        borderRadius: 8,
                        border: `1.5px solid ${colors.gray[200]}`,
                        fontSize: 14,
                        color: colors.gray[900],
                        outline: "none",
                        fontFamily: "'Pretendard', sans-serif",
                        backgroundColor: "white",
                        boxSizing: "border-box",
                      }}
                    />
                    <span
                      style={{
                        position: "absolute",
                        left: 12,
                        top: "50%",
                        transform: "translateY(-50%)",
                        color: colors.gray[400],
                        fontSize: 14,
                      }}
                    >
                      🔍
                    </span>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8 }}>
                  <select
                    style={{
                      flex: 1,
                      padding: "10px 14px",
                      borderRadius: 8,
                      border: `1.5px solid ${colors.gray[200]}`,
                      fontSize: 14,
                      color: colors.gray[700],
                      fontFamily: "'Pretendard', sans-serif",
                      backgroundColor: "white",
                    }}
                  >
                    <option>카테고리</option>
                  </select>
                  <select
                    style={{
                      flex: 1,
                      padding: "10px 14px",
                      borderRadius: 8,
                      border: `1.5px solid ${colors.gray[200]}`,
                      fontSize: 14,
                      color: colors.gray[700],
                      fontFamily: "'Pretendard', sans-serif",
                      backgroundColor: "white",
                    }}
                  >
                    <option>가격순</option>
                  </select>
                </div>
              </div>
            </Section>

            <Section title="Spacing & Radius" subtitle="일관된 간격 체계">
              <div style={{ display: "flex", gap: 24, flexWrap: "wrap" }}>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 600, color: colors.gray[600], marginBottom: 12 }}>
                    Spacing Scale
                  </div>
                  <div style={{ display: "flex", gap: 8, alignItems: "flex-end" }}>
                    {[4, 8, 12, 16, 20, 24, 32, 40, 48].map((s) => (
                      <div key={s} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
                        <div
                          style={{
                            width: s,
                            height: s,
                            backgroundColor: colors.primary[200],
                            borderRadius: 2,
                          }}
                        />
                        <span style={{ fontSize: 10, color: colors.gray[400], fontFamily: "'JetBrains Mono'" }}>
                          {s}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 600, color: colors.gray[600], marginBottom: 12 }}>
                    Border Radius
                  </div>
                  <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                    {[
                      { r: 6, label: "sm" },
                      { r: 8, label: "md" },
                      { r: 10, label: "default" },
                      { r: 12, label: "lg" },
                      { r: 16, label: "xl" },
                    ].map((item) => (
                      <div
                        key={item.label}
                        style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}
                      >
                        <div
                          style={{
                            width: 40,
                            height: 40,
                            backgroundColor: colors.primary[100],
                            border: `1.5px solid ${colors.primary[300]}`,
                            borderRadius: item.r,
                          }}
                        />
                        <span style={{ fontSize: 10, color: colors.gray[400], fontFamily: "'JetBrains Mono'" }}>
                          {item.r}px
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </Section>
          </>
        )}

        {/* Cards Tab */}
        {activeTab === "cards" && (
          <>
            <Section title="Product Card" subtitle="핵심 컴포넌트. 검증 상태가 즉시 눈에 들어와야 함">
              <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
                {/* Card 1 - Verified */}
                <div
                  style={{
                    width: 260,
                    borderRadius: 12,
                    backgroundColor: "white",
                    border: `1px solid ${colors.gray[200]}`,
                    overflow: "hidden",
                    boxShadow: "0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.02)",
                  }}
                >
                  <div
                    style={{
                      height: 160,
                      backgroundColor: colors.gray[100],
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      position: "relative",
                    }}
                  >
                    <span style={{ fontSize: 40, opacity: 0.3 }}>🖥️</span>
                    <div style={{ position: "absolute", top: 10, left: 10 }}>
                      <Badge variant="verified">✓ 검증 완료</Badge>
                    </div>
                    <div
                      style={{
                        position: "absolute",
                        top: 10,
                        right: 10,
                        width: 32,
                        height: 32,
                        borderRadius: 8,
                        backgroundColor: "rgba(255,255,255,0.9)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        cursor: "pointer",
                        fontSize: 14,
                      }}
                    >
                      ♡
                    </div>
                  </div>
                  <div style={{ padding: "14px 16px 16px" }}>
                    <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
                      <Badge variant="primary">GPU</Badge>
                      <Badge variant="default">택배</Badge>
                    </div>
                    <div
                      style={{
                        fontSize: 15,
                        fontWeight: 700,
                        color: colors.gray[900],
                        marginBottom: 4,
                        fontFamily: "'Pretendard', sans-serif",
                      }}
                    >
                      RTX 4070 Ti SUPER
                    </div>
                    <div
                      style={{
                        fontSize: 13,
                        color: colors.gray[400],
                        marginBottom: 10,
                        fontFamily: "'Pretendard', sans-serif",
                      }}
                    >
                      ASUS TUF · 사용 8개월
                    </div>
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}
                    >
                      <span
                        style={{
                          fontSize: 18,
                          fontWeight: 800,
                          color: colors.gray[900],
                          fontFamily: "'Pretendard', sans-serif",
                        }}
                      >
                        720,000
                        <span style={{ fontSize: 13, fontWeight: 500, color: colors.gray[500] }}> 원</span>
                      </span>
                      <span style={{ fontSize: 12, color: colors.gray[400] }}>3시간 전</span>
                    </div>
                  </div>
                </div>

                {/* Card 2 - Unverified */}
                <div
                  style={{
                    width: 260,
                    borderRadius: 12,
                    backgroundColor: "white",
                    border: `1px solid ${colors.gray[200]}`,
                    overflow: "hidden",
                    boxShadow: "0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.02)",
                  }}
                >
                  <div
                    style={{
                      height: 160,
                      backgroundColor: colors.gray[100],
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      position: "relative",
                    }}
                  >
                    <span style={{ fontSize: 40, opacity: 0.3 }}>⚙️</span>
                    <div style={{ position: "absolute", top: 10, left: 10 }}>
                      <Badge variant="warning">⏳ 검증 중</Badge>
                    </div>
                    <div
                      style={{
                        position: "absolute",
                        top: 10,
                        right: 10,
                        width: 32,
                        height: 32,
                        borderRadius: 8,
                        backgroundColor: "rgba(255,255,255,0.9)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        cursor: "pointer",
                        fontSize: 14,
                      }}
                    >
                      ♡
                    </div>
                  </div>
                  <div style={{ padding: "14px 16px 16px" }}>
                    <div style={{ display: "flex", gap: 6, marginBottom: 8 }}>
                      <Badge variant="primary">CPU</Badge>
                      <Badge variant="default">직거래</Badge>
                    </div>
                    <div
                      style={{
                        fontSize: 15,
                        fontWeight: 700,
                        color: colors.gray[900],
                        marginBottom: 4,
                        fontFamily: "'Pretendard', sans-serif",
                      }}
                    >
                      Ryzen 7 7800X3D
                    </div>
                    <div
                      style={{
                        fontSize: 13,
                        color: colors.gray[400],
                        marginBottom: 10,
                        fontFamily: "'Pretendard', sans-serif",
                      }}
                    >
                      정품 · 사용 1년
                    </div>
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}
                    >
                      <span
                        style={{
                          fontSize: 18,
                          fontWeight: 800,
                          color: colors.gray[900],
                          fontFamily: "'Pretendard', sans-serif",
                        }}
                      >
                        340,000
                        <span style={{ fontSize: 13, fontWeight: 500, color: colors.gray[500] }}> 원</span>
                      </span>
                      <span style={{ fontSize: 12, color: colors.gray[400] }}>1일 전</span>
                    </div>
                  </div>
                </div>
              </div>
            </Section>

            <Section title="Verification Result Card" subtitle="검증 리포트 요약 카드">
              <div
                style={{
                  maxWidth: 480,
                  borderRadius: 12,
                  backgroundColor: "white",
                  border: `1px solid ${colors.gray[200]}`,
                  overflow: "hidden",
                }}
              >
                <div
                  style={{
                    padding: "14px 20px",
                    backgroundColor: colors.success.light,
                    borderBottom: "1px solid #D1FAE5",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <div
                      style={{
                        width: 28,
                        height: 28,
                        borderRadius: "50%",
                        backgroundColor: colors.success.main,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "white",
                        fontSize: 14,
                        fontWeight: 700,
                      }}
                    >
                      ✓
                    </div>
                    <span
                      style={{
                        fontSize: 15,
                        fontWeight: 700,
                        color: colors.success.dark,
                        fontFamily: "'Pretendard', sans-serif",
                      }}
                    >
                      검증 통과
                    </span>
                  </div>
                  <span style={{ fontSize: 12, color: colors.success.main, fontWeight: 500 }}>
                    2026.03.21 14:32
                  </span>
                </div>
                <div style={{ padding: 20 }}>
                  {[
                    { label: "GPU 모델", value: "RTX 4070 Ti SUPER", status: "match" },
                    { label: "VRAM", value: "16GB GDDR6X", status: "match" },
                    { label: "벤치 점수", value: "22,450 (3DMark)", status: "normal" },
                    { label: "온도 (풀로드)", value: "72°C", status: "normal" },
                    { label: "팬 상태", value: "정상 작동", status: "match" },
                  ].map((item, i) => (
                    <div
                      key={i}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        padding: "10px 0",
                        borderBottom: i < 4 ? `1px solid ${colors.gray[100]}` : "none",
                      }}
                    >
                      <span
                        style={{
                          fontSize: 13,
                          color: colors.gray[500],
                          fontFamily: "'Pretendard', sans-serif",
                        }}
                      >
                        {item.label}
                      </span>
                      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                        <span
                          style={{
                            fontSize: 14,
                            fontWeight: 600,
                            color: colors.gray[800],
                            fontFamily: "'Pretendard', sans-serif",
                          }}
                        >
                          {item.value}
                        </span>
                        <span
                          style={{
                            fontSize: 11,
                            color: item.status === "match" ? colors.success.main : colors.primary[500],
                          }}
                        >
                          {item.status === "match" ? "✓" : "—"}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </Section>
          </>
        )}

        {/* CSS Tokens Tab */}
        {activeTab === "tokens" && (
          <Section title="globals.css Variables" subtitle="shadcn/ui 테마에 바로 복붙 가능한 CSS 변수">
            <div
              style={{
                borderRadius: 12,
                backgroundColor: colors.gray[900],
                padding: 24,
                overflow: "auto",
              }}
            >
              <pre
                style={{
                  margin: 0,
                  fontSize: 12,
                  lineHeight: 1.8,
                  color: "#E2E8F0",
                  fontFamily: "'JetBrains Mono', monospace",
                  whiteSpace: "pre-wrap",
                }}
              >
                {`:root {
  /* ── Brand ── */
  --primary: 217 91% 60%;        /* #3B82F6 */
  --primary-foreground: 0 0% 100%;
  --primary-hover: 221 83% 53%;  /* #2563EB */

  /* ── Background ── */
  --background: 210 20% 98%;     /* #F8FAFC */
  --foreground: 222 47% 11%;     /* #0F172A */
  --card: 0 0% 100%;
  --card-foreground: 222 47% 11%;

  /* ── Muted ── */
  --muted: 210 40% 96%;          /* #F1F5F9 */
  --muted-foreground: 215 16% 47%; /* #64748B */

  /* ── Border ── */
  --border: 214 32% 91%;         /* #E2E8F0 */
  --input: 214 32% 91%;
  --ring: 217 91% 60%;

  /* ── Semantic ── */
  --success: 160 84% 39%;        /* #059669 */
  --success-light: 152 81% 96%;
  --warning: 32 95% 44%;         /* #D97706 */
  --warning-light: 48 96% 89%;
  --destructive: 0 72% 51%;      /* #DC2626 */
  --destructive-light: 0 86% 97%;

  /* ── Radius ── */
  --radius: 0.625rem;            /* 10px */

  /* ── Shadows ── */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.04);
  --shadow-md: 0 1px 3px rgba(0,0,0,0.04),
               0 1px 2px rgba(0,0,0,0.02);
  --shadow-lg: 0 4px 6px rgba(0,0,0,0.04),
               0 2px 4px rgba(0,0,0,0.02);
}

/* ── Typography ── */
@layer base {
  body {
    font-family: 'Pretendard', -apple-system,
      BlinkMacSystemFont, 'Segoe UI', sans-serif;
    -webkit-font-smoothing: antialiased;
    font-feature-settings: 'ss01';
  }
}`}
              </pre>
            </div>
            <div
              style={{
                marginTop: 16,
                padding: "12px 16px",
                borderRadius: 10,
                backgroundColor: colors.primary[50],
                border: `1px solid ${colors.primary[100]}`,
                fontSize: 13,
                color: colors.primary[800],
                lineHeight: 1.6,
              }}
            >
              <strong>적용 방법:</strong> globals.css의 :root 블록에 위 변수를 교체. shadcn/ui 컴포넌트가 자동으로 반영됨.
              Pretendard는 CDN 또는 next/font로 로드.
            </div>
          </Section>
        )}
      </div>
    </div>
  );
}
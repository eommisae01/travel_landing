import { NextResponse } from "next/server";
import { hasSession } from "@/app/lib/auth";
import { hasSupabaseConfig } from "@/app/lib/server-data";

const tripContext = `
타카마쓰/나오시마 가족여행. 인원은 가족 3명 기준.
2026-06-22 RS0741 10:30 타카마쓰 도착. 첫날은 짐을 들고 우동집/공원에 가지 않고 12:00 숙소 짐보관에 맞춰 이동.
2026-06-23 나오시마. 10:14 다카마쓰항 출발 페리, 11:04 나오시마 도착이 기본 후보. 지중미술관은 12:00 예약 완료.
섬 안에서는 미야노우라항 2번 정류장, 츠츠지소행 100엔 버스, 베네세 무료 셔틀을 중요하게 봐야 함.
2026-06-24 RS0742 11:40 출발이라 마지막 날은 관광보다 공항 이동 중심.
원하는 답변은 가족이 현장에서 바로 판단할 수 있게 짧고 구체적으로: 추천 이유, 이동 리스크, 예약/영업 확인 포인트, Google Maps에서 검색할 키워드.
`;

async function guard() {
  if (!hasSupabaseConfig()) return null;
  if (await hasSession()) return null;
  return NextResponse.json({ message: "가족코드가 필요합니다." }, { status: 401 });
}

function extractOutputText(payload: unknown) {
  if (!payload || typeof payload !== "object") return "";
  const maybe = payload as { output_text?: unknown; output?: Array<{ content?: Array<{ text?: unknown }> }> };
  if (typeof maybe.output_text === "string") return maybe.output_text;
  return (maybe.output || [])
    .flatMap((item) => item.content || [])
    .map((item) => typeof item.text === "string" ? item.text : "")
    .filter(Boolean)
    .join("\n\n");
}

export async function POST(request: Request) {
  const blocked = await guard();
  if (blocked) return blocked;

  if (!process.env.OPENAI_API_KEY) {
    return NextResponse.json(
      { message: "OPENAI_API_KEY가 아직 서버 환경변수에 없어요. 로컬 .env.local 또는 Vercel 환경변수에 추가하면 추천 생성이 켜집니다." },
      { status: 503 }
    );
  }

  const body = await request.json().catch(() => null) as { topic?: string; prompt?: string } | null;
  const topic = body?.topic?.trim() || "식당";
  const prompt = body?.prompt?.trim() || "";

  const input = `
${tripContext}

요청 주제: ${topic}
추가 조건: ${prompt || "특별 조건 없음"}

한국어로 답해줘. 4-6개 항목으로 정리하고, 각 항목은 너무 길지 않게 써줘.
`;

  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: process.env.OPENAI_RECOMMENDATION_MODEL || "gpt-4.1-mini",
        input
      })
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      const message = typeof payload === "object" && payload && "error" in payload
        ? ((payload as { error?: { message?: string } }).error?.message || "추천 API 호출에 실패했어요.")
        : "추천 API 호출에 실패했어요.";
      return NextResponse.json({ message }, { status: response.status });
    }

    const text = extractOutputText(payload);
    return NextResponse.json({ text: text || "추천 결과를 읽어오지 못했어요. 잠시 후 다시 시도해 주세요." });
  } catch (error) {
    return NextResponse.json({ message: error instanceof Error ? error.message : "추천 API를 호출하지 못했어요." }, { status: 500 });
  }
}

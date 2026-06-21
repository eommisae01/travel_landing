import { NextResponse } from "next/server";
import { inferGoogleMapsName, isAllowedGoogleMapsUrl } from "@/app/lib/maps";

export async function POST(request: Request) {
  const { url } = await request.json().catch(() => ({ url: "" }));
  const inputUrl = String(url || "").trim();

  if (!isAllowedGoogleMapsUrl(inputUrl)) {
    return NextResponse.json({ message: "Google Maps 링크만 사용할 수 있습니다." }, { status: 400 });
  }

  let finalUrl = inputUrl;
  if (new URL(inputUrl).hostname === "maps.app.goo.gl" || new URL(inputUrl).hostname === "goo.gl") {
    try {
      const response = await fetch(inputUrl, { redirect: "follow" });
      if (isAllowedGoogleMapsUrl(response.url)) finalUrl = response.url;
    } catch {
      finalUrl = inputUrl;
    }
  }

  const inferredName = inferGoogleMapsName(finalUrl) || inferGoogleMapsName(inputUrl);

  return NextResponse.json({
    originalUrl: inputUrl,
    finalUrl,
    name: inferredName || "Google Maps 장소"
  });
}

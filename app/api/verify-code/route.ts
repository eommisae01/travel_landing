import { NextResponse } from "next/server";
import { createSession, verifyFamilyCode } from "@/app/lib/auth";

export async function POST(request: Request) {
  const { code } = await request.json().catch(() => ({ code: "" }));
  if (!verifyFamilyCode(String(code || ""))) {
    return NextResponse.json({ ok: false, message: "가족코드가 맞지 않아요." }, { status: 401 });
  }

  await createSession();
  return NextResponse.json({ ok: true });
}

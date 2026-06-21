import { NextResponse } from "next/server";
import { clearSession, hasSession } from "@/app/lib/auth";
import { hasSupabaseConfig } from "@/app/lib/server-data";

export async function GET() {
  return NextResponse.json({
    authenticated: hasSupabaseConfig() ? await hasSession() : true,
    authRequired: hasSupabaseConfig()
  });
}

export async function DELETE() {
  await clearSession();
  return NextResponse.json({ ok: true });
}

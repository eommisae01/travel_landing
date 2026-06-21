import { NextResponse } from "next/server";
import { hasSession } from "@/app/lib/auth";
import { createRow, deleteRow, hasSupabaseConfig, isTableName, readTripData, updateRow } from "@/app/lib/server-data";

async function guard() {
  if (!hasSupabaseConfig()) return null;
  if (await hasSession()) return null;
  return NextResponse.json({ message: "가족코드가 필요합니다." }, { status: 401 });
}

export async function GET() {
  const blocked = await guard();
  if (blocked) return blocked;

  try {
    return NextResponse.json(await readTripData());
  } catch (error) {
    return NextResponse.json({ message: error instanceof Error ? error.message : "데이터를 불러오지 못했어요." }, { status: 500 });
  }
}

export async function POST(request: Request) {
  const blocked = await guard();
  if (blocked) return blocked;

  const body = await request.json().catch(() => null);
  if (!body || !isTableName(body.table) || !["create", "update", "delete"].includes(body.action)) {
    return NextResponse.json({ message: "잘못된 요청입니다." }, { status: 400 });
  }

  try {
    if (body.action === "create") return NextResponse.json({ row: await createRow(body.table, body.row || {}) });
    if (body.action === "update") return NextResponse.json({ row: await updateRow(body.table, String(body.id), body.patch || {}) });
    return NextResponse.json({ row: await deleteRow(body.table, String(body.id)) });
  } catch (error) {
    return NextResponse.json({ message: error instanceof Error ? error.message : "저장하지 못했어요." }, { status: 500 });
  }
}

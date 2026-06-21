import { createClient } from "@supabase/supabase-js";
import { randomUUID } from "crypto";
import { readMyMapsTripData } from "./my-maps";
import { DEFAULT_TRIP_ID, seedData } from "./seed";
import { TableName, TripData } from "./types";

const tables: TableName[] = [
  "trips",
  "trip_members",
  "itinerary_items",
  "places",
  "food_candidates",
  "checklist_items",
  "gallery_items",
  "onsite_notes",
  "expenses",
  "quick_links",
  "app_settings"
];

function supabaseAdmin() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  return createClient(url, key, { auth: { persistSession: false } });
}

export function hasSupabaseConfig() {
  return Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY);
}

export async function readTripData(): Promise<{ data: TripData; mode: "supabase" | "demo" }> {
  const supabase = supabaseAdmin();
  if (!supabase) {
    try {
      return { data: await readMyMapsTripData(seedData), mode: "demo" };
    } catch {
      return { data: seedData, mode: "demo" };
    }
  }

  const entries = await Promise.all(
    tables.map(async (table) => {
      const query = supabase.from(table).select("*");
      const { data, error } = table === "trips" || table === "app_settings"
        ? await query
        : await query.eq("trip_id", DEFAULT_TRIP_ID);
      if (error) throw error;
      return [table, data || []] as const;
    })
  );

  return { data: Object.fromEntries(entries) as TripData, mode: "supabase" };
}

export async function createRow(table: TableName, row: Record<string, unknown>) {
  const supabase = supabaseAdmin();
  const nextRow = { id: String(row.id || randomUUID()), trip_id: DEFAULT_TRIP_ID, ...row };
  if (!supabase) return nextRow;
  const { data, error } = await supabase.from(table).insert(nextRow).select("*").single();
  if (error) throw error;
  return data;
}

export async function updateRow(table: TableName, id: string, patch: Record<string, unknown>) {
  const supabase = supabaseAdmin();
  if (!supabase) return { id, ...patch };
  const { data, error } = await supabase.from(table).update(patch).eq("id", id).select("*").single();
  if (error) throw error;
  return data;
}

export async function deleteRow(table: TableName, id: string) {
  const supabase = supabaseAdmin();
  if (!supabase) return { id };
  const { error } = await supabase.from(table).delete().eq("id", id);
  if (error) throw error;
  return { id };
}

export function isTableName(value: string): value is TableName {
  return tables.includes(value as TableName);
}

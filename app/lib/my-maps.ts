import { DEFAULT_TRIP_ID, googleMapUrlFromCoords, MY_MAPS_MID, seedData } from "./seed";
import { FoodCandidate, Place, TripData } from "./types";

type Placemark = {
  name: string;
  folder: string;
  description: string;
  coordinates: string;
};

const foodFolders = ["식당", "카페", "디저트", "이자카야", "우동", "야키니쿠", "스시", "소바"];

function stripTags(value: string) {
  return value.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
}

function decodeXml(value: string) {
  return stripTags(value)
    .replaceAll("&amp;", "&")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", "\"")
    .replaceAll("&#39;", "'");
}

function readTag(xml: string, tag: string) {
  const match = xml.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i"));
  return match ? decodeXml(match[1]) : "";
}

function slug(value: string) {
  const normalized = value.toLowerCase().replace(/[^a-z0-9가-힣ぁ-んァ-ン一-龥]+/g, "-").replace(/^-|-$/g, "");
  return normalized || Math.random().toString(16).slice(2);
}

function parseKml(kml: string): Placemark[] {
  const folders = [...kml.matchAll(/<Folder[^>]*>([\s\S]*?)<\/Folder>/gi)];
  return folders.flatMap((folderMatch) => {
    const folderXml = folderMatch[1];
    const folder = readTag(folderXml, "name") || "기타";
    return [...folderXml.matchAll(/<Placemark[^>]*>([\s\S]*?)<\/Placemark>/gi)].map((placeMatch) => {
      const placeXml = placeMatch[1];
      const coordinateMatch = placeXml.match(/<coordinates[^>]*>\s*([^<\s]+)\s*<\/coordinates>/i);
      return {
        name: readTag(placeXml, "name") || "이름 없는 장소",
        folder,
        description: readTag(placeXml, "description"),
        coordinates: coordinateMatch ? coordinateMatch[1] : ""
      };
    });
  }).filter((place) => place.coordinates);
}

function isFood(folder: string) {
  return foodFolders.some((name) => folder.includes(name));
}

function toPlace(item: Placemark, index: number): Place {
  return {
    id: `mymap-place-${index}-${slug(item.name)}`,
    trip_id: DEFAULT_TRIP_ID,
    name: item.name,
    category: item.folder === "제목없는 레이어" ? "관광지" : item.folder,
    address: item.coordinates,
    map_url: googleMapUrlFromCoords(item.coordinates),
    hours: "확인 필요",
    reservation_note: "Google My Maps 자동 반영",
    sensitive_note: item.description
  };
}

function toFood(item: Placemark, index: number): FoodCandidate {
  return {
    id: `mymap-food-${index}-${slug(item.name)}`,
    trip_id: DEFAULT_TRIP_ID,
    name: item.name,
    category: item.folder,
    location: item.coordinates,
    map_url: googleMapUrlFromCoords(item.coordinates),
    reservation: "확인 필요",
    wait_note: "확인 필요",
    recommender: "My Maps",
    note: item.description,
    is_favorite: false
  };
}

function mergeByName<T extends { name: string }>(base: T[], incoming: T[]) {
  const seen = new Set<string>();
  return [...base, ...incoming].filter((item) => {
    const key = item.name.trim().toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

export async function readMyMapsTripData(base: TripData = seedData): Promise<TripData> {
  const response = await fetch(`https://www.google.com/maps/d/kml?mid=${MY_MAPS_MID}`, {
    cache: "no-store",
    headers: { "User-Agent": "travel-dashboard/1.0" }
  });
  if (!response.ok) throw new Error("Google My Maps KML을 불러오지 못했어요.");

  const placemarks = parseKml(await response.text());
  if (!placemarks.length) return base;

  const foods = placemarks.filter((item) => isFood(item.folder)).map(toFood);
  const places = placemarks.filter((item) => !isFood(item.folder)).map(toPlace);
  if (!foods.length && !places.length) return base;

  return {
    ...base,
    places: places.length ? mergeByName(base.places, places) : base.places,
    food_candidates: foods.length ? mergeByName(base.food_candidates, foods) : base.food_candidates
  };
}

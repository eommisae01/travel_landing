export function inferGoogleMapsName(url: string) {
  try {
    const parsed = new URL(url);
    const query = parsed.searchParams.get("query") || parsed.searchParams.get("q");
    if (query) return decodeURIComponent(query).replace(/\+/g, " ");
    const parts = parsed.pathname.split("/");
    const placeIndex = parts.findIndex((part) => part === "place");
    if (placeIndex >= 0) return decodeURIComponent(parts[placeIndex + 1] || "").replace(/\+/g, " ");
  } catch {
    return "";
  }
  return "";
}

export function isAllowedGoogleMapsUrl(url: string) {
  try {
    const parsed = new URL(url);
    return (
      parsed.protocol === "https:" &&
      (parsed.hostname === "maps.app.goo.gl" ||
        parsed.hostname === "goo.gl" ||
        parsed.hostname === "www.google.com" ||
        parsed.hostname === "google.com") &&
      (parsed.hostname === "maps.app.goo.gl" || parsed.hostname === "goo.gl" || parsed.pathname.startsWith("/maps"))
    );
  } catch {
    return false;
  }
}

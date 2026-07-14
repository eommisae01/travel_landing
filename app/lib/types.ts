export type TableName =
  | "trips"
  | "trip_members"
  | "itinerary_items"
  | "places"
  | "food_candidates"
  | "checklist_items"
  | "gallery_items"
  | "onsite_notes"
  | "expenses"
  | "quick_links"
  | "app_settings";

export type Trip = {
  id: string;
  name: string;
  region: string;
  start_date: string;
  end_date: string;
  hero_image: string;
  note: string;
  country?: string;
  cities?: string[];
  accommodation?: string;
  my_maps_url?: string;
  outbound_origin?: string;
  outbound_destination?: string;
  outbound_flight?: string;
  outbound_departure_time?: string;
  outbound_arrival_time?: string;
  return_origin?: string;
  return_destination?: string;
  return_flight?: string;
  return_departure_time?: string;
  return_arrival_time?: string;
  budget_amount?: number;
  budget_currency?: string;
};

export type TripMember = {
  id: string;
  trip_id: string;
  name: string;
  color: string;
  role: string;
  avatar_url?: string;
};

export type ItineraryItem = {
  id: string;
  trip_id: string;
  date: string;
  time_label: string;
  start_time: string;
  end_time: string;
  title: string;
  description: string;
  location: string;
  priority: string;
  reservation_status: string;
  weather_impact: string;
  owner: string;
  sort_order: number;
};

export type Place = {
  id: string;
  trip_id: string;
  name: string;
  category: string;
  address: string;
  map_url: string;
  hours: string;
  reservation_note: string;
  sensitive_note: string;
};

export type FoodCandidate = {
  id: string;
  trip_id: string;
  name: string;
  category: string;
  location: string;
  map_url: string;
  reservation: string;
  wait_note: string;
  recommender: string;
  note: string;
  is_favorite?: boolean;
};

export type ChecklistItem = {
  id: string;
  trip_id: string;
  group_name: string;
  text: string;
  owner: string;
  is_done: boolean;
  sort_order?: number;
  is_archived?: boolean;
};

export type GalleryItem = {
  id: string;
  trip_id: string;
  title: string;
  src: string;
  date: string;
  category: string;
  note: string;
  is_favorite?: boolean;
  sort_order?: number;
};

export type OnsiteNote = {
  id: string;
  trip_id: string;
  title: string;
  body: string;
  tone: string;
  sort_order?: number;
};

export type Expense = {
  id: string;
  trip_id: string;
  category: string;
  item: string;
  amount: number;
  currency: string;
  payer: string;
  note: string;
  intended_payer?: string;
  participants?: string[];
};

export type QuickLink = {
  id: string;
  trip_id: string;
  label: string;
  kind: string;
  url: string;
};

export type AppSettings = {
  id: string;
  default_trip_id: string;
  public_sensitive: boolean;
};

export type TripData = {
  trips: Trip[];
  trip_members: TripMember[];
  itinerary_items: ItineraryItem[];
  places: Place[];
  food_candidates: FoodCandidate[];
  checklist_items: ChecklistItem[];
  gallery_items: GalleryItem[];
  onsite_notes: OnsiteNote[];
  expenses: Expense[];
  quick_links: QuickLink[];
  app_settings: AppSettings[];
};

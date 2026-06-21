insert into trips (id, name, region, start_date, end_date, hero_image, note) values
('trip-takamatsu-2026', '타카마쓰 가족여행', '타카마쓰 · 나오시마', '2026-06-22', '2026-06-24', '/assets/setouchi-hero.png', '월·화 중심의 짧은 세토내해 여행. 수요일은 11시 비행기로 공항 이동 우선.')
on conflict (id) do update set name = excluded.name;

insert into trip_members (id, trip_id, name, color, role) values
('member-me', 'trip-takamatsu-2026', '예지', '#16a3a3', '지도/예약 관리'),
('member-dad', 'trip-takamatsu-2026', '승환', '#ff6f61', '컨디션/동선 확인'),
('member-minji', 'trip-takamatsu-2026', '민지', '#ffc857', '맛집/카페 후보')
on conflict (id) do nothing;

insert into itinerary_items (id, trip_id, date, time_label, start_time, end_time, title, description, location, priority, reservation_status, weather_impact, owner, sort_order) values
('iti-1', 'trip-takamatsu-2026', '2026-06-22', '오전', '10:30', '12:00', '타카마쓰 도착', '공항에서 시내 이동. 호텔에 짐 맡기기.', '타카마쓰 공항 → 시내', '필수', '확인 필요', '낮음', '나', 10),
('iti-2', 'trip-takamatsu-2026', '2026-06-22', '오후', '14:00', '16:00', '리쓰린 공원', '날씨가 괜찮으면 천천히 산책.', '리쓰린 공원', '날씨 좋으면', '해당 없음', '중간', '다 같이', 20),
('iti-3', 'trip-takamatsu-2026', '2026-06-23', '아침', '08:30', '10:00', '타카마쓰항 → 나오시마', '페리 시간과 강풍 여부 확인.', '타카마쓰항', '필수', '확인 필요', '높음', '나', 30),
('iti-4', 'trip-takamatsu-2026', '2026-06-23', '낮', '11:00', '13:00', '지중미술관', '이번 여행의 핵심. 예약 시간과 휴관일 확인.', '나오시마', '필수', '예약 필요', '중간', '다 같이', 40),
('iti-5', 'trip-takamatsu-2026', '2026-06-24', '아침', '07:30', '09:00', '체크아웃 / 공항 이동', '11:00 비행기 기준으로 이동 우선.', '호텔 → 공항', '필수', '확인 필요', '낮음', '다 같이', 50)
on conflict (id) do nothing;

insert into places (id, trip_id, name, category, address, map_url, hours, reservation_note, sensitive_note) values
('place-1', 'trip-takamatsu-2026', '지중미술관', '미술관', '일본어 주소 확인 필요', 'https://www.google.com/maps', '운영시간 확인 필요', '예약 필요 가능성 높음', '예약번호는 상세 메모에 입력'),
('place-2', 'trip-takamatsu-2026', '리쓰린 공원', '공원', '일본어 주소 확인 필요', 'https://www.google.com/maps', '마지막 입장 확인 필요', '예약 불필요', '')
on conflict (id) do nothing;

insert into food_candidates (id, trip_id, name, category, location, map_url, reservation, wait_note, recommender, note, is_favorite) values
('food-1', 'trip-takamatsu-2026', '우동 후보 1', '우동', '타카마쓰 시내', 'https://www.google.com/maps', '예약 불필요', '점심 대기 가능', '다 같이', '첫날 또는 마지막 날 가볍게', false),
('food-2', 'trip-takamatsu-2026', '비 오는 날 카페 후보', '카페', '역/상점가 근처', 'https://www.google.com/maps', '해당 없음', '보통', '민지', '폭우나 강풍일 때 쉬어가기', false)
on conflict (id) do nothing;

insert into gallery_items (id, trip_id, title, src, date, category, note, is_favorite, sort_order) values
('gallery-01', 'trip-takamatsu-2026', '공항 리무진버스 경로', '/assets/gallery/route-airport-bus.png', '2026-06-22', '공항/버스', '다카마쓰 공항에서 시내로 이동하는 버스 경로 참고', true, 1),
('gallery-02', 'trip-takamatsu-2026', '공항 환전/ATM', '/assets/gallery/airport-exchange-atm.png', '2026-06-22', '공항/환전', '114Bank Money Exchange, 은행 ATM. 트래블카드 출금 확인', true, 2),
('gallery-04', 'trip-takamatsu-2026', '다카마쓰 → 나오시마 시간표', '/assets/gallery/ferry-takamatsu-to-naoshima.png', '2026-06-23', '페리', '10:14 출발 추천', true, 4),
('gallery-09', 'trip-takamatsu-2026', '베네세 버스 시간표', '/assets/gallery/benesse-bus-timetable.png', '2026-06-23', '버스/셔틀', '지중미술관행/츠츠지소행 셔틀 시간표', true, 9),
('gallery-14', 'trip-takamatsu-2026', '지중미술관 메모', '/assets/gallery/chichu-note.png', '2026-06-23', '미술관', '온라인 2,500엔, 사전예약 필수, 90-120분', true, 14)
on conflict (id) do nothing;

insert into onsite_notes (id, trip_id, title, body, tone, sort_order) values
('onsite-1', 'trip-takamatsu-2026', '공항 이동', '6/24 RS0742 11:40 출발. 마지막 날은 관광보다 체크아웃과 공항 이동을 우선.', 'urgent', 1),
('onsite-2', 'trip-takamatsu-2026', '공항 환전/출금', '타카마쓰 공항 국제선 쪽 114Bank Money Exchange와 은행 ATM 위치 확인. 사진 기준 환전 9:00-21:00. 트래블카드 출금, 현금 엔화 보충, 리무진버스 티켓 구매 위치를 공항에서 같이 확인.', 'money', 2),
('onsite-3', 'trip-takamatsu-2026', '나오시마 버스 핵심', '미야노우라항 도착 후 2번 정류장으로 바로 이동. 츠츠지소행 시내버스는 100엔, 하차할 때 지불. 약 20분 이동 후 츠츠지소에서 베네세 구역 무료 셔틀버스로 환승.', 'move', 3),
('onsite-4', 'trip-takamatsu-2026', '베네세 무료 셔틀', '츠츠지소 → 히로시 스기모토 갤러리 → 베네세 하우스 뮤지엄 → 이우환 미술관/Valley Gallery → 지중미술관. 반대 방향은 지중미술관에서 출발해 츠츠지소로 돌아감. 버스 대기 시간이 일정의 병목.', 'move', 4),
('onsite-5', 'trip-takamatsu-2026', '나룻배체험', '선착순 성격이 강하고 원하는 시간대가 있으면 미리 예매 여부 확인. 6/23은 12:00 지중미술관 예약이 있어 오전에는 무리하지 않기.', 'note', 5)
on conflict (id) do nothing;

insert into quick_links (id, trip_id, label, kind, url) values
('link-1', 'trip-takamatsu-2026', '공유 지도', 'map', 'https://www.google.com/maps'),
('link-2', 'trip-takamatsu-2026', '날씨', 'weather', 'https://weather.com/'),
('link-3', 'trip-takamatsu-2026', '페리 시간', 'ferry', 'https://www.shikokukisen.com/'),
('link-4', 'trip-takamatsu-2026', 'Google Calendar', 'calendar', 'https://calendar.google.com/')
on conflict (id) do nothing;

insert into app_settings (id, default_trip_id, public_sensitive) values
('settings-main', 'trip-takamatsu-2026', false)
on conflict (id) do update set default_trip_id = excluded.default_trip_id;

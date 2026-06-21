-- Run this after schema.sql when the first short seed was already inserted.
-- It restores the richer local trip data without deleting anything the family added,
-- except the two placeholder place/food rows from the old sample seed.

delete from places where id in ('place-1', 'place-2');
delete from food_candidates where id in ('food-1', 'food-2');

insert into trips (id, name, region, start_date, end_date, hero_image, note) values
('trip-takamatsu-2026', '타카마쓰 가족여행', '타카마쓰 · 나오시마', '2026-06-22', '2026-06-24', '/assets/setouchi-hero.png', 'RS0741 10:30 도착, RS0742 11:40 출발. 짐을 들고 우동집/공원에 가지 않고 숙소 짐보관 후 움직이는 일정.')
on conflict (id) do update set name = excluded.name, region = excluded.region, start_date = excluded.start_date, end_date = excluded.end_date, hero_image = excluded.hero_image, note = excluded.note;

insert into trip_members (id, trip_id, name, color, role) values
('member-me', 'trip-takamatsu-2026', '예지', '#16a3a3', '지도/예약 관리'),
('member-dad', 'trip-takamatsu-2026', '승환', '#ff6f61', '컨디션/동선 확인'),
('member-minji', 'trip-takamatsu-2026', '민지', '#ffc857', '맛집/카페 후보')
on conflict (id) do update set name = excluded.name, color = excluded.color, role = excluded.role;

insert into itinerary_items (id, trip_id, date, time_label, start_time, end_time, title, description, location, priority, reservation_status, weather_impact, owner, sort_order) values
('iti-1', 'trip-takamatsu-2026', '2026-06-22', '오전', '10:30', '12:00', 'RS0741 타카마쓰 도착 / 숙소 짐보관', '10:30 도착 기준. 공항에서 바로 시내로 무리하게 뛰지 않고 12:00 숙소 짐보관 시간에 맞춰 이동. 짐 들고 우동집/공원 이동 금지.', '타카마쓰 공항 → 숙소', '필수', '확정', '낮음', '다 같이', 10),
('iti-2', 'trip-takamatsu-2026', '2026-06-22', '오후', '14:00', '16:00', '리쓰린 공원', '날씨가 괜찮으면 천천히 산책. 첫날 핵심 일정.', '리쓰린 공원', '날씨 좋으면', '해당 없음', '중간', '다 같이', 20),
('iti-3', 'trip-takamatsu-2026', '2026-06-23', '아침', '09:20', '10:10', '숙소 → 다카마쓰항 이동', 'JR 리쓰린코엔 기타구치역에서 9:20 전후 열차로 다카마쓰역 이동 후 항구로 이동.', '리쓰린코엔 기타구치역 → 다카마쓰항', '필수', '확인 필요', '낮음', '다 같이', 30),
('iti-4', 'trip-takamatsu-2026', '2026-06-23', '오전', '10:14', '11:04', '페리: 타카마쓰항 → 나오시마', '추천 페리. 소요 약 50분, 성인 편도 520엔. 도착 후 항구 앞 자전거 대여와 점심 후보 확인.', '타카마쓰항 → 미야노우라항', '필수', '시간 확정', '높음', '다 같이', 40),
('iti-5', 'trip-takamatsu-2026', '2026-06-23', '오전', '11:05', '11:45', '미야노우라항 → 츠츠지소 → 지중미술관', '페리 하차 후 2번 정류장으로 이동. 츠츠지소행 시내버스 100엔, 하차할 때 지불. 츠츠지소에서 베네세 구역 무료 셔틀버스로 지중미술관 이동. 버스 대기 시간이 핵심.', '미야노우라항 2번 정류장 → 츠츠지소 → 지중미술관', '필수', '확인 필요', '중간', '다 같이', 50),
('iti-6', 'trip-takamatsu-2026', '2026-06-23', '낮', '12:00', '13:30', '지중미술관 예약', 'Chichu Art Museum Jun 23, 2026 (Tue) 12:00. 성인 3명, 각 ¥2,500. QR은 예약 화면에서 확인. 관람 90-120분 예상.', '지중미술관', '필수', '예약 완료', '중간', '다 같이', 60),
('iti-7', 'trip-takamatsu-2026', '2026-06-23', '오후', '13:30', '16:30', '베네세 구역 미술관 후보', '이우환미술관, Valley Gallery, 베네세 하우스 뮤지엄 후보. 셔틀 시간 안 맞으면 도보/전기자전거가 빠를 수 있음.', '지중미술관 주변', '선택', '현장 판단', '중간', '다 같이', 70),
('iti-8', 'trip-takamatsu-2026', '2026-06-23', '오후', '17:00', '17:50', '페리: 나오시마 → 다카마쓰항', '추천 복귀편. 시내 도착 후 저녁 일정으로 연결.', '미야노우라항 → 다카마쓰항', '필수', '시간 확정', '높음', '다 같이', 80),
('iti-9', 'trip-takamatsu-2026', '2026-06-24', '아침', '08:00', '10:00', '체크아웃 / RS0742 공항 이동', 'RS0742 11:40 출발. 마지막 날은 관광보다 공항 이동 중심으로 줄이기. 공항에서 트래블카드 ATM/환전 필요하면 이 시간 안에 처리.', '호텔 → 타카마쓰 공항', '필수', '확인 필요', '낮음', '다 같이', 90)
on conflict (id) do update set date = excluded.date, time_label = excluded.time_label, start_time = excluded.start_time, end_time = excluded.end_time, title = excluded.title, description = excluded.description, location = excluded.location, priority = excluded.priority, reservation_status = excluded.reservation_status, weather_impact = excluded.weather_impact, owner = excluded.owner, sort_order = excluded.sort_order;

insert into places (id, trip_id, name, category, address, map_url, hours, reservation_note, sensitive_note)
select id, 'trip-takamatsu-2026', name, category, coords, 'https://www.google.com/maps/search/?api=1&query=' || split_part(coords, ',', 2) || ',' || split_part(coords, ',', 1), '확인 필요', 'My Maps에서 가져옴', note
from (values
('place-airport-1', '타카마쓰 공항 환전/ATM', '공항', '134.018922,34.219017,0', '국제선 쪽 114Bank Money Exchange, 은행 ATM. 사진 기준 운영 9:00-21:00. 트래블카드 출금/환전 확인.'),
('place-port-1', '미야노우라항 2번 버스정류장', '환승', '133.972996,34.459005,0', '페리 도착 후 재빨리 2번 정류장으로 이동. 츠츠지소행 100엔 버스 탑승.'),
('place-bus-1', '츠츠지소', '환승', '133.993486,34.438656,0', '시내버스 종점. 여기서 베네세 구역 무료 셔틀버스로 갈아타기.'),
('place-art-0', '지중미술관', '미술관', '133.986422,34.444914,0', '10:00-17:00, 마지막 입장 16:00. 날짜/시간 예약 필요. 6/23 12:00 예약 완료.'),
('place-art-1', '타카마츠시 미술관', '관광지', '134.049138,34.344046,0', ''),
('place-art-2', '리쓰린 공원', '관광지', '134.0457696,34.3299036,0', ''),
('place-art-3', '이우환 미술관', '관광지', '133.9891177,34.4485238,0', ''),
('place-art-4', 'Pumpkin by Yayoi Kusama', '관광지', '133.9956455,34.4463665,0', ''),
('place-art-5', '베네세 하우스 뮤지엄', '미술관', '133.991591,34.442386,0', '08:00-21:00, 마지막 입장 20:00.'),
('place-art-6', 'Valley Gallery', '미술관', '133.989973,34.444196,0', '09:30-16:00, 마지막 입장 15:30. 베네세 하우스 티켓에 포함.'),
('place-art-7', '히로시 스기모토 갤러리', '미술관', '133.991872,34.444019,0', '11:00-15:00, 마지막 입장 14:00. 날짜/시간 예약 필요.')
) as v(id, name, category, coords, note)
on conflict (id) do update set name = excluded.name, category = excluded.category, address = excluded.address, map_url = excluded.map_url, hours = excluded.hours, reservation_note = excluded.reservation_note, sensitive_note = excluded.sensitive_note;

insert into food_candidates (id, trip_id, name, category, location, map_url, reservation, wait_note, recommender, note, is_favorite)
select id, 'trip-takamatsu-2026', name, category, coords, 'https://www.google.com/maps/search/?api=1&query=' || split_part(coords, ',', 2) || ',' || split_part(coords, ',', 1), '확인 필요', '확인 필요', 'My Maps', note, false
from (values
('dessert-1', '산비키노 코부타 (아기돼지 세마리)', '디저트', '134.051646,34.3386338,0', ''),
('dessert-2', '브랑제리 쿠리무기', '디저트', '134.046978,34.3283155,0', ''),
('dessert-3', 'さくらドーナツ堂', '디저트', '134.052507,34.3387569,0', ''),
('dessert-4', 'As canele &. 瓦町店', '디저트', '134.0508241,34.3396691,0', '까눌레!!!!!'),
('dessert-5', 'Le Reve', '디저트', '134.0496431,34.3415212,0', '빵!!!'),
('izakaya-1', 'おばんざい家庭料理 いろいろ', '이자카야', '134.0505282,34.3408073,0', '이자카야'),
('izakaya-2', 'Okamura', '이자카야', '134.0507691,34.3411097,0', ''),
('izakaya-3', '讃岐のちょい呑み屋 EViSU / Sanuki Izakaya EViSU', '이자카야', '134.0505362,34.3398497,0', '아주 늦게까지'),
('izakaya-4', 'Issekigocho', '이자카야', '134.0506978,34.3414884,0', ''),
('food-udon-1', '가마아게 우동 오카지마 다카마츠점', '우동', '134.0491239,34.3488577,0', ''),
('food-local-1', '호네츠키도리 잇카쿠 타카마츠점', '식당', '134.0486208,34.3430677,0', ''),
('food-udon-2', '우동보 타카마츠본점', '우동', '134.0483626,34.3394937,0', ''),
('food-seafood-1', '해물 우마이몬야 하마카이도 카지야마치점', '식당', '134.0488211,34.3433379,0', ''),
('food-yakiniku-1', '야키니쿠호루몬 신묘정육점 카지야마치점', '야키니쿠', '134.0486874,34.3434107,0', ''),
('food-yakiniku-2', '야키니쿠 하나후사 본점', '야키니쿠', '134.0542011,34.3417554,0', ''),
('food-udon-3', '신페이 우동', '우동', '134.0524855,34.3416034,0', ''),
('food-udon-4', '우동 바카이치다이', '우동', '134.0585379,34.3367417,0', ''),
('food-yakiniku-3', '焼肉 丸惠 松縄店', '야키니쿠', '134.0656764,34.3165395,0', '야키니쿠'),
('food-unagi-1', '우나기 마츠모토', '식당', '134.0491649,34.3235171,0', '민물장어'),
('food-soba-1', 'Tasu Hiku', '소바', '134.0447632,34.3323896,0', '소바'),
('food-udon-5', '혼카쿠테우치모리야', '우동', '134.0473602,34.3523085,0', ''),
('food-udon-6', '사누키 우동 우에하라야 본점', '우동', '134.0453842,34.3271176,0', ''),
('food-udon-7', '마츠시타 제면소', '우동', '134.0449083,34.3350154,0', ''),
('food-yakiniku-4', '焼肉イトーロインすき焼亭', '야키니쿠', '134.0502471,34.3462657,0', '스키야키'),
('food-bistro-1', '粋香(夜) / 日々 粋香(昼)', '식당', '134.0454632,34.3430253,0', ''),
('food-bistro-2', 'Bistro Bon', '식당', '134.0495334,34.3315728,0', '함박'),
('food-yakiniku-5', '黒毛和牛ホルモン 大衆焼肉しんすけ トキワ新町店', '야키니쿠', '134.0507739,34.3412928,0', '곱창구이'),
('food-sushi-1', '鮨 猿の手', '스시', '134.0516597,34.3427279,0', '오마카세?'),
('food-local-2', 'Honetsuki-dori Ippon Gabumaru', '식당', '134.0516688,34.343559,0', ''),
('food-local-3', '엔마대왕''s 키친', '식당', '134.0516226,34.3434486,0', ''),
('food-gyoza-1', '교자야', '식당', '134.0527714,34.3429114,0', ''),
('food-udon-8', '수타 우동 무기조', '우동', '134.0603187,34.347775,0', '오픈런해야함'),
('food-sushi-2', '스시 도코로 이토한', '스시', '134.052336,34.3420079,0', '오마카세, 6시-3시'),
('food-sushi-3', '세토노마쓰리 스시 효고마치점', '스시', '134.0498007,34.3459902,0', ''),
('cafe-naoshima-1', '나오시마 커피', '카페', '134.0005878,34.4568835,0', '미야노우라항 근처 카페 후보'),
('cafe-1', '豆丸珈琲 鍛冶屋町焙煎所', '카페', '134.0492534,34.3429955,0', '원두카페'),
('cafe-2', '스벅 スターバックス コーヒー 高松上福岡店', '카페', '134.06453,34.327048,0', '스벅'),
('cafe-3', 'Kona''s Coffee Ritsurin Garden', '카페', '134.0433778,34.3239173,0', ''),
('cafe-4', 'Akaito Coffee', '카페', '133.9752235,34.4586412,0', '')
) as v(id, name, category, coords, note)
on conflict (id) do update set name = excluded.name, category = excluded.category, location = excluded.location, map_url = excluded.map_url, reservation = excluded.reservation, wait_note = excluded.wait_note, recommender = excluded.recommender, note = excluded.note;

insert into checklist_items (id, trip_id, group_name, text, owner, is_done, sort_order, is_archived) values
('check-1', 'trip-takamatsu-2026', '여행준비', '여권', '예지', false, 1, false),
('check-2', 'trip-takamatsu-2026', '여행준비', 'RS0741/RS0742 항공권 확인', '승환', false, 2, false),
('check-3', 'trip-takamatsu-2026', '여행준비', '호텔 예약 확인', '민지', false, 3, false),
('check-4', 'trip-takamatsu-2026', '여행준비', 'eSIM / 로밍', '예지', false, 4, false),
('check-5', 'trip-takamatsu-2026', '여행준비', '신용카드', '승환', false, 5, false),
('check-6', 'trip-takamatsu-2026', '여행준비', '현금 / 엔화', '민지', false, 6, false),
('check-7', 'trip-takamatsu-2026', '여행준비', '공항 ATM/환전 위치 확인', '예지', false, 7, false),
('check-8', 'trip-takamatsu-2026', '여행준비', '보조배터리', '승환', false, 8, false),
('check-9', 'trip-takamatsu-2026', '여행준비', '지중미술관 QR 확인', '민지', false, 9, false),
('check-10', 'trip-takamatsu-2026', '여행준비', '페리/리무진버스 티켓 구매 위치 확인', '예지', false, 10, false),
('check-11', 'trip-takamatsu-2026', '여행준비', '츠츠지소 셔틀 동선 확인', '승환', false, 11, false),
('check-12', 'trip-takamatsu-2026', '여행준비', '나룻배체험 예매/선착순 확인', '민지', false, 12, false)
on conflict (id) do update set group_name = excluded.group_name, text = excluded.text, owner = excluded.owner, sort_order = excluded.sort_order;

insert into gallery_items (id, trip_id, title, src, date, category, note, is_favorite, sort_order) values
('gallery-01', 'trip-takamatsu-2026', '공항 리무진버스 경로', '/assets/gallery/route-airport-bus.png', '2026-06-22', '공항/버스', '다카마쓰 공항에서 시내로 이동하는 버스 경로 참고', true, 1),
('gallery-02', 'trip-takamatsu-2026', '공항 환전/ATM', '/assets/gallery/airport-exchange-atm.png', '2026-06-22', '공항/환전', '114Bank Money Exchange, 은행 ATM. 트래블카드 출금 확인', true, 2),
('gallery-03', 'trip-takamatsu-2026', '나오시마 → 다카마쓰 시간표', '/assets/gallery/ferry-naoshima-to-takamatsu.png', '2026-06-23', '페리', '복귀편 17:00 추천', true, 3),
('gallery-04', 'trip-takamatsu-2026', '다카마쓰 → 나오시마 시간표', '/assets/gallery/ferry-takamatsu-to-naoshima.png', '2026-06-23', '페리', '10:14 출발 추천', true, 4),
('gallery-05', 'trip-takamatsu-2026', '페리 전체 표', '/assets/gallery/ferry-table-overview.png', '2026-06-23', '페리', '왕복 페리/고속페리 비교 표', false, 5),
('gallery-06', 'trip-takamatsu-2026', '베네세 셔틀 환승 안내', '/assets/gallery/benesse-shuttle-transfer.png', '2026-06-23', '버스/셔틀', '츠츠지소에서 베네세 구역 무료 셔틀 환승', true, 6),
('gallery-07', 'trip-takamatsu-2026', '셔틀 시간 하이라이트', '/assets/gallery/shuttle-times-highlight.png', '2026-06-23', '버스/셔틀', '이우환/밸리 갤러리에서 츠츠지소행 시간', false, 7),
('gallery-08', 'trip-takamatsu-2026', '이우환/밸리 버스 안내', '/assets/gallery/lee-ufan-valley-bus.png', '2026-06-23', '버스/셔틀', '이우환 미술관/Valley Gallery 앞 셔틀 안내', false, 8),
('gallery-09', 'trip-takamatsu-2026', '베네세 버스 시간표', '/assets/gallery/benesse-bus-timetable.png', '2026-06-23', '버스/셔틀', '지중미술관행/츠츠지소행 셔틀 시간표', true, 9),
('gallery-10', 'trip-takamatsu-2026', '츠츠지소 100엔 버스', '/assets/gallery/tsutsuji-town-bus.png', '2026-06-23', '버스/셔틀', '미야노우라항에서 츠츠지소행 100엔 버스 시간 참고', true, 10),
('gallery-11', 'trip-takamatsu-2026', '나오시마 지도 메모', '/assets/gallery/naoshima-map-annotated.png', '2026-06-23', '지도', '항구/미술관/츠츠지소 위치 관계', true, 11),
('gallery-12', 'trip-takamatsu-2026', '미술관 사이 이동 시간', '/assets/gallery/museum-transfer-times.png', '2026-06-23', '미술관', '지중-이우환-베네세 이동 감각', true, 12),
('gallery-13', 'trip-takamatsu-2026', '이우환 미술관 메모', '/assets/gallery/lee-ufan-note.png', '2026-06-23', '미술관', '온라인 1,200엔, 관람 50분 정도', false, 13),
('gallery-14', 'trip-takamatsu-2026', '지중미술관 메모', '/assets/gallery/chichu-note.png', '2026-06-23', '미술관', '온라인 2,500엔, 사전예약 필수, 90-120분', true, 14),
('gallery-15', 'trip-takamatsu-2026', '관람 순서 후보', '/assets/gallery/viewing-order-note.png', '2026-06-23', '미술관', 'A/B 관람 순서 후보', false, 15),
('gallery-16', 'trip-takamatsu-2026', '베네세 하우스 메모', '/assets/gallery/benesse-house-note.png', '2026-06-23', '미술관', '온라인 1,300엔, 관람 1시간 30분', false, 16),
('gallery-17', 'trip-takamatsu-2026', 'Valley Gallery 메모', '/assets/gallery/valley-gallery-note.png', '2026-06-23', '미술관', '베네세 뮤지엄 관람 시 무료, 20-30분', false, 17)
on conflict (id) do update set title = excluded.title, src = excluded.src, date = excluded.date, category = excluded.category, note = excluded.note, is_favorite = excluded.is_favorite, sort_order = excluded.sort_order;

insert into onsite_notes (id, trip_id, title, body, tone, sort_order) values
('onsite-1', 'trip-takamatsu-2026', '공항 이동', '6/24 RS0742 11:40 출발. 마지막 날은 관광보다 체크아웃과 공항 이동을 우선.', 'urgent', 1),
('onsite-2', 'trip-takamatsu-2026', '공항 환전/출금', '타카마쓰 공항 국제선 쪽 114Bank Money Exchange와 은행 ATM 위치 확인. 사진 기준 환전 9:00-21:00. 트래블카드 출금, 현금 엔화 보충, 리무진버스 티켓 구매 위치를 공항에서 같이 확인.', 'money', 2),
('onsite-3', 'trip-takamatsu-2026', '나오시마 버스 핵심', '미야노우라항 도착 후 2번 정류장으로 바로 이동. 츠츠지소행 시내버스는 100엔, 하차할 때 지불. 약 20분 이동 후 츠츠지소에서 베네세 구역 무료 셔틀버스로 환승.', 'move', 3),
('onsite-4', 'trip-takamatsu-2026', '베네세 무료 셔틀', '츠츠지소 → 히로시 스기모토 갤러리 → 베네세 하우스 뮤지엄 → 이우환 미술관/Valley Gallery → 지중미술관. 반대 방향은 지중미술관에서 출발해 츠츠지소로 돌아감. 버스 대기 시간이 일정의 병목.', 'move', 4),
('onsite-5', 'trip-takamatsu-2026', '나룻배체험', '선착순 성격이 강하고 원하는 시간대가 있으면 미리 예매 여부 확인. 6/23은 12:00 지중미술관 예약이 있어 오전에는 무리하지 않기.', 'note', 5)
on conflict (id) do update set title = excluded.title, body = excluded.body, tone = excluded.tone, sort_order = excluded.sort_order;

insert into expenses (id, trip_id, category, item, amount, currency, payer, note) values
('expense-1', 'trip-takamatsu-2026', '교통비', '페리 예상', 3120, 'JPY', '예지', '성인 3명 왕복 기준 520엔 x 2 x 3'),
('expense-2', 'trip-takamatsu-2026', '입장권', '지중미술관', 7500, 'JPY', '예지', '성인 3명, 12:00 예약, 각 2,500엔')
on conflict (id) do update set category = excluded.category, item = excluded.item, amount = excluded.amount, currency = excluded.currency, payer = excluded.payer, note = excluded.note;

insert into quick_links (id, trip_id, label, kind, url) values
('link-1', 'trip-takamatsu-2026', '공유 지도', 'map', 'https://www.google.com/maps/d/u/0/viewer?mid=1njIQAzxY74XFmaChyqYaY-q7t1KsC-M'),
('link-2', 'trip-takamatsu-2026', '날씨', 'weather', 'https://weather.com/'),
('link-3', 'trip-takamatsu-2026', '페리 시간', 'ferry', 'https://www.shikokukisen.com/'),
('link-4', 'trip-takamatsu-2026', 'Google Calendar', 'calendar', 'https://calendar.google.com/')
on conflict (id) do update set label = excluded.label, kind = excluded.kind, url = excluded.url;

insert into app_settings (id, default_trip_id, public_sensitive) values
('settings-main', 'trip-takamatsu-2026', false)
on conflict (id) do update set default_trip_id = excluded.default_trip_id, public_sensitive = excluded.public_sensitive;

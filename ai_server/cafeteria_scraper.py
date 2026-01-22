import requests
from bs4 import BeautifulSoup
import json
import os
import datetime
import pytz
import firebase_admin
from firebase_admin import credentials, firestore
import re

# ==========================================
# 1. Firebase 접속
# ==========================================
if not firebase_admin._apps:
    try:
        # 1. 환경변수 확인 (GitHub Actions 용)
        firebase_key_json = os.environ.get('FIREBASE_KEY')
        
        if firebase_key_json:
            cred_dict = json.loads(firebase_key_json)
            cred = credentials.Certificate(cred_dict)
            print("🔥 Firebase Connected via Env Var!")
        else:
            # 2. 로컬 파일 확인
            # 절대 경로 (사용자 로컬)
            key_path = "/Users/kdh/Desktop/MY_CSE/ai_server/serviceAccountKey.json"
            # 상대 경로 (ai_server 폴더 내 실행 시)
            if not os.path.exists(key_path):
                key_path = "serviceAccountKey.json"
                # ai_server 상위에서 실행 시
                if not os.path.exists(key_path):
                     key_path = "ai_server/serviceAccountKey.json"

            cred = credentials.Certificate(key_path) if os.path.exists(key_path) else None
        
        if cred:
            firebase_admin.initialize_app(cred)
            print("🔥 Firebase Connected!")
        else:
            print("⚠️ Warning: serviceAccountKey.json not found and FIREBASE_KEY not set.")
    except Exception as e:
        print(f"⚠️ Firebase Key Error: {e}")

db = firestore.client() if firebase_admin._apps else None

def scrape_and_save_menu():
    base_url = "https://www.gnu.ac.kr/main/ad/fm/foodmenu/selectFoodMenuView.do"
    
    # 한국 시간 기준
    kst = pytz.timezone("Asia/Seoul")
    today = datetime.datetime.now(tz=kst)
    # 이번주 월요일 계산 (달력은 보통 월~일 혹은 해당 주 표시)
    start_of_week = today - datetime.timedelta(days=today.weekday())
    schDt = start_of_week.strftime("%Y-%m-%d")

    print(f"📅 Request Date (Week Start): {schDt}")

    cafeterias = [
        {"name": "중앙식당", "seq": "5", "sysId": "main"},
        {"name": "교문센1층", "seq": "63", "sysId": "main"},
        {"name": "교직원식당", "seq": "4", "sysId": "main"},
        {"name": "칠암1식당", "seq": "8", "sysId": "cdorm"}, # 칠암은 시스템ID가 다를 수 있으나 url 파라미터로 제어
    ]

    all_menus = {} # { "2024-01-22": { "중앙식당": "...", "교직원": "..." } }

    for cafe in cafeterias:
        print(f"🔍 Scraping {cafe['name']}...")
        try:
            params = {
                "mi": "1341", # 메뉴 ID
                "restSeq": cafe["seq"],
                "schDt": schDt
            }
            if cafe['sysId'] == 'cdorm':
                # 칠암 등 다른 캠퍼스는 URL이 다를 수 있음. 확인 필요. 
                # 일단 공통 URL 사용해보고 안되면 예외 처리.
                # 보통 캠퍼스별 도메인이 다름 (www vs chilam 등)
                pass 

            response = requests.get(base_url, params=params, timeout=10)
            soup = BeautifulSoup(response.text, "html.parser")
            
            # 테이블 찾기
            table = soup.select_one("div.cal_box table")
            if not table:
                table = soup.select_one("table") # Fallback to any table
            
            if not table:
                print(f"   ⚠️ No table found for {cafe['name']}")
                continue

            # 날짜 헤더 파싱
            headers = table.select("thead th")
            date_map = {} # { index: "YYYY-MM-DD" }
            
            # 정규식으로 날짜 추출 (2024.01.22 또는 01.22, 구분자 유연하게)
            # YYYY.MM.DD or YYYY-MM-DD
            date_pattern_full = re.compile(r"(\d{4})[./-](\d{2})[./-](\d{2})")
            # MM.DD or MM-DD or MM/DD
            date_pattern_short = re.compile(r"(\d{2})[./-](\d{2})")

            for idx, th in enumerate(headers):
                text = th.get_text(strip=True)
                print(f"     Header[{idx}]: {text}")  # DEBUG

                match_full = date_pattern_full.search(text)
                if match_full:
                    # YYYY-MM-DD
                    date_str = f"{match_full.group(1)}-{match_full.group(2)}-{match_full.group(3)}"
                    date_map[idx] = date_str
                    continue
                
                match_short = date_pattern_short.search(text)
                if match_short:
                    # MM.DD -> YYYY-MM-DD (Use start_of_week year)
                    # 주의: 연도가 바뀌는 주간(12월 말~1월 초) 처리 필요할 수 있음
                    # 일단 간단히 start_of_week.year 사용
                    year = start_of_week.year
                    # 만약 start_of_week가 12월이고 현재 월이 1월이면 year+1? (복잡하므로 year 그대로 사용. 보통 학식은 당해년도)
                    
                    date_str = f"{year}-{match_short.group(1)}-{match_short.group(2)}"
                    date_map[idx] = date_str
            # 만약 날짜 파싱이 하나도 안되었거나 너무 적으면(1개 이하), 컬럼 순서대로(월~일) 할당 (Fallback)
            if len(date_map) <= 1:
                print("   ⚠️ Date parsing insufficient. Using column index fallback (Mon-Sun).")
                # headers[0]은 '구분'일 확률 높음. 1부터 월요일.
                # start_of_week는 월요일.
                
                for idx in range(1, len(headers)):
                    # idx=1 -> Mon (start_of_week + 0)
                    # idx=2 -> Tue (start_of_week + 1)
                    delta = idx - 1
                    target_date = start_of_week + datetime.timedelta(days=delta)
                    date_str = target_date.strftime("%Y-%m-%d")
                    date_map[idx] = date_str
                    print(f"     Fallback Header[{idx}] -> {date_str}")
            
            # 메뉴 파싱 (tbody)
            rows = table.select("tbody tr")
            for tr in rows:
                th = tr.select_one("th")
                if not th: continue
                
                row_title = th.get_text(strip=True) # 조식, 중식, 석식 등
                
                # 데이터 셀
                tds = tr.select("td")
                
                for i, td in enumerate(tds):
                    # headers 인덱스와 매칭 (td 인덱스 + 1 == th 인덱스, 보통 첫 th가 row header이므로)
                    # 구조: thead th 개수와 tbody td 개수가 맞는지 확인
                    # 보통 thead 첫번째 th는 '구분' 등 빈칸.
                    
                    # date_map의 키는 thead의 th 인덱스.
                    # tbody의 td내용은 date_map[i+1] 날짜에 해당 (td 0번 -> th 1번)
                    
                    date_key = date_map.get(i + 1)
                    if date_key:
                        content = td.get_text("\n", strip=True)
                        if content:
                            if date_key not in all_menus:
                                all_menus[date_key] = {}
                            
                            # 기존 내용 병합 (조식, 중식 등 구분)
                            existing = all_menus[date_key].get(cafe['name'], "")
                            if existing:
                                existing += f"\n\n[{row_title}]\n{content}"
                            else:
                                existing = f"[{row_title}]\n{content}"
                            
                            all_menus[date_key][cafe['name']] = existing

        except Exception as e:
            print(f"   ❌ Error: {e}")

    # Firestore 저장
    if db and all_menus:
        print(f"💾 Saving {len(all_menus)} dates to Firestore...")
        batch = db.batch()
        
        for date_key, menus in all_menus.items():
            doc_ref = db.collection('cafeteria_menus').document(date_key)
            batch.set(doc_ref, {
                "date": date_key,
                "menus": menus,
                "updated_at": firestore.SERVER_TIMESTAMP
            }, merge=True)
            
        batch.commit()
        print("✅ Menu Saved Successfully!")
    else:
        print("⚠️ No data to save or DB not connected.")
        # print(json.dumps(all_menus, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    scrape_and_save_menu()

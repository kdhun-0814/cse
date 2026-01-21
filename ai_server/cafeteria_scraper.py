import requests
from bs4 import BeautifulSoup
import json
import os
import datetime
import pytz
import firebase_admin
from firebase_admin import credentials, firestore

# ==========================================
# 1. Firebase 접속
# ==========================================
if not firebase_admin._apps:
    firebase_key_json = os.environ.get('FIREBASE_KEY')
    if firebase_key_json:
        cred_dict = json.loads(firebase_key_json)
        cred = credentials.Certificate(cred_dict)
    else:
        if os.path.exists("serviceAccountKey.json"):
            cred = credentials.Certificate("serviceAccountKey.json")
        else:
            print("⚠️ Warning: No Firebase Key found. Running in Dry Run mode (Printing only).")
            cred = None

    if cred:
        firebase_admin.initialize_app(cred)
        print("🔥 Firebase Connected!")
    else:
        print("⚠️ Firebase connection skipped.")

db = firestore.client() if firebase_admin._apps else None

def scrape_and_save_menu():
    url = "https://www.gnu.ac.kr/main/ad/fm/foodmenu/selectFoodMenuView.do?mi=1341"
    
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        # 쿠키는 상황에 따라 필요 없을 수도 있으나 기존 bap.py 참조
        "Cookie": "JSESSIONID=0200F392B15A8B5DFCA98EBCDA16B51A.worker1" 
    }

    # 한국 시간 기준 오늘 날짜
    kst = pytz.timezone("Asia/Seoul")
    today = datetime.datetime.now(tz=kst)
    schDt = today.strftime("%Y-%m-%d") # API 요청용
    doc_id = today.strftime("%Y-%m-%d") # Firestore 문서 ID

    print(f"📅 Scrape Date: {schDt}")

    cafeterias = [
        {"name": "중앙식당", "seq": "5", "sysId": "main"},
        {"name": "교문센1층", "seq": "63", "sysId": "main"},
        {"name": "교직원식당", "seq": "4", "sysId": "main"},
        {"name": "칠암", "seq": "8", "sysId": "cdorm"},
    ]

            # 헤더(요일) 파싱
            headers_list = [th.get_text(" ", strip=True) for th in calr_top_div.find("thead").find_all("th")]
            
            # 날짜 컬럼 인덱스 식별
            # headers_list 예: ['구분', '2024-01-21(화)', '2024-01-22(수)', ...]
            date_col_map = {} # { col_idx: "YYYY-MM-DD" }
            
            import re
            date_pattern = re.compile(r"(\d{4}-\d{2}-\d{2})")

            for idx, h in enumerate(headers_list):
                match = date_pattern.search(h)
                if match:
                    date_str = match.group(1)
                    date_col_map[idx] = date_str
            
            print(f"   Found dates: {list(date_col_map.values())}")

            # 행(Row) 순회
            for tr in calr_top_div.find("tbody").find_all("tr"):
                current_time_menu = "" 
                
                row_header = tr.find("th").get_text(" ", strip=True)
                if "고정메뉴" in row_header or "알레르기" in row_header or "더진국" in row_header:
                    continue

                cells = tr.find_all("td")
                
                # 각 날짜 컬럼별로 데이터 추출
                for col_idx, date_val in date_col_map.items():
                    # cells 인덱스 = header 인덱스 - 1 (구분 컬럼 제외된 td들)
                    cell_idx = col_idx - 1
                    
                    if 0 <= cell_idx < len(cells):
                         val = cells[cell_idx].get_text("\n", strip=True)
                         if val:
                             # 해당 날짜, 해당 식당에 메뉴 추가
                             if date_val not in all_menus:
                                 all_menus[date_val] = {} # { "date":..., "menus": { "식당이름": "메뉴..." } }
                             
                             if cafe['name'] not in all_menus[date_val]:
                                 all_menus[date_val][cafe['name']] = ""
                                 
                             # 기존 내용이 있으면 줄바꿈 후 추가 (조식, 중식 등 누적)
                             current_text = all_menus[date_val][cafe['name']]
                             if current_text:
                                 current_text += "\n\n"
                             current_text += f"[{row_header}]\n{val}"
                             all_menus[date_val][cafe['name']] = current_text

        except Exception as e:
            print(f"   ⚠️ Error scraping {cafe['name']}: {e}")
            # 에러 발생 시 별도 처리는 생략 (다른 식당이라도 진행)

    # Firestore 저장 (날짜별로)
    if db:
        print(f"💾 Saving {len(all_menus)} days to Firestore...")
        batch = db.batch()
        count = 0
        
        for date_key, menus_map in all_menus.items():
            doc_ref = db.collection('cafeteria_menus').document(date_key)
            # set with merge=True를 써서 기존 데이터(다른 식당 루프에서 채워졌을 수 있음)와 병합해야 함?
            # 아니, all_menus 구조를 바꿔야 함.
            # all_menus = { "2024-01-21": { "중앙": "...", "칠암": "..." } }
            
            # 위 로직에서 all_menus[date_val] 은 식당별 맵이 되어야 함.
            
            # 구조 보정:
            # all_menus 구조: { "2024-01-21": { "중앙식당": "메뉴...", "교직원": "메뉴..." } }
            
            batch.set(doc_ref, {
                "date": date_key,
                "menus": menus_map,
                "updated_at": firestore.SERVER_TIMESTAMP
            }, merge=True)
            count += 1

        batch.commit()
        print(f"✨ Done. Saved {count} documents.")
    else:
        print("🔎 [Dry Run Result]")
        print(json.dumps(all_menus, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    scrape_and_save_menu()

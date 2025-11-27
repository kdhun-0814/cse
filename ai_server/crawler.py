# ai_server/crawler.py
import requests
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore
import time
import os
import json
import re
import pickle # AI 모델 로딩용

# ==========================================
# 1. Firebase 접속 설정
# ==========================================
if not firebase_admin._apps:
    firebase_key_json = os.environ.get('FIREBASE_KEY')
    if firebase_key_json:
        # GitHub Actions 환경
        cred_dict = json.loads(firebase_key_json)
        cred = credentials.Certificate(cred_dict)
    else:
        # 로컬 환경
        if os.path.exists("serviceAccountKey.json"):
            cred = credentials.Certificate("serviceAccountKey.json")
        else:
            raise FileNotFoundError("Firebase 키 파일을 찾을 수 없습니다.")  
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ==========================================
# 2. AI 모델 로드 (없으면 키워드 방식 사용)
# ==========================================
try:
    with open('model.pkl', 'rb') as f:
        ai_model = pickle.load(f)
    print("🧠 AI 모델(model.pkl) 로드 성공!")
except:
    print("⚠️ AI 모델이 없습니다. 키워드 규칙 기반으로 작동합니다.")
    ai_model = None

BASE_HOST = "https://www.gnu.ac.kr"
BASE_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"

# ==========================================
# 3. 크롤링 함수
# ==========================================
def crawl_gnu_cse(mode='update'):
    # 안전장치: 최대 페이지 수 (전체 수집 시 500, 업데이트 시 3)
    MAX_PAGE_LIMIT = 500 if mode == 'all' else 3
    
    print(f"🚀 크롤링 시작! 모드: {mode} (최대 {MAX_PAGE_LIMIT}페이지)")
    
    page = 1
    stop_crawling = False 

    while not stop_crawling:
        if page > MAX_PAGE_LIMIT:
            print(f"   🛑 안전장치 발동: {MAX_PAGE_LIMIT}페이지 도달. 종료.")
            break

        print(f"\n📄 {page}페이지 읽는 중...", end=" ")
        target_url = f"{BASE_URL}&nttPageIndex={page}"
        
        try:
            response = requests.get(target_url)
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')
            rows = soup.select('tbody tr')
            
            if not rows:
                print("-> 글이 없습니다. 종료합니다.")
                break
            
            min_date_in_page = "9999.99.99" # 페이지 흐름 확인용

            for row in rows:
                # 제목 및 링크 추출
                title_tag = row.select_one('a.nttInfoBtn')
                if not title_tag: continue
                
                title = title_tag.get_text(strip=True)
                link_id = title_tag['data-id'] # 고유 ID
                full_url = f"{BASE_HOST}/cse/na/ntt/selectNttInfo.do?mi=17093&bbsId=4753&nttSn={link_id}"
                
                # 테이블 컬럼 추출
                cols = row.select('td')
                num_str = cols[0].get_text(strip=True) # 번호 (또는 '공지')
                
                # 1. 날짜 자동 찾기 (정규표현식)
                date_str = ""
                for col in cols:
                    text = col.get_text(strip=True)
                    if re.match(r'^\d{4}\.\d{2}\.\d{2}$', text):
                        date_str = text
                        break
                
                if not date_str: continue

                # 2. 날짜 흐름 체크 (2022년 이전 중단 로직)
                # '공지'가 아닌 일반 글만 날짜로 과거인지 판단
                if "공지" not in num_str:
                    if date_str < min_date_in_page:
                        min_date_in_page = date_str
                    
                    if date_str < "2022.01.01":
                        print(f"\n   🛑 {date_str} 발견! 2022년 이전 데이터이므로 크롤링 종료.")
                        stop_crawling = True
                        break 
                
                # 3. 고정(Pin) 여부 판단
                is_pinned = False
                if "공지" in num_str:
                    is_pinned = True
                
                # 4. 카테고리 분류 (AI + 규칙 하이브리드)
                category = "일반"
                
                if is_pinned:
                    category = "긴급" # 고정 공지는 일단 긴급으로
                elif ai_model:
                    # AI가 예측 (리스트 형태라 [0]으로 꺼냄)
                    category = ai_model.predict([title])[0]
                else:
                    # AI 없을 때 백업 규칙
                    if "장학" in title: category = "장학"
                    elif "수강" in title or "학사" in title: category = "학사"
                    elif "채용" in title or "인턴" in title: category = "취업"
                    elif "행사" in title or "대회" in title: category = "행사"
                
                # 5. DB 저장
                doc_ref = db.collection('notices').document(link_id)
                doc = doc_ref.get()
                
                if not doc.exists:
                    doc_ref.set({
                        'title': title,
                        'link': full_url,
                        'date': date_str,
                        'category': category,
                        'author': "학과사무실",
                        'is_pinned': is_pinned, # [핵심] 고정 여부 저장
                        'is_manual': False,
                        'crawled_at': firestore.SERVER_TIMESTAMP
                    })
                    # print(".", end="", flush=True) # 진행바처럼 점 찍기
                else:
                    pass

            if not stop_crawling:
                print(f"-> (~{min_date_in_page})")
            
            page += 1
            if not stop_crawling:
                time.sleep(0.5) # 서버 부하 방지

        except Exception as e:
            print(f"\n❌ 에러 발생: {e}")
            break

if __name__ == "__main__":
    # 최초 실행 시 'all', 평소엔 'update'
    crawl_gnu_cse(mode='update')
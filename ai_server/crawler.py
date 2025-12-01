from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore
import time
import os
import json
import re
import csv
import requests # 상세 페이지 크롤링용
from datetime import datetime
from gemini_classifier import classify_notice_with_gemini

# ==========================================
# 1. Firebase 접속 설정
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
            raise FileNotFoundError("Firebase 키 파일을 찾을 수 없습니다.")  
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ==========================================
# 2. 족보 로드
# ==========================================
manual_labels = {} 
try:
    with open('dataset.csv', 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        next(reader) 
        for row in reader:
            if len(row) >= 2:
                manual_labels[row[0].strip()] = row[1].strip()
    print(f"📂 족보 로드 완료: {len(manual_labels)}개 데이터")
except:
    print("⚠️ dataset.csv 없음. 100% Gemini 의존.")

# ==========================================
# 설정 및 함수
# ==========================================
START_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"
BASE_HOST = "https://www.gnu.ac.kr" # 이미지/파일 경로 결합용
CUTOFF_DATE = "2023.01.01"

def check_deadline_urgency(title):
    try:
        match = re.search(r'~(\s*)(\d{1,2})[./](\d{1,2})', title)
        if match:
            month, day = int(match.group(2)), int(match.group(3))
            now = datetime.now()
            deadline = datetime(now.year, month, day)
            if deadline < now and (now.month - month) > 6:
                 deadline = datetime(now.year + 1, month, day)
            diff = (deadline - now).days
            if 0 <= diff <= 2: return True
    except: pass
    return False

# ==========================================
# [NEW] 상세 페이지 크롤링 함수
# ==========================================
def get_notice_detail(detail_url):
    """
    상세 페이지에 접속해서 본문, 이미지, 첨부파일 정보를 가져옵니다.
    """
    try:
        # 셀레니움 대신 requests를 써서 속도를 높입니다.
        response = requests.get(detail_url)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 1. 본문 내용 (HTML 태그 구조에 따라 다를 수 있음, 일반적인 구조 타겟팅)
        # 경상대 홈페이지 구조상 'bbs_cntn' 또는 'view_con' 클래스에 본문이 있음
        content_div = soup.select_one('.bbs_cntn') or soup.select_one('.view_con')
        
        content_text = ""
        images = []
        
        if content_div:
            # 텍스트 추출 (줄바꿈 유지)
            content_text = content_div.get_text('\n', strip=True)
            
            # 이미지 URL 추출
            img_tags = content_div.select('img')
            for img in img_tags:
                src = img.get('src')
                if src:
                    # 상대 경로(/resource/...)를 절대 경로(https://...)로 변환
                    if src.startswith('/'):
                        src = BASE_HOST + src
                    images.append(src)

        # 2. 첨부파일 추출
        files = []
        # 파일 영역 찾기 (보통 .file_area 또는 .bo_file)
        file_links = soup.select('.file_area a') or soup.select('.bo_file a')
        
        for file in file_links:
            f_name = file.get_text(strip=True)
            f_url = file.get('href')
            if f_url:
                if f_url.startswith('/'):
                    f_url = BASE_HOST + f_url
                files.append({
                    'name': f_name,
                    'url': f_url
                })

        return {
            'content': content_text,
            'images': images, # 이미지 URL 리스트
            'files': files    # 파일 정보 리스트 [{name, url}]
        }

    except Exception as e:
        print(f"   ❌ 상세 수집 실패: {e}")
        return {'content': '내용을 불러오지 못했습니다.', 'images': [], 'files': []}


# ==========================================
# 3. 크롤링 메인 함수
# ==========================================
def crawl_gnu_cse(mode='all'):
    MAX_PAGE_LIMIT = 500 if mode == 'all' else 3
    print(f"🕷️ 최종 시스템 가동 (상세 내용 포함)")
    
    options = webdriver.ChromeOptions()
    options.add_argument('--headless') # 창 없이 실행
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    driver.get(START_URL)
    time.sleep(3) 

    total_count = 0
    page = 1
    stop_crawling = False

    while not stop_crawling:
        if page > MAX_PAGE_LIMIT: break

        html = driver.page_source
        soup = BeautifulSoup(html, 'html.parser')
        rows = soup.select('tbody tr')
        
        # 페이지 검증
        check_title = "제목못찾음"
        for r in rows:
            if "공지" not in r.select('td')[0].get_text():
                t = r.select_one('a.nttInfoBtn')
                if t: 
                    check_title = t.get_text(strip=True)[:10]
                    break
        print(f"\n📄 {page}페이지 스캔 중 (일반글: {check_title}...)")

        new_in_page = 0
        
        for row in rows:
            cols = row.select('td')
            if not cols: continue
            
            num_str = cols[0].get_text(strip=True)
            title_tag = row.select_one('a.nttInfoBtn')
            if not title_tag: continue
            
            title = title_tag.get_text(strip=True)
            link_id = title_tag['data-id']
            full_url = f"{BASE_HOST}/cse/na/ntt/selectNttInfo.do?mi=17093&bbsId=4753&nttSn={link_id}"
            
            date_str = ""
            for col in cols:
                text = col.get_text(strip=True)
                if re.match(r'^\d{4}\.\d{2}\.\d{2}$', text):
                    date_str = text
                    break
            
            # 날짜 필터링
            if "공지" not in num_str and date_str:
                if date_str < CUTOFF_DATE:
                    stop_crawling = True
                    break

            # --- DB 체크 ---
            doc_ref = db.collection('notices').document(link_id)
            doc = doc_ref.get()
            
            # [중요] 이미 있고, 내용(content)도 있으면 건너뜀 (시간 절약)
            if doc.exists and doc.to_dict().get('content'):
                continue 

            # --- 상세 내용 수집 (새 글이거나 내용이 없을 때만 실행) ---
            print(f"   🔍 상세 내용 긁는 중: {title[:15]}...")
            detail_data = get_notice_detail(full_url) # 위에서 만든 함수 호출
            
            # --- 분류 로직 ---
            IMPORTANT_KEYWORDS = ["수강신청", "기숙사", "휴학", "복학", "졸업","국가장학금"]
            is_pinned_on_web = "공지" in num_str
            has_important_keyword = any(keyword in title for keyword in IMPORTANT_KEYWORDS)
            is_important = is_pinned_on_web or has_important_keyword

            category = "학사"
            if title in manual_labels:
                category = manual_labels[title]
            else:
                category = classify_notice_with_gemini(title)
                time.sleep(0.5) 

            is_deadline_imminent = check_deadline_urgency(title)
            is_urgent_display = is_important or is_deadline_imminent

            # --- 저장 데이터 준비 ---
            save_data = {
                'title': title,
                'link': full_url,
                'date': date_str,
                'category': category,
                'is_important': is_important,
                'is_urgent': is_urgent_display,
                'author': "학과사무실",
                'is_manual': False,
                'crawled_at': firestore.SERVER_TIMESTAMP,
                
                # [추가됨] 상세 내용들
                'content': detail_data['content'],
                'images': detail_data['images'], # 이미지 URL 리스트
                'files': detail_data['files']    # 파일 정보 리스트
            }

            doc_ref.set(save_data, merge=True) # merge=True: 기존 필드 유지하며 덮어쓰기
            new_in_page += 1
            
            # 상세 페이지 접속 텀 (서버 부하 방지)
            time.sleep(0.2)

        print(f"   -> {new_in_page}개 처리 완료")
        
        if stop_crawling: break

        # 페이지 이동
        page += 1
        try:
            driver.execute_script(f"goPaging({page});")
            time.sleep(2) 
        except Exception as e:
            print(f"❌ 이동 실패: {e}")
            break

    driver.quit()
    print(f"\n✅ 모든 작업 완료!")

if __name__ == "__main__":
    crawl_gnu_cse(mode='all')
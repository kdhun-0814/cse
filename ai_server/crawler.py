from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore
import time
import os
import json
import re
import csv
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
# 설정
# ==========================================
START_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"
BASE_HOST = "https://www.gnu.ac.kr"
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
# 3. 상세 페이지 크롤링 (Selenium 사용)
# ==========================================
def scrape_detail_with_selenium(driver, url):
    try:
        # 새 탭 열기 및 이동
        driver.execute_script("window.open('');")
        driver.switch_to.window(driver.window_handles[1])
        driver.get(url)
        time.sleep(2) # 로딩 대기

        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # [핵심] 본문 찾기 전략 (사용자 제공 구조 기반)
        # <tr class="cont"> <td colspan="2"> ... </td> </tr>
        content_html = ""
        images = []
        files = []

        # 1. 본문 (HTML 구조 유지)
        cont_row = soup.select_one('tr.cont')
        if cont_row:
             content_td = cont_row.select_one('td')
             if content_td:
                 # 이미지 경로 절대주소로 변환
                 for img in content_td.select('img'):
                     src = img.get('src')
                     if src and src.startswith('/'):
                         img['src'] = BASE_HOST + src
                         images.append(img['src'])
                 
                 # style 속성 중 불필요한 것 제거 or 유지? 
                 # 모바일에서 보기에 너무 넓은 width나 고정된 height은 제거하는게 좋음
                 # 일단 innerHTML을 그대로 가져오되, 불필요한 공백 제거
                 content_html = content_td.decode_contents()

        # 1-1. 메타데이터 (작성자, 조회수, 등록일, 제목 등) - 테이블 구조 분석
        metadata = {'author': '학과사무실', 'views': 0, 'date': ''} 
        try:
            # 보통 content_tr 위에 다른 tr들이 있음.
            # 방법: "작성자", "조회수" 등을 포함하는 th/td 찾기
            
            # 작성자
            author_tag = soup.find(string=re.compile("작성자"))
            if author_tag:
                 # 부모나 형제 노드에서 값 찾기
                 # case: <th>작성자</th><td>홍길동</td>
                 author_td = author_tag.find_parent('th').find_next_sibling('td')
                 if author_td:
                     metadata['author'] = author_td.get_text(strip=True)
            
            # 조회수
            views_tag = soup.find(string=re.compile("조회수|조회"))
            if views_tag:
                 views_td = views_tag.find_parent('th').find_next_sibling('td')
                 if views_td:
                     try:
                         metadata['views'] = int(re.sub(r'[^0-9]', '', views_td.get_text()))
                     except: pass
            
            # 작성일 (디테일 페이지에 있다면 가져오기)
            date_tag = soup.find(string=re.compile("등록일|작성일"))
            if date_tag:
                 date_td = date_tag.find_parent('th').find_next_sibling('td')
                 if date_td:
                     metadata['date'] = date_td.get_text(strip=True)

        except Exception as e:
            print(f"   ⚠️ 메타 파싱 에러: {e}")

        # 1-2. 검색용 순수 텍스트 (Title + Content)
        content_text = ""
        if content_html:
            # HTML 태그 제거하고 텍스트만
            text_soup = BeautifulSoup(content_html, 'html.parser')
            content_text = text_soup.get_text(separator=' ', strip=True)

        # 만약 tr.cont를 못 찾으면 기존 방식(백업) 시도
        if not content_html:
            content_div = soup.select_one('.bbs_cntn') or \
                          soup.select_one('.bdv_txt') or \
                          soup.select_one('.view_con')
            if content_div:
                for img in content_div.select('img'):
                     src = img.get('src')
                     if src and src.startswith('/'):
                         img['src'] = BASE_HOST + src
                         images.append(img['src'])
                content_html = content_div.decode_contents()

        # 2. 첨부파일 찾기 (ul.file)
        # <ul class="file"> <li> <a href="..."> ... </a> </li> </ul>
        file_ul = soup.select_one('ul.file')
        if file_ul:
            file_links = file_ul.select('a')
            for file in file_links:
                # "바로보기" 버튼 등 제외하고 다운로드 링크만
                href = file.get('href')
                if href and 'fileDown' in href and not href.startswith('javascript'):
                    f_name = file.get_text(strip=True)
                    # (다운로드 : 4회) 같은 텍스트 제거하고 파일명만 남기기 위해 정제 가능하나 일단 그대로 둠
                    # 혹은 <strong> 태그 내용 제거
                    for span in file.select('strong'):
                        span.extract()
                    f_name = file.get_text(strip=True)
                    
                    if href.startswith('/'): href = BASE_HOST + href
                    
                    if not any(f['url'] == href for f in files):
                        files.append({'name': f_name, 'url': href})
        
        # 기존 방식 백업 (첨부파일)
        if not files:
            file_links = soup.select('.file_area a') or soup.select('.bo_file a')
            for file in file_links:
                f_name = file.get_text(strip=True)
                f_url = file.get('href')
                if f_url and not f_url.startswith('javascript'):
                    if f_url.startswith('/'): f_url = BASE_HOST + f_url
                    if not any(f['url'] == f_url for f in files):
                        files.append({'name': f_name, 'url': f_url})

        # 탭 닫기 및 복귀
        driver.close()
        driver.switch_to.window(driver.window_handles[0])
        
        return {
            'content': content_html, 
            'text': content_text,
            'images': images, 
            'files': files,
            'metadata': metadata
        }

    except Exception as e:
        print(f"   ❌ 상세 수집 에러: {e}")
        # 에러 나도 탭은 닫아야 함
        if len(driver.window_handles) > 1:
            driver.close()
            driver.switch_to.window(driver.window_handles[0])
        return {
            'content': '', 
            'text': '',
            'images': [],
            'files': [], 
            'metadata': {}
        }

# ==========================================
# 4. 메인 크롤러
# ==========================================
def crawl_gnu_cse(mode='all', headless=True, page_limit=None):
    if page_limit:
        MAX_PAGE_LIMIT = page_limit
    else:
        MAX_PAGE_LIMIT = 500 if mode == 'all' else 3
    print(f"🕷️ 최종 시스템 가동 (Selenium 탭 전환 방식)")
    
    options = webdriver.ChromeOptions()
    if headless:
        options.add_argument('--headless')
    
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    driver.get(START_URL)
    time.sleep(2) 

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
            
            # 날짜 확인
            date_str = ""
            for col in cols:
                text = col.get_text(strip=True)
                if re.match(r'^\d{4}\.\d{2}\.\d{2}$', text):
                    date_str = text
                    break
            
            # 날짜 컷오프
            if "공지" not in num_str and date_str:
                if date_str < CUTOFF_DATE:
                    print(f"   🛑 2023년 이전 데이터 발견 ({date_str}). 종료.")
                    stop_crawling = True
                    break

            # --- DB 중복 체크 (내용 있으면 패스) ---
            doc_ref = db.collection('notices').document(link_id)
            doc = doc_ref.get()
            
            # 내용(content)까지 이미 꽉 차있으면 건너뜀
            if doc.exists and doc.to_dict().get('content'):
                continue 

            # --- [상세 내용 수집] ---
            # Selenium 브라우저를 그대로 넘겨줘서 쿠키 유지!
            print(f"   🔍 상세 수집: {title[:10]}...", end="")
            detail_data = scrape_detail_with_selenium(driver, full_url)
            print(" 완료")

            # --- 분류 로직 (중요/카테고리/긴급) ---
            # 중요 공지 키워드 확장
            IMPORTANT_KEYWORDS = ["수강신청", "기숙사", "휴학", "복학", "졸업", "국가장학금", "등록금", "장학금"]
            is_pinned_on_web = "공지" in num_str
            has_important_keyword = any(keyword in title for keyword in IMPORTANT_KEYWORDS)
            
            # 중요: 웹 고정(공지 번호)이거나 키워드 포함 시
            is_important = is_pinned_on_web or has_important_keyword

            category = "학사"
            if title in manual_labels:
                category = manual_labels[title]
            else:
                category = classify_notice_with_gemini(title)
                time.sleep(0.5) 

            is_deadline_imminent = check_deadline_urgency(title)
            # 긴급: 중요 공지이면서 마감 임박인 경우 (또는 관리자 수동 설정)
            # 여기서는 '자동' 긴급 로직만 설정
            is_urgent_display = is_important and is_deadline_imminent

            # --- 저장 ---
            final_author = detail_data['metadata'].get('author', "학과사무실")
            if final_author == "학과사무실" and "작성자" in title: 
                 pass

            final_date = date_str 
            if detail_data['metadata'].get('date'):
                final_date = detail_data['metadata']['date']

            save_data = {
                'title': title,
                'link': full_url,
                'date': final_date,
                'category': category,
                'is_important': is_important,
                'is_urgent': is_urgent_display, # 초기값 (관리자가 바꿀 수 있음)
                
                'author': final_author,
                'views': detail_data['metadata'].get('views', 0),
                # views_today는 여기서 건드리지 않음 (0으로 덮어쓰면 안됨)
                
                'is_manual': False,
                'crawled_at': firestore.SERVER_TIMESTAMP,
                
                'content': detail_data['content'],
                'content_text': detail_data['text'],
                'images': detail_data['images'], 
                'files': detail_data['files']
            }
            
            # views_today 필드가 없으면 0으로 초기화 (merge=True라 기존 값 유지됨)
            # 하지만 덮어쓰기 위해 set(merge=True) 사용중
            # set을 쓰면 없는 필드는 보존되나? merge=True면 보존됨.
            # 단, 새 문서일 경우 views_today가 없을 수 있음.
            
            if not doc.exists:
                save_data['views_today'] = 0
            
            doc_ref.set(save_data, merge=True)
            new_in_page += 1

# ==========================================
# 5. 데일리 조회수 초기화 (자정 실행용)
# ==========================================
def reset_daily_views():
    print("🌙 자정 작업: 일일 조회수(views_today) 초기화 시작...")
    batch = db.batch()
    count = 0
    
    # views_today가 0보다 큰 것만 가져와서 0으로 만듦
    docs = db.collection('notices').where('views_today', '>', 0).stream()
    
    for doc in docs:
        batch.update(doc.reference, {'views_today': 0})
        count += 1
        if count % 400 == 0: 
            batch.commit()
            batch = db.batch()
            
    if count > 0:
        batch.commit()
        
    print(f"✅ 총 {count}개 공지의 일일 조회수 초기화 완료.")
            
        print(f"   -> {new_in_page}개 처리 완료")
        
        if stop_crawling: break

        # 페이지 이동 (goPaging)
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
    # [GitHub Actions / Cron 모드]
    # 스케줄러에 의해 실행되므로 루프 없이 1회 실행 후 종료
    # mode='recent' -> 앞쪽 3페이지만 빠르게 스캔
    print(f"⏰ 정기 크롤링 시작: {datetime.now()}")
    crawl_gnu_cse(mode='recent', headless=True)
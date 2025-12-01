from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import csv
import time

# 목표: 1000개
TARGET_COUNT = 1000
START_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"

def collect_data_selenium():
    print(f"🕷️ 셀레니움 실행 (HTML 분석 완료: goPaging 모드 / 목표: {TARGET_COUNT}개)")
    
    options = webdriver.ChromeOptions()
    # options.add_argument('headless') # 창 숨기려면 주석 해제
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    driver.get(START_URL)
    time.sleep(2) 

    f = open('dataset.csv', 'w', encoding='utf-8-sig', newline='')
    wr = csv.writer(f)
    wr.writerow(['title', 'category']) 

    total_count = 0
    page = 1
    seen_titles = set()

    while total_count < TARGET_COUNT:
        # HTML 가져오기
        html = driver.page_source
        soup = BeautifulSoup(html, 'html.parser')
        rows = soup.select('tbody tr')
        
        # [검증] 페이지 확인용 제목 출력
        check_title = "제목못찾음"
        for r in rows:
            # 공지가 아닌 첫 번째 글 찾기
            if "공지" not in r.select('td')[0].get_text():
                t = r.select_one('a.nttInfoBtn')
                if t: 
                    check_title = t.get_text(strip=True)[:10]
                    break
        
        print(f"\n📄 {page}페이지 스캔 중 (일반글: {check_title}...)")

        new_in_page = 0
        for row in rows:
            cols = row.select('td')
            # 1. 상단 공지 패스
            if not cols or "공지" in cols[0].get_text(strip=True):
                continue

            title_tag = row.select_one('a.nttInfoBtn')
            if not title_tag: continue
            
            title = title_tag.get_text(strip=True)
                
            if title in seen_titles:
                continue
            
            # --- [수정된 카테고리 7종 분류 로직] ---
            category = "학사" # 기본값 (딱히 없으면 학사로)
                # 1. 중요 (상단 공지)
            if "공지" in cols[0].get_text(strip=True):
                    category = "중요"
                
                # 2. 키워드 기반 분류
            elif "장학" in title: 
                    category = "장학"
            elif "공모전" in title or "대회" in title or "경진" in title or "아이디어" in title: 
                    category = "공모전"
            elif "채용" in title or "인턴" in title or "취업" in title or "사원" in title or "LINC" in title: 
                    category = "취업" # (오타 '튀업' 수정완료)
            elif "특강" in title or "설명회" in title or "교육" in title or "세미나" in title or "캠프" in title: 
                    category = "외부행사"
            elif "학생회" in title or "MT" in title or "OT" in title or "총회" in title or "간식" in title: 
                    category = "학과행사" # (보통 관리자가 올리지만 키워드도 추가)
            elif "수강" in title or "졸업" in title or "성적" in title or "등록" in title: 
                    category = "학사"

            wr.writerow([title, category])
            seen_titles.add(title)
            total_count += 1
            new_in_page += 1
            
            if total_count >= TARGET_COUNT: break
        
        print(f"   -> {new_in_page}개 저장 (누적 {total_count}개)")
        if total_count >= TARGET_COUNT: break

        # 3. [핵심] 페이지 이동 (HTML 분석 결과 반영)
        page += 1
        try:
            print(f"   🏃 {page}페이지로 이동 (goPaging({page}) 실행)...")
            
            # 보내주신 HTML에 있는 함수 'goPaging'을 직접 실행합니다.
            # 이것은 사용자가 숫자를 클릭하는 것과 100% 동일합니다.
            driver.execute_script(f"goPaging({page});")
            
            time.sleep(2) # 로딩 대기
            
        except Exception as e:
            print(f"❌ 이동 실패: {e}")
            break

    driver.quit()
    f.close()
    print(f"\n✅ 수집 완료! 총 {total_count}개 저장됨.")

if __name__ == "__main__":
    collect_data_selenium()
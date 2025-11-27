import requests
from bs4 import BeautifulSoup
import csv
import time

TARGET_COUNT = 1000

# URL을 쪼갭니다 (기본 주소 + 파라미터)
BASE_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do"
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def collect_data_unique():
    print(f"🕷️ 데이터 수집 시작 (목표: {TARGET_COUNT}개)")
    
    f = open('dataset.csv', 'w', encoding='utf-8-sig', newline='')
    wr = csv.writer(f)
    wr.writerow(['title', 'category']) 

    count = 0
    page = 1
    seen_titles = set()

    while count < TARGET_COUNT:
        # [핵심 수정] URL 뒤에 붙이는 대신, params 딕셔너리로 깔끔하게 전달
        params = {
            'mi': 17093,
            'bbsId': 4753,
            'nttPageIndex': page  # 페이지 번호 자동 적용
        }
        
        try:
            # params를 넣어서 요청
            response = requests.get(BASE_URL, headers=HEADERS, params=params)
            soup = BeautifulSoup(response.text, 'html.parser')
            rows = soup.select('tbody tr')
            
            if not rows: 
                print("   -> 글이 없습니다. 종료.")
                break
            
            new_in_page = 0
            
            for row in rows:
                # 1. '공지'라고 적힌 상단 고정글은 무조건 건너뜁니다.
                # (이유: 모든 페이지에 중복으로 나오기 때문에 헷갈림 방지)
                cols = row.select('td')
                if not cols: continue
                
                num_text = cols[0].get_text(strip=True)
                if "공지" in num_text:
                    continue # 고정 공지는 수집 안 함 (일반 글만 수집해서 학습)

                title_tag = row.select_one('a.nttInfoBtn')
                if not title_tag: continue
                
                title = title_tag.get_text(strip=True)
                
                # 중복 체크
                if title in seen_titles:
                    continue
                
                # 분류 로직 (임시)
                category = "일반"
                if "장학" in title: category = "장학"
                elif "수강" in title or "학사" in title or "성적" in title: category = "학사"
                elif "채용" in title or "인턴" in title or "모집" in title: category = "취업"
                elif "행사" in title or "대회" in title or "특강" in title: category = "행사"

                wr.writerow([title, category])
                seen_titles.add(title)
                count += 1
                new_in_page += 1
                
                if count >= TARGET_COUNT: break
            
            # 로그 출력: 이번 페이지에서 진짜 새로운 글을 찾았는지 확인
            if new_in_page > 0:
                print(f"📄 {page}페이지: {new_in_page}개 저장 완료 (누적 {count}개)")
            else:
                print(f"📄 {page}페이지: 건질 게 없음 (다 중복이거나 공지)")

            page += 1
            time.sleep(0.3)
            
        except Exception as e:
            print(f"❌ 에러 발생: {e}")
            break
            
    f.close()
    print(f"\n✅ 수집 완료! 총 {count}개 저장됨.")

if __name__ == "__main__":
    collect_data_unique()
import requests
from bs4 import BeautifulSoup
import json
from typing import List, Dict
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# --- [중요] 설정값: 이곳의 주소를 실제 학과 홈페이지 주소로 맞춰주세요 ---
# 1. 목록 페이지 URL (크롤링할 게시판 주소)
BOARD_LIST_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753"

# 2. 상세 페이지 기본 URL (게시물 클릭 시 이동하는 기본 경로)
# 보통 목록 URL과 앞부분이 같습니다. (예: https://www.gnu.ac.kr/cse/na/ntt)
BOARD_BASE_URL = "https://www.gnu.ac.kr/cse/na/ntt/selectNttInfo.do?mi=17093&bbsId=4753&nttSn"

# 3. CSS Selector 설정 (보내주신 HTML 기준)
BOARD_CONTAINER_SELECTOR = "div.BD_list table tbody tr" 
TITLE_SELECTOR = "td.ta_l a.nttInfoBtn"
DATE_SELECTOR = "td:nth-child(4)"
CONTENT_SELECTOR = "div.BD_view" # 상세 페이지 본문 영역
# -------------------------------------------------------------------


def crawl_detail(full_url: str) -> str:
    """
    상세 페이지의 본문을 가져옵니다.
    """
    if not full_url or not full_url.startswith('http'):
        return "URL 오류"

    try:
        response = requests.get(full_url, timeout=5)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 상세 본문 추출
        content_element = soup.select_one(CONTENT_SELECTOR)
        
        if content_element:
            return content_element.get_text(separator=' ', strip=True)
        else:
            return "본문 내용 없음 (CONTENT_SELECTOR 확인 필요)"
            
    except Exception as e:
        print(f"  [상세 크롤링 오류] {e}")
        return "접근 불가"


def crawl_notices() -> List[Dict]:
    """
    공지사항 목록을 크롤링합니다.
    """
    notices = []
    print(f"크롤링 시작: {BOARD_LIST_URL}")

    try:
        # 1. 목록 페이지 접속
        response = requests.get(
            BOARD_LIST_URL,
            headers={'User-Agent': 'Mozilla/5.0'},
            timeout=10
        )
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 2. 게시글 행(tr) 선택
        post_rows = soup.select(BOARD_CONTAINER_SELECTOR)
        
        if not post_rows:
            print("게시글 목록을 찾지 못했습니다. BOARD_CONTAINER_SELECTOR를 확인하세요.")
            return []

        # 3. 데이터 추출
        for index, row in enumerate(post_rows):
            title_element = row.select_one(TITLE_SELECTOR)
            date_element = row.select_one(DATE_SELECTOR)
            
            if title_element and date_element:
                title = title_element.get_text(strip=True)
                date = date_element.get_text(strip=True)
                
                # data-id 추출 (게시물 고유 번호)
                data_id = title_element.get('data-id')
                
                if data_id:
                    # 상세 URL 생성: BOARD_BASE_URL에 게시물 ID를 붙입니다.
                    full_url = f"{BOARD_BASE_URL}={data_id}"
                else:
                    full_url = "링크 없음"

                # 상세 내용 크롤링
                # 속도 테스트를 위해 일부만 크롤링하려면 아래 주석을 해제하세요.
                # if index >= 3: break 
                content = crawl_detail(full_url)
                
                notice_data = {
                    'id': index + 1,
                    'title': title,
                    'date': date,
                    'url': full_url,
                    'content': content,
                    'category': '미분류'
                }
                notices.append(notice_data)
                print(f"  - 수집 완료: {title}")

    except Exception as e:
        print(f"전체 목록 크롤링 중 오류 발생: {e}")
        
    return notices


if __name__ == "__main__":
    crawled_data = crawl_notices()

    if crawled_data:
        try:
            # --- Firebase 연결 ---
            # 서비스 계정 키 파일 경로
            cred = credentials.Certificate("/Users/kdh/Desktop/CseApp/serviceAccountKey.json")
            
            # Firebase 앱 초기화 (이미 초기화되었다면 오류 방지)
            if not firebase_admin._apps:
                firebase_admin.initialize_app(cred)

            # Firestore 클라이언트 가져오기
            db = firestore.client()
            print("\nFirebase에 성공적으로 연결되었습니다.")

            # --- Firestore에 데이터 저장 ---
            # 'notices' 컬렉션에 각 공지사항을 문서로 저장
            for notice in crawled_data:
                # 문서 ID를 'id' 필드 값으로 설정
                doc_ref = db.collection('notices').document(str(notice['id']))
                doc_ref.set(notice)
            
            print(f"\n총 {len(crawled_data)}개의 공지사항을 Firestore에 저장했습니다.")

        except Exception as e:
            print(f"\nFirebase 연결 또는 데이터 저장 중 오류 발생: {e}")
    else:
        print("\n데이터가 없습니다. 설정값(URL, Selector)을 다시 확인해주세요.")x
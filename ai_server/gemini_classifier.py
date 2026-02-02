import requests
import json
import time
import os

# 1. API 키 설정
# 보안을 위해 환경변수 사용 권장
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    # 로컬 테스트용 (필요시 주석 처리 후 입력, 절대 커밋 금지)
    # GEMINI_API_KEY = "YOUR_API_KEY_HERE"
    print("⚠️ GEMINI_API_KEY 환경변수가 설정되지 않았습니다.")

def keyword_fallback(title):
    """
    Gemini API 실패 시 사용할 키워드 기반 분류기
    """
    title = title.replace(" ", "") # 공백 제거 후 검색
    
    # 1. 공모전/대회
    if any(k in title for k in ["공모전", "경진대회", "대회", "아이디어톤", "해커톤", "캡스톤", "팀모집", "챌린지"]):
        return "공모전"
    
    # 2. 장학
    if any(k in title for k in ["장학", "장학생", "국가장학", "등록금", "생활비", "지원금"]):
        if "근로" in title: return "장학" 
        return "장학"
        
    # 3. 취업
    if any(k in title for k in ["채용", "취업", "인턴", "현장실습", "LINC", "박람회", "직무", "나란히", "추천", "모집"]):
        if "서포터즈" in title or "봉사" in title: return "외부행사"
        return "취업"

    # 4. 학과행사
    if any(k in title for k in ["학생회", "총회", "간식", "MT", "OT", "오리엔테이션", "새터", "학위수여식", "졸업작품"]):
        return "학과행사"
        
    # 5. 외부행사 (행사 -> 외부행사로 명확화)
    if any(k in title for k in ["특강", "설명회", "교육", "서포터즈", "조사", "참가자", "전시회", "캠프", "프로그램"]):
        if "채용" in title: return "취업"
        return "외부행사"

    # 6. 학사 (기본값)
    return "학사"

def classify_notice_with_gemini(title):
    # 2. 모델 설정 (Gemini 2.0 Flash)
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}"
    headers = { 'Content-Type': 'application/json' }

    prompt_text = f"""
    당신은 대학교 학과 공지사항 분류 전문가입니다.
    아래 제목을 보고 [장학, 취업, 학사, 외부행사, 학과행사, 공모전] 중 가장 적절한 하나를 선택해서 단어만 출력하세요.
    
    [분류 기준]
    - 학사: 수강신청, 졸업, 성적, 휴학/복학, 예비군, 강의평가, 학적, 전과
    - 장학: 장학금 신청, 선발, 지급 안내, 근로장학생
    - 취업: 채용, 인턴, 현장실습, LINC, 취업박람회, 직무캠프, 추천채용
    - 외부행사: 외부 기관 주최 특강, 설명회, 교육, 서포터즈 모집, 설문조사, 대외활동
    - 학과행사: 학생회 주관, MT, 간식행사, 총회, 학과 전용 행사, 학위수여식
    - 공모전: 경진대회, 공모전, 해커톤, 아이디어 대회, 챌린지, 캡스톤 팀 모집

    제목: "{title}"
    """
    data = { "contents": [{ "parts": [{"text": prompt_text}] }] }

    max_retries = 3
    retry_delay = 2  # 시작 대기 시간 (초)

    for attempt in range(max_retries):
        try:
            response = requests.post(url, headers=headers, data=json.dumps(data))
            
            if response.status_code == 200:
                result = response.json()
                if 'candidates' in result and result['candidates']:
                    category = result['candidates'][0]['content']['parts'][0]['text'].strip()
                    valid_list = ["장학", "취업", "학사", "외부행사", "학과행사", "공모전"]
                    for v in valid_list:
                        if v in category:
                            return v
                    return keyword_fallback(title) 
                else:
                    return keyword_fallback(title)
            
            elif response.status_code == 429:
                print(f"   ⚠️ Gemini 429 Too Many Requests. {retry_delay}초 후 재시도... ({attempt+1}/{max_retries})")
                time.sleep(retry_delay)
                retry_delay *= 2 # 지수 백오프 (2초 -> 4초 -> 8초)
                continue

            elif response.status_code == 403:
                # 403 (Quota/Permission) -> 즉시 키워드 백업 사용 (무료 API 한계)
                print(f"   ⚠️ Gemini 403 (Quota/Perm). 키워드 분류로 대체.")
                return keyword_fallback(title)
            
            else:
                print(f"⚠️ Gemini 에러: {response.status_code}")
                return keyword_fallback(title)

        except Exception as e:
            print(f"⚠️ 요청 실패: {e}")
            return keyword_fallback(title)
    
    # 재시도 횟수 초과 시
    print("   ❌ 재시도 횟수 초과. 키워드 분류로 넘어갑니다.")
    return keyword_fallback(title)

# 테스트
if __name__ == "__main__":
    print(classify_notice_with_gemini("2025학년도 1학기 수강신청 안내"))
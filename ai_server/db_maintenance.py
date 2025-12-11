import firebase_admin
from firebase_admin import credentials, firestore
import json
import os
from datetime import datetime, timedelta

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
            # 상위 디렉토리나 다른 경로 확인 (필요시)
            raise FileNotFoundError("Firebase 키 파일을 찾을 수 없습니다.")
            
    firebase_admin.initialize_app(cred)

db = firestore.client()

def delete_old_notices(days_to_keep=365):
    """
    현재 날짜로부터 days_to_keep일 지난 공지사항 삭제
    (날짜 형식이 'YYYY.MM.DD' 문자열이라고 가정)
    """
    print(f"🧹 데이터 정리 시작: 최근 {days_to_keep}일 데이터만 유지합니다.")
    
    cutoff_date = datetime.now() - timedelta(days=days_to_keep)
    cutoff_str = cutoff_date.strftime("%Y.%m.%d")
    print(f"   기준 날짜: {cutoff_str} 이전 데이터 삭제")

    # 'date' 필드가 문자열 'YYYY.MM.DD' 형식이면 문자열 비교 가능 (ISO 8601 유사성)
    docs = db.collection('notices').where('date', '<', cutoff_str).stream()
    
    count = 0
    batch = db.batch()
    
    for doc in docs:
        print(f"   🗑️ 삭제 대상: {doc.id} ({doc.to_dict().get('date')}) - {doc.to_dict().get('title')}")
        batch.delete(doc.reference)
        count += 1

        if count % 400 == 0: # Firestore 배치 한도 500
            batch.commit()
            batch = db.batch()
            print("   ...배치 실행 중...")

    if count > 0:
        batch.commit()
    
    print(f"✅ 총 {count}개의 오래된 공지가 삭제되었습니다.")

def delete_all_notices():
    """
    모든 공지사항 데이터를 삭제합니다 (초기화용)
    """
    print("⚠️ 경고: 모든 공지사항 데이터를 삭제합니다...")
    docs = db.collection('notices').stream()
    
    count = 0
    batch = db.batch()
    
    for doc in docs:
        print(f"   🗑️ 삭제: {doc.id}")
        batch.delete(doc.reference)
        count += 1
        
        if count % 400 == 0:
            batch.commit()
            batch = db.batch()
            
    if count > 0:
        batch.commit()
        
    print(f"✅ 전체 데이터 삭제 완료: {count}개")

if __name__ == "__main__":
    # 예: 1년(365일) 지난 것 삭제
    # delete_old_notices(days_to_keep=365)
    
    # [주의] 전체 삭제
    delete_all_notices()

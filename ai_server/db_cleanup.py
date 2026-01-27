import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import os
import json

# Firebase 초기화
if not firebase_admin._apps:
    try:
        firebase_key_json = os.environ.get('FIREBASE_KEY')
        if firebase_key_json:
            cred_dict = json.loads(firebase_key_json)
            cred = credentials.Certificate(cred_dict)
        else:
            key_path = "/Users/kdh/Desktop/MY_CSE/ai_server/serviceAccountKey.json"
            if not os.path.exists(key_path):
                key_path = "serviceAccountKey.json"
            cred = credentials.Certificate(key_path) if os.path.exists(key_path) else None
        
        if cred:
            firebase_admin.initialize_app(cred)
            print("🔥 Firebase Connected!")
        else:
            print("⚠️ Warning: serviceAccountKey.json not found")
            exit(1)
    except Exception as e:
        print(f"⚠️ Firebase Key Error: {e}")
        exit(1)

db = firestore.client()

def delete_old_notices():
    """3년 이상 된 공지사항 삭제"""
    print("🗑️ 공지사항 정리 시작...")
    
    # 3년 전 날짜 계산
    three_years_ago = datetime.now() - timedelta(days=3*365)
    cutoff_date = three_years_ago.strftime('%Y-%m-%d')
    
    print(f"📅 기준 날짜: {cutoff_date} 이전 데이터 삭제")
    
    try:
        # 3년 이상 된 공지 조회
        old_notices = db.collection('notices').where('date', '<', cutoff_date).stream()
        
        deleted_count = 0
        batch = db.batch()
        batch_count = 0
        
        for notice in old_notices:
            batch.delete(notice.reference)
            batch_count += 1
            deleted_count += 1
            
            # Firestore batch는 최대 500개까지
            if batch_count >= 500:
                batch.commit()
                print(f"  ✅ {batch_count}개 삭제 완료")
                batch = db.batch()
                batch_count = 0
        
        # 남은 항목 삭제
        if batch_count > 0:
            batch.commit()
            print(f"  ✅ {batch_count}개 삭제 완료")
        
        print(f"✅ 총 {deleted_count}개의 오래된 공지사항 삭제 완료")
        
    except Exception as e:
        print(f"❌ 공지사항 삭제 중 오류: {e}")

def delete_old_cafeteria_menus():
    """3년 이상 된 학식 메뉴 삭제"""
    print("\n🗑️ 학식 메뉴 정리 시작...")
    
    # 3년 전 날짜 계산
    three_years_ago = datetime.now() - timedelta(days=3*365)
    cutoff_date = three_years_ago.strftime('%Y-%m-%d')
    
    print(f"📅 기준 날짜: {cutoff_date} 이전 데이터 삭제")
    
    try:
        # 3년 이상 된 학식 메뉴 조회
        old_menus = db.collection('cafeteria_menus').where('date', '<', cutoff_date).stream()
        
        deleted_count = 0
        batch = db.batch()
        batch_count = 0
        
        for menu in old_menus:
            batch.delete(menu.reference)
            batch_count += 1
            deleted_count += 1
            
            # Firestore batch는 최대 500개까지
            if batch_count >= 500:
                batch.commit()
                print(f"  ✅ {batch_count}개 삭제 완료")
                batch = db.batch()
                batch_count = 0
        
        # 남은 항목 삭제
        if batch_count > 0:
            batch.commit()
            print(f"  ✅ {batch_count}개 삭제 완료")
        
        print(f"✅ 총 {deleted_count}개의 오래된 학식 메뉴 삭제 완료")
        
    except Exception as e:
        print(f"❌ 학식 메뉴 삭제 중 오류: {e}")

def cleanup_old_data():
    """3년 이상 된 데이터 일괄 정리"""
    print("=" * 50)
    print("🧹 데이터베이스 정리 작업 시작")
    print("=" * 50)
    
    delete_old_notices()
    delete_old_cafeteria_menus()
    
    print("\n" + "=" * 50)
    print("✅ 데이터베이스 정리 작업 완료")
    print("=" * 50)

if __name__ == "__main__":
    cleanup_old_data()

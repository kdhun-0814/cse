import firebase_admin
from firebase_admin import credentials, messaging, firestore
import time
import os
import json

# ==========================================
# Firebase 초기화
# ==========================================
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

def send_push_for_notice(notice_id):
    """특정 공지에 대한 푸시 알림 발송"""
    try:
        # 1. 공지 정보 가져오기
        notice_doc = db.collection('notices').document(notice_id).get()
        if not notice_doc.exists:
            print(f"❌ 공지 {notice_id} 없음")
            return
        
        notice_data = notice_doc.to_dict()
        title = notice_data.get('title', '새 공지')
        category = notice_data.get('category', '전체')
        
        print(f"📢 푸시 발송 시작: [{category}] {title}")
        
        # 2. 푸시 수신 동의한 유저 찾기
        users_query = db.collection('users').where('isPushEnabled', '==', True).stream()
        
        tokens = []
        for user in users_query:
            user_data = user.to_dict()
            
            # 카테고리별 설정 확인
            push_settings = user_data.get('push_settings', {})
            category_enabled = push_settings.get(category, True)  # 기본값 True
            
            if category_enabled:
                fcm_token = user_data.get('fcm_token')
                if fcm_token:
                    tokens.append(fcm_token)
        
        if not tokens:
            print("⚠️ 푸시 수신 대상 없음")
            # 플래그 초기화
            db.collection('notices').document(notice_id).update({
                'push_requested': False,
                'push_sent_at': firestore.SERVER_TIMESTAMP,
                'push_recipient_count': 0,
            })
            return
        
        print(f"📱 수신 대상: {len(tokens)}명")
        
        # 3. 메시지 생성 및 발송 (배치 처리)
        # FCM은 한 번에 최대 500개 토큰 지원
        batch_size = 500
        total_success = 0
        total_failure = 0
        
        for i in range(0, len(tokens), batch_size):
            batch_tokens = tokens[i:i + batch_size]
            
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=f"[{category}] 새 공지",
                    body=title,
                ),
                data={
                    'notice_id': notice_id,
                    'category': category,
                    'type': 'notice',
                },
                tokens=batch_tokens,
            )
            
            try:
                response = messaging.send_multicast(message)
                total_success += response.success_count
                total_failure += response.failure_count
                
                # 실패한 토큰 처리 (선택사항)
                if response.failure_count > 0:
                    failed_tokens = [
                        batch_tokens[idx] for idx, resp in enumerate(response.responses)
                        if not resp.success
                    ]
                    print(f"⚠️ 실패한 토큰 {len(failed_tokens)}개")
                    # TODO: 실패한 토큰을 DB에서 제거하는 로직 추가 가능
                    
            except Exception as e:
                print(f"❌ 배치 발송 실패: {e}")
                total_failure += len(batch_tokens)
        
        print(f"✅ 푸시 발송 완료: 성공 {total_success}/{len(tokens)}")
        
        # 4. 플래그 초기화 및 발송 기록
        db.collection('notices').document(notice_id).update({
            'push_requested': False,
            'push_sent_at': firestore.SERVER_TIMESTAMP,
            'push_recipient_count': total_success,
        })
        
    except Exception as e:
        print(f"❌ 푸시 발송 오류: {e}")

def monitor_push_requests():
    """push_requested가 true인 공지 감지 및 발송"""
    print("🚀 푸시 알림 모니터링 시작...")
    print("   - 10초마다 push_requested=true 공지 확인")
    print("   - Ctrl+C로 종료\n")
    
    try:
        while True:
            # push_requested가 true인 공지 찾기
            notices = db.collection('notices').where('push_requested', '==', True).stream()
            
            for notice in notices:
                print(f"\n🔔 푸시 요청 감지: {notice.id}")
                send_push_for_notice(notice.id)
            
            time.sleep(10)  # 10초마다 체크
            
    except KeyboardInterrupt:
        print("\n\n⏹️ 모니터링 종료")

if __name__ == "__main__":
    monitor_push_requests()

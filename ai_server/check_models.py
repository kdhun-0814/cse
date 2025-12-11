# ai_server/check_models.py
import requests
import os

# 여기에 API 키를 넣으세요
GEMINI_API_KEY = "AIzaSyAfiDe3Zbzt2e3aJxHyF6Qqrv_HHWM7tIU" 

def list_models():
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={GEMINI_API_KEY}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print("✅ 사용 가능한 모델 목록:")
            for m in models:
                # 'generateContent' 기능을 지원하는 모델만 출력
                if 'generateContent' in m['supportedGenerationMethods']:
                    print(f"- {m['name']}") # 예: models/gemini-1.5-flash
        else:
            print(f"❌ 에러 발생: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ 실행 실패: {e}")

if __name__ == "__main__":
    list_models()
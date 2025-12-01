# ai_server/check_models.py
import google.generativeai as genai
import os
import sys

# API 키 설정 (직접 넣거나 환경변수)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY is None:
    print("🚨 에러: GEMINI_API_KEY 환경 변수가 설정되지 않았습니다.")
    print("💡 해결 방법: 시스템 환경 변수에 GEMINI_API_KEY를 추가하고 발급받은 API 키를 값으로 설정해주세요.")
    sys.exit(1)

genai.configure(api_key=GEMINI_API_KEY)

print("🔍 사용 가능한 모델 목록:")
for m in genai.list_models():
    if 'generateContent' in m.supported_generation_methods:
        print(f"- {m.name}")
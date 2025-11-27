# ai_server/train_ai.py
import pandas as pd
import pickle # 모델 저장용
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split

def train_model():
    print("📚 AI 학습을 시작합니다...")

    # 1. 데이터 불러오기
    try:
        df = pd.read_csv('dataset.csv')
    except:
        print("❌ 'dataset.csv' 파일이 없습니다. 1단계(데이터 수집)부터 진행하세요.")
        return

    # 데이터가 비어있는지 확인
    if df.empty:
        print("❌ 데이터가 없습니다.")
        return

    print(f"   -> 총 {len(df)}개의 데이터를 학습합니다.")

    # 2. 학습 데이터 준비 (제목 -> 카테고리)
    X = df['title']   # 문제 (제목)
    y = df['category'] # 정답 (카테고리)

    # 3. 데이터 분리 (학습용 80%, 시험용 20%)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # 4. 파이프라인 구축 (텍스트 변환 + 분류기)
    # TfidfVectorizer: 글자를 숫자로 바꿈 (단어의 중요도 분석)
    # MultinomialNB: 나이브 베이즈 분류기 (텍스트 분류에 빠르고 강력함)
    model = Pipeline([
        ('tfidf', TfidfVectorizer(max_features=2000)), 
        ('clf', MultinomialNB()),
    ])

    # 5. 진짜 학습 (Fit)
    model.fit(X_train, y_train)

    # 6. 성능 평가
    accuracy = model.score(X_test, y_test)
    print(f"✅ 학습 완료! 예상 정확도: {accuracy*100:.2f}%")

    # 7. 모델 저장 (model.pkl 파일로 저장)
    with open('model.pkl', 'wb') as f:
        pickle.dump(model, f)
    print("💾 'model.pkl' 파일로 저장되었습니다.")

    # 8. 테스트 해보기
    test_titles = ["2025학년도 1학기 국가장학금 신청 안내", "삼성전자 SW 개발자 채용"]
    predictions = model.predict(test_titles)
    print("\n--- 테스트 결과 ---")
    for title, category in zip(test_titles, predictions):
        print(f"'{title}' -> [{category}]")

if __name__ == "__main__":
    train_model()
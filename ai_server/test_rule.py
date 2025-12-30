from gemini_classifier import classify_by_rule

titles = [
    "2025학년도 동계 계절학기 현장실습 참여 학생 모집", # Should be 취업
    "2025년 국가근로장학사업 「동계방학 집중근로 프로그램」 학생 신청 안내", # Should be 장학
    "2025학년도 1학기 수강신청 안내" # Should be 학사
]

print("--- Testing Rules ---")
for t in titles:
    cat = classify_by_rule(t)
    print(f"Title: {t[:20]}... -> Category: {cat}")

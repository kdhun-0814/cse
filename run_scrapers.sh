#!/bin/bash

# 프로젝트 경로 설정 (사용자 환경에 맞게 수정 필요)
PROJECT_DIR="/Users/kdh/Desktop/MY_CSE"
PYTHON_BIN="python3"

echo "=========================================="
echo "Starting Scheduled Crawling: $(date)"
echo "=========================================="

cd "$PROJECT_DIR" || exit

# 1. 공지사항 크롤러 실행
echo "Running Notice Crawler..."
$PYTHON_BIN ai_server/crawler.py

# 2. 식단 크롤러 실행
echo "Running Cafeteria Scraper..."
$PYTHON_BIN ai_server/cafeteria_scraper.py

# 3. 일일 초기화 (hot notice 등) - 필요 시 별도 파일이면 추가 실행
# $PYTHON_BIN ai_server/daily_reset.py

echo "=========================================="
echo "All Tasks Completed: $(date)"
echo "=========================================="

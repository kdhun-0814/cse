#!/bin/sh

set -e # 에러 발생 시 즉시 중단

# 로그: 현재 위치 및 환경 변수 출력
echo "🚀 [Start] Xcode Cloud Build Script"
echo "Current directory: $(pwd)"
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

# 1. Flutter 프로젝트 루트로 이동
# 저장소 구조가 root/app 이므로 app 폴더로 이동합니다.
cd $CI_PRIMARY_REPOSITORY_PATH/app
echo "Moved to Flutter Project Root: $(pwd)"

# 2. Flutter SDK 설치 (안정 버전)
if [ ! -d "$HOME/flutter" ]; then
    echo "⬇️ Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
else
    echo "✅ Flutter SDK already exists."
fi

export PATH="$PATH:$HOME/flutter/bin"
echo "Flutter path: $(which flutter)"
flutter --version

# 3. Flutter 의존성 설치 및 생성 파일 빌드
echo "📦 Running flutter pub get..."
flutter precache
flutter pub get

# 4. CocoaPods 설치 및 iOS 의존성 해결
echo "🍎 Setting up iOS dependencies..."
cd ios
echo "Current directory (iOS): $(pwd)"

# Homebrew를 통한 Cocoapods 설치 (Xcode Cloud에는 기본적으로 있을 수 있으나 확실히 하기 위해)
if ! command -v pod &> /dev/null; then
    echo "⬇️ Installing CocoaPods..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
else
    echo "✅ CocoaPods is already installed."
fi

# Podfile.lock과 매니페스트 동기화 문제 방지를 위해 repo-update 사용 권장
# 🍎 iOS 의존성 설치 최적화
echo "📦 Running pod install with Google DNS fix..."

# 1. 코코아팟 저장소를 CDN 방식으로 고정 (속도 및 연결 안정성 향상)
rm -rf Pods
rm -rf Podfile.lock
pod repo update

# 2. curl 타임아웃 방지를 위해 환경 변수 설정
export COCOAPODS_SKIP_UPDATE_MESSAGE=1

# 3. pod install 실행 (실패 시 3번 재시도)
n=0
until [ "$n" -ge 3 ]
do
   pod install --repo-update && break
   n=$((n+1))
   echo "⚠️ 네트워크 지연 발생. $n번째 재시도 중..."
   sleep 10 # 재시도 간격을 10초로 늘려 안정성 확보
done

echo "✅ [Success] Build preparation complete!"
exit 0

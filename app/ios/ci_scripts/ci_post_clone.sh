#!/bin/sh

# 1. 플러터 SDK 설치 (안정 버전)
cd $CI_PRIMARY_REPOSITORY_PATH
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 2. 플러터 도구 준비 및 패키지 다운로드
# 프로젝트가 app 폴더 안에 있으므로 이동
cd $CI_PRIMARY_REPOSITORY_PATH/app

flutter precache
flutter pub get

# 3. CocoaPods 설치 및 업데이트
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
# ios 폴더는 app/ios에 위치
cd ios
pod install # 여기서 에러가 나면 pod install --repo-update 사용

exit 0

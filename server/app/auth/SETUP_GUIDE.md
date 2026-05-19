# DADA-AI 소셜 로그인 설정 가이드

## 개요

Flutter 앱 → 소셜 SDK 인증 → Firebase Auth → 우리 서버(JWT) 구조

```
Flutter App
  ├── Kakao SDK → ID Token
  ├── Apple SDK → Identity Token
  ├── Google SDK → ID Token
  └── Facebook SDK → Access Token
         ↓
   Firebase Auth (통합 인증)
         ↓
   POST /auth/social-login
         ↓
   우리 JWT 발급 → 모든 API에 사용
```

---

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com) 접속
2. **프로젝트 추가** → 이름: `dada-ai`
3. **Authentication** → **Sign-in method** → 아래 제공자 활성화
4. **프로젝트 설정** → **서비스 계정** → **새 비공개 키 생성**
   - 다운로드한 JSON → 서버에 `firebase-service-account.json` 로 저장
5. `.env` 파일에서 `# FIREBASE_CRED_PATH=` 주석 해제

---

## 2. 각 소셜 제공자 설정

### 카카오 (Kakao)

1. [Kakao Developers](https://developers.kakao.com) → 앱 생성
2. **내 애플리케이션** → **요약 정보** → **앱 키** (Native App Key)
3. **플랫폼** → **Flutter** → 패키지명 등록
4. **카카오 로그인** → **활성화** → Redirect URI 설정

### 애플 (Sign in with Apple)

1. [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. **Identifiers** → **Service ID** 생성
3. **Sign in with Apple** → Enable
4. **Return URL**: `https://dada.privseai.com/auth/apple/callback`

### 구글 (Google Sign-In)

1. [Google Cloud Console](https://console.cloud.google.com) → 프로젝트 선택
2. **API 및 서비스** → **OAuth 동의 화면** → 설정
3. **사용자 인증 정보** → **OAuth 클라이언트 ID**
   - Android, iOS, Web 각각 생성
4. Firebase Console에서 Google 로그인 활성화

### 페이스북 (Facebook Login)

1. [Facebook Developers](https://developers.facebook.com) → 앱 생성
2. **Facebook 로그인** → 설정
3. Firebase Console에서 Facebook 로그인 활성화
4. App ID + App Secret 입력

---

## 3. Firebase 설정 파일 추가

### Android
- Firebase Console → 프로젝트 설정 → **Android 앱** 추가
- `google-services.json` 다운로드 → `flutter_app/android/app/` 에 저장

### iOS
- Firebase Console → 프로젝트 설정 → **iOS 앱** 추가
- `GoogleService-Info.plist` 다운로드 → Xcode 프로젝트에 추가

---

## 4. Flutter SDK 통합 (코드 작성 완료)

다음 SDK를 `pubspec.yaml`에 추가:

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  google_sign_in: ^6.0.0
  sign_in_with_apple: ^6.0.0
  flutter_kakao_login: ^4.0.0  # or kakao_flutter_sdk
  flutter_facebook_auth: ^7.0.0
  http: ^1.0.0
  provider: ^6.0.0
```

### login_screen.dart (이미 작성 완료)
`flutter_app/lib/screens/login_screen.dart` 에 소셜 로그인 UI 준비됨

### auth_service.dart (이미 작성 완료)
`flutter_app/lib/services/auth_service.dart` 에 토큰 교환 로직 준비됨

---

## 5. 서버에서 auth 적용할 라우터 결정

현재 `app/auth/dependencies.py` 에 두 가지 의존성 제공:

```python
# Option A: 인증 필수 (payment, booking 등)
@router.post("/payment/create")
async def create_payment(req: Request, user: dict = Depends(get_current_user)):
    ...

# Option B: 인증 선택 (chat, browsing 등)
@router.post("/chat")
async def chat(req: Request, user: Optional[dict] = Depends(get_optional_user)):
    ...
```

---

## 6. 보안 체크리스트

- [ ] `.env`의 `JWT_SECRET`을 강력한 랜덤 문자열로 변경
- [ ] `firebase-service-account.json`을 `.gitignore`에 추가
- [ ] HTTPS 적용 (Caddy가 이미 처리 중)
- [ ] 필요시 JWT 만료 시간 조정 (현재 72시간)

# Liberty Reach (Privseai) — 멀티에이전트 협업 완료 플랜

> **작성일:** 2026-05-14  
> **참여 에이전트:** Hermes Agent, OpenClaw, [New Agent]  
> **목표:** Liberty Reach (Privseai) AI-P2P Messenger Flutter Web 앱 완성 및 안정화

---

## 📊 현재 상태 요약

| 영역 | 상태 | 상세 |
|------|------|------|
| **Git Rebase** | ⛔ 중단됨 | `da51b36` 커밋 적용 후 충돌 (README.md), 6개 커밋 남음 |
| **Flutter Web 빌드** | ✅ 성공 | WASM + canVaskit fallback, production 배포 완료 |
| **서버 배포** | ✅ 완료 | Caddy, Cloudflare, 이미지 최적화 완료 |
| **Rust Core** | 🟡 개발 중 | P2P, AI, Crypto, Storage 모듈 |
| **FastAPI 서버** | 🟡 개발 중 | Python FastAPI 서버 |
| **신규 기능 파일** | 📝 스테이징됨 | 67개 파일 (clean architecture), 34개 추가 수정 대기 |

---

## 🌟 주요 프로젝트 영역

### A. DADA-AI (Liberty Reach) — 메인 앱
- **Flutter Web** + **Rust Core** + **FastAPI Server**
- P2P 메신저 (libp2p 기반), AI 통합, 블록체인/리워드 시스템, Loops 통합
- `/root/DADA-AI/`

### B. openclaw-zero-token
- 무료 LLM 액세스 게이트웨이
- `/root/openclaw-zero-token/` (별도 프로젝트, git clean)

### C. liberty-reach (Rust 전용)
- Rust P2P 백엔드 (git 아님)
- `/root/liberty-reach/`

---

## 📋 태스크 분할 (4개 워크스트림)

### 워크스트림 1: Git Rebase 완료 & 코드베이스 안정화
**담당:** Hermes Agent  
**우선순위:** 🔴 최우선

| # | 태스크 | 예상 시간 |
|---|--------|----------|
| 1 | Rebase 충돌 해결 (README.md) | 2분 |
| 2 | 남은 6개 커밋 순차 적용 | 10분 |
| 3 | Unstaged 34개 파일 커밋 | 5분 |
| 4 | `pubspec.yaml`에 없는 패키지 확인 (mobile_scanner, qr_flutter) | 5분 |
| 5 | Flutter Web 재빌드 + 배포 테스트 | 10분 |

### 워크스트림 2: Flutter Web 기능 완성
**담당:** New Agent  
**우선순위:** 🟡 높음

| # | 태스크 | 예상 시간 |
|---|--------|----------|
| 1 | Missing import 해결 (mobile_scanner, qr_flutter) | 5분 |
| 2 | 각 스크린 UI 상태 점검 (chat, settings, contacts, splash) | 15분 |
| 3 | Loops 화면 연동 확인 | 10분 |
| 4 | 보이스/영상 통화 UI 테스트 | 10분 |
| 5 | 반응형 레이아웃 확인 (responsive_builder) | 5분 |

### 워크스트림 3: Rust Core + FastAPI 서버 완성
**담당:** OpenClaw  
**우선순위:** 🟡 높음

| # | 태스크 | 예상 시간 |
|---|--------|----------|
| 1 | `rust_core/` 소스 컴파일 확인 | 10분 |
| 2 | P2P 스웜 로직 검토 및 버그 수정 | 20분 |
| 3 | FastAPI 서버 (`server/`) 실행 테스트 | 10분 |
| 4 | AI 서비스 (LocalAI/Ollama) 연동 확인 | 10분 |
| 5 | Crypto (Noise) 프로토콜 검증 | 10분 |

### 워크스트림 4: 배포 & 모니터링
**담당:** Hermes Agent (+ 모든 에이전트 검증 후)

| # | 태스크 | 예상 시간 |
|---|--------|----------|
| 1 | 통합 테스트 (Flutter → Rust → API) | 15분 |
| 2 | Cloudflare CDN 캐시 퍼지 | 2분 |
| 3 | Privseai.com 전체 기능 산책 (smoke test) | 10분 |
| 4 | 성능 측정 (Lighthouse or 수동) | 5분 |
| 5 | 디스크/메모리 모니터링 설정 | 5분 |

---

## 🧩 에이전트 간 협업 규칙

### 파일 잠금 규칙
```
Hermes:   lib/ (Flutter 핵심), pubspec.yaml, */.git/*
New:      lib/screens/*, lib/widgets/* (UI 레이어)
OpenClaw: rust_core/*, server/*, src/* (백엔드)
```

### 커뮤니케이션 규칙
1. 각 에이전트는 작업 완료 후 `docs/plans/progress-{agent}.md`에 진행상황 기록
2. 공유 의존성 변경 시 다른 에이전트에 태그 (`@agent`)
3. 모든 커밋 메시지는 `[agent-name] type: description` 형식

### 완료 조건 (Definition of Done)
- ✅ 모든 에이전트의 워크스트림 100% 완료
- ✅ `flutter build web --wasm` 성공
- ✅ `privseai.com`에서 모든 주요 기능 정상 작동
- ✅ Git rebase 완료, main 브랜치 클린
- ✅ Rust Core + FastAPI 서버 실행 및 연동 확인

---

## 🚀 시작 순서

```
1️⃣ [Hermes]  Git Rebase 완료 (워크스트림 1)
       ↓
2️⃣ [New]     Flutter UI 점검 (워크스트림 2)
3️⃣ [OpenClaw] Rust/서버 완성 (워크스트림 3)  ← 동시 진행 가능
       ↓
4️⃣ [Hermes + All] 통합 테스트 + 배포 (워크스트림 4)
```

---

## ⚠️ 알려진 이슈

| 이슈 | 영향 | 해결 |
|------|------|------|
| `mobile_scanner` + `qr_flutter` 미설치 | 빌드 에러 가능 | pubspec.yaml에 추가 필요 |
| LocalAI 모델 파일 삭제됨 | AI 기능 동작 안 함 | Ollama로 마이그레이션 (커밋 30b9105) |
| Rust target 디렉토리 삭제됨 | Rust 빌드 시간 ↑ | `cargo build`로 재생성 |
| Git rebase 진행 중 | 새 커밋 불가 | 먼저 rebase 완료 필요 |

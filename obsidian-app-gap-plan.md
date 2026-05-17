# 📋 Obsidian 내용 vs privseai.com 앱 — 차이 분석 및 실행 Plan

> 작성일: 2026-05-16  
> 분석 기준: README.md / PLAN.md / DESIGN_SYSTEM.md / docs/ / server.py

---

## 1️⃣ 현재 상황 진단

### 📂 Obsidian Vault (서버)
- **`/root/obsidian-vault/`** — Syncthing sync 대상이지만 **아직 동기화 안 됨**
- 파일: `README.md` (서버 동기화 안내) + 빈 `DADA-AI/` 폴더
- ⚠️ 실제 Obsidian 노트는 Windows 랩탑(`kommau`)에 있으며 아직 서버로 sync 안 됨
- → 대신 프로젝트 문서(PLAN.md, README.md, DESIGN_SYSTEM.md, docs/)를 기준으로 분석

### 🟢 privseai.com 앱 현황 (동작 중)
| 영역 | 상태 |
|------|------|
| Flutter Web (WASM + CanvasKit) | ✅ 배포 완료 |
| FastAPI 서버 (port 8000) | ✅ PM2 running (⚠️ 1356회 재시작 = 불안정) |
| Chat | ✅ AI 채팅 (Gemini + OpenCode 연동) |
| Loops | ✅ 트렌딩 영상 + 플레이어 |
| Ranking (Leaderboard) | ✅ 포인트 랭킹 |
| Contacts | ✅ 연락처 |
| Settings | ✅ 설정 |
| Caddy + Cloudflare CDN | ✅ 배포 완료 |

---

## 2️⃣ 누락된 기능 (Spec/Design vs 구현)

### 🟡 Phase 1 — 코드는 있지만 앱에서 안 보이는 기능
| # | 기능 | 코드 위치 | 현재 상태 |
|---|------|-----------|----------|
| 1 | **Commerce / 마켓** | `live_commerce_screen.dart`, `market_screen.dart`, `commerce_service.dart` | ✅ 코드 있음 ❌ Bottom Nav에 없음 |
| 2 | **Wallet / 지갑** | `wallet_screen.dart`, `wallet_service.dart` | ✅ 코드 있음 ❌ 접근 경로 없음 |
| 3 | **Reward / 포인트** | `reward_screen.dart`, `reward_dashboard.dart`, `reward_service.dart` | ✅ 코드 있음 ❌ Nav/접근 경로 없음 |
| 4 | **QR Scan** | `qr_scan_screen.dart` | ✅ 코드 있음 ❌ 접근 경로 없음 |
| 5 | **HomeScreen (Featured)** | `home_screen.dart` | ✅ 코드 있음 ❌ 현재 Main 대신 ChatList가 1st tab |
| 6 | **MainHomeScreen** | `main_home_screen.dart` | ✅ 코드 있음 ❌ 미사용 |

### 🟠 Phase 2 — Spec에 있으나 미구현
| # | 기능 | README/설계 | Flutter 구현 | 서버 구현 |
|---|------|------------|-------------|----------|
| 7 | **멀티 에이전트 AI UI** (Hermes/OpenMythos/OpenClaw 버블) | README + DESIGN_SYSTEM.md | ❌ Agent Bubble 없음 | ✅ `/ai/code-assist` (멀티모드) |
| 8 | **P2P 메시징** (libp2p) | README "P2P Messaging" | ❌ Rust bridge 미연결 | ❌ Rust Core 미컴파일 |
| 9 | **Snap & Sell** (찍고팔기) | README "Snap & Sell" | ❌ | ❌ |
| 10 | **Voice AI / TTS** | README "Voice AI" | `voice_input_button.dart` ✅ (UV) | `tts_service.dart` ✅ |
| 11 | **Glass Agent UI** (full glassmorphism) | DESIGN_SYSTEM.md "Agent UI" | `app_colors.dart` / `glass_effect.dart` ✅ | ❌ UI 조합 안 됨 |
| 12 | **DADA Points / 코인 경제** | README + docs/tokenomics.md | `reward_screen.dart` ✅ | `/blockchain/*` ✅ |

### 🔴 Phase 3 — Roadmap 항목 (미시작)
| # | 기능 | 로드맵 |
|---|------|--------|
| 13 | 위치 기반 P2P 전파 | ❌ |
| 14 | Puter WebOS 통합 | ❌ (Puter 앱은 따로 있음) |
| 15 | Golem + Hyperspace 분산 컴퓨팅 | ❌ |
| 16 | DADA Coin 경제 모델 완성 | ❌ |
| 17 | 실시간 음성/영상 통화 | ❌ |

### ⚠️ 인프라 이슈
| # | 문제 | 심각도 |
|---|------|--------|
| 18 | **FastAPI 서버 1356회 재시작** — 2시간에 1356회 = 약 5초에 한 번 꼴 | 🔴 심각 |
| 19 | LocalAI/Ollama 모델 삭제됨 | 🟡 AI fallback만 동작 |
| 20 | Rust Core (`rust_core/`) 미컴파일 | 🟡 |
| 21 | Syncthing Obsidian 랩탑↔서버 미동기화 | 🟡 |

---

## 3️⃣ 실행 Plan (우선순위 순)

### 🔥 Phase 0 — 안정화 (즉시)
```
1. 서버 크래시 원인 분석 및 수정 (PM2 1356회 restart)
   → server/app/main.py + legacy_routes.py 로그 확인
   → try/except 누락된 경로, import 오류 수정
   
2. LocalAI/Ollama 모델 재설치 또는 API fallback 정리
   
3. Rust Core 컴파일 확인 (cargo build)
```

### 🎯 Phase 1 — Bottom Nav 재구성 (1-2일)
```
1. Home 탭 추가 (MainHomeScreen 또는 HomeScreen)
   → 기존 ChatListScreen → Chat 탭으로 이동
   → 새로운 Home 탭: Trending Loops + Featured
   
2. LiveCommerce / Market 탭 추가
   → commerce_service 연동
   → Snap & Sell 기본 UI
   
3. Wallet + Reward 통합
   → Settings에 Wallet 서브메뉴
   → Reward Dashboard 탭 or Drawer
   
4. QR Scan → Contacts에 통합
```

### 🚀 Phase 2 — 핵심 기능 구현 (3-5일)
```
1. Multi-Agent AI UI
   - Agent Bubble 위젯 (Hermes:민트, OpenMythos:퍼플, OpenClaw:레드)
   - Chat 화면에 Agent 선택 칩
   - `/ai/code-assist` 연동
   
2. Voice AI 통합
   - TTS 설정을 Chat으로 연결
   - 음성 입력 버튼을 Chat Input Bar에 통합
   
3. Glass Agent UI 완성
   - DESIGN_SYSTEM.md 기반 컴포넌트 완성
   - Glass Card, Agent Bubble, Voice Waveform
   - 모든 상태 (Loading/Empty/Error)
   
4. DADA Points 연동
   - Rewards를 Chat/Loops 활동에 연결
   - Leaderboard에 실시간 반영
```

### 🌟 Phase 3 — 고급 기능 (1-2주)
```
1. P2P Messaging (Rust Core 연동)
   - flutter_rust_bridge 연결
   - libp2p Gossipsub 채팅
   
2. Snap & Sell
   - 카메라/갤러리 → AI 분석 → P2P 마켓 등록
   
3. Location-based P2P
   - geolocator + P2P discovery
   
4. Puter WebOS 통합
   - 기존 teamchat/dashboard와 연동
```

---

## 4️⃣ Obsidian Vault 동기화 우선 필요

**서버 Obsidian vault가 비어 있어서** 실제 Danang의 개인 노트 내용은 반영 못 함.
Syncthing 동기화가 완료되면:
- Windows 랩탑 Obsidian → 서버 `~/obsidian-vault/` 로 sync
- 그 안의 DADA-AI 프로젝트 노트, 피처 리스트, TODO 등을 추가 분석
- 추가 누락 기능 발견 시 위 Plan 업데이트

---

## 5️⃣ 권장 첫 스텝

```
1️⃣ 서버 안정화 (PM2 crash fix) ← 지금 당장
2️⃣ Bottom Nav에 Home/Commerce/Wallet 탭 추가
3️⃣ Agent UI 구현 시작
4️⃣ Syncthing 동기화 확인해서 실제 Obsidian 노트 확보
```

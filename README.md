# DADA-AI

AI-Powered P2P Messenger + Decentralized Live Commerce Platform

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-000000?logo=rust&logoColor=white)
![Minima](https://img.shields.io/badge/Minima-Blockchain-00FFAA)

---

## 🚀 프로젝트 소개

**DADA-AI**는 Liberty Reach P2P 네트워크 위에 구축된 **차세대 AI 메신저 + 탈중앙 라이브 커머스 플랫폼**입니다.

기존 메신저와 달리, **사용자의 감정·기억·취향**을 학습하는 **Multi-Agent AI** 시스템이 함께 대화하며,  
P2P 네트워크와 Minima 블록체인을 통해 **중앙 서버 없이도** 안전하고 보상받는 경험을 제공합니다.

### 핵심 특징

- **Multi-Agent AI**: Hermes(공감), OpenMythos(깊은 사고), OpenClaw(실행) 등 에이전트 협업
- **P2P 기반 실시간 메시징** (libp2p)
- **📸 사진 찍어서 바로 판매** — AI 자동 분석 + 위치 기반 P2P 전파 (Market)
- **🎬 Loops 영상 생태계** — 영상 촬영 → AI 자동 편집 → 위치 기반 P2P 전파
- **💬 실시간 음성 대화**: Cheetah STT + 다국어 TTS + 감정 분석
- **💰 DADA Point 보상** — Minima 블록체인 기반 기여도 보상
- **🛡️ 완전 온디바이스 우선** — 프라이버시 보호 + 오프라인 지원
- **✨ Glass Agent UI** — 미래감 있는 Glassmorphism 디자인

---

## 🛠 기술 스택

| 영역 | 기술 |
|------|------|
| **Frontend** | Flutter 3.24 (Mobile + Web WASM) |
| **Backend** | FastAPI + Python |
| **Core** | Rust (libp2p, Crypto, AI) |
| **AI Engine** | Gemini + Ollama (Local) |
| **Agent Orchestration** | Hermes Agent + OpenClaw |
| **P2P** | Liberty Reach (libp2p + Gossipsub) |
| **Blockchain** | Minima (Tx-PoW + Coloring) |
| **Web Server** | Caddy |
| **Deployment** | Docker + Cloudflare CDN |
| **WebOS** | Puter (선택) |

---

## 📦 빠른 시작

```bash
# 1. 클론
git clone https://github.com/koraussie7/DADA-AI.git
cd DADA-AI

# 2. 서버 실행
cd server
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 3. Flutter 앱 실행 (Mobile)
cd ../flutter_app
flutter pub get
flutter run

# 4. Flutter Web (WASM)
flutter build web --wasm
```

Docker로 실행:
```bash
docker-compose up -d
```

---

## 📁 프로젝트 구조

```
DADA-AI/
├── flutter_app/          # Flutter 클라이언트 (UI)
├── rust_core/            # libp2p Rust Core
├── server/               # FastAPI + Hermes 에이전트 API
├── puter-apps/           # Puter WebOS 앱
├── docs/                 # 문서 (아키텍처, 로드맵)
└── docker/               # Docker 설정
```

---

## ✨ 현재 주요 기능

| 기능 | 설명 | 상태 |
|------|------|------|
| **Market** | 📸 사진 촬영 → AI 자동 분석 → 즉시 판매 등록 | ✅ 완료 |
| **Loops** | 🎬 영상 촬영 → AI 편집 → P2P 위치 기반 전파 | ✅ 완료 |
| **Multi-Agent Chat** | 💬 Hermes + OpenClaw 협업 채팅 | ✅ 완료 |
| **P2P Network** | 🌐 Liberty Reach 기반 분산 네트워크 | 🟡 개발 중 |
| **DADA Point** | 🪙 Minima 블록체인 리워드 시스템 | 🟡 개발 중 |
| **Puter WebOS** | 🖥️ 브라우저 기반 데스크탑 통합 | 📝 예정 |
| **Golem + Hyperspace** | 🚀 분산 컴퓨팅 연동 | 📝 예정 |

---

## 🗺 Roadmap

- [x] Flutter Web WASM 빌드 + Caddy 배포
- [x] Multi-Agent Orchestrator (Hermes + OpenClaw)
- [x] AI 자동 상품 분석 (Market)
- [ ] 위치 기반 P2P 전파 고도화
- [ ] Puter WebOS 통합
- [ ] Golem + Hyperspace 연동
- [ ] DADA Coin 경제 모델 완성
- [ ] 실시간 음성/영상 통화

---

## 🏗 실시간 프로젝트 현황

실시간 서버 상태와 에이전트 작업 보드는 아래에서 확인하세요:

👉 **[https://privseai.com/dashboard/](https://privseai.com/dashboard/)**

### 👥 협업 에이전트

| 에이전트 | 역할 |
|----------|------|
| 🔵 **Hermes** | Git Rebase, Flutter Web 배포, 최적화 |
| 🟠 **OpenClaw** | Rust Core, P2P, 서버 관리 |
| 🟢 **New Agent** | Flutter UI, 스크린 개발 |

💬 **팀 채팅방**: [https://privseai.com/teamchat/](https://privseai.com/teamchat/)

---

## 🤝 Contributing

Pull Request 언제든지 환영합니다!  
에이전트와 협업하거나 직접 기여해주세요.

## 📄 License

Apache License 2.0

---

**Made with ❤️ by DADA-AI Team**  
*Decentralized. Intelligent. Yours.*

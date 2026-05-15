<div align="center">

# DADA-AI

**AI-Powered P2P Messenger · Decentralized Live Commerce Platform**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-000000?logo=rust&logoColor=white)](https://www.rust-lang.org)
[![Minima](https://img.shields.io/badge/Minima-Blockchain-00FFAA)](https://minima.com)
[![Python](https://img.shields.io/badge/Python-FastAPI-009688?logo=python&logoColor=white)](https://fastapi.tiangolo.com)

<br>

<!-- Language Toggle Buttons -->
<a href="#en">🇺🇸 <b>English</b></a> &nbsp;·&nbsp; <a href="#ko">🇰🇷 <b>한국어</b></a>

</div>

---

<br>

<a id="en"></a>
<div align="center">

# 🌐 English

</div>

**DADA-AI** is a next-generation intelligent messenger and decentralized live commerce platform built on the **Liberty Reach P2P network**.

Unlike traditional messengers, it features a **Multi-Agent AI** system that learns your emotions, memories, and preferences — all while keeping your data private through peer-to-peer architecture and Minima blockchain.

---

## ✨ Key Features

| | Feature | Description |
|---|---------|-------------|
| 🤖 | **Multi-Agent AI** | Hermes (Empathy), OpenMythos (Deep Reasoning), OpenClaw (Action) collaborate in real-time |
| 🌍 | **P2P Messaging** | Fully decentralized chat powered by libp2p, no central server |
| 📸 | **Snap & Sell** | Take a photo → AI analyzes → instantly listed on P2P Market with location-based propagation |
| 🎬 | **Loops** | Record videos, AI auto-edits, and P2P distributes to nearby peers |
| 🎙️ | **Voice AI** | Cheetah STT + multi-language TTS with emotion-aware responses |
| 💰 | **DADA Points** | Minima blockchain-based contribution rewards (Tx-PoW) |
| 🛡️ | **Privacy First** | On-device by default, zero central server dependency |
| ✨ | **Glass Agent UI** | Immersive glassmorphism design with agent visualization |

---

## 🛠 Tech Stack

| Area | Technology |
|------|------------|
| **Frontend** | Flutter 3.24 (Mobile + Web WASM) |
| **Backend** | FastAPI + Python |
| **Core** | Rust (libp2p, Crypto, AI) |
| **AI Engine** | Gemini + Ollama (Local) |
| **Orchestration** | Hermes Agent + OpenClaw |
| **P2P** | Liberty Reach (libp2p + Gossipsub) |
| **Blockchain** | Minima (Tx-PoW + Coloring) |
| **Web Server** | Caddy |
| **CDN** | Cloudflare |
| **Deployment** | Docker |

---

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/koraussie7/DADA-AI.git
cd DADA-AI

# API Server
cd server
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Flutter App (Mobile)
cd ../flutter_app
flutter pub get
flutter run

# Flutter Web (WASM)
flutter build web --wasm
```

Or with Docker:
```bash
docker-compose up -d
```

---

## 📁 Project Structure

```
DADA-AI/
├── flutter_app/      # Flutter UI (Mobile + Web)
├── rust_core/        # Rust Core (P2P, Crypto, AI)
├── server/           # FastAPI + Agent API
├── puter-apps/       # Puter WebOS apps
├── assets/           # Icons, fonts, media
├── models/           # AI models & configs
├── docs/             # Architecture, Roadmap
├── docker/           # Docker configuration
└── scripts/          # Build & deployment scripts
```

---

## 🗺 Roadmap

- [x] Flutter Web WASM + Caddy deployment
- [x] Multi-Agent Orchestrator (Hermes + OpenClaw)
- [x] AI-powered product analysis (Market)
- [ ] Location-based P2P propagation
- [ ] Puter WebOS integration
- [ ] Golem + Hyperspace distributed computing
- [ ] DADA Coin economic model
- [ ] Real-time voice/video calls

---

## 🤝 Contributing

Pull requests are welcome! Feel free to contribute or collaborate with our agents.

---

## 📄 License

**Apache License 2.0** — see [LICENSE](LICENSE) for details.

---

<br>

<a id="ko"></a>
<div align="center">

# 🇰🇷 한국어

</div>

**DADA-AI**는 **Liberty Reach P2P 네트워크** 위에 구축된 차세대 지능형 메신저이자 **탈중앙화 라이브 커머스 플랫폼**입니다.

기존 메신저와 달리, 사용자의 감정·기억·취향을 학습하는 **멀티 에이전트 AI** 시스템을 갖추고 있으며, P2P 아키텍처와 Minima 블록체인을 통해 데이터 프라이버시를 완벽히 보호합니다.

---

## ✨ 주요 기능

| | 기능 | 설명 |
|---|------|------|
| 🤖 | **멀티 에이전트 AI** | Hermes(공감), OpenMythos(심층 추론), OpenClaw(실행)가 실시간 협업 |
| 🌍 | **P2P 메시징** | libp2p 기반 완전 탈중앙화 채팅, 중앙 서버 불필요 |
| 📸 | **찍고 팔기 (Snap & Sell)** | 사진 촬영 → AI 분석 → P2P 마켓에 즉시 등록, 위치 기반 전파 |
| 🎬 | **Loops** | 영상 녹화 → AI 자동 편집 → 주변 P2P 피어와 공유 |
| 🎙️ | **음성 AI** | Cheetah STT + 다국어 TTS + 감정 인식 응답 |
| 💰 | **DADA 포인트** | Minima 블록체인 기반 기여도 보상 시스템 (Tx-PoW) |
| 🛡️ | **프라이버시 우선** | 기본적으로 온디바이스 작동, 중앙 서버 의존도 0% |
| ✨ | **Glass Agent UI** | 미래지향적 Glassmorphism 디자인 + 에이전트 시각화 |

---

## 🛠 기술 스택

| 영역 | 기술 |
|------|------|
| **프론트엔드** | Flutter 3.24 (모바일 + Web WASM) |
| **백엔드** | FastAPI + Python |
| **코어** | Rust (libp2p, 암호화, AI) |
| **AI 엔진** | Gemini + Ollama (로컬) |
| **오케스트레이션** | Hermes Agent + OpenClaw |
| **P2P** | Liberty Reach (libp2p + Gossipsub) |
| **블록체인** | Minima (Tx-PoW + Coloring) |
| **웹 서버** | Caddy |
| **CDN** | Cloudflare |
| **배포** | Docker |

---

## 🚀 빠른 시작

```bash
# 클론
git clone https://github.com/koraussie7/DADA-AI.git
cd DADA-AI

# API 서버
cd server
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Flutter 앱 (모바일)
cd ../flutter_app
flutter pub get
flutter run

# Flutter Web (WASM)
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
├── flutter_app/      # Flutter UI (모바일 + 웹)
├── rust_core/        # Rust 코어 (P2P, 암호화, AI)
├── server/           # FastAPI + Agent API
├── puter-apps/       # Puter WebOS 앱
├── assets/           # 아이콘, 폰트, 미디어
├── models/           # AI 모델 및 설정
├── docs/             # 아키텍처, 로드맵
├── docker/           # Docker 설정
└── scripts/          # 빌드 및 배포 스크립트
```

---

## 🗺 로드맵

- [x] Flutter Web WASM + Caddy 배포
- [x] 멀티 에이전트 오케스트레이터 (Hermes + OpenClaw)
- [x] AI 상품 분석 (마켓)
- [ ] 위치 기반 P2P 전파
- [ ] Puter WebOS 통합
- [ ] Golem + Hyperspace 분산 컴퓨팅
- [ ] DADA 코인 경제 모델
- [ ] 실시간 음성/영상 통화

---

## 🤝 기여하기

Pull Request는 언제나 환영합니다! 함께 기여하거나 우리의 AI 에이전트와 협업해보세요.

---

## 📄 라이선스

**Apache License 2.0** — 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

---

<br>

<div align="center">

*Decentralized. Intelligent. Yours.*  
*탈중앙화된. 지능적인. 당신의.*

**Made with ❤️ by the DADA-AI Team**

<br>

<a href="#en">🇺🇸 English</a> &nbsp;·&nbsp; <a href="#ko">🇰🇷 한국어</a> &nbsp;·&nbsp; <a href="#">⬆️ Back to Top</a>

</div>

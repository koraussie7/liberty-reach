# Liberty Reach

**The Intelligent P2P AI Messenger**

![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Rust](https://img.shields.io/badge/Rust-000000?logo=rust&logoColor=white)
![Minima](https://img.shields.io/badge/Minima-Blockchain-00FFAA)

---

## 🌟 Vision

**Liberty Reach** is a fully decentralized AI-powered messenger that understands you — not just your words, but your emotions, memories, and preferences.

It combines **Multi-Agent AI**, **real-time voice conversation**, **emotional intelligence**, and **P2P video economy** into one seamless experience — all while protecting your privacy.

---

## ✨ Key Features

- **Multi-Agent Voice System** — Hermes (Empathy), OpenMythos (Deep Reasoning), OpenClaw (Action) work together
- **Real-time Emotional Intelligence** — Understands your mood and adjusts responses accordingly
- **Loops Video Ecosystem** — Watch, earn DADA Points, and get AI insights
- **Cheetah STT + Multi-language TTS** — Natural voice conversation with agent-specific voices
- **Glass Agent UI** — Beautiful, modern, and immersive interface
- **Minima Blockchain Rewards** — Contribute and get rewarded with DADA Point
- **Privacy First** — Everything runs on-device by default

---

## 🛠 Tech Stack

- **Frontend**: Flutter 3.24
- **Backend**: Rust + flutter_rust_bridge
- **AI Engine**: LocalAI + Gemma-2-2B + OpenMythos + TFLite
- **Speech**: Picovoice Cheetah (STT) + flutter_tts (Multi-language)
- **P2P**: libp2p + Gossipsub
- **Blockchain**: Minima (Tx-PoW + Coloring)
- **Storage**: Isar + AES-256 Encryption
- **Deployment**: Docker + Nginx

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/koraussie7/liberty-reach.git
cd liberty-reach

# Run Flutter App
cd flutter_app
flutter pub get
flutter run

# Build Rust Core (in another terminal)
cd ../rust_core
cargo build --release
```

Run with Docker:
```bash
docker-compose up -d
```

---

## 📁 Project Structure

```
liberty-reach/
├── flutter_app/          # Flutter UI (Glass Agent, Voice, Loops)
├── rust_core/            # Rust Backend (Orchestrator, libp2p, Minima, Reward)
├── models/               # TFLite, Cheetah, LocalAI models
├── docker/               # Docker Compose & Nginx
├── scripts/              # Build & Deployment scripts
├── assets/               # Icons, models, fonts
├── docs/                 # Architecture, Tokenomics, Roadmap
└── README.md
```

---

## 🛣 Roadmap

- **v0.5** (Current) — Multi-Agent Voice + Glass UI + Minima Reward
- **v0.7** — Real-time Emotion Profiling + Preference Model
- **v1.0** — Full Loops + AI Integration + DADA Point DEX Preparation

---

## 📄 License

Apache License 2.0

---

Built for a decentralized and emotionally intelligent future.  
Made with ❤️ by the Liberty Reach Team

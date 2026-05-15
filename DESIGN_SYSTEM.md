# DADA-AI (Liberty Reach) — Figma Design System

## Pages

| Page | Description | Contents |
|------|------------|----------|
| **01. Foundation** | Design system base | Color Styles, Text Styles, Effects, Grid, Components |
| **02. Components** | All reusable components | Glass Card, Agent Bubble, Button, Input Bar |
| **03. iPhone Screens** | Screen mockups | Home, Chat, Loops Player, Leaderboard, Reward |
| **04. Flows** | User flows | Onboarding → Chat → Loops Upload → Reward |
| **05. Variants & States** | State variants | Loading, Empty, Error, Dark/Light |
| **06. Assets** | Icons, illustrations, Lottie | SVG, PNG, 3D Mockup |
| **07. Archive** | Previous versions | v1, v2 |

## Components Structure

```
01. Foundation
    ├── Colors (Semantic Tokens)
    ├── Typography
    ├── Effects (Glass, Neon Glow, Blur)
    └── Grid & Layout

02. UI Primitives
    ├── Buttons (Primary, Secondary, Glass, Neon)
    ├── Input Fields
    ├── Cards (Glass Card, Reward Card)
    └── Badges & Tags

03. Agent UI
    ├── Hermes Bubble
    ├── OpenMythos Bubble
    ├── Multi-Agent Circle
    └── Voice Waveform

04. Loops
    ├── Loops Preview Bar
    ├── Video Player Card
    ├── AI Overlay Sheet
    └── Upload Button

05. Navigation
    ├── Bottom Tab Bar
    ├── Top Bar
    └── Side Menu

06. Feedback
    ├── Toast Notification
    ├── Reward Animation
    └── Loading Skeleton
```

## Naming Convention

- **Color**: `Violet-500`, `Cyan-400`, `Glass-Bg`
- **Text**: `Title-1`, `Body`, `Caption`
- **Component**: `GlassCard / Default`, `AgentBubble / Hermes`
- **Variant**: `State=Default`, `State=Pressed`, `State=Loading`

## Build Order

1. Foundation → colors, typography, glass effect
2. Components → reusable primitives
3. iPhone Screens → compose screens from components
4. Use Auto Layout + Variants throughout

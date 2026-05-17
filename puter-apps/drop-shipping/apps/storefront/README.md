# ShopDrop — Storefront

Customer-facing shop for the ShopDrop drop shipping platform.

**Runs on:** `localhost:3000` (dev) / `yourstore.com` (production)

## What's in here

```
app/
  page.tsx                  ← Homepage (hero + categories + featured products)
  products/                 ← Product listing + detail pages
  cart/                     ← Cart page
  checkout/                 ← Stripe checkout, success, cancel
  (auth)/login              ← Customer login
  (auth)/register           ← Customer registration
  api/checkout/             ← Creates Stripe checkout session
  api/webhooks/stripe/      ← Receives Stripe payment events → creates order
  api/auth/                 ← NextAuth routes

modules/
  products/                 ← Product catalogue (interfaces/models/repository/services/components)
  cart/                     ← localStorage cart + CartDrawer
  orders/                   ← Order creation and tracking
  payments/                 ← Stripe integration
  auth/                     ← Register + login (bcrypt)

shared/
  components/layout/        ← Header (sticky, search, cart icon), Footer
  components/ui/            ← Button, Badge, StarRating, PriceDisplay
  context/                  ← CartContext, SessionProvider
```

## Environment Variables

Copy `.env.local.example` to `.env.local` and fill in:

```
DATABASE_URL=
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3000
STRIPE_PUBLIC_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

## Run

```bash
pnpm dev        # starts on localhost:3000
```

> Run from the monorepo root with `pnpm dev` to start both apps together.

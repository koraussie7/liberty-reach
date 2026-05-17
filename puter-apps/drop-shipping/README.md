# ShopDrop — Full-Stack Drop Shipping Platform

A production-ready, modular drop shipping platform built with Next.js, Prisma, PostgreSQL, Stripe and Docker.

## Architecture

Two separate Next.js apps sharing a single PostgreSQL database via a monorepo:

```
apps/
  storefront/   → Customer-facing shop      (localhost:3000)
  admin/        → Owner admin dashboard     (localhost:3002)
packages/
  database/     → Prisma schema + client    (shared)
  shared-types/ → TypeScript DTOs           (shared)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Language | TypeScript |
| Database | PostgreSQL + Prisma ORM |
| Auth | NextAuth.js v5 |
| Payments | Stripe Checkout + Webhooks |
| Styling | Tailwind CSS v4 |
| Monorepo | pnpm workspaces |
| Dev DB | Docker (Postgres container) |
| Production | IONOS VPS + Docker Compose + Nginx |

## Module Structure

Every module follows the same layered pattern:

```
module-name/
  interfaces/   ← contracts (IProductService, IProductRepository)
  models/       ← domain types and DTOs
  repository/   ← database access via Prisma only
  services/     ← business logic (depends on interfaces, fully testable)
  components/   ← React UI components
```

## Modules

### Module 1 — Core (built)
- Product catalogue with category navigation
- Customer storefront with search
- Shopping cart (localStorage)
- Stripe Checkout + webhook order creation
- Customer auth (register / login)
- Admin dashboard (stats, products, orders)
- Product management (add / edit / delete)
- Margin calculator (customer price − supplier cost)

### Module 2 — Suppliers (planned)
- Supplier management
- Auto-forward orders to suppliers
- Inventory sync

### Module 3 — Fulfilment (planned)
- Order tracking
- Customer tracking emails
- Supplier portal

### Module 4 — Analytics (planned)
- Revenue dashboard
- Best-selling products
- Conversion tracking

## Drop Shipping Flow

```
Customer orders  →  Stripe charges customer
       ↓
Admin sees order  →  Forwards to supplier
       ↓
Supplier ships  →  Admin enters tracking number
       ↓
Customer receives order confirmation + tracking
```

## Getting Started

### Prerequisites
- Node.js 22+
- pnpm
- Docker Desktop

### Setup

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/drop-shipping.git
cd drop-shipping

# Install dependencies
pnpm install

# Start Postgres
docker-compose up -d

# Copy env files
copy apps\storefront\.env.local.example apps\storefront\.env.local
copy apps\admin\.env.local.example apps\admin\.env.local
# Fill in your Stripe keys in storefront .env.local

# Generate Prisma client + create tables
pnpm db:generate
pnpm db:push

# Start both apps
pnpm dev
```

Storefront → http://localhost:3000  
Admin → http://localhost:3002

## Production Deployment (IONOS)

```bash
# On your IONOS server
git clone https://github.com/YOUR_USERNAME/drop-shipping.git
cp .env.production.example .env.production
# Fill in production values

docker-compose -f docker-compose.prod.yml up -d
```

Nginx routes:
- `yourstore.com` → storefront
- `admin.yourstore.com` → admin dashboard

## Environment Variables

**Storefront** (`apps/storefront/.env.local`):
```
DATABASE_URL=
NEXTAUTH_SECRET=
NEXTAUTH_URL=
STRIPE_PUBLIC_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
```

**Admin** (`apps/admin/.env.local`):
```
DATABASE_URL=
NEXTAUTH_SECRET=
NEXTAUTH_URL=
ADMIN_EMAIL=
```

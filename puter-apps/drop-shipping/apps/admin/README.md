# ShopDrop — Admin Dashboard

Private admin panel for managing the ShopDrop drop shipping store.

**Runs on:** `localhost:3002` (dev) / `admin.yourstore.com` (production)

## What's in here

```
app/
  (dashboard)/
    page.tsx                ← Overview (revenue, orders, pending forwarding alerts)
    products/               ← Product list, add product, edit product
    orders/                 ← All orders, forwarding status
    suppliers/              ← Supplier management (Module 2 — stub)
  api/products/             ← REST API for product CRUD
  api/auth/                 ← NextAuth routes

modules/
  products/                 ← Full CRUD (interfaces/models/repository/services/components)
  orders/                   ← Order management + forward to supplier
  suppliers/                ← Stub — ready for Module 2

shared/
  components/layout/        ← Sidebar navigation with teal active states
```

## Key Features

- **Product management** — add/edit/delete products, set customer price + supplier cost
- **Margin calculator** — shows your profit per product live as you type
- **Order dashboard** — highlights paid orders waiting to be forwarded to supplier
- **Forwarding workflow** — mark orders as forwarded, enter tracking numbers

## Environment Variables

Copy `.env.local.example` to `.env.local` and fill in:

```
DATABASE_URL=
NEXTAUTH_SECRET=
NEXTAUTH_URL=http://localhost:3002
ADMIN_EMAIL=
```

## Run

```bash
pnpm dev        # starts on localhost:3002
```

> Run from the monorepo root with `pnpm dev` to start both apps together.

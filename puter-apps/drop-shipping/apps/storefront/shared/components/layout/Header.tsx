'use client'

import Link from 'next/link'
import { useState } from 'react'
import { useSession, signOut } from 'next-auth/react'
import { useCart } from '@/shared/context/CartContext'
import { CartDrawer } from '@/modules/cart/components/CartDrawer'

const NAV_CATEGORIES = [
  { label: 'Living Room', href: '/categories/living-room' },
  { label: 'Bedroom', href: '/categories/bedroom' },
  { label: 'Kitchen', href: '/categories/kitchen' },
  { label: 'Office', href: '/categories/office' },
  { label: 'Outdoor', href: '/categories/outdoor' },
  { label: 'Sale', href: '/categories/sale' },
]

export function Header() {
  const { cart, isOpen, setIsOpen } = useCart()
  const { data: session } = useSession()
  const [search, setSearch] = useState('')
  const [menuOpen, setMenuOpen] = useState(false)

  return (
    <>
      <header className="sticky top-0 z-40 bg-white border-b border-gray-200 shadow-sm">
        {/* Top bar */}
        <div className="bg-primary-700 text-white text-xs text-center py-1.5 px-4">
          Free UK delivery on orders over £50 &nbsp;·&nbsp; Easy 30-day returns
        </div>

        {/* Main header */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16 gap-4">
            {/* Logo */}
            <Link href="/" className="flex-shrink-0 text-2xl font-bold text-primary-700 tracking-tight">
              ShopDrop
            </Link>

            {/* Search */}
            <form
              onSubmit={(e) => { e.preventDefault(); window.location.href = `/products?search=${search}` }}
              className="flex-1 max-w-xl hidden sm:flex"
            >
              <div className="relative w-full">
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search products..."
                  className="w-full pl-4 pr-10 py-2 border border-gray-300 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
                <button type="submit" className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-primary-600">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </button>
              </div>
            </form>

            {/* Actions */}
            <div className="flex items-center gap-3">
              {session ? (
                <div className="hidden sm:flex items-center gap-3">
                  <span className="text-sm text-gray-600">Hi, {session.user?.name?.split(' ')[0] ?? 'there'}</span>
                  <button onClick={() => signOut()} className="text-sm text-gray-500 hover:text-red-500">Sign out</button>
                </div>
              ) : (
                <Link href="/login" className="hidden sm:flex items-center gap-1 text-sm text-gray-600 hover:text-primary-600">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                  <span>Sign in</span>
                </Link>
              )}

              <button
                onClick={() => setIsOpen(true)}
                className="relative flex items-center gap-1 text-sm text-gray-600 hover:text-primary-600"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 3h2l.4 2M7 13h10l4-9H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                {cart.itemCount > 0 && (
                  <span className="absolute -top-2 -right-2 bg-primary-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold">
                    {cart.itemCount}
                  </span>
                )}
                <span className="hidden sm:inline">Cart</span>
              </button>

              {/* Mobile menu toggle */}
              <button className="sm:hidden" onClick={() => setMenuOpen(!menuOpen)}>
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={menuOpen ? 'M6 18L18 6M6 6l12 12' : 'M4 6h16M4 12h16M4 18h16'} />
                </svg>
              </button>
            </div>
          </div>
        </div>

        {/* Category nav */}
        <nav className="hidden sm:block border-t border-gray-100 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <ul className="flex items-center gap-6 h-10 text-sm">
              <li>
                <Link href="/products" className="font-semibold text-primary-700 hover:text-primary-800">
                  All Products
                </Link>
              </li>
              {NAV_CATEGORIES.map((cat) => (
                <li key={cat.href}>
                  <Link href={cat.href} className={`text-gray-600 hover:text-primary-700 transition-colors ${cat.label === 'Sale' ? 'text-red-500 font-semibold' : ''}`}>
                    {cat.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </nav>

        {/* Mobile menu */}
        {menuOpen && (
          <div className="sm:hidden border-t border-gray-100 bg-white px-4 py-3 space-y-2">
            <form onSubmit={(e) => { e.preventDefault(); window.location.href = `/products?search=${search}` }}>
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search products..."
                className="w-full px-4 py-2 border border-gray-300 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 mb-2"
              />
            </form>
            {NAV_CATEGORIES.map((cat) => (
              <Link key={cat.href} href={cat.href} className="block py-1.5 text-gray-700 hover:text-primary-600" onClick={() => setMenuOpen(false)}>
                {cat.label}
              </Link>
            ))}
          </div>
        )}
      </header>

      <CartDrawer />
    </>
  )
}

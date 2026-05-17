'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

const NAV = [
  { href: '/',          label: 'Dashboard', icon: '📊' },
  { href: '/products',  label: 'Products',  icon: '📦' },
  { href: '/orders',    label: 'Orders',    icon: '🛒' },
  { href: '/suppliers', label: 'Suppliers', icon: '🏭', badge: 'Module 2' },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-56 bg-gray-900 text-gray-300 min-h-screen flex flex-col">
      <div className="px-5 py-6 border-b border-gray-700">
        <span className="text-white font-bold text-lg">ShopDrop</span>
        <span className="ml-2 text-xs bg-primary-600 text-white px-2 py-0.5 rounded">Admin</span>
      </div>
      <nav className="flex-1 px-3 py-4 space-y-1">
        {NAV.map((item) => {
          const active = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href))
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors ${
                active ? 'bg-primary-700 text-white' : 'hover:bg-gray-800 hover:text-white'
              }`}
            >
              <span>{item.icon}</span>
              <span className="flex-1">{item.label}</span>
              {item.badge && (
                <span className="text-xs bg-gray-700 text-gray-400 px-1.5 py-0.5 rounded">{item.badge}</span>
              )}
            </Link>
          )
        })}
      </nav>
      <div className="px-5 py-4 border-t border-gray-700 text-xs text-gray-500">
        ShopDrop Admin v1.0
      </div>
    </aside>
  )
}

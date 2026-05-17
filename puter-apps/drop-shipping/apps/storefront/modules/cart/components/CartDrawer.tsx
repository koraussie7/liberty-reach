'use client'

import Link from 'next/link'
import Image from 'next/image'
import { useCart } from '@/shared/context/CartContext'
import { Button } from '@/shared/components/ui/Button'

export function CartDrawer() {
  const { cart, removeItem, updateQuantity, isOpen, setIsOpen } = useCart()

  return (
    <>
      {/* Overlay */}
      {isOpen && <div className="fixed inset-0 bg-black/40 z-50" onClick={() => setIsOpen(false)} />}

      {/* Drawer */}
      <div className={`fixed top-0 right-0 h-full w-full max-w-sm bg-white shadow-2xl z-50 flex flex-col transition-transform duration-300 ${isOpen ? 'translate-x-0' : 'translate-x-full'}`}>
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900">Your Cart ({cart.itemCount})</h2>
          <button onClick={() => setIsOpen(false)} className="text-gray-400 hover:text-gray-600">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Items */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
          {cart.items.length === 0 ? (
            <div className="text-center py-16 text-gray-400">
              <svg className="w-12 h-12 mx-auto mb-3 text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 3h2l.4 2M7 13h10l4-9H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <p className="text-sm">Your cart is empty</p>
              <button onClick={() => setIsOpen(false)} className="mt-3 text-primary-600 text-sm underline">Continue shopping</button>
            </div>
          ) : (
            cart.items.map((item) => (
              <div key={item.productId} className="flex gap-3">
                <div className="relative w-16 h-16 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                  <Image src={item.image} alt={item.name} fill className="object-cover" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">{item.name}</p>
                  <p className="text-sm text-primary-600 font-semibold">£{item.price.toFixed(2)}</p>
                  <div className="flex items-center gap-2 mt-1">
                    <button onClick={() => updateQuantity(item.productId, item.quantity - 1)} className="w-6 h-6 rounded border border-gray-300 flex items-center justify-center text-gray-600 hover:bg-gray-50">−</button>
                    <span className="text-sm w-4 text-center">{item.quantity}</span>
                    <button onClick={() => updateQuantity(item.productId, item.quantity + 1)} className="w-6 h-6 rounded border border-gray-300 flex items-center justify-center text-gray-600 hover:bg-gray-50">+</button>
                    <button onClick={() => removeItem(item.productId)} className="ml-2 text-gray-400 hover:text-red-500 text-xs">Remove</button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* Footer */}
        {cart.items.length > 0 && (
          <div className="border-t border-gray-200 px-4 py-4 space-y-3">
            <div className="flex justify-between text-sm text-gray-600">
              <span>Subtotal</span>
              <span className="font-semibold text-gray-900">£{cart.total.toFixed(2)}</span>
            </div>
            <p className="text-xs text-gray-400">Shipping calculated at checkout</p>
            <Link href="/checkout" onClick={() => setIsOpen(false)}>
              <Button className="w-full" size="lg">Checkout</Button>
            </Link>
            <button onClick={() => setIsOpen(false)} className="w-full text-sm text-gray-500 hover:text-gray-700">
              Continue Shopping
            </button>
          </div>
        )}
      </div>
    </>
  )
}

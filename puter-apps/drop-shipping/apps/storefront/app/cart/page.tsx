'use client'

import Link from 'next/link'
import Image from 'next/image'
import { useCart } from '@/shared/context/CartContext'
import { Button } from '@/shared/components/ui/Button'
import { useState } from 'react'

export default function CartPage() {
  const { cart, removeItem, updateQuantity, clearCart } = useCart()
  const [loading, setLoading] = useState(false)

  const handleCheckout = async () => {
    setLoading(true)
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ items: cart.items }),
      })
      const { url } = await res.json()
      if (url) window.location.href = url
    } finally {
      setLoading(false)
    }
  }

  if (cart.items.length === 0) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-20 text-center">
        <p className="text-2xl font-semibold text-gray-900 mb-3">Your cart is empty</p>
        <p className="text-gray-500 mb-6">Looks like you haven't added anything yet.</p>
        <Link href="/products"><Button size="lg">Start Shopping</Button></Link>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Your Cart</h1>
      <div className="lg:grid lg:grid-cols-3 lg:gap-10">
        {/* Items */}
        <div className="lg:col-span-2 space-y-4">
          {cart.items.map((item) => (
            <div key={item.productId} className="bg-white rounded-xl p-4 flex gap-4 shadow-sm border border-gray-100">
              <div className="relative w-20 h-20 rounded-lg overflow-hidden bg-gray-50 flex-shrink-0">
                <Image src={item.image} alt={item.name} fill className="object-cover" />
              </div>
              <div className="flex-1">
                <Link href={`/products/${item.slug}`} className="font-medium text-gray-900 hover:text-primary-600">{item.name}</Link>
                <p className="text-primary-600 font-semibold mt-1">£{item.price.toFixed(2)}</p>
                <div className="flex items-center gap-3 mt-2">
                  <div className="flex items-center border border-gray-200 rounded-lg overflow-hidden">
                    <button onClick={() => updateQuantity(item.productId, item.quantity - 1)} className="px-3 py-1 hover:bg-gray-50 text-gray-600">−</button>
                    <span className="px-3 py-1 text-sm border-x border-gray-200">{item.quantity}</span>
                    <button onClick={() => updateQuantity(item.productId, item.quantity + 1)} className="px-3 py-1 hover:bg-gray-50 text-gray-600">+</button>
                  </div>
                  <button onClick={() => removeItem(item.productId)} className="text-sm text-red-400 hover:text-red-600">Remove</button>
                </div>
              </div>
              <div className="text-right font-semibold text-gray-900">
                £{(item.price * item.quantity).toFixed(2)}
              </div>
            </div>
          ))}
          <button onClick={clearCart} className="text-sm text-gray-400 hover:text-red-500">Clear cart</button>
        </div>

        {/* Summary */}
        <div className="mt-8 lg:mt-0">
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 sticky top-24">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Order Summary</h2>
            <div className="space-y-2 text-sm text-gray-600 mb-4">
              <div className="flex justify-between"><span>Subtotal ({cart.itemCount} items)</span><span>£{cart.total.toFixed(2)}</span></div>
              <div className="flex justify-between"><span>Shipping</span><span className="text-green-600">{cart.total >= 50 ? 'Free' : '£4.99'}</span></div>
            </div>
            <div className="border-t pt-3 flex justify-between font-bold text-gray-900 mb-5">
              <span>Total</span>
              <span>£{(cart.total >= 50 ? cart.total : cart.total + 4.99).toFixed(2)}</span>
            </div>
            <Button onClick={handleCheckout} loading={loading} size="lg" className="w-full">
              Proceed to Checkout
            </Button>
            <Link href="/products" className="block text-center mt-3 text-sm text-gray-500 hover:text-gray-700">
              Continue Shopping
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import { CartService } from '@/modules/cart/services/CartService'
import type { Cart, CartItem } from '@dropshipping/shared-types'

interface CartContextValue {
  cart: Cart
  addItem: (item: CartItem) => void
  removeItem: (productId: string) => void
  updateQuantity: (productId: string, quantity: number) => void
  clearCart: () => void
  isOpen: boolean
  setIsOpen: (open: boolean) => void
}

const CartContext = createContext<CartContextValue | null>(null)
const service = new CartService()

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [cart, setCart] = useState<Cart>({ items: [], total: 0, itemCount: 0 })
  const [isOpen, setIsOpen] = useState(false)

  useEffect(() => {
    setCart(service.getCart())
  }, [])

  const refresh = () => setCart(service.getCart())

  const addItem = (item: CartItem) => {
    service.addItem(item)
    refresh()
    setIsOpen(true)
  }

  const removeItem = (productId: string) => {
    service.removeItem(productId)
    refresh()
  }

  const updateQuantity = (productId: string, quantity: number) => {
    service.updateQuantity(productId, quantity)
    refresh()
  }

  const clearCart = () => {
    service.clearCart()
    refresh()
  }

  return (
    <CartContext.Provider value={{ cart, addItem, removeItem, updateQuantity, clearCart, isOpen, setIsOpen }}>
      {children}
    </CartContext.Provider>
  )
}

export function useCart() {
  const ctx = useContext(CartContext)
  if (!ctx) throw new Error('useCart must be used inside CartProvider')
  return ctx
}

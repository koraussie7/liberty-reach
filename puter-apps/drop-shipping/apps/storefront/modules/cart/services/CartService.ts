import type { ICartService } from '../interfaces/ICartService'
import type { Cart, CartItem } from '@dropshipping/shared-types'
import { CART_STORAGE_KEY } from '../models/cart.model'

export class CartService implements ICartService {
  getCart(): Cart {
    if (typeof window === 'undefined') return { items: [], total: 0, itemCount: 0 }
    const stored = localStorage.getItem(CART_STORAGE_KEY)
    const items: CartItem[] = stored ? JSON.parse(stored) : []
    return {
      items,
      total: items.reduce((sum, i) => sum + i.price * i.quantity, 0),
      itemCount: items.reduce((sum, i) => sum + i.quantity, 0),
    }
  }

  addItem(item: CartItem): void {
    const cart = this.getCart()
    const existing = cart.items.find((i) => i.productId === item.productId)
    if (existing) {
      existing.quantity += item.quantity
    } else {
      cart.items.push(item)
    }
    this.save(cart.items)
  }

  removeItem(productId: string): void {
    const cart = this.getCart()
    this.save(cart.items.filter((i) => i.productId !== productId))
  }

  updateQuantity(productId: string, quantity: number): void {
    if (quantity <= 0) return this.removeItem(productId)
    const cart = this.getCart()
    const item = cart.items.find((i) => i.productId === productId)
    if (item) {
      item.quantity = quantity
      this.save(cart.items)
    }
  }

  clearCart(): void {
    localStorage.removeItem(CART_STORAGE_KEY)
  }

  getItemCount(): number {
    return this.getCart().itemCount
  }

  getTotal(): number {
    return this.getCart().total
  }

  private save(items: CartItem[]): void {
    localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(items))
  }
}

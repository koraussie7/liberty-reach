import type { Cart, CartItem } from '@dropshipping/shared-types'

export interface ICartService {
  getCart(): Cart
  addItem(item: CartItem): void
  removeItem(productId: string): void
  updateQuantity(productId: string, quantity: number): void
  clearCart(): void
  getItemCount(): number
  getTotal(): number
}

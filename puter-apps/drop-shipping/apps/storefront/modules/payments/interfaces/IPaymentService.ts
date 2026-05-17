import type { CartItem } from '@dropshipping/shared-types'

export interface CheckoutSessionResult {
  sessionId: string
  url: string
}

export interface IPaymentService {
  createCheckoutSession(items: CartItem[], customerEmail?: string): Promise<CheckoutSessionResult>
  handleWebhookEvent(payload: string, signature: string): Promise<void>
}

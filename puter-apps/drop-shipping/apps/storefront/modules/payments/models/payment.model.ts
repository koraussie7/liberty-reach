export type { CheckoutSessionResult } from '../interfaces/IPaymentService'

export interface StripeLineItem {
  price_data: {
    currency: string
    product_data: { name: string; images: string[] }
    unit_amount: number
  }
  quantity: number
}

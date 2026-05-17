import Stripe from 'stripe'
import type { IPaymentService, CheckoutSessionResult } from '../interfaces/IPaymentService'
import type { CartItem } from '@dropshipping/shared-types'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2024-11-20.acacia' })

export class StripeService implements IPaymentService {
  async createCheckoutSession(items: CartItem[], customerEmail?: string): Promise<CheckoutSessionResult> {
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      customer_email: customerEmail,
      line_items: items.map((item) => ({
        price_data: {
          currency: 'gbp',
          product_data: {
            name: item.name,
            images: [item.image],
          },
          unit_amount: Math.round(item.price * 100),
        },
        quantity: item.quantity,
      })),
      success_url: `${process.env.NEXTAUTH_URL}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.NEXTAUTH_URL}/checkout/cancel`,
      shipping_address_collection: {
        allowed_countries: ['GB', 'US', 'CA', 'AU', 'DE', 'FR'],
      },
      metadata: {
        cartItems: JSON.stringify(items.map((i) => ({ productId: i.productId, quantity: i.quantity, unitPrice: i.price }))),
      },
    })

    return { sessionId: session.id, url: session.url! }
  }

  async handleWebhookEvent(payload: string, signature: string): Promise<void> {
    const event = stripe.webhooks.constructEvent(
      payload,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )

    if (event.type === 'checkout.session.completed') {
      // OrderService handles this — see api/webhooks/stripe/route.ts
    }
  }
}

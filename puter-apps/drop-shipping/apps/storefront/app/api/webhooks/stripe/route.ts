import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { prisma } from '@dropshipping/database'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2024-11-20.acacia' })

export async function POST(req: NextRequest) {
  const payload = await req.text()
  const sig = req.headers.get('stripe-signature')!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(payload, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session
    const cartItems = JSON.parse(session.metadata?.cartItems ?? '[]')
    const address = session.shipping_details?.address

    await prisma.order.create({
      data: {
        customerEmail: session.customer_email ?? '',
        customerName: session.shipping_details?.name ?? '',
        stripeSessionId: session.id,
        totalAmount: (session.amount_total ?? 0) / 100,
        status: 'PAID',
        shippingAddress: {
          line1: address?.line1 ?? '',
          line2: address?.line2 ?? '',
          city: address?.city ?? '',
          postcode: address?.postal_code ?? '',
          country: address?.country ?? '',
        },
        items: {
          create: cartItems.map((i: { productId: string; quantity: number; unitPrice: number }) => ({
            productId: i.productId,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
          })),
        },
      },
    })
  }

  return NextResponse.json({ received: true })
}

export const config = { api: { bodyParser: false } }

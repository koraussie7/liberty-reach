import { NextRequest, NextResponse } from 'next/server'
import { StripeService } from '@/modules/payments/services/StripeService'
import type { CartItem } from '@dropshipping/shared-types'

const stripeService = new StripeService()

export async function POST(req: NextRequest) {
  try {
    const { items, customerEmail }: { items: CartItem[]; customerEmail?: string } = await req.json()
    if (!items?.length) return NextResponse.json({ error: 'Cart is empty' }, { status: 400 })

    const session = await stripeService.createCheckoutSession(items, customerEmail)
    return NextResponse.json(session)
  } catch (err) {
    console.error('Checkout error:', err)
    return NextResponse.json({ error: 'Failed to create checkout session' }, { status: 500 })
  }
}

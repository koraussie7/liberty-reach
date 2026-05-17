import { NextRequest, NextResponse } from 'next/server'
import { ProductRepository } from '@/modules/products/repository/ProductRepository'
import { ProductService } from '@/modules/products/services/ProductService'

const service = new ProductService(new ProductRepository())

export async function POST(req: NextRequest) {
  try {
    const data = await req.json()
    const product = await service.create(data)
    return NextResponse.json(product, { status: 201 })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to create product'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

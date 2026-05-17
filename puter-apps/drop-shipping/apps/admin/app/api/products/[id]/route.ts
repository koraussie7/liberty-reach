import { NextRequest, NextResponse } from 'next/server'
import { ProductRepository } from '@/modules/products/repository/ProductRepository'
import { ProductService } from '@/modules/products/services/ProductService'

const service = new ProductService(new ProductRepository())

interface Params { params: Promise<{ id: string }> }

export async function PUT(req: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    const data = await req.json()
    const product = await service.update(id, data)
    return NextResponse.json(product)
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to update product'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

export async function DELETE(_req: NextRequest, { params }: Params) {
  try {
    const { id } = await params
    await service.delete(id)
    return NextResponse.json({ success: true })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to delete product'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

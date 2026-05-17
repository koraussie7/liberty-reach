import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ProductForm } from '@/modules/products/components/ProductForm'
import { ProductRepository } from '@/modules/products/repository/ProductRepository'
import { ProductService } from '@/modules/products/services/ProductService'

interface Props { params: Promise<{ id: string }> }

export default async function EditProductPage({ params }: Props) {
  const { id } = await params
  let product = null
  try {
    product = await new ProductService(new ProductRepository()).getById(id)
  } catch {}
  if (!product) notFound()

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3">
        <Link href="/products" className="text-gray-400 hover:text-gray-600 text-sm">← Products</Link>
        <span className="text-gray-300">/</span>
        <span className="text-sm text-gray-600">Edit Product</span>
      </div>
      <h2 className="text-2xl font-bold text-gray-900">Edit Product</h2>
      <ProductForm product={product} />
    </div>
  )
}

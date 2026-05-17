import Link from 'next/link'
import { ProductForm } from '@/modules/products/components/ProductForm'

export default function NewProductPage() {
  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3">
        <Link href="/products" className="text-gray-400 hover:text-gray-600 text-sm">← Products</Link>
        <span className="text-gray-300">/</span>
        <span className="text-sm text-gray-600">Add Product</span>
      </div>
      <h2 className="text-2xl font-bold text-gray-900">Add New Product</h2>
      <ProductForm />
    </div>
  )
}

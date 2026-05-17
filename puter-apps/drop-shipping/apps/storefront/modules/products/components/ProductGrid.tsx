import { ProductCard } from './ProductCard'
import type { ProductCardProps } from '../models/product.model'

export function ProductGrid({ products, title }: { products: ProductCardProps[]; title?: string }) {
  if (products.length === 0) {
    return (
      <div className="text-center py-16 text-gray-400">
        <p>No products found.</p>
      </div>
    )
  }

  return (
    <section>
      {title && <h2 className="text-2xl font-bold text-gray-900 mb-6">{title}</h2>}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
        {products.map((p) => (
          <ProductCard key={p.id} product={p} />
        ))}
      </div>
    </section>
  )
}

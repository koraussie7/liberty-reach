'use client'

import Link from 'next/link'
import Image from 'next/image'
import { useCart } from '@/shared/context/CartContext'
import { StarRating } from '@/shared/components/ui/StarRating'
import { PriceDisplay } from '@/shared/components/ui/PriceDisplay'
import type { ProductCardProps } from '../models/product.model'

export function ProductCard({ product }: { product: ProductCardProps }) {
  const { addItem } = useCart()

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault()
    addItem({
      productId: product.id,
      name: product.name,
      image: product.image,
      price: product.customerPrice,
      quantity: 1,
      slug: product.slug,
    })
  }

  return (
    <Link href={`/products/${product.slug}`} className="group block">
      <div className="bg-white rounded-xl overflow-hidden border border-gray-100 hover:shadow-lg transition-shadow duration-200">
        {/* Image */}
        <div className="relative aspect-square bg-gray-50 overflow-hidden">
          <Image
            src={product.image}
            alt={product.name}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
        </div>

        {/* Info */}
        <div className="p-3">
          <p className="text-xs text-gray-400 uppercase tracking-wide mb-1">{product.category}</p>
          <h3 className="text-sm font-medium text-gray-900 line-clamp-2 mb-2 group-hover:text-primary-700 transition-colors">
            {product.name}
          </h3>
          <StarRating rating={4} count={12} />
          <div className="flex items-center justify-between mt-2">
            <PriceDisplay price={product.customerPrice} />
            <button
              onClick={handleAddToCart}
              className="bg-primary-600 hover:bg-primary-700 text-white text-xs font-medium px-3 py-1.5 rounded-lg transition-colors"
            >
              Add
            </button>
          </div>
        </div>
      </div>
    </Link>
  )
}

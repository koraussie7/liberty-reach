import type { Product } from '@dropshipping/database'

export type { Product }

export interface ProductCardProps {
  id: string
  name: string
  slug: string
  image: string
  customerPrice: number
  category: string
  isActive: boolean
}

export function toProductCard(product: Product): ProductCardProps {
  return {
    id: product.id,
    name: product.name,
    slug: product.slug,
    image: product.images[0] ?? '/placeholder.jpg',
    customerPrice: Number(product.customerPrice),
    category: product.category,
    isActive: product.isActive,
  }
}

import type { Product } from '@dropshipping/database'

export interface IProductRepository {
  findAll(filters?: ProductFilters): Promise<Product[]>
  findById(id: string): Promise<Product | null>
  findBySlug(slug: string): Promise<Product | null>
  findByCategory(category: string): Promise<Product[]>
  findFeatured(limit?: number): Promise<Product[]>
}

export interface ProductFilters {
  category?: string
  search?: string
  minPrice?: number
  maxPrice?: number
  isActive?: boolean
}

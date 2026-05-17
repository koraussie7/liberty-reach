import type { Product } from '@dropshipping/database'
import type { ProductFilters } from './IProductRepository'

export interface IProductService {
  getAll(filters?: ProductFilters): Promise<Product[]>
  getById(id: string): Promise<Product | null>
  getBySlug(slug: string): Promise<Product | null>
  getByCategory(category: string): Promise<Product[]>
  getFeatured(limit?: number): Promise<Product[]>
  getCategories(): Promise<string[]>
}

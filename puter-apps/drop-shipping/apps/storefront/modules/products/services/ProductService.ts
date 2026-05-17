import type { IProductService } from '../interfaces/IProductService'
import type { IProductRepository, ProductFilters } from '../interfaces/IProductRepository'
import type { Product } from '@dropshipping/database'

export class ProductService implements IProductService {
  constructor(private readonly repo: IProductRepository) {}

  getAll(filters?: ProductFilters): Promise<Product[]> {
    return this.repo.findAll(filters)
  }

  getById(id: string): Promise<Product | null> {
    return this.repo.findById(id)
  }

  getBySlug(slug: string): Promise<Product | null> {
    return this.repo.findBySlug(slug)
  }

  getByCategory(category: string): Promise<Product[]> {
    return this.repo.findByCategory(category)
  }

  getFeatured(limit?: number): Promise<Product[]> {
    return this.repo.findFeatured(limit)
  }

  async getCategories(): Promise<string[]> {
    const all = await this.repo.findAll({ isActive: true })
    return [...new Set(all.map((p) => p.category))].sort()
  }
}

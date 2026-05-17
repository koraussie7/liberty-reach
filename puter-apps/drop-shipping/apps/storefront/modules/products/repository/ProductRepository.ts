import { prisma } from '@dropshipping/database'
import type { IProductRepository, ProductFilters } from '../interfaces/IProductRepository'
import type { Product } from '@dropshipping/database'

export class ProductRepository implements IProductRepository {
  async findAll(filters: ProductFilters = {}): Promise<Product[]> {
    return prisma.product.findMany({
      where: {
        isActive: filters.isActive ?? true,
        ...(filters.category && { category: filters.category }),
        ...(filters.search && {
          OR: [
            { name: { contains: filters.search, mode: 'insensitive' } },
            { description: { contains: filters.search, mode: 'insensitive' } },
          ],
        }),
        ...(filters.minPrice !== undefined && {
          customerPrice: { gte: filters.minPrice },
        }),
        ...(filters.maxPrice !== undefined && {
          customerPrice: { lte: filters.maxPrice },
        }),
      },
      orderBy: { createdAt: 'desc' },
    })
  }

  async findById(id: string): Promise<Product | null> {
    return prisma.product.findUnique({ where: { id } })
  }

  async findBySlug(slug: string): Promise<Product | null> {
    return prisma.product.findUnique({ where: { slug, isActive: true } })
  }

  async findByCategory(category: string): Promise<Product[]> {
    return prisma.product.findMany({
      where: { category, isActive: true },
      orderBy: { createdAt: 'desc' },
    })
  }

  async findFeatured(limit = 8): Promise<Product[]> {
    return prisma.product.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
      take: limit,
    })
  }
}

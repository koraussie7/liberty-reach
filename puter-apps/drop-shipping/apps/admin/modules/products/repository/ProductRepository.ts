import { prisma } from '@dropshipping/database'
import type { Product } from '@dropshipping/database'
import type { IProductRepository } from '../interfaces/IProductRepository'
import type { CreateProductDto, UpdateProductDto } from '@dropshipping/shared-types'

export class ProductRepository implements IProductRepository {
  findAll(): Promise<Product[]> {
    return prisma.product.findMany({ orderBy: { createdAt: 'desc' } })
  }

  findById(id: string): Promise<Product | null> {
    return prisma.product.findUnique({ where: { id } })
  }

  create(data: CreateProductDto): Promise<Product> {
    return prisma.product.create({ data })
  }

  update(id: string, data: UpdateProductDto): Promise<Product> {
    return prisma.product.update({ where: { id }, data })
  }

  async delete(id: string): Promise<void> {
    await prisma.product.delete({ where: { id } })
  }

  toggleActive(id: string, isActive: boolean): Promise<Product> {
    return prisma.product.update({ where: { id }, data: { isActive } })
  }
}

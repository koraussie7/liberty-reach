import type { Product } from '@dropshipping/database'
import type { CreateProductDto, UpdateProductDto } from '@dropshipping/shared-types'

export interface IProductRepository {
  findAll(): Promise<Product[]>
  findById(id: string): Promise<Product | null>
  create(data: CreateProductDto): Promise<Product>
  update(id: string, data: UpdateProductDto): Promise<Product>
  delete(id: string): Promise<void>
  toggleActive(id: string, isActive: boolean): Promise<Product>
}

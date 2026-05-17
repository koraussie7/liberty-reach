import type { Product } from '@dropshipping/database'
import type { CreateProductDto, UpdateProductDto } from '@dropshipping/shared-types'

export interface IProductService {
  getAll(): Promise<Product[]>
  getById(id: string): Promise<Product | null>
  create(data: CreateProductDto): Promise<Product>
  update(id: string, data: UpdateProductDto): Promise<Product>
  delete(id: string): Promise<void>
  toggleActive(id: string, isActive: boolean): Promise<Product>
  getMargin(product: Product): number
}

import type { IProductService } from '../interfaces/IProductService'
import type { IProductRepository } from '../interfaces/IProductRepository'
import type { Product } from '@dropshipping/database'
import type { CreateProductDto, UpdateProductDto } from '@dropshipping/shared-types'

export class ProductService implements IProductService {
  constructor(private readonly repo: IProductRepository) {}

  getAll(): Promise<Product[]> { return this.repo.findAll() }
  getById(id: string): Promise<Product | null> { return this.repo.findById(id) }
  create(data: CreateProductDto): Promise<Product> { return this.repo.create(data) }
  update(id: string, data: UpdateProductDto): Promise<Product> { return this.repo.update(id, data) }
  delete(id: string): Promise<void> { return this.repo.delete(id) }
  toggleActive(id: string, isActive: boolean): Promise<Product> { return this.repo.toggleActive(id, isActive) }

  getMargin(product: Product): number {
    return Number(product.customerPrice) - Number(product.supplierCost)
  }
}

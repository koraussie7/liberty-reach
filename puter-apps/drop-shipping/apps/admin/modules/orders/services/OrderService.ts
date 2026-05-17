import type { IOrderService } from '../interfaces/IOrderService'
import type { IOrderRepository } from '../interfaces/IOrderRepository'
import type { Order, OrderStatus } from '@dropshipping/database'
import type { ForwardOrderDto } from '@dropshipping/shared-types'

export class OrderService implements IOrderService {
  constructor(private readonly repo: IOrderRepository) {}

  getAll(): Promise<Order[]> { return this.repo.findAll() }
  getById(id: string): Promise<Order | null> { return this.repo.findById(id) }
  getPending(): Promise<Order[]> { return this.repo.findPending() }
  updateStatus(id: string, status: OrderStatus): Promise<Order> { return this.repo.updateStatus(id, status) }
  updateTracking(id: string, trackingNumber: string): Promise<Order> { return this.repo.updateTracking(id, trackingNumber) }

  async forwardToSupplier(data: ForwardOrderDto): Promise<Order> {
    const order = await this.repo.findById(data.orderId)
    if (!order) throw new Error('Order not found')
    if (order.supplierForwarded) throw new Error('Order already forwarded')
    return this.repo.markForwarded(data.orderId)
  }
}

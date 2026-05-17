import type { Order, OrderStatus } from '@dropshipping/database'
import type { ForwardOrderDto } from '@dropshipping/shared-types'

export interface IOrderService {
  getAll(): Promise<Order[]>
  getById(id: string): Promise<Order | null>
  getPending(): Promise<Order[]>
  forwardToSupplier(data: ForwardOrderDto): Promise<Order>
  updateTracking(id: string, trackingNumber: string): Promise<Order>
  updateStatus(id: string, status: OrderStatus): Promise<Order>
}

import type { Order, OrderStatus } from '@dropshipping/database'

export interface IOrderRepository {
  findAll(): Promise<Order[]>
  findById(id: string): Promise<Order | null>
  findPending(): Promise<Order[]>
  updateStatus(id: string, status: OrderStatus): Promise<Order>
  updateTracking(id: string, trackingNumber: string): Promise<Order>
  markForwarded(id: string): Promise<Order>
}

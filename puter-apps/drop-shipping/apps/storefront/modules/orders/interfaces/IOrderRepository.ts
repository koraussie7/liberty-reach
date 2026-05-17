import type { Order } from '@dropshipping/database'
import type { CreateOrderDto } from '@dropshipping/shared-types'

export interface IOrderRepository {
  create(data: CreateOrderDto): Promise<Order>
  findById(id: string): Promise<Order | null>
  findByStripeSession(sessionId: string): Promise<Order | null>
  findByUser(userId: string): Promise<Order[]>
  findByEmail(email: string): Promise<Order[]>
}

import type { Order } from '@dropshipping/database'
import type { CreateOrderDto } from '@dropshipping/shared-types'

export interface IOrderService {
  createFromStripeWebhook(sessionId: string): Promise<Order>
  getById(id: string): Promise<Order | null>
  getByUser(userId: string): Promise<Order[]>
}

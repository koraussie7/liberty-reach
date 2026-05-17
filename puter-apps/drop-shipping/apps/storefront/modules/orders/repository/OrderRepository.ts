import { prisma } from '@dropshipping/database'
import type { Order } from '@dropshipping/database'
import type { IOrderRepository } from '../interfaces/IOrderRepository'
import type { CreateOrderDto } from '@dropshipping/shared-types'

export class OrderRepository implements IOrderRepository {
  async create(data: CreateOrderDto): Promise<Order> {
    return prisma.order.create({
      data: {
        customerEmail: data.customerEmail,
        customerName: data.customerName,
        shippingAddress: data.shippingAddress,
        stripeSessionId: data.stripeSessionId,
        totalAmount: data.totalAmount,
        items: {
          create: data.items.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          })),
        },
      },
      include: { items: true },
    })
  }

  async findById(id: string): Promise<Order | null> {
    return prisma.order.findUnique({
      where: { id },
      include: { items: { include: { product: true } } },
    })
  }

  async findByStripeSession(sessionId: string): Promise<Order | null> {
    return prisma.order.findUnique({ where: { stripeSessionId: sessionId } })
  }

  async findByUser(userId: string): Promise<Order[]> {
    return prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { items: true },
    })
  }

  async findByEmail(email: string): Promise<Order[]> {
    return prisma.order.findMany({
      where: { customerEmail: email },
      orderBy: { createdAt: 'desc' },
      include: { items: true },
    })
  }
}

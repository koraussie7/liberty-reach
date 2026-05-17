import { prisma } from '@dropshipping/database'
import type { Order, OrderStatus } from '@dropshipping/database'
import type { IOrderRepository } from '../interfaces/IOrderRepository'

export class OrderRepository implements IOrderRepository {
  findAll(): Promise<Order[]> {
    return prisma.order.findMany({
      orderBy: { createdAt: 'desc' },
      include: { items: { include: { product: true } }, user: true },
    })
  }

  findById(id: string): Promise<Order | null> {
    return prisma.order.findUnique({
      where: { id },
      include: { items: { include: { product: true } }, user: true },
    })
  }

  findPending(): Promise<Order[]> {
    return prisma.order.findMany({
      where: { status: 'PAID', supplierForwarded: false },
      orderBy: { createdAt: 'asc' },
      include: { items: { include: { product: true } } },
    })
  }

  updateStatus(id: string, status: OrderStatus): Promise<Order> {
    return prisma.order.update({ where: { id }, data: { status } })
  }

  updateTracking(id: string, trackingNumber: string): Promise<Order> {
    return prisma.order.update({
      where: { id },
      data: { trackingNumber, status: 'SHIPPED' },
    })
  }

  markForwarded(id: string): Promise<Order> {
    return prisma.order.update({
      where: { id },
      data: { supplierForwarded: true, status: 'FORWARDED_TO_SUPPLIER' },
    })
  }
}

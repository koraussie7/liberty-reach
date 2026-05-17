import { prisma } from '@dropshipping/database'
import Link from 'next/link'

async function getStats() {
  try {
    const [totalOrders, pendingOrders, totalProducts, revenue] = await Promise.all([
      prisma.order.count(),
      prisma.order.count({ where: { status: 'PAID', supplierForwarded: false } }),
      prisma.product.count({ where: { isActive: true } }),
      prisma.order.aggregate({ _sum: { totalAmount: true }, where: { status: { in: ['PAID', 'SHIPPED', 'DELIVERED'] } } }),
    ])
    return { totalOrders, pendingOrders, totalProducts, revenue: Number(revenue._sum.totalAmount ?? 0) }
  } catch {
    return { totalOrders: 0, pendingOrders: 0, totalProducts: 0, revenue: 0 }
  }
}

async function getRecentOrders() {
  try {
    return prisma.order.findMany({ orderBy: { createdAt: 'desc' }, take: 5, include: { items: true } })
  } catch {
    return []
  }
}

const STATUS_COLORS: Record<string, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800',
  PAID: 'bg-blue-100 text-blue-800',
  FORWARDED_TO_SUPPLIER: 'bg-teal-100 text-teal-800',
  SHIPPED: 'bg-purple-100 text-purple-800',
  DELIVERED: 'bg-green-100 text-green-800',
  CANCELLED: 'bg-red-100 text-red-800',
}

export default async function DashboardPage() {
  const [stats, recentOrders] = await Promise.all([getStats(), getRecentOrders()])

  const statCards = [
    { label: 'Total Revenue', value: `£${stats.revenue.toFixed(2)}`, icon: '💰', color: 'bg-green-50 border-green-200' },
    { label: 'Total Orders', value: stats.totalOrders, icon: '🛒', color: 'bg-blue-50 border-blue-200' },
    { label: 'Pending Forwarding', value: stats.pendingOrders, icon: '⏳', color: 'bg-yellow-50 border-yellow-200' },
    { label: 'Active Products', value: stats.totalProducts, icon: '📦', color: 'bg-teal-50 border-teal-200' },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Overview</h2>
        <p className="text-gray-500 text-sm mt-1">Welcome back. Here's what's happening today.</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((s) => (
          <div key={s.label} className={`bg-white rounded-xl border ${s.color} p-5`}>
            <div className="text-2xl mb-2">{s.icon}</div>
            <div className="text-2xl font-bold text-gray-900">{s.value}</div>
            <div className="text-sm text-gray-500 mt-1">{s.label}</div>
          </div>
        ))}
      </div>

      {/* Pending orders alert */}
      {stats.pendingOrders > 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-2xl">⚠️</span>
            <div>
              <p className="font-semibold text-yellow-800">{stats.pendingOrders} order{stats.pendingOrders > 1 ? 's' : ''} need forwarding to supplier</p>
              <p className="text-sm text-yellow-600">These are paid but not yet forwarded.</p>
            </div>
          </div>
          <Link href="/orders" className="bg-yellow-600 text-white text-sm font-medium px-4 py-2 rounded-lg hover:bg-yellow-700">
            View Orders
          </Link>
        </div>
      )}

      {/* Recent orders */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h3 className="font-semibold text-gray-900">Recent Orders</h3>
          <Link href="/orders" className="text-sm text-primary-600 hover:underline">View all</Link>
        </div>
        {recentOrders.length === 0 ? (
          <div className="p-10 text-center text-gray-400 text-sm">No orders yet</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                {['Order', 'Customer', 'Items', 'Total', 'Status'].map((h) => (
                  <th key={h} className="px-5 py-3 text-left">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {recentOrders.map((order) => (
                <tr key={order.id} className="hover:bg-gray-50">
                  <td className="px-5 py-3">
                    <Link href={`/orders/${order.id}`} className="text-primary-600 hover:underline font-mono text-xs">
                      #{order.id.slice(-6).toUpperCase()}
                    </Link>
                  </td>
                  <td className="px-5 py-3 text-gray-700">{order.customerName}</td>
                  <td className="px-5 py-3 text-gray-500">{order.items.length} item{order.items.length > 1 ? 's' : ''}</td>
                  <td className="px-5 py-3 font-semibold text-gray-900">£{Number(order.totalAmount).toFixed(2)}</td>
                  <td className="px-5 py-3">
                    <span className={`text-xs font-medium px-2 py-1 rounded-full ${STATUS_COLORS[order.status] ?? 'bg-gray-100 text-gray-600'}`}>
                      {order.status.replace(/_/g, ' ')}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}

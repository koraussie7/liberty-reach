import Link from 'next/link'
import { OrderRepository } from '@/modules/orders/repository/OrderRepository'
import { OrderService } from '@/modules/orders/services/OrderService'
import { ORDER_STATUS_COLORS, ORDER_STATUS_LABELS } from '@/modules/orders/models/order.model'

async function getOrders() {
  try {
    return new OrderService(new OrderRepository()).getAll()
  } catch { return [] }
}

export default async function OrdersPage() {
  const orders = await getOrders()
  const pending = orders.filter((o) => o.status === 'PAID' && !o.supplierForwarded)

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Orders</h2>
          <p className="text-sm text-gray-500 mt-0.5">{orders.length} total · {pending.length} need forwarding</p>
        </div>
      </div>

      {pending.length > 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 text-sm text-yellow-800">
          ⚠️ <strong>{pending.length} paid order{pending.length > 1 ? 's' : ''}</strong> waiting to be forwarded to supplier.
        </div>
      )}

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        {orders.length === 0 ? (
          <div className="p-16 text-center text-gray-400 text-sm">No orders yet</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                {['Order ID', 'Customer', 'Date', 'Total', 'Status', 'Forwarded', ''].map((h) => (
                  <th key={h} className="px-5 py-3 text-left">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {orders.map((order) => (
                <tr key={order.id} className={`hover:bg-gray-50 ${order.status === 'PAID' && !order.supplierForwarded ? 'bg-yellow-50/40' : ''}`}>
                  <td className="px-5 py-3 font-mono text-xs text-primary-600">
                    #{order.id.slice(-6).toUpperCase()}
                  </td>
                  <td className="px-5 py-3">
                    <p className="font-medium text-gray-900">{order.customerName}</p>
                    <p className="text-gray-400 text-xs">{order.customerEmail}</p>
                  </td>
                  <td className="px-5 py-3 text-gray-500 text-xs">
                    {new Date(order.createdAt).toLocaleDateString('en-GB')}
                  </td>
                  <td className="px-5 py-3 font-semibold text-gray-900">£{Number(order.totalAmount).toFixed(2)}</td>
                  <td className="px-5 py-3">
                    <span className={`text-xs font-medium px-2 py-1 rounded-full ${ORDER_STATUS_COLORS[order.status] ?? 'bg-gray-100 text-gray-600'}`}>
                      {ORDER_STATUS_LABELS[order.status] ?? order.status}
                    </span>
                  </td>
                  <td className="px-5 py-3">
                    {order.supplierForwarded
                      ? <span className="text-green-600 text-xs">✓ Yes</span>
                      : <span className="text-gray-400 text-xs">No</span>}
                  </td>
                  <td className="px-5 py-3">
                    <Link href={`/orders/${order.id}`} className="text-primary-600 hover:underline text-xs font-medium">
                      View
                    </Link>
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

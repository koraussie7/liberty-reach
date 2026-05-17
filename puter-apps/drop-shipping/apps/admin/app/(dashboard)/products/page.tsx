import Link from 'next/link'
import { ProductRepository } from '@/modules/products/repository/ProductRepository'
import { ProductService } from '@/modules/products/services/ProductService'

async function getProducts() {
  try {
    return new ProductService(new ProductRepository()).getAll()
  } catch { return [] }
}

export default async function ProductsPage() {
  const products = await getProducts()

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Products</h2>
          <p className="text-sm text-gray-500 mt-0.5">{products.length} products in catalogue</p>
        </div>
        <Link href="/products/new" className="bg-primary-600 text-white text-sm font-medium px-4 py-2 rounded-lg hover:bg-primary-700 transition-colors">
          + Add Product
        </Link>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        {products.length === 0 ? (
          <div className="p-16 text-center text-gray-400">
            <p className="text-lg mb-2">No products yet</p>
            <Link href="/products/new" className="text-primary-600 text-sm underline">Add your first product</Link>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                {['Product', 'Category', 'Customer Price', 'Supplier Cost', 'Margin', 'Stock', 'Status', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {products.map((p) => {
                const margin = Number(p.customerPrice) - Number(p.supplierCost)
                return (
                  <tr key={p.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <p className="font-medium text-gray-900 truncate max-w-xs">{p.name}</p>
                    </td>
                    <td className="px-4 py-3 text-gray-500">{p.category}</td>
                    <td className="px-4 py-3 font-semibold text-gray-900">£{Number(p.customerPrice).toFixed(2)}</td>
                    <td className="px-4 py-3 text-gray-500">£{Number(p.supplierCost).toFixed(2)}</td>
                    <td className="px-4 py-3 font-semibold text-green-600">£{margin.toFixed(2)}</td>
                    <td className="px-4 py-3 text-gray-500">{p.stock}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-medium px-2 py-1 rounded-full ${p.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                        {p.isActive ? 'Active' : 'Hidden'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <Link href={`/products/${p.id}`} className="text-primary-600 hover:underline text-xs">Edit</Link>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}

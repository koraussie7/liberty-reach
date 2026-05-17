import Link from 'next/link'
import { ProductGrid } from '@/modules/products/components/ProductGrid'
import { CategoryTiles } from '@/modules/products/components/CategoryTiles'
import { ProductRepository } from '@/modules/products/repository/ProductRepository'
import { ProductService } from '@/modules/products/services/ProductService'
import { toProductCard } from '@/modules/products/models/product.model'

async function getFeaturedProducts() {
  try {
    const service = new ProductService(new ProductRepository())
    const products = await service.getFeatured(8)
    return products.map(toProductCard)
  } catch {
    return []
  }
}

export default async function HomePage() {
  const featured = await getFeaturedProducts()

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-primary-700 to-primary-900 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 flex flex-col md:flex-row items-center gap-10">
          <div className="flex-1 text-center md:text-left">
            <h1 className="text-4xl md:text-5xl font-extrabold leading-tight mb-4">
              Style Your Space,<br />
              <span className="text-primary-200">Without the Hassle</span>
            </h1>
            <p className="text-primary-100 text-lg mb-8 max-w-lg">
              Thousands of quality products delivered straight to your door. Free UK shipping on orders over £50.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 justify-center md:justify-start">
              <Link href="/products" className="bg-white text-primary-700 font-semibold px-8 py-3 rounded-full hover:bg-primary-50 transition-colors">
                Shop Now
              </Link>
              <Link href="/categories/sale" className="border border-white text-white font-semibold px-8 py-3 rounded-full hover:bg-white/10 transition-colors">
                View Sale
              </Link>
            </div>
          </div>
          <div className="flex-1 flex justify-center">
            <div className="w-72 h-72 rounded-3xl bg-white/10 flex items-center justify-center text-8xl shadow-2xl">
              🛋️
            </div>
          </div>
        </div>
      </section>

      {/* Trust badges */}
      <section className="bg-white border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center text-sm text-gray-600">
            {[
              { icon: '🚚', text: 'Free UK delivery over £50' },
              { icon: '↩️', text: '30-day easy returns' },
              { icon: '🔒', text: 'Secure checkout' },
              { icon: '⭐', text: '10,000+ happy customers' },
            ].map((b) => (
              <div key={b.text} className="flex items-center justify-center gap-2">
                <span className="text-xl">{b.icon}</span>
                <span>{b.text}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 space-y-14">
        {/* Categories */}
        <CategoryTiles />

        {/* Featured products */}
        {featured.length > 0 ? (
          <ProductGrid products={featured} title="Featured Products" />
        ) : (
          <section>
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Featured Products</h2>
            <div className="bg-white rounded-xl border border-dashed border-gray-200 p-12 text-center text-gray-400">
              <p className="text-lg mb-2">No products yet</p>
              <p className="text-sm">Add your first product in the <Link href="http://localhost:3001" className="text-primary-600 underline">admin dashboard</Link></p>
            </div>
          </section>
        )}
      </div>
    </div>
  )
}

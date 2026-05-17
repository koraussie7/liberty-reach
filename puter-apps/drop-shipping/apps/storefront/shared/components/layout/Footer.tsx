import Link from 'next/link'

export function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-300 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          <div>
            <h3 className="text-white font-bold text-lg mb-4">ShopDrop</h3>
            <p className="text-sm text-gray-400">Quality products, delivered to your door. Free UK shipping on orders over £50.</p>
          </div>
          <div>
            <h4 className="text-white font-semibold mb-3">Shop</h4>
            <ul className="space-y-2 text-sm">
              <li><Link href="/products" className="hover:text-primary-400 transition-colors">All Products</Link></li>
              <li><Link href="/categories/living-room" className="hover:text-primary-400 transition-colors">Living Room</Link></li>
              <li><Link href="/categories/bedroom" className="hover:text-primary-400 transition-colors">Bedroom</Link></li>
              <li><Link href="/categories/sale" className="hover:text-primary-400 transition-colors">Sale</Link></li>
            </ul>
          </div>
          <div>
            <h4 className="text-white font-semibold mb-3">Help</h4>
            <ul className="space-y-2 text-sm">
              <li><Link href="/returns" className="hover:text-primary-400 transition-colors">Returns Policy</Link></li>
              <li><Link href="/shipping" className="hover:text-primary-400 transition-colors">Shipping Info</Link></li>
              <li><Link href="/contact" className="hover:text-primary-400 transition-colors">Contact Us</Link></li>
              <li><Link href="/faq" className="hover:text-primary-400 transition-colors">FAQ</Link></li>
            </ul>
          </div>
          <div>
            <h4 className="text-white font-semibold mb-3">Account</h4>
            <ul className="space-y-2 text-sm">
              <li><Link href="/login" className="hover:text-primary-400 transition-colors">Sign In</Link></li>
              <li><Link href="/register" className="hover:text-primary-400 transition-colors">Register</Link></li>
              <li><Link href="/orders" className="hover:text-primary-400 transition-colors">Track Order</Link></li>
            </ul>
          </div>
        </div>
        <div className="border-t border-gray-700 mt-8 pt-6 text-center text-sm text-gray-500">
          © {new Date().getFullYear()} ShopDrop. All rights reserved.
        </div>
      </div>
    </footer>
  )
}

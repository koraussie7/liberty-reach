import Link from 'next/link'

export default function CancelPage() {
  return (
    <div className="max-w-xl mx-auto px-4 py-24 text-center">
      <div className="text-6xl mb-6">😕</div>
      <h1 className="text-3xl font-bold text-gray-900 mb-3">Payment Cancelled</h1>
      <p className="text-gray-500 mb-8">Your order was not placed. Your cart is still saved.</p>
      <Link href="/cart" className="bg-primary-600 text-white font-semibold px-8 py-3 rounded-full hover:bg-primary-700 transition-colors">
        Return to Cart
      </Link>
    </div>
  )
}

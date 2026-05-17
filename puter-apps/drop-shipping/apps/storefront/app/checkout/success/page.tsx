import Link from 'next/link'

export default function SuccessPage() {
  return (
    <div className="max-w-xl mx-auto px-4 py-24 text-center">
      <div className="text-6xl mb-6">🎉</div>
      <h1 className="text-3xl font-bold text-gray-900 mb-3">Order Confirmed!</h1>
      <p className="text-gray-500 mb-8">Thank you for your purchase. You'll receive a confirmation email shortly.</p>
      <Link href="/products" className="bg-primary-600 text-white font-semibold px-8 py-3 rounded-full hover:bg-primary-700 transition-colors">
        Continue Shopping
      </Link>
    </div>
  )
}

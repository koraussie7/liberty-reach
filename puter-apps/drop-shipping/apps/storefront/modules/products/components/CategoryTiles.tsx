import Link from 'next/link'

const CATEGORIES = [
  { name: 'Living Room', href: '/categories/living-room', emoji: '🛋️', bg: 'bg-amber-50' },
  { name: 'Bedroom',     href: '/categories/bedroom',     emoji: '🛏️', bg: 'bg-blue-50' },
  { name: 'Kitchen',     href: '/categories/kitchen',     emoji: '🍳', bg: 'bg-green-50' },
  { name: 'Office',      href: '/categories/office',      emoji: '💼', bg: 'bg-purple-50' },
  { name: 'Outdoor',     href: '/categories/outdoor',     emoji: '🌿', bg: 'bg-teal-50' },
  { name: 'Sale',        href: '/categories/sale',        emoji: '🏷️', bg: 'bg-red-50' },
]

export function CategoryTiles() {
  return (
    <section>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Shop by Category</h2>
      <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
        {CATEGORIES.map((cat) => (
          <Link
            key={cat.href}
            href={cat.href}
            className={`${cat.bg} rounded-xl p-4 flex flex-col items-center justify-center gap-2 hover:shadow-md transition-shadow group`}
          >
            <span className="text-3xl">{cat.emoji}</span>
            <span className="text-xs font-medium text-gray-700 text-center group-hover:text-primary-700">{cat.name}</span>
          </Link>
        ))}
      </div>
    </section>
  )
}

export function PriceDisplay({ price, originalPrice }: { price: number; originalPrice?: number }) {
  const isOnSale = originalPrice && originalPrice > price
  return (
    <div className="flex items-center gap-2">
      <span className={`font-bold text-lg ${isOnSale ? 'text-red-600' : 'text-gray-900'}`}>
        £{price.toFixed(2)}
      </span>
      {isOnSale && (
        <span className="text-sm text-gray-400 line-through">£{originalPrice!.toFixed(2)}</span>
      )}
    </div>
  )
}

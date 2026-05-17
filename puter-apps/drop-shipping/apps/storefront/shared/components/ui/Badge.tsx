export function Badge({ label, variant = 'new' }: { label: string; variant?: 'new' | 'sale' | 'hot' }) {
  const styles = {
    new:  'bg-primary-600 text-white',
    sale: 'bg-red-500 text-white',
    hot:  'bg-orange-500 text-white',
  }
  return (
    <span className={`text-xs font-semibold px-2 py-0.5 rounded ${styles[variant]}`}>
      {label}
    </span>
  )
}

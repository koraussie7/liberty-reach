'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import type { Product } from '@dropshipping/database'

interface ProductFormProps {
  product?: Product
}

function slugify(text: string) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
}

export function ProductForm({ product }: ProductFormProps) {
  const router = useRouter()
  const isEdit = !!product

  const [form, setForm] = useState({
    name:          product?.name          ?? '',
    slug:          product?.slug          ?? '',
    description:   product?.description   ?? '',
    category:      product?.category      ?? '',
    images:        product?.images.join('\n') ?? '',
    tags:          product?.tags.join(', ')   ?? '',
    customerPrice: product ? String(product.customerPrice) : '',
    supplierCost:  product ? String(product.supplierCost)  : '',
    stock:         product ? String(product.stock)         : '0',
    isActive:      product?.isActive ?? true,
  })

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const set = (field: string, value: string | boolean) =>
    setForm((prev) => ({ ...prev, [field]: value }))

  const handleNameChange = (name: string) => {
    setForm((prev) => ({ ...prev, name, slug: prev.slug || slugify(name) }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    const payload = {
      name:          form.name,
      slug:          form.slug,
      description:   form.description,
      category:      form.category,
      images:        form.images.split('\n').map((s) => s.trim()).filter(Boolean),
      tags:          form.tags.split(',').map((s) => s.trim()).filter(Boolean),
      customerPrice: parseFloat(form.customerPrice),
      supplierCost:  parseFloat(form.supplierCost),
      stock:         parseInt(form.stock),
      isActive:      form.isActive,
    }

    try {
      const res = await fetch(
        isEdit ? `/api/products/${product!.id}` : '/api/products',
        {
          method:  isEdit ? 'PUT' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body:    JSON.stringify(payload),
        }
      )
      const data = await res.json()
      if (!res.ok) throw new Error(data.error ?? 'Something went wrong')
      router.push('/products')
      router.refresh()
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  const margin =
    form.customerPrice && form.supplierCost
      ? (parseFloat(form.customerPrice) - parseFloat(form.supplierCost)).toFixed(2)
      : null

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-2xl">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-4 py-3">
          {error}
        </div>
      )}

      {/* Name & Slug */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
        <h3 className="font-semibold text-gray-900">Basic Info</h3>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Product Name *</label>
          <input
            required
            type="text"
            value={form.name}
            onChange={(e) => handleNameChange(e.target.value)}
            placeholder="e.g. Comfort Sofa 3-Seater"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Slug *</label>
          <input
            required
            type="text"
            value={form.slug}
            onChange={(e) => set('slug', slugify(e.target.value))}
            placeholder="comfort-sofa-3-seater"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
          <p className="text-xs text-gray-400 mt-1">URL: /products/{form.slug || '...'}</p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Description *</label>
          <textarea
            required
            rows={4}
            value={form.description}
            onChange={(e) => set('description', e.target.value)}
            placeholder="Describe the product..."
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500 resize-none"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Category *</label>
            <select
              required
              value={form.category}
              onChange={(e) => set('category', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Select category</option>
              {['Living Room', 'Bedroom', 'Kitchen', 'Office', 'Outdoor', 'Sale'].map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Tags</label>
            <input
              type="text"
              value={form.tags}
              onChange={(e) => set('tags', e.target.value)}
              placeholder="sofa, fabric, modern"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
            <p className="text-xs text-gray-400 mt-1">Comma separated</p>
          </div>
        </div>
      </div>

      {/* Pricing */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
        <h3 className="font-semibold text-gray-900">Pricing</h3>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Customer Price (£) *</label>
            <input
              required
              type="number"
              min="0"
              step="0.01"
              value={form.customerPrice}
              onChange={(e) => set('customerPrice', e.target.value)}
              placeholder="0.00"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
            <p className="text-xs text-gray-400 mt-1">What customer pays</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Supplier Cost (£) *</label>
            <input
              required
              type="number"
              min="0"
              step="0.01"
              value={form.supplierCost}
              onChange={(e) => set('supplierCost', e.target.value)}
              placeholder="0.00"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
            />
            <p className="text-xs text-gray-400 mt-1">What you pay supplier</p>
          </div>
        </div>

        {margin !== null && (
          <div className={`rounded-lg px-4 py-3 text-sm font-medium ${parseFloat(margin) > 0 ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'}`}>
            Your margin: £{margin} {parseFloat(margin) <= 0 && '⚠️ Selling at a loss!'}
          </div>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Stock</label>
          <input
            type="number"
            min="0"
            value={form.stock}
            onChange={(e) => set('stock', e.target.value)}
            className="w-32 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-teal-500"
          />
        </div>
      </div>

      {/* Images */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
        <h3 className="font-semibold text-gray-900">Images</h3>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Image URLs</label>
          <textarea
            rows={3}
            value={form.images}
            onChange={(e) => set('images', e.target.value)}
            placeholder={'https://example.com/image1.jpg\nhttps://example.com/image2.jpg'}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-teal-500 resize-none"
          />
          <p className="text-xs text-gray-400 mt-1">One URL per line</p>
        </div>
      </div>

      {/* Status */}
      <div className="bg-white rounded-xl border border-gray-200 p-5">
        <label className="flex items-center gap-3 cursor-pointer">
          <input
            type="checkbox"
            checked={form.isActive}
            onChange={(e) => set('isActive', e.target.checked)}
            className="w-4 h-4 accent-teal-600"
          />
          <div>
            <span className="text-sm font-medium text-gray-900">Active (visible on storefront)</span>
            <p className="text-xs text-gray-400">Uncheck to hide this product from customers</p>
          </div>
        </label>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={loading}
          className="bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white font-medium px-6 py-2.5 rounded-lg text-sm transition-colors"
        >
          {loading ? 'Saving...' : isEdit ? 'Save Changes' : 'Add Product'}
        </button>
        <button
          type="button"
          onClick={() => router.back()}
          className="text-sm text-gray-500 hover:text-gray-700 px-4 py-2.5"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}

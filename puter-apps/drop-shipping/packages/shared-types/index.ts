// ─── PRODUCT DTOs ─────────────────────────────────────────────────────────────

export interface CreateProductDto {
  name: string
  slug: string
  description: string
  images: string[]
  category: string
  tags: string[]
  customerPrice: number
  supplierCost: number
  stock: number
  isActive?: boolean
}

export interface UpdateProductDto extends Partial<CreateProductDto> {}

// ─── ORDER DTOs ───────────────────────────────────────────────────────────────

export interface ShippingAddress {
  line1: string
  line2?: string
  city: string
  postcode: string
  country: string
}

export interface CreateOrderDto {
  customerEmail: string
  customerName: string
  shippingAddress: ShippingAddress
  items: OrderItemDto[]
  stripeSessionId: string
  totalAmount: number
}

export interface OrderItemDto {
  productId: string
  quantity: number
  unitPrice: number
}

export interface ForwardOrderDto {
  orderId: string
  supplierEmail?: string
  notes?: string
}

// ─── AUTH DTOs ────────────────────────────────────────────────────────────────

export interface RegisterDto {
  email: string
  password: string
  name?: string
}

export interface LoginDto {
  email: string
  password: string
}

// ─── CART ─────────────────────────────────────────────────────────────────────

export interface CartItem {
  productId: string
  name: string
  image: string
  price: number
  quantity: number
  slug: string
}

export interface Cart {
  items: CartItem[]
  total: number
  itemCount: number
}

// ─── API RESPONSES ────────────────────────────────────────────────────────────

export interface ApiResponse<T> {
  data?: T
  error?: string
  message?: string
}

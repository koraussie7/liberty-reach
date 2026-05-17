import { NextRequest, NextResponse } from 'next/server'
import { AuthService } from '@/modules/auth/services/AuthService'

const authService = new AuthService()

export async function POST(req: NextRequest) {
  try {
    const { email, password, name } = await req.json()
    if (!email || !password) {
      return NextResponse.json({ error: 'Email and password are required' }, { status: 400 })
    }
    if (password.length < 8) {
      return NextResponse.json({ error: 'Password must be at least 8 characters' }, { status: 400 })
    }
    const user = await authService.register({ email, password, name })
    return NextResponse.json({ id: user.id, email: user.email }, { status: 201 })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Registration failed'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

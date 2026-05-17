import bcrypt from 'bcryptjs'
import { prisma } from '@dropshipping/database'
import type { User } from '@dropshipping/database'
import type { IAuthService } from '../interfaces/IAuthService'
import type { RegisterDto } from '@dropshipping/shared-types'

export class AuthService implements IAuthService {
  async register(data: RegisterDto): Promise<User> {
    const existing = await prisma.user.findUnique({ where: { email: data.email } })
    if (existing) throw new Error('Email already registered')

    const hashed = await bcrypt.hash(data.password, 12)
    return prisma.user.create({
      data: { email: data.email, password: hashed, name: data.name },
    })
  }

  async validateCredentials(email: string, password: string): Promise<User | null> {
    const user = await prisma.user.findUnique({ where: { email } })
    if (!user) return null
    const valid = await bcrypt.compare(password, user.password)
    return valid ? user : null
  }
}

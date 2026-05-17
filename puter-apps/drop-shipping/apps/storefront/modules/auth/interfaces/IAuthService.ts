import type { User } from '@dropshipping/database'
import type { RegisterDto } from '@dropshipping/shared-types'

export interface IAuthService {
  register(data: RegisterDto): Promise<User>
  validateCredentials(email: string, password: string): Promise<User | null>
}

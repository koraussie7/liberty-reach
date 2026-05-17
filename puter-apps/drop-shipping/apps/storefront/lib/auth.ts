import NextAuth from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { AuthService } from '@/modules/auth/services/AuthService'

const authService = new AuthService()

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [
    Credentials({
      credentials: {
        email:    { label: 'Email',    type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) return null
        const user = await authService.validateCredentials(
          credentials.email as string,
          credentials.password as string
        )
        if (!user) return null
        return { id: user.id, email: user.email, name: user.name ?? undefined }
      },
    }),
  ],
  pages: {
    signIn: '/login',
  },
  callbacks: {
    jwt({ token, user }) {
      if (user) token.id = user.id
      return token
    },
    session({ session, token }) {
      if (session.user) session.user.id = token.id as string
      return session
    },
  },
  session: { strategy: 'jwt' },
})

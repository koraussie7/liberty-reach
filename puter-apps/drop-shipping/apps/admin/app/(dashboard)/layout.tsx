import { Sidebar } from '@/shared/components/layout/Sidebar'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col">
        <header className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h1 className="text-lg font-semibold text-gray-900">Admin Dashboard</h1>
          <div className="text-sm text-gray-500">ShopDrop Management</div>
        </header>
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  )
}

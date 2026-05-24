import Dashboard from '@/components/Dashboard';

export const metadata = {
  title: 'RTS Game Manager | Admin Dashboard',
  description: 'Manage civilizations, units, buildings and technologies for your RTS game.',
};

export default function Home() {
  return (
    <main>
      <Dashboard />
    </main>
  );
}

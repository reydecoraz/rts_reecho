import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Toaster } from "react-hot-toast";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "RTS Admin Console",
  description: "Real-time strategy game balance dashboard",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <body className={`${inter.className} bg-[#0f1115] antialiased`} suppressHydrationWarning>
        {children}
        <Toaster
          position="bottom-right"
          toastOptions={{
            style: {
              background: '#0f111a',
              color: '#e5e7eb',
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '1rem',
              fontSize: '12px',
              fontWeight: 700,
            },
            success: { iconTheme: { primary: '#10b981', secondary: '#0f111a' } },
            error: { iconTheme: { primary: '#ef4444', secondary: '#0f111a' } },
          }}
        />
      </body>
    </html>
  );
}

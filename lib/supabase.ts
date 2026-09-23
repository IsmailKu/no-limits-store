import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

export const isSupabaseConfigured = Boolean(url && anonKey);
export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(url!, anonKey!, { auth: { persistSession: true, autoRefreshToken: true } })
  : null;

const publicBase = ((import.meta.env.BASE_URL as string | undefined) || '/').replace(/\/$/, '');
export const sitePath = (path = '/') => `${publicBase}${path.startsWith('/') ? path : `/${path}`}` || '/';
export const assetUrl = (path: string) => /^https?:\/\//.test(path) ? path : sitePath(path);

export const storeWhatsApp = (import.meta.env.VITE_STORE_WHATSAPP as string | undefined) || '';
export const whatsappUrl = storeWhatsApp ? `https://wa.me/${storeWhatsApp.replace(/\D/g, '')}` : '';

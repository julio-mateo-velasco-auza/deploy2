// src/lib/privado.ts
export const PRIVATE_FLAG_KEY = 'inbolsa:qr:ok';
export const PRIVATE_EXPIRES_KEY = 'inbolsa:qr:exp';
export const PRIVATE_PRODUCTS_KEY = 'inbolsa:qr:products';

function hasCookie(name: string): boolean {
  try { return document.cookie.split(';').some(c => c.trim().startsWith(name + '=')); }
  catch { return false; }
}

export function enablePrivate(minutes = 120) {
  try {
    localStorage.setItem(PRIVATE_FLAG_KEY, '1');
    const exp = Date.now() + minutes * 60_000;
    localStorage.setItem(PRIVATE_EXPIRES_KEY, String(exp));
    // Cookie local para fallback UI
    document.cookie = `${PRIVATE_FLAG_KEY}=1; path=/; SameSite=Lax`;
  } catch {}
}

export function disablePrivate() {
  try {
    localStorage.removeItem(PRIVATE_FLAG_KEY);
    localStorage.removeItem(PRIVATE_EXPIRES_KEY);
    localStorage.removeItem(PRIVATE_PRODUCTS_KEY);
    document.cookie = `${PRIVATE_FLAG_KEY}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  } catch {}
}

export function isPrivateEnabled(): boolean {
  try {
    // 1) localStorage
    if (localStorage.getItem(PRIVATE_FLAG_KEY) === '1') {
      const exp = Number(localStorage.getItem(PRIVATE_EXPIRES_KEY) || '0');
      if (!exp || Date.now() <= exp) return true;
      disablePrivate(); // expirado
      return false;
    }
    // 2) cookies locales nuevas
    if (hasCookie(PRIVATE_FLAG_KEY)) return true;
    // 3) compat: cookies antiguas del back (si existen)
    if (hasCookie('qrauth') || hasCookie('inb_access')) return true;
    return false;
  } catch {
    // 4) último recurso, cookies
    return hasCookie(PRIVATE_FLAG_KEY) || hasCookie('qrauth') || hasCookie('inb_access');
  }
}

export function setGrantProducts(ids: string[]) {
  try {
    const arr = Array.isArray(ids) ? ids.filter(Boolean) : [];
    localStorage.setItem(PRIVATE_PRODUCTS_KEY, JSON.stringify(arr));
  } catch {}
}

export function getGrantProducts(): string[] {
  try {
    const raw = localStorage.getItem(PRIVATE_PRODUCTS_KEY);
    if (!raw) return [];
    const arr = JSON.parse(raw);
    return Array.isArray(arr) ? arr : [];
  } catch { return []; }
}

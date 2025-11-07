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
    console.log(`Habilitando modo privado por ${minutes} minutos`);
    localStorage.setItem(PRIVATE_FLAG_KEY, '1');
    const exp = Date.now() + minutes * 60_000;
    localStorage.setItem(PRIVATE_EXPIRES_KEY, String(exp));
    document.cookie = `${PRIVATE_FLAG_KEY}=1; path=/; SameSite=Lax; max-age=${minutes * 60}`;
    
    window.dispatchEvent(new CustomEvent('inbolsa:private:change', { 
      detail: { enabled: true } 
    }));
  } catch (e) {
    console.error("Error habilitando privado:", e);
  }
}

export function disablePrivate() {
  try {
    console.log("Deshabilitando modo privado");
    localStorage.removeItem(PRIVATE_FLAG_KEY);
    localStorage.removeItem(PRIVATE_EXPIRES_KEY);
    localStorage.removeItem(PRIVATE_PRODUCTS_KEY);
    
    document.cookie = `${PRIVATE_FLAG_KEY}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    document.cookie = `qrauth=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    document.cookie = `inb_access=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    document.cookie = `priv_mode=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    
    window.dispatchEvent(new CustomEvent('inbolsa:private:change', { 
      detail: { enabled: false } 
    }));
    
    if (location.pathname === '/privado' || location.pathname === '/productos') {
      location.href = '/';
    }
  } catch (e) {
    console.error("Error deshabilitando privado:", e);
  }
}

export function isPrivateEnabled(): boolean {
  try {
    if (localStorage.getItem(PRIVATE_FLAG_KEY) === '1') {
      const exp = Number(localStorage.getItem(PRIVATE_EXPIRES_KEY) || '0');
      if (!exp || Date.now() <= exp) {
        return true;
      }
      disablePrivate();
      return false;
    }
    if (hasCookie(PRIVATE_FLAG_KEY)) {
      return true;
    }
    if (hasCookie('qrauth') || hasCookie('inb_access') || hasCookie('priv_mode')) {
      return true;
    }
    return false;
  } catch (e) {
    console.error("Error verificando privado:", e);
    return hasCookie(PRIVATE_FLAG_KEY) || hasCookie('qrauth') || hasCookie('inb_access') || hasCookie('priv_mode');
  }
}

export function setGrantProducts(ids: string[]) {
  try {
    console.log("Guardando productos permitidos:", ids);
    const arr = Array.isArray(ids) ? ids.filter(Boolean) : [];
    localStorage.setItem(PRIVATE_PRODUCTS_KEY, JSON.stringify(arr));
    
    window.dispatchEvent(new CustomEvent('inbolsa:products:change', { 
      detail: { products: arr } 
    }));
  } catch (e) {
    console.error("Error guardando productos:", e);
  }
}

export function getGrantProducts(): string[] {
  try {
    const raw = localStorage.getItem(PRIVATE_PRODUCTS_KEY);
    if (raw) {
      const arr = JSON.parse(raw);
      return Array.isArray(arr) ? arr : [];
    }
    
    try {
      const params = new URLSearchParams(window.location.search);
      const pParam = params.get('p');
      if (pParam) {
        const products = pParam.split(',').filter(Boolean);
        setGrantProducts(products);
        return products;
      }
    } catch {}
    
    return [];
  } catch (e) { 
    console.error("Error obteniendo productos:", e);
    return []; 
  }
}

// Función para verificar si el acceso sigue siendo válido
export async function checkAccessValid(): Promise<boolean> {
  try {
    // Actualizado para iPage: uso de ruta relativa en lugar de URL absoluta
    const response = await fetch('/inbolsa-api/api/access/payload', {
      credentials: 'include'
    });
    
    if (!response.ok) {
      return false;
    }
    
    const data = await response.json();
    return data.ok === true;
  } catch (e) {
    console.error("Error verificando acceso:", e);
    return false;
  }
}

// Función para iniciar verificación periódica
export function startRevocationCheck() {
  setInterval(async () => {
    if (!isPrivateEnabled()) return;
    
    try {
      console.log("Verificando validez del acceso...");
      const isValid = await checkAccessValid();
      
      if (!isValid) {
        console.log("Acceso revocado o inválido, deshabilitando acceso");
        disablePrivate();
      }
    } catch (e) {
      console.error("Error en verificación de revocación:", e);
    }
  }, 30000); // Cada 30 segundos
}

// Iniciar verificación si estamos en el navegador
if (typeof window !== 'undefined') {
  setTimeout(() => {
    startRevocationCheck();
  }, 5000);
}


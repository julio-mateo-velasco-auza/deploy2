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
    // Cookie local para fallback UI
    document.cookie = `${PRIVATE_FLAG_KEY}=1; path=/; SameSite=Lax; max-age=${minutes * 60}`;
    
    // Emitir evento personalizado para sincronizar componentes
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
    // Eliminar de localStorage
    localStorage.removeItem(PRIVATE_FLAG_KEY);
    localStorage.removeItem(PRIVATE_EXPIRES_KEY);
    localStorage.removeItem(PRIVATE_PRODUCTS_KEY);
    
    // Eliminar cookies
    document.cookie = `${PRIVATE_FLAG_KEY}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    document.cookie = `qrauth=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    document.cookie = `inb_access=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    document.cookie = `priv_mode=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
    
    // Emitir evento personalizado para sincronizar componentes
    window.dispatchEvent(new CustomEvent('inbolsa:private:change', { 
      detail: { enabled: false } 
    }));
    
    // Si estamos en página privada, redirigir a home
    if (location.pathname === '/privado' || location.pathname === '/productos') {
      location.href = '/';
    }
  } catch (e) {
    console.error("Error deshabilitando privado:", e);
  }
}

export function isPrivateEnabled(): boolean {
  try {
    // 1) localStorage
    if (localStorage.getItem(PRIVATE_FLAG_KEY) === '1') {
      const exp = Number(localStorage.getItem(PRIVATE_EXPIRES_KEY) || '0');
      if (!exp || Date.now() <= exp) {
        return true;
      }
      disablePrivate(); // expirado
      return false;
    }
    // 2) cookies locales
    if (hasCookie(PRIVATE_FLAG_KEY)) {
      return true;
    }
    // 3) compat: cookies antiguas del back
    if (hasCookie('qrauth') || hasCookie('inb_access') || hasCookie('priv_mode')) {
      return true;
    }
    return false;
  } catch (e) {
    console.error("Error verificando privado:", e);
    // Último recurso, cookies
    return hasCookie(PRIVATE_FLAG_KEY) || hasCookie('qrauth') || hasCookie('inb_access') || hasCookie('priv_mode');
  }
}

export function setGrantProducts(ids: string[]) {
  try {
    console.log("Guardando productos permitidos:", ids);
    const arr = Array.isArray(ids) ? ids.filter(Boolean) : [];
    localStorage.setItem(PRIVATE_PRODUCTS_KEY, JSON.stringify(arr));
    
    // Evento para notificar cambios
    window.dispatchEvent(new CustomEvent('inbolsa:products:change', { 
      detail: { products: arr } 
    }));
  } catch (e) {
    console.error("Error guardando productos:", e);
  }
}

export function getGrantProducts(): string[] {
  try {
    // Primero intentar desde localStorage
    const raw = localStorage.getItem(PRIVATE_PRODUCTS_KEY);
    if (raw) {
      const arr = JSON.parse(raw);
      return Array.isArray(arr) ? arr : [];
    }
    
    // Si no hay en localStorage, intentar desde URL params
    try {
      const params = new URLSearchParams(window.location.search);
      const pParam = params.get('p');
      if (pParam) {
        const products = pParam.split(',').filter(Boolean);
        // Guardar para futuras referencias
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

// Función para verificar periódicamente si el token sigue siendo válido
export function startRevocationCheck() {
  // Verificar cada 30 segundos
  setInterval(() => {
    // Solo verificar si hay un token activo
    if (!isPrivateEnabled()) return;
    
    try {
      console.log("Verificando validez del token...");
      // Esto usa las cookies existentes automáticamente
      fetch('http://localhost/inbolsa-api/api/access/payload', {
        credentials: 'include'
      })
      .then(response => {
        if (!response.ok) {
          console.log("Token revocado o inválido, deshabilitando acceso");
          disablePrivate();
        }
      })
      .catch(err => {
        console.error("Error verificando token:", err);
      });
    } catch (e) {
      console.error("Error en verificación de revocación:", e);
    }
  }, 30000); // Cada 30 segundos
}

// Iniciar verificación si estamos en el navegador
if (typeof window !== 'undefined') {
  // Iniciar después de un pequeño retraso para no interferir con la carga inicial
  setTimeout(() => {
    startRevocationCheck();
  }, 5000);
}
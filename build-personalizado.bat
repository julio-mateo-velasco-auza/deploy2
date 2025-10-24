@echo off
REM build-personalizado.bat
REM Script para Windows que construye el proyecto y añade los archivos necesarios

echo === INBOLSA: SCRIPT DE CONSTRUCCION PERSONALIZADO (WINDOWS) ===
echo.

REM Paso 1: Ejecutar el build normal de Astro
echo Ejecutando npm run build...
call npm run build
if %ERRORLEVEL% neq 0 (
  echo Error en el build de Astro
  exit /b %ERRORLEVEL%
)

REM Paso 2: Crear carpeta lib en dist
echo Creando carpetas necesarias...
if not exist "dist\lib" mkdir dist\lib

REM Paso 3: Crear versiones JavaScript de los archivos TypeScript
echo Creando archivo api.js...

REM Contenido de api.js
(
  echo // lib/api.js - Version convertida de api.ts
  echo export const API_BASE = typeof import.meta !== 'undefined' ^&^& import.meta.env?.PUBLIC_API_BASE ^|^| '/inbolsaNeo/inbolsa-api/api';
  echo export const BACK_BASE = API_BASE.replace^(/\/api$/, ""^);
  echo.
  echo async function fetchJSON^(path, init = {}^) {
  echo   console.log^(`Fetching ${API_BASE}${path}`, init^);
  echo   
  echo   try {
  echo     const res = await fetch^(`${API_BASE}${path}`, {
  echo       credentials: "include",
  echo       headers: { 
  echo         "Content-Type": "application/json", 
  echo         ...^(init.headers ^|^| {}^) 
  echo       },
  echo       ...init,
  echo     }^);
  echo     
  echo     const ct = res.headers.get^("content-type"^) ^|^| "";
  echo     const isJSON = ct.includes^("application/json"^);
  echo     
  echo     let data;
  echo     let responseText = '';
  echo     
  echo     try {
  echo       responseText = await res.text^(^);
  echo       data = responseText ? JSON.parse^(responseText^) : {};
  echo     } catch ^(parseErr^) {
  echo       console.error^("Error parsing JSON response:", parseErr^);
  echo       console.error^("Response text:", responseText^);
  echo       throw new Error^(`Respuesta inválida: ${responseText.substring^(0, 100^)}`^);
  echo     }
  echo     
  echo     if ^(!res.ok^) {
  echo       throw new Error^(typeof data === "string" ? data : data?.error ^|^| "Request failed"^);
  echo     }
  echo     
  echo     return data;
  echo   } catch ^(err^) {
  echo     console.error^(`Error fetching ${path}:`, err^);
  echo     throw err;
  echo   }
  echo }
  echo.
  echo export const api = {
  echo   // Health
  echo   health: ^(^) =^> fetchJSON^("/health"^),
  echo.
  echo   // Auth
  echo   login: ^(email, password^) =^>
  echo     fetchJSON^("/auth/login", { method: "POST", body: JSON.stringify^({ email, password }^) }^),
  echo   logout: ^(^) =^> fetchJSON^("/auth/logout", { method: "POST" }^),
  echo   me: ^(^) =^> fetchJSON^("/auth/me"^),
  echo.
  echo   // QR
  echo   qrCreate: ^(input^) =^>
  echo     fetchJSON^("/qr/create", { 
  echo       method: "POST", 
  echo       body: JSON.stringify^(input^),
  echo       headers: {
  echo         "Content-Type": "application/json"
  echo       }
  echo     }^),
  echo   qrList: ^(^) =^> fetchJSON^("/qr/list"^),
  echo   qrRevoke: ^(code^) =^>
  echo     fetchJSON^("/qr/revoke", { method: "POST", body: JSON.stringify^({ code }^) }^),
  echo   qrValidate: ^(code^) =^> fetchJSON^(`/qr/validate?code=${encodeURIComponent^(code^)}`^),
  echo.
  echo   // Landing / acceso
  echo   accessPayload: ^(token^) =^>
  echo     fetchJSON^(`/access/payload${token ? `?token=${encodeURIComponent^(token^)}` : ""}`^),
  echo };
) > dist\lib\api.js

echo Creando archivo privado.js...

REM Contenido de privado.js
(
  echo // lib/privado.js - Version convertida de privado.ts
  echo export const PRIVATE_FLAG_KEY = 'inbolsa:qr:ok';
  echo export const PRIVATE_EXPIRES_KEY = 'inbolsa:qr:exp';
  echo export const PRIVATE_PRODUCTS_KEY = 'inbolsa:qr:products';
  echo.
  echo function hasCookie^(name^) {
  echo   try { return document.cookie.split^(';'^).some^(c =^> c.trim^(^).startsWith^(name + '='^)^); }
  echo   catch { return false; }
  echo }
  echo.
  echo export function enablePrivate^(minutes = 120^) {
  echo   try {
  echo     console.log^(`Habilitando modo privado por ${minutes} minutos`^);
  echo     localStorage.setItem^(PRIVATE_FLAG_KEY, '1'^);
  echo     const exp = Date.now^(^) + minutes * 60_000;
  echo     localStorage.setItem^(PRIVATE_EXPIRES_KEY, String^(exp^)^);
  echo     document.cookie = `${PRIVATE_FLAG_KEY}=1; path=/; SameSite=Lax; max-age=${minutes * 60}`;
  echo     
  echo     window.dispatchEvent^(new CustomEvent^('inbolsa:private:change', { 
  echo       detail: { enabled: true } 
  echo     }^)^);
  echo   } catch ^(e^) {
  echo     console.error^("Error habilitando privado:", e^);
  echo   }
  echo }
  echo.
  echo export function disablePrivate^(^) {
  echo   try {
  echo     console.log^("Deshabilitando modo privado"^);
  echo     localStorage.removeItem^(PRIVATE_FLAG_KEY^);
  echo     localStorage.removeItem^(PRIVATE_EXPIRES_KEY^);
  echo     localStorage.removeItem^(PRIVATE_PRODUCTS_KEY^);
  echo     
  echo     document.cookie = `${PRIVATE_FLAG_KEY}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  echo     document.cookie = `qrauth=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  echo     document.cookie = `inb_access=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  echo     document.cookie = `priv_mode=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  echo     
  echo     window.dispatchEvent^(new CustomEvent^('inbolsa:private:change', { 
  echo       detail: { enabled: false } 
  echo     }^)^);
  echo     
  echo     if ^(location.pathname === '/inbolsaNeo/privado' ^|^| location.pathname === '/inbolsaNeo/productos'^) {
  echo       location.href = '/inbolsaNeo/';
  echo     }
  echo   } catch ^(e^) {
  echo     console.error^("Error deshabilitando privado:", e^);
  echo   }
  echo }
  echo.
  echo export function isPrivateEnabled^(^) {
  echo   try {
  echo     if ^(localStorage.getItem^(PRIVATE_FLAG_KEY^) === '1'^) {
  echo       const exp = Number^(localStorage.getItem^(PRIVATE_EXPIRES_KEY^) ^|^| '0'^);
  echo       if ^(!exp ^|^| Date.now^(^) ^<= exp^) {
  echo         return true;
  echo       }
  echo       disablePrivate^(^);
  echo       return false;
  echo     }
  echo     if ^(hasCookie^(PRIVATE_FLAG_KEY^)^) {
  echo       return true;
  echo     }
  echo     if ^(hasCookie^('qrauth'^) ^|^| hasCookie^('inb_access'^) ^|^| hasCookie^('priv_mode'^)^) {
  echo       return true;
  echo     }
  echo     return false;
  echo   } catch ^(e^) {
  echo     console.error^("Error verificando privado:", e^);
  echo     return hasCookie^(PRIVATE_FLAG_KEY^) ^|^| hasCookie^('qrauth'^) ^|^| hasCookie^('inb_access'^) ^|^| hasCookie^('priv_mode'^);
  echo   }
  echo }
  echo.
  echo export function setGrantProducts^(ids^) {
  echo   try {
  echo     console.log^("Guardando productos permitidos:", ids^);
  echo     const arr = Array.isArray^(ids^) ? ids.filter^(Boolean^) : [];
  echo     localStorage.setItem^(PRIVATE_PRODUCTS_KEY, JSON.stringify^(arr^)^);
  echo     
  echo     window.dispatchEvent^(new CustomEvent^('inbolsa:products:change', { 
  echo       detail: { products: arr } 
  echo     }^)^);
  echo   } catch ^(e^) {
  echo     console.error^("Error guardando productos:", e^);
  echo   }
  echo }
  echo.
  echo export function getGrantProducts^(^) {
  echo   try {
  echo     const raw = localStorage.getItem^(PRIVATE_PRODUCTS_KEY^);
  echo     if ^(raw^) {
  echo       const arr = JSON.parse^(raw^);
  echo       return Array.isArray^(arr^) ? arr : [];
  echo     }
  echo     
  echo     try {
  echo       const params = new URLSearchParams^(window.location.search^);
  echo       const pParam = params.get^('p'^);
  echo       if ^(pParam^) {
  echo         const products = pParam.split^(','^).filter^(Boolean^);
  echo         setGrantProducts^(products^);
  echo         return products;
  echo       }
  echo     } catch {}
  echo     
  echo     return [];
  echo   } catch ^(e^) { 
  echo     console.error^("Error obteniendo productos:", e^);
  echo     return []; 
  echo   }
  echo }
  echo.
  echo // Función para verificar si el acceso sigue siendo válido
  echo export async function checkAccessValid^(^) {
  echo   try {
  echo     // Usamos la ruta fija para XAMPP/iPage
  echo     const API_BASE = '/inbolsaNeo/inbolsa-api/api';
  echo     
  echo     const response = await fetch^(`${API_BASE}/access/payload`, {
  echo       credentials: 'include'
  echo     }^);
  echo     
  echo     if ^(!response.ok^) {
  echo       return false;
  echo     }
  echo     
  echo     const data = await response.json^(^);
  echo     return data.ok === true;
  echo   } catch ^(e^) {
  echo     console.error^("Error verificando acceso:", e^);
  echo     return false;
  echo   }
  echo }
  echo.
  echo // Función para iniciar verificación periódica
  echo export function startRevocationCheck^(^) {
  echo   setInterval^(async ^(^) =^> {
  echo     if ^(!isPrivateEnabled^(^)^) return;
  echo     
  echo     try {
  echo       console.log^("Verificando validez del acceso..."^);
  echo       const isValid = await checkAccessValid^(^);
  echo       
  echo       if ^(!isValid^) {
  echo         console.log^("Acceso revocado o inválido, deshabilitando acceso"^);
  echo         disablePrivate^(^);
  echo       }
  echo     } catch ^(e^) {
  echo       console.error^("Error en verificación de revocación:", e^);
  echo     }
  echo   }, 30000^); // Cada 30 segundos
  echo }
  echo.
  echo // Iniciar verificación si estamos en el navegador
  echo if ^(typeof window !== 'undefined'^) {
  echo   setTimeout^(^(^) =^> {
  echo     startRevocationCheck^(^);
  echo   }, 5000^);
  echo }
) > dist\lib\privado.js

REM Paso 4: Verificar y crear carpeta para páginas de app
echo Verificando páginas de app...
if not exist "dist\app" (
  echo - Creando carpeta app...
  mkdir dist\app
  mkdir dist\app\panel
  mkdir dist\app\login
  
  REM Crear páginas HTML para redirecciones
  echo - Creando páginas HTML para app...
  
  REM Índice de app
  (
    echo ^<!DOCTYPE html^>
    echo ^<html lang="es"^>
    echo ^<head^>
    echo     ^<meta charset="UTF-8"^>
    echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
    echo     ^<title^>Inbolsa App^</title^>
    echo     ^<script^>
    echo         window.location.href = "/inbolsaNeo/app/login";
    echo     ^</script^>
    echo ^</head^>
    echo ^<body^>
    echo     ^<p^>Redireccionando a login...^</p^>
    echo ^</body^>
    echo ^</html^>
  ) > dist\app\index.html
  
  REM Login
  (
    echo ^<!DOCTYPE html^>
    echo ^<html lang="es"^>
    echo ^<head^>
    echo     ^<meta charset="UTF-8"^>
    echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
    echo     ^<meta http-equiv="refresh" content="0;url=/inbolsaNeo/app/login/"^>
    echo     ^<title^>Inbolsa App - Login^</title^>
    echo ^</head^>
    echo ^<body^>
    echo     ^<p^>Redireccionando...^</p^>
    echo ^</body^>
    echo ^</html^>
  ) > dist\app\login\index.html
  
  REM Panel
  (
    echo ^<!DOCTYPE html^>
    echo ^<html lang="es"^>
    echo ^<head^>
    echo     ^<meta charset="UTF-8"^>
    echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
    echo     ^<meta http-equiv="refresh" content="0;url=/inbolsaNeo/app/panel/"^>
    echo     ^<title^>Inbolsa App - Panel^</title^>
    echo ^</head^>
    echo ^<body^>
    echo     ^<p^>Redireccionando...^</p^>
    echo ^</body^>
    echo ^</html^>
  ) > dist\app\panel\index.html
) else (
  echo - Carpeta app ya existe
)

REM Paso 5: Copiar archivo .env si existe
if exist ".env" (
  echo Copiando archivo .env a dist...
  copy .env dist\.env
) else (
  echo Creando archivo .env básico en dist...
  (
    echo # Variables de entorno para Inbolsa en XAMPP
    echo PUBLIC_API_BASE=/inbolsaNeo/inbolsa-api/api
    echo PUBLIC_BASE=/inbolsaNeo/
    echo PUBLIC_PRODUCTION=false
    echo PUBLIC_SITE_URL=http://localhost/inbolsaNeo
    echo PUBLIC_ENABLE_LOGS=true
  ) > dist\.env
)

REM Paso 6: Verificación final
echo Verificando archivos críticos generados...
if exist "dist\lib\api.js" (
  if exist "dist\lib\privado.js" (
    echo [OK] Los archivos de lib/ se han creado correctamente.
  ) else (
    echo [ERROR] No se ha creado dist\lib\privado.js
  )
) else (
  echo [ERROR] No se ha creado dist\lib\api.js
)

REM Paso 7: Éxito
echo.
echo === CONSTRUCCION COMPLETADA ===
echo El proyecto está listo para ser copiado a XAMPP o iPage.
echo Recuerda revisar las rutas de importación si hay problemas.
echo.
pause
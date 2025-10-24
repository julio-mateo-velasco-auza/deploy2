@echo off
REM ============================================================
REM deploy-xampp.bat (simple, robusto, sin FOR ni expansión)
REM Despliegue de Inbolsa en XAMPP (Windows)
REM - Si no recibe la ruta de la API como parámetro, la pide por consola
REM ============================================================

REM === DESTINO EN XAMPP (ajusta si lo necesitas) ==============
set "XAMPP_PATH=C:\xampp\htdocs"
set "INBOLSA_DIR=%XAMPP_PATH%\inbolsaNeo"
set "API_DIR=%INBOLSA_DIR%\inbolsa-api"

echo === DESPLIEGUE DE INBOLSA PARA XAMPP ===
echo.

REM === 1) VALIDAR BUILD =======================================
echo Verificando build...
if not exist "dist" (
  echo [ERROR] No se encuentra la carpeta 'dist'. Ejecuta primero 'build-personalizado.bat'
  goto :fin
)

REM === 2) OBTENER RUTA DE LA API ORIGEN =======================
set "API_SRC="
if not "%~1"=="" (
  set "API_SRC=%~1"
) else (
  echo.
  echo Indica la ruta de la carpeta de la API (donde esta index.php):
  echo - Puedes escribir .\api  o  .\inbolsa-api  o  .   o una ruta absoluta
  set /p API_SRC="Ruta API: "
)

REM Normalizar comillas si el usuario las incluye
set "API_SRC=%API_SRC:"=%"

if "%API_SRC%"=="" (
  echo [ERROR] No se indico ruta de API.
  goto :fin
)

REM Si la ruta es relativa, convertirla a absoluta basada en el directorio actual
pushd "%CD%" >nul
pushd "%API_SRC%" 2>nul
if errorlevel 1 (
  echo [ERROR] La ruta indicada no existe: %API_SRC%
  goto :fin
)
set "API_SRC=%CD%"
popd >nul
popd >nul

if not exist "%API_SRC%\index.php" (
  echo [ERROR] No existe index.php en: %API_SRC%
  goto :fin
)

echo Origen de API: %API_SRC%
echo.

REM === 3) CREAR DIRECTORIOS EN XAMPP ==========================
echo Creando directorios de destino...
if not exist "%INBOLSA_DIR%" mkdir "%INBOLSA_DIR%"
if not exist "%API_DIR%" mkdir "%API_DIR%"

REM === 4) COPIAR FRONTEND =====================================
echo Copiando frontend a %INBOLSA_DIR% ...
xcopy "dist\*" "%INBOLSA_DIR%" /E /Y /Q >nul
if errorlevel 1 (
  echo [ADVERTENCIA] xcopy de frontend devolvio un codigo distinto de 0. Revisa permisos/rutas.
) else (
  echo [OK] Frontend copiado.
)

REM === 5) COPIAR API ==========================================
echo Copiando API desde %API_SRC% a %API_DIR% ...
xcopy "%API_SRC%\*.php" "%API_DIR%" /Y /Q >nul
if errorlevel 1 (
  echo [ADVERTENCIA] No se pudieron copiar algunos .php (o no existen). Verifica %API_SRC%.
) else (
  echo [OK] API copiada.
)

REM === 6) CREAR .HTACCESS =====================================
echo Creando .htaccess para la API...
(
  echo # .htaccess para la API de Inbolsa (acepta /api/*)
  echo RewriteEngine On
  echo RewriteBase /inbolsaNeo/inbolsa-api
  echo
  echo # Si la URI comienza con /inbolsaNeo/inbolsa-api/api -> enviar a index.php
  echo RewriteCond %%{REQUEST_URI} ^/inbolsaNeo/inbolsa-api/api(/.*)?$ [NC]
  echo RewriteRule ^ api [QSA,PT,L]
  echo
  echo # Si el archivo o directorio no existe, redirigir a index.php
  echo RewriteCond %%{REQUEST_FILENAME} !-f
  echo RewriteCond %%{REQUEST_FILENAME} !-d
  echo RewriteRule ^ index.php [QSA,L]
  echo
  echo # CORS solo para desarrollo local (opcional)
  echo ^<IfModule mod_headers.c^>
  echo   Header set Access-Control-Allow-Origin "http://localhost"
  echo   Header add Vary "Origin"
  echo   Header set Access-Control-Allow-Credentials "true"
  echo   Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
  echo   Header set Access-Control-Allow-Headers "Content-Type, Authorization"
  echo ^</IfModule^>
) > "%API_DIR%\.htaccess"
echo [OK] .htaccess creado.

REM === 7) VERIFY.PHP ==========================================
echo Creando verify.php...
(
  echo ^<?php
  echo header('Content-Type: text/plain');
  echo echo "INBOLSA VERIFICATION\n";
  echo echo "=====================\n";
  echo echo "PHP version: " . phpversion() . "\n";
  echo echo "Document root: " . $_SERVER['DOCUMENT_ROOT'] . "\n";
  echo echo "Base URL: " . dirname($_SERVER['SCRIPT_NAME']) . "\n";
  echo echo "Server software: " . $_SERVER['SERVER_SOFTWARE'] . "\n";
  echo echo "Current time: " . date('Y-m-d H:i:s') . "\n";
  echo echo "API directory exists: " . (is_dir(dirname($_SERVER['SCRIPT_FILENAME']) . '/inbolsa-api') ? 'Yes' : 'No') . "\n";
  echo echo "=====================\n";
  echo echo "You can safely delete this file after verification.\n";
  echo ^?>
) > "%INBOLSA_DIR%\verify.php"
echo [OK] verify.php creado.

REM === 8) SQL OPCIONAL ========================================
echo Creando inbolsa_db_setup.sql ...
(
  echo -- inbolsa_db_setup.sql
  echo CREATE DATABASE IF NOT EXISTS inbolsa_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  echo USE inbolsa_dev;
  echo
  echo CREATE TABLE IF NOT EXISTS admin_users (
  echo   id INT AUTO_INCREMENT PRIMARY KEY,
  echo   email VARCHAR(255) NOT NULL UNIQUE,
  echo   password_hash VARCHAR(255) NOT NULL,
  echo   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  echo   updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  echo ) ENGINE=InnoDB;
  echo
  echo -- password: 123456
  echo INSERT INTO admin_users (email, password_hash)
  echo VALUES ('admin@inbolsa.com','$$2y$$10$$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
  echo ON DUPLICATE KEY UPDATE email='admin@inbolsa.com';
  echo
  echo CREATE TABLE IF NOT EXISTS qr_codes (
  echo   id INT AUTO_INCREMENT PRIMARY KEY,
  echo   code VARCHAR(64) NOT NULL UNIQUE,
  echo   type VARCHAR(64) NOT NULL,
  echo   payload TEXT,
  echo   status ENUM('active','revoked') NOT NULL DEFAULT 'active',
  echo   usage_count INT NOT NULL DEFAULT 0,
  echo   usage_limit INT NULL,
  echo   expires_at DATETIME NULL,
  echo   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  echo   created_by INT NULL,
  echo   FOREIGN KEY (created_by) REFERENCES admin_users(id)
  echo ) ENGINE=InnoDB;
  echo
  echo CREATE TABLE IF NOT EXISTS qr_events (
  echo   id INT AUTO_INCREMENT PRIMARY KEY,
  echo   qr_code_id INT NOT NULL,
  echo   event_type ENUM('create','validate','open','revoke') NOT NULL,
  echo   ip_address VARCHAR(45) NULL,
  echo   user_agent TEXT NULL,
  echo   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  echo   FOREIGN KEY (qr_code_id) REFERENCES qr_codes(id)
  echo ) ENGINE=InnoDB;
) > "%INBOLSA_DIR%\inbolsa_db_setup.sql"
echo [OK] SQL creado.

REM === 9) RESUMEN =============================================
echo.
echo =============================================
echo ¡Despliegue en XAMPP completado!
echo Frontend : http://localhost/inbolsaNeo/
echo API      : http://localhost/inbolsaNeo/inbolsa-api/api/health
echo Verifica : http://localhost/inbolsaNeo/verify.php
echo =============================================
echo.
echo Si ves 404 en /api/*, activa mod_rewrite y AllowOverride All en Apache.
echo.

:fin
pause

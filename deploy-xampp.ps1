param(
  [string]$ApiSrc
)

# ===== DESTINO EN XAMPP (ajusta si hace falta) =====
$XamppPath  = 'C:\xampp\htdocs'
$InbolsaDir = Join-Path $XamppPath 'inbolsaNeo'
$ApiDir     = Join-Path $InbolsaDir 'inbolsa-api'

Write-Host "=== DESPLIEGUE DE INBOLSA PARA XAMPP ===`n"

# 1) Validar build
if (-not (Test-Path -LiteralPath 'dist')) {
  Write-Host "[ERROR] No existe la carpeta 'dist'. Ejecuta primero build-personalizado.bat" -ForegroundColor Red
  exit 1
}

# 2) Resolver ruta de API origen
if (-not $ApiSrc) {
  Write-Host "Indica la ruta de la API (carpeta que contiene index.php). Ej: .\api  o  .\inbolsa-api  o  ."
  $ApiSrc = Read-Host "Ruta API"
}
$ApiSrc = $ApiSrc.Trim('"')

# Normalizar a absoluta
try {
  $ApiFull = (Resolve-Path $ApiSrc).Path
} catch {
  Write-Host "[ERROR] La ruta indicada no existe: $ApiSrc" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $ApiFull 'index.php'))) {
  Write-Host "[ERROR] No existe index.php en: $ApiFull" -ForegroundColor Red
  exit 1
}
Write-Host "Origen de API: $ApiFull`n"

# 3) Crear directorios destino
New-Item -ItemType Directory -Force -Path $InbolsaDir | Out-Null
New-Item -ItemType Directory -Force -Path $ApiDir     | Out-Null

# 4) Copiar frontend
Write-Host "Copiando frontend a $InbolsaDir ..."
robocopy "dist" "$InbolsaDir" /E /NFL /NDL /NJH /NJS /NP | Out-Null
Write-Host "[OK] Frontend copiado.`n"

# 5) Copiar API (.php)
Write-Host "Copiando API desde $ApiFull a $ApiDir ..."
robocopy "$ApiFull" "$ApiDir" *.php /NFL /NDL /NJH /NJS /NP | Out-Null
Write-Host "[OK] API copiada.`n"

# 6) .htaccess
$htaccess = @"
# .htaccess para la API de Inbolsa (acepta /api/*)
RewriteEngine On
RewriteBase /inbolsa-api

# Si la URI comienza con /inbolsa-api/api -> enviar a index.php
RewriteCond %{REQUEST_URI} ^/inbolsa-api/api(/.*)?$ [NC]
RewriteRule ^ api [QSA,PT,L]

# Si el archivo o directorio no existe, redirigir a index.php
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.php [QSA,L]

# CORS solo para desarrollo local (opcional)
<IfModule mod_headers.c>
  Header set Access-Control-Allow-Origin "http://localhost"
  Header add Vary "Origin"
  Header set Access-Control-Allow-Credentials "true"
  Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
  Header set Access-Control-Allow-Headers "Content-Type, Authorization"
</IfModule>
"@
Set-Content -Encoding UTF8 -Path (Join-Path $ApiDir ".htaccess") -Value $htaccess
Write-Host "[OK] .htaccess creado.`n"

# 7) verify.php
$verify = @"
<?php
header('Content-Type: text/plain');
echo "INBOLSA VERIFICATION\n";
echo "=====================\n";
echo "PHP version: " . phpversion() . "\n";
echo "Document root: " . \$_SERVER['DOCUMENT_ROOT'] . "\n";
echo "Base URL: " . dirname(\$_SERVER['SCRIPT_NAME']) . "\n";
echo "Server software: " . \$_SERVER['SERVER_SOFTWARE'] . "\n";
echo "Current time: " . date('Y-m-d H:i:s') . "\n";
echo "API directory exists: " . (is_dir(dirname(\$_SERVER['SCRIPT_FILENAME']) . '/inbolsa-api') ? 'Yes' : 'No') . "\n";
echo "=====================\n";
echo "You can safely delete this file after verification.\n";
"@
Set-Content -Encoding UTF8 -Path (Join-Path $InbolsaDir "verify.php") -Value $verify
Write-Host "[OK] verify.php creado.`n"

# 8) SQL opcional
$sql = @"
-- inbolsa_db_setup.sql
CREATE DATABASE IF NOT EXISTS inbolsa_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE inbolsa_dev;

CREATE TABLE IF NOT EXISTS admin_users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- password: 123456
INSERT INTO admin_users (email, password_hash)
VALUES ('admin@inbolsa.com', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
ON DUPLICATE KEY UPDATE email='admin@inbolsa.com';

CREATE TABLE IF NOT EXISTS qr_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) NOT NULL UNIQUE,
  type VARCHAR(64) NOT NULL,
  payload TEXT,
  status ENUM('active','revoked') NOT NULL DEFAULT 'active',
  usage_count INT NOT NULL DEFAULT 0,
  usage_limit INT NULL,
  expires_at DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by INT NULL,
  FOREIGN KEY (created_by) REFERENCES admin_users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS qr_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  qr_code_id INT NOT NULL,
  event_type ENUM('create','validate','open','revoke') NOT NULL,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (qr_code_id) REFERENCES qr_codes(id)
) ENGINE=InnoDB;
"@
Set-Content -Encoding UTF8 -Path (Join-Path $InbolsaDir "inbolsa_db_setup.sql") -Value $sql
Write-Host "[OK] SQL creado.`n"

# 9) Resumen
Write-Host "============================================="
Write-Host "¡Despliegue en XAMPP completado!"
Write-Host "Frontend : http://localhost/"
Write-Host "API      : http://localhost/inbolsa-api/api/health"
Write-Host "Verifica : http://localhost/verify.php"
Write-Host "============================================="


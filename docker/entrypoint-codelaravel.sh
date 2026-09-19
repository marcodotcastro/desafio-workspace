#!/bin/bash
set -e

echo "=== [Volt Sovereign Abstraction] Inicializando CodeLaravel (Laravel 11 / PHP 8.2) ==="

cd /app

mkdir -p /app/storage/framework/views \
         /app/storage/framework/sessions \
         /app/storage/framework/cache \
         /app/storage/logs \
         /app/bootstrap/cache \
         /data

chmod -R 777 /app/storage /app/bootstrap/cache /data

if [ ! -f /data/database.sqlite ]; then
  echo "Criando banco SQLite em /data/database.sqlite..."
  touch /data/database.sqlite
  chmod 666 /data/database.sqlite
fi

echo "Executando migrações do Laravel no banco SQLite isolado..."
php artisan migrate --force

echo "Executando seed de usuários do Laravel..."
php artisan db:seed --force

echo "Credenciais CodeLaravel ativas: test@example.com | senha: password"

echo "Iniciando servidor Artisan na porta 3003..."
exec php artisan serve --host=0.0.0.0 --port=3003

#!/bin/bash
set -e

echo "=== [Volt Sovereign Abstraction] Inicializando Compras (Rails 6.1) ==="

cd /app

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USERNAME:-postgres}"
DB_PASS="${DB_PASSWORD:-postgres}"
DB_NAME="${DB_NAME:-compras_devme_development}"
export PGPASSWORD="$DB_PASS"

echo "Aguardando PostgreSQL em ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; do
  sleep 1
done
echo "PostgreSQL pronto para conexões."

# Garante banco de dados
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"

# Verifica se o schema inicial precisa ser carregado
TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")
if [ "${TABLE_COUNT:-0}" -lt 10 ]; then
  echo "Carregando dump de schema inicial (contabil.sql)..."
  if [ -f /app/db/dumps/contabil.sql.zip ]; then
    unzip -p /app/db/dumps/contabil.sql.zip | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1 || true
  fi
fi

# Ajustes de compatibilidade e multi-tenancy
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
  ALTER TABLE compras_judgment_forms ADD COLUMN IF NOT EXISTS enabled boolean DEFAULT true;
  ALTER TABLE compras_customers ADD COLUMN IF NOT EXISTS secret_token varchar(255);
  CREATE OR REPLACE VIEW unico_customers AS SELECT * FROM compras_customers;
  UPDATE compras_customers SET database = 'postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}';
" >/dev/null 2>&1 || true

# Provisiona clientes para domínios padrão
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
  INSERT INTO compras_customers (name, domain, database, secret_token, created_at, updated_at) 
  SELECT 'Desenvolvimento Volt', 'localhost', 'postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}', 'token123', NOW(), NOW()
  WHERE NOT EXISTS (SELECT 1 FROM compras_customers WHERE domain = 'localhost');

  INSERT INTO compras_customers (name, domain, database, secret_token, created_at, updated_at) 
  SELECT 'Desenvolvimento Volt 127', '127.0.0.1', 'postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}', 'token124', NOW(), NOW()
  WHERE NOT EXISTS (SELECT 1 FROM compras_customers WHERE domain = '127.0.0.1');

  INSERT INTO compras_customers (name, domain, database, secret_token, created_at, updated_at) 
  SELECT 'Desenvolvimento Volt 0000', '0.0.0.0', 'postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}', 'token125', NOW(), NOW()
  WHERE NOT EXISTS (SELECT 1 FROM compras_customers WHERE domain = '0.0.0.0');
" >/dev/null 2>&1 || true

# Garante usuários
bundle exec rails runner '
begin
  admin = User.find_or_initialize_by(login: "admin")
  admin.name = "Administrador Volt"
  admin.email = "admin@compras.local"
  admin.password = "senha123"
  admin.password_confirmation = "senha123"
  admin.administrator = true
  admin.skip_confirmation! if admin.respond_to?(:skip_confirmation!)
  admin.save(validate: false)

  claudemir = User.find_or_initialize_by(login: "claudemir")
  claudemir.name = "Compras e Licitações"
  claudemir.email = "claudemir@nobesistemas.com.br"
  claudemir.password = "claudemir"
  claudemir.password_confirmation = "claudemir"
  claudemir.administrator = true
  claudemir.skip_confirmation! if claudemir.respond_to?(:skip_confirmation!)
  claudemir.save(validate: false)

  puts "Usuários Compras provisionados: admin / senha123 e claudemir / claudemir"
rescue => e
  puts "Aviso ao configurar usuários: #{e.message}"
end
' || true

# Remove PID antigo e cria diretórios
mkdir -p /app/tmp/pids /app/tmp/cache /app/tmp/sockets /app/log
rm -f /app/tmp/pids/server.pid

echo "Iniciando servidor Rails na porta 3001..."
exec bundle exec rails server -b 0.0.0.0 -p 3001 -e development

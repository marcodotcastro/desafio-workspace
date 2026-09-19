# Orpheus Space Volter — Workspace Soberano Multi-Projetos (Demanda 1010)

Orquestração soberana de 3 ecossistemas tecnológicos completamente heterogêneos sob a **Camada de Abstração do Volt**, operando simultaneamente sem alterar uma única linha de código nos repositórios originais.

---

## 1. Visão Geral & Arquitetura

O desafio da Demanda 1010 consiste em subir e integrar 3 projetos distintos através de uma camada de orquestração desacoplada:

1. **Compras:** Rails 6.1 / Ruby 3.2.2 / Puma / PostgreSQL 15 (Porta `3001`)
2. **AnythingLLM:** Node 18 / Express + React / Base Vetorial & Armazenamento Isolado (Porta `3002`)
3. **CodeLaravel:** Laravel 11 / PHP 8.2 / SQLite Isolado (Porta `3003`)
4. **Volt Sovereign Hub:** Painel de Controle oficial unificado seguindo a Identidade Visual Soberana do Volt (Porta `8080`)

### Regra de Ouro Inegociável (Preservada a 100%)
Nenhum arquivo, configuração ou diretório nos repositórios originais foi modificado.
Toda inteligência de runtime, monkey patches de migrações legadas, roteamento de banco de dados, geração de chaves e injeção de credenciais residem exclusivamente na camada de abstração deste workspace (`desafio-workspace`).

Evidência de integridade:
```bash
git -C /home/marcodotcastro/Projects/volt-organization/compras status --short       # Limpo
git -C /home/marcodotcastro/Projects/volt-organization/anything-llm status --short  # Limpo
git -C /home/marcodotcastro/Projects/volt-organization/CodeLaravel status --short   # Limpo
```

---

## 2. Mapa de Portas e URLs de Acesso

| Serviço | URL Local | Protocolo | Status Probe |
|---|---|---|---|
| **Volt Sovereign Hub** | `http://localhost:8080` | HTTP/1.1 | `200 OK` |
| **Compras** (Rails 6.1) | `http://localhost:3001` | HTTP/1.1 | `302 Found` / `200 OK` (em `/users/sign_in`) |
| **AnythingLLM** (AI Platform) | `http://localhost:3002` | HTTP/1.1 | `200 OK` |
| **CodeLaravel** (Laravel 11) | `http://localhost:3003` | HTTP/1.1 | `200 OK` |

---

## 3. Credenciais de Acesso Consolidadas

### 1. Compras (Rails 6.1)
- **URL Direta:** `http://localhost:3001` (redireciona para login em `http://localhost:3001/users/sign_in`)
- **Credencial 1 (Admin Volt):**
  - **Login:** `admin`
  - **Senha:** `senha123`
  - **Email:** `admin@compras.local`
- **Credencial 2 (Seed Original):**
  - **Login:** `claudemir`
  - **Senha:** `claudemir`
  - **Email:** `claudemir@nobesistemas.com.br`
- *Nota:* O sistema utiliza o Devise autenticando pelo campo `login`. Ambos os usuários possuem privilégios de administrador ativos.

### 2. AnythingLLM
- **URL Direta:** `http://localhost:3002`
- **Modo de Operação:** Single-User Soberano.
- **Autenticação:** Acesso direto instantâneo sem necessidade de login.
- **Armazenamento:** Base vetorial e histórico persistidos de forma segura no volume isolado `anythingllm_storage`.

### 3. CodeLaravel (Laravel 11)
- **URL Direta:** `http://localhost:3003`
- **Usuário Teste (DatabaseSeeder):**
  - **Email:** `test@example.com`
  - **Senha:** `password`
- **Endpoint:** Retorna view de boas-vindas "Hello World!" ou JSON via header `Accept: application/json`.
- **Armazenamento:** Banco SQLite localizado em volume dedicado (`/data/database.sqlite`), mantendo o repositório 100% livre de escritas.

---

## 4. Desafios de Engenharia & Soluções da Abstração

### A. Compras (Rails 6.1 / Postgres)
1. **Migrações Legadas (Rails 4 -> Rails 6.1):** As migrações do engine `unico` herdavam diretamente de `ActiveRecord::Migration` sem especificar versão `[4.2]`, disparando exceção no Rails 6.1. Foi injetado o patch `docker/legacy_migration_compatibility.rb` para tolerar herança direta e idempotência de índices.
2. **Multi-Tenancy por Domínio:** O Compras utiliza resolução de schema e conexão por domínio (`Customer.find_by_domain!`). O entrypoint auto-provisiona os domínios `localhost`, `127.0.0.1` e `0.0.0.0` mapeando para a base PostgreSQL do contêiner.
3. **Dump Inicial (`contabil.sql.zip`):** O entrypoint detecta banco virgem e restaura automaticamente o dump original de tabelas do sistema sem intervenção manual.

### B. CodeLaravel (Laravel 11 / PHP 8.2)
1. **Faker em Modo Dev:** A migração padrão com `User::factory()` requeria o pacote `fakerphp/faker` (do `require-dev`). O Dockerfile multi-stage instala o conjunto completo de dependências do `composer.lock`.
2. **SQLite Isolado:** Banco alocado em `/data/database.sqlite` fora da árvore de código do repositório.

### C. AnythingLLM (Node 18 / React)
- Execução direta da imagem oficial `mintplexlabs/anythingllm:latest`, eliminando tempo de build de bindings nativos pesados (como `node-llama-cpp` e `chromium`), mapeando a porta interna `3001` para a porta do host `3002`.

### D. Painel Hub Volt Soberano
- Desenvolvido em Nginx Alpine servindo a Identidade Visual Oficial do Volt (`Dark Deep Obsidian #080c12`, `Electric Cyan #38bdf8`, `Emerald Glow #10b981`), sem emojis, com badges dinâmicos de status e links funcionais para os 3 projetos.

---

## 5. Instruções de Operação

### Subir o workspace:
```bash
docker compose up -d
```

### Verificar status dos containers:
```bash
docker compose ps
```

### Inspecionar logs:
```bash
docker compose logs -f compras
docker compose logs -f anything-llm
docker compose logs -f codelaravel
docker compose logs -f hub
```

### Parar o workspace:
```bash
docker compose down
```

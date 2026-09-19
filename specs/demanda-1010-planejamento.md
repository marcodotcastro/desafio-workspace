# DEMANDA 1010 — PLANEJAMENTO DE ARQUITETURA & ORQUESTRAÇÃO SOBERANA

**Autor:** Volt Builder Specialist  
**Demandante:** Marco Castro  
**Data:** 19 de Setembro de 2026  
**Status:** Em Execução / Aprovado para Calibração  
**Workspace:** `/home/marcodotcastro/Work/desafio-workspace`

---

## 1. VISÃO GERAL E OBJETIVO

Orquestrar de forma unificada e soberana três projetos de naturezas tecnológicas completamente distintas em um único workspace sob a égide do **Volt**, garantindo a operação simultânea de todos os serviços através de uma camada de abstração limpa em Docker Compose, sem alterar nenhuma linha de código ou configuração nos repositórios de origem.

### Os Três Projetos Alvo:
1. **Compras:** Rails 6.1 / Ruby 3.2.2 / Puma / PostgreSQL 15 (`/home/marcodotcastro/Projects/volt-organization/compras`)
2. **AnythingLLM:** Node >= 18 / Express + React / SQLite & Vector Store (`/home/marcodotcastro/Projects/volt-organization/anything-llm`)
3. **CodeLaravel:** Laravel 11 / PHP 8.2 / SQLite (`/home/marcodotcastro/Projects/volt-organization/CodeLaravel`)
4. **Volt Sovereign Hub:** Painel de Controle unificado com Identidade Visual Soberana na porta 8080.

---

## 2. REGRAS DE OURO & RESTRIÇÕES ESTRITAS

1. **Inviolabilidade do Código-Fonte Original:**
   - Nenhuma linha de código, arquivo de configuração, `.env` ou arquivo de banco de dados nos diretórios originais pode ser modificado.
   - Os diretórios de código-fonte são montados nos contêineres em modo somente leitura (`:ro`).
   - Toda escrita em tempo de execução (banco de dados, arquivos de log, caches, sessões e uploads) é redirecionada para volumes isolados do Docker.
   - Validação contínua via `git -C <repo> status --short` (deve retornar rigorosamente vazio).

2. **Isolamento de Estado:**
   - O estado do PostgreSQL do `Compras` fica confinado no volume gerenciado `postgres_data`.
   - O banco SQLite do `CodeLaravel` é inicializado em volume isolado (`codelaravel_data`).
   - O armazenamento vetorial e documentos do `AnythingLLM` residem em volume dedicado (`anythingllm_storage`).

3. **Portas e Roteamento Determinístico:**
   - **8080:** Volt Sovereign Hub (Painel de Controle)
   - **3001:** Compras (Rails 6.1)
   - **3002:** AnythingLLM (AI Platform)
   - **3003:** CodeLaravel (Laravel 11)
   - **5432:** PostgreSQL 15 (Isolado na rede interna do workspace)

---

## 3. MATRIZ DE DESAFIOS TÉCNICOS & SOLUÇÕES DA CAMADA DE ABSTRAÇÃO

| Componente | Desafio Técnico Identificado | Solução Aplicada na Abstração Volt |
|---|---|---|
| **Compras (Rails 6.1)** | - Incompatibilidade de host no `config/database.yml` original (`localhost`).<br>- Dependência de gems locais no diretório `vendor/`.<br>- Necessidade de escrita em `tmp/pids/` e `log/`.<br>- Usuário admin para teste imediato. | - Montagem de `docker/compras-database.yml` dinâmico sobrepondo o original em `:ro`.<br>- Cópia de `vendor/` para o build de imagem isolado.<br>- Volumes nomeados dedicados para `/app/tmp` e `/app/log`.<br>- Entrypoint automatizado que aguarda PostgreSQL, roda migrations e injeta via Rails Runner o administrador Volt (`admin` / `senha123`), além de preservar os seeds originais (`claudemir` / `claudemir`). |
| **CodeLaravel (Laravel 11)** | - Ausência de pasta `vendor/` no repositório original.<br>- Necessidade de chave `APP_KEY` e banco SQLite sem alterar o repo.<br>- Escrita em `storage/` e `bootstrap/cache`. | - Dockerfile multi-stage com Composer instalando dependências em cache interno de build.<br>- Entrypoint provisiona dependências para volume isolado `/workspace/vendor`.<br>- Banco SQLite alocado em `/data/database.sqlite` (volume externo ao repositório).<br>- Variáveis de ambiente injetadas via Docker Compose.<br>- Seed automatizado do usuário `test@example.com` (`password`). |
| **AnythingLLM** | - Complexidade de compilação local de bindings nativos (node-llama-cpp, collector, chromium).<br>- Autenticação e persistência de dados. | - Utilização da imagem soberana oficial `mintplexlabs/anythingllm:latest`.<br>- Mapeamento de porta `3002:3001`.<br>- Persistência em volume dedicado `anythingllm_storage`.<br>- Modo single-user aberto para onboarding imediato. |
| **Hub Volt** | - Exigência de conformidade estrita com o Design System Oficial Volt (Deep Obsidian, Electric Cyan, Emerald Glow).<br>- Monitoramento e acesso unificado aos 3 serviços. | - Nginx Alpine servindo `index.html` compilado a partir do `hub-template.html` oficial.<br>- Verificação dinâmica em tempo real do status dos serviços via JavaScript assíncrono no browser.<br>- Links diretos e credenciais visíveis no painel. |

---

## 4. CREDENCIAIS CONSOLIDADAS DE ACESSO

### 1. Compras (Rails 6.1)
- **URL:** `http://localhost:3001`
- **Login 1 (Volt Admin):** `admin` | **Senha:** `senha123`
- **Login 2 (Seed Original):** `claudemir` | **Senha:** `claudemir`
- **Nota:** O Devise utiliza o campo `login` como chave de autenticação primária.

### 2. AnythingLLM
- **URL:** `http://localhost:3002`
- **Modo:** Single-User (Acesso Soberano Direto sem senha na primeira abertura)
- **Onboarding:** Permite configuração assistida imediata de modelo local ou API key.

### 3. CodeLaravel (Laravel 11)
- **URL:** `http://localhost:3003`
- **Usuário Seed:** `test@example.com`
- **Senha:** `password`
- **Endpoint Principal:** Retorna view de boas-vindas "Hello World!" ou JSON via header `Accept: application/json`.

---

## 5. PLANO DE EXECUÇÃO EM FASES

1. **Fase 1 — Preparação dos Arquivos de Abstração:**
   - `docker/Dockerfile.compras` & `docker/entrypoint-compras.sh` & `docker/compras-database.yml`
   - `docker/Dockerfile.codelaravel` & `docker/entrypoint-codelaravel.sh`
   - `docker/hub/index.html` & `docker/hub/nginx.conf` & `docker/Dockerfile.hub`
   - `docker-compose.yml` consolidado.

2. **Fase 2 — Build e Orquestração (`docker compose up -d --build`):**
   - Subida coordenada dos 5 serviços (`postgres`, `compras`, `anything-llm`, `codelaravel`, `hub`).
   - Monitoramento de logs e espera ativa da saúde dos containers.

3. **Fase 3 — Verificação e Probes HTTP:**
   - Teste de conectividade HTTP (códigos 200/302) em todas as portas (`8080`, `3001`, `3002`, `3003`).
   - Inspeção de integridade nos repositórios de origem via `git status --short`.

4. **Fase 4 — Git, GitHub & Pull Request:**
   - Criação do repositório remoto `marcodotcastro/desafio-workspace`.
   - Criação da branch `feat/volt-workspace-orchestration-demanda-1010`.
   - Abertura de Pull Request via `gh pr create`.

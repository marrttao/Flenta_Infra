# Flenta_Infra

Інфраструктура проєкту Flenta: схема БД (Supabase/PostgreSQL), Docker Compose, конфіг.

## Структура
- `db/migrations/` SQL-міграції (застосовуються по порядку: 001, 002, ...)
- `docker-compose.yml` запуск backend і frontend
- `.env.example` шаблон змінних середовища

## Швидкий старт
1. `git clone`
2. `cp .env.example .env` і вписати пароль від Supabase
3. Локальна БД для тестів: `docker compose --profile local up -d db-local` (порт 5433)
4. Повний запуск backend/frontend: коли будуть готові Dockerfile

## База даних
БД хоститься в Supabase. Підключення через **Session pooler** (IPv4).

### Як застосувати міграцію
1. Supabase -> SQL Editor -> New query
2. Ввміст файлу з `db/migrations/`
3. Run

### Правила
- Міграції застосовуються по порядку: 001, 002, 003
- Застосований файл не редагуємо, зміни йдуть новим файлом (`003_...`).

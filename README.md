# Flenta_Infra

Інфраструктура проєкту Flenta: Docker Compose для всього проєкту (база, міграції, backend, сайт, тести), шаблон змінних середовища, початкова схема БД (креслення).

## Що потрібно
- Docker Desktop запущений
- Три репозиторії
  ```
  Flenta_Infra/
  Flenta_Backend/
  Flenta_Desktop/ 
  ```

## Швидкий старт
1. `cp .env.example .env`
2. Запуск усього проєкту (завжди з **обома** профілями):
   ```
   docker compose --profile local --profile app up -d --build
   docker compose --profile local --profile app ps -a
   ```
   Очікувано: `db-local` і `frontend` у статусі `healthy`, `migrate` і `db-seed` у статусі `Exited (0)`, `backend` і `adminer` у статусі `Up`.
3. Зупинити: `docker compose --profile local --profile app stop`
4. Скинути все до чистого стану (разом з даними бази): `docker compose --profile local --profile app down -v`

| Сервіс | Адреса |
|--------|--------|
| Веб-застосунок | http://localhost:3000 |
| Backend (health check) | http://localhost:5080/health |
| Adminer (перегляд БД) | http://localhost:8080 (System: PostgreSQL, Server: `db-local`, user `flenta`, password `*********`, db `flenta`) |
| PostgreSQL | `localhost:5433` |

## Тести backend однією командою
```
docker compose --profile test run --rm tests
```
Піднімає базу, чекає на її готовність і запускає `dotnet test` (у тому числі інтеграційні тести з PostgreSQL). У підсумку має бути `Skipped: 0`.
Лише частина тестів: `docker compose --profile test run --rm tests dotnet test --filter "FullyQualifiedName~Iban"`.
Зупинити базу після тестів: `docker compose --profile test down`.

## Сервіси в docker-compose.yml
| Сервіс | Призначення |
|--------|-------------|
| `db-local` | локальний PostgreSQL з постійним сховищем і health check |
| `migrate` | одноразово застосовує міграції EF Core (схема `banking`) перед стартом backend |
| `backend` | ASP.NET Core API, порт 5080 |
| `frontend` | веб-застосунок (nginx), порт 3000 |
| `adminer` | веб-інтерфейс до бази |
| `tests` | запуск тестів backend |
| `db-seed` | тестові дані для початкової схеми з `db/migrations` (необов'язково) |

## Змінні середовища (.env)
- `BANKING_ENABLED`, `BANKING_CONNECTION_STRING`, `BANKING_CARD_ENCRYPTION_KEY` для банківської частини backend (за замовчуванням вимкнено).
- `DIDIT_*` і `SUPABASE_*` для KYC та авторизації. Без ключів ці інтеграції вимкнені, контейнер усе одно стартує.
- `VITE_API_BASE_URL`, `VITE_CURRENCY_SPREAD` вшиваються в сайт під час збірки (після зміни потрібна пересборка `--build`).
- `LOCAL_DB_*` параметри локальної бази (можна не змінювати).

## База даних
- **Схему backend веде EF Core** (міграції в `Flenta_Backend/src/Flenta.Infrastructure/Persistence/Banking/Migrations`). Сервіс `migrate` застосовує їх автоматично.
- `db/migrations/` і `db/seed/` це початкове креслення таблиць за ТЗ (схема `public`) і тестові дані до нього. Backend їх не використовує, у Adminer вони видні поруч зі схемою `banking`.
- Основна спільна БД хоститься в Supabase.

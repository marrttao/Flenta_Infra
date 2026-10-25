# Flenta Infra

Репозиторій відповідає за запуск PostgreSQL та параметри середовища.
AppDbContext, конфігурації сутностей, EF-міграції і snapshot знаходяться у
[Flenta_Backend](https://github.com/marrttao/Flenta_Backend/tree/MarisPersistence).
C#-моделі й копії EF-міграцій у цей репозиторій не додаються.

## Відповідальність репозиторіїв

| Репозиторій | Що зберігає |
| --- | --- |
| Flenta_Backend | Domain entities, Infrastructure/Persistence/AppDbContext, Configurations, Migrations, EF tooling |
| Flenta_Infra | Docker Compose, локальний Postgres, шаблон параметрів підключення |
| Flenta_Desktop | HTML-форми та клієнт API; без доступу до БД і її паролів |

## Локальна база

У корені Flenta_Infra у PowerShell:

```powershell
if (!(Test-Path .env)) { Copy-Item .env.example .env }
# У .env задайте LOCAL_DB_PASSWORD та узгодьте параметри підключення Backend.
docker compose --profile local up -d db-local
docker compose --profile local ps
```

База доступна лише на `127.0.0.1:5433` (порт змінюється через LOCAL_DB_PORT).
Пароль задається у .env; файл не комітиться. Усередині Docker-мережі адреса
`db-local:5432`. Збережений volume pgdata_local не очищається під час оновлень.
На новій порожній БД Compose не створює таблиці застосунку автоматично.

## EF Core

Сусідній checkout Backend повинен містити AppDbContext і EF tooling
(гілка MarisPersistence або інтегрована з нею гілка):

```powershell
Set-Location ../Flenta_Backend
if (!(Test-Path .env.local)) { Copy-Item .env.example .env.local }
# Заповніть ConnectionStrings__AppDb: локальний host/port/user/password з Infra.
./scripts/ef.ps1 list
./scripts/ef.ps1 update
./scripts/ef.ps1 check
```

Зміна схеми: змініть сутність/конфігурацію у Backend, створіть там міграцію
`./scripts/ef.ps1 add НазваМіграціїЛатиницею`, перегляньте Up/Down і тести.
Для розгортання Backend генерує ідемпотентний SQL або migration bundle у свою
ігноровану папку artifacts/. Згенерований SQL не копіюється в Infra як друга
незалежна історія міграцій. Runtime-API не застосовує DDL автоматично.

## Старі SQL-файли

`db/migrations/001_init.sql` та `002_extended.sql` збережені без змін як
історична схема в `public`. Вони мають інші колонки й модель користувача,
ніж поточна банківська схема `banking` у Backend, тому не є заміною EF-міграцій.
Compose більше не монтує їх у docker-entrypoint-initdb.d.

Якщо старі SQL уже застосовані у Supabase або локальному volume, таблиці й дані
залишаються на місці. AppDbContext не управляє цими таблицями. Додавання
підтримки KYC, savings та інших старих моделей потребує окремої зміни Backend
і перевіреної міграції даних, а не повторного запуску початкових SQL.

## Supabase

Для прямого EF-підключення потрібні облікові дані PostgreSQL, а не API key.
Для IPv4 можна використовувати Session pooler. Задайте у Backend
`ConnectionStrings__AppDb` зі своїм host, username і паролем та перевіркою TLS
`SSL Mode=VerifyFull`. Параметри Supabase Auth налаштовуються окремо.
Зміни цієї гілки самі по собі не змінюють хмарну БД.
-- застосовувати в Supabase > SQL Editor. Після застосування файл НЕ редагувати
-- нові зміни додавати окремими файлами (003_..., 004_...).

create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;



-- USERS
create table users (
  id             uuid primary key default gen_random_uuid(),
  email          text not null unique,
  phone          text unique,
  password_hash  text not null,
  first_name     text not null,
  last_name      text not null,
  date_of_birth  date,
  tax_id         text unique,                          -- РНОКПП
  kyc_status     text not null default 'none'
                 check (kyc_status in ('none','pending','approved','rejected')),
  role           text not null default 'user'
                 check (role in ('user','admin')),
  status         text not null default 'active'
                 check (status in ('active','blocked')),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);



-- ACCOUNTS
create table accounts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users(id) on delete cascade,
  iban        text not null unique,
  currency    char(3) not null default 'UAH',
  balance     numeric(18,2) not null default 0 check (balance >= 0),
  status      text not null default 'active'
              check (status in ('active','frozen','closed')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index idx_accounts_user_id on accounts(user_id);




-- CARDS

-- повний номер і CVV зберігаються ТІЛЬКИ зашифрованими
create table cards (
  id                    uuid primary key default gen_random_uuid(),
  account_id            uuid not null references accounts(id) on delete cascade,
  card_number_encrypted text not null,
  cvv_encrypted         text not null,
  last4                 char(4) not null,
  holder_name           text not null,
  expiry_month          smallint not null check (expiry_month between 1 and 12),
  expiry_year           smallint not null check (expiry_year >= 2024),
  status                text not null default 'active'
                        check (status in ('active','blocked_by_user','blocked_by_admin','expired')),
  daily_limit           numeric(18,2) not null default 50000  check (daily_limit >= 0),
  monthly_limit         numeric(18,2) not null default 200000 check (monthly_limit >= 0),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create index idx_cards_account_id on cards(account_id);



-- TRANSACTIONS
create table transactions (
  id                 uuid primary key default gen_random_uuid(),
  account_id         uuid not null references accounts(id),
  card_id            uuid references cards(id),
  related_account_id uuid references accounts(id),     -- для внутрішніх переказів
  type               text not null
                     check (type in ('deposit','withdrawal','transfer_internal','transfer_iban',
                                     'currency_exchange','savings_deposit','savings_withdrawal',
                                     'payment','fee','cashback')),
  amount             numeric(18,2) not null check (amount > 0),
  currency           char(3) not null,
  fee                numeric(18,2) not null default 0 check (fee >= 0),
  exchange_rate      numeric(18,8) check (exchange_rate > 0),
  status             text not null default 'pending'
                     check (status in ('pending','completed','failed','cancelled')),
  category           text,                              -- для фінансової аналітики
  description        text,
  counterparty_iban  text,
  counterparty_name  text,
  created_at         timestamptz not null default now()
);
create index idx_transactions_account_created on transactions(account_id, created_at desc);
create index idx_transactions_card_id on transactions(card_id);
create index idx_transactions_category on transactions(category);




-- updated_at
create trigger trg_users_updated    before update on users    for each row execute function set_updated_at();
create trigger trg_accounts_updated before update on accounts for each row execute function set_updated_at();
create trigger trg_cards_updated    before update on cards    for each row execute function set_updated_at();



-- RLS
alter table users        enable row level security;
alter table accounts     enable row level security;
alter table cards        enable row level security;
alter table transactions enable row level security;

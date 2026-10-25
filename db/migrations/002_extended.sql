

-- KYC
create table kyc_applications (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references users(id) on delete cascade,
  status           text not null default 'pending'
                   check (status in ('pending','approved','rejected')),
  rejection_reason text,
  reviewed_by      uuid references users(id),
  reviewed_at      timestamptz,
  submitted_at     timestamptz not null default now()
);
create index idx_kyc_applications_user on kyc_applications(user_id);
create index idx_kyc_applications_status on kyc_applications(status);

create table kyc_documents (
  id             uuid primary key default gen_random_uuid(),
  application_id uuid not null references kyc_applications(id) on delete cascade,
  doc_type       text not null
                 check (doc_type in ('passport','id_card','tax_id_card','selfie','proof_of_address')),
  file_url       text not null,
  uploaded_at    timestamptz not null default now()
);
create index idx_kyc_documents_application on kyc_documents(application_id);



-- ACCUMULATION 
create table savings_goals (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users(id) on delete cascade,
  account_id     uuid not null references accounts(id),
  name           text not null,
  target_amount  numeric(18,2) not null check (target_amount > 0),
  current_amount numeric(18,2) not null default 0 check (current_amount >= 0),
  currency       char(3) not null default 'UAH',
  deadline       date,
  status         text not null default 'active'
                 check (status in ('active','completed','cancelled')),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index idx_savings_goals_user on savings_goals(user_id);



-- CASHBACK
create table cashback_accruals (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references users(id) on delete cascade,
  transaction_id uuid not null references transactions(id),
  rate           numeric(5,4) not null check (rate >= 0),
  amount         numeric(18,2) not null check (amount >= 0),
  currency       char(3) not null,
  status         text not null default 'pending'
                 check (status in ('pending','paid')),
  created_at     timestamptz not null default now()
);
create index idx_cashback_user on cashback_accruals(user_id);



-- NOTICE
create table notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users(id) on delete cascade,
  type        text not null,
  title       text not null,
  body        text,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);
create index idx_notifications_user_read on notifications(user_id, is_read, created_at desc);




-- SESSIONS
create table sessions (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references users(id) on delete cascade,
  refresh_token_hash text not null,
  device_name        text,
  platform           text check (platform in ('web','desktop','ios','android')),
  ip_address         text,
  created_at         timestamptz not null default now(),
  last_active_at     timestamptz not null default now(),
  expires_at         timestamptz not null,
  revoked_at         timestamptz
);
create index idx_sessions_user on sessions(user_id);
create index idx_sessions_token on sessions(refresh_token_hash);

-- USER SETTINGS
create table user_settings (
  user_id               uuid primary key references users(id) on delete cascade,
  language              text not null default 'uk' check (language in ('uk','en')),
  theme                 text not null default 'system' check (theme in ('light','dark','system')),
  notifications_enabled boolean not null default true,
  updated_at            timestamptz not null default now()
);

-- AUDIT
create table audit_logs (
  id          bigint generated always as identity primary key,
  user_id     uuid references users(id) on delete set null,
  action      text not null, 
  entity_type text,
  entity_id   text,
  details     jsonb,
  ip_address  text,
  created_at  timestamptz not null default now()
);
create index idx_audit_user_created on audit_logs(user_id, created_at desc);
create index idx_audit_action on audit_logs(action);



-- EXCHANGE RATES
create table exchange_rates (
  id              uuid primary key default gen_random_uuid(),
  base_currency   char(3) not null,
  quote_currency  char(3) not null,
  rate            numeric(18,8) not null check (rate > 0),
  updated_at      timestamptz not null default now(),
  unique (base_currency, quote_currency)
);



-- OTP 
create table otp_codes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references users(id) on delete cascade,
  purpose     text not null
              check (purpose in ('login','transfer','password_reset','card_details')),
  code_hash   text not null,
  attempts    smallint not null default 0,
  expires_at  timestamptz not null,
  used_at     timestamptz,
  created_at  timestamptz not null default now()
);
create index idx_otp_user_purpose on otp_codes(user_id, purpose);



-- updated_at
create trigger trg_savings_updated  before update on savings_goals  for each row execute function set_updated_at();
create trigger trg_settings_updated before update on user_settings  for each row execute function set_updated_at();
create trigger trg_rates_updated    before update on exchange_rates for each row execute function set_updated_at();



-- RLS 
alter table kyc_applications  enable row level security;
alter table kyc_documents     enable row level security;
alter table savings_goals     enable row level security;
alter table cashback_accruals enable row level security;
alter table notifications     enable row level security;
alter table sessions          enable row level security;
alter table user_settings     enable row level security;
alter table audit_logs        enable row level security;
alter table exchange_rates    enable row level security;
alter table otp_codes         enable row level security;

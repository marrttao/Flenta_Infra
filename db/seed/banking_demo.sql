-- Демо-дані для схеми banking
-- Скрипт можна запускати повторно - дублів не буде


-- Дані узгоджені з правилами БД: проводки по кожній валюті в сумі дають 0,

-- Картки містять ПЛЕЙСХОЛДЕР замість зашифрованих реквізитів

-- Кешбек і округлення в накопичення тут не проведені: невідомо, з якого рахунку їх проводить застосунок.

-- Щоб демо-дані з'явилися після входу реальним користувачем, задайте його id в .env:
--   SEED_OWNER_1=<uuid користувача 1>   SEED_OWNER_2=<uuid користувача 2>

\if :{?owner1}
\else
  \set owner1 '11111111-1111-1111-1111-111111111111'
\endif
\if :{?owner2}
\else
  \set owner2 '22222222-2222-2222-2222-222222222222'
\endif

\set kind_topup    'TopUp'
\set kind_internal 'InternalTransfer'
\set kind_iban     'IbanTransfer'
\set kind_purchase 'Purchase'
\set kind_exchange 'Exchange'
\set kind_savings  'SavingsDeposit'

BEGIN;

-- ---------- Системні рахунки ----------
INSERT INTO banking.accounts ("Id","OwnerId","Iban","Kind","BalanceMinorUnits","CreatedAt","CurrencyCode")
SELECT v.id::uuid, NULL, NULL, v.kind, 0, now(), v.cur
FROM (VALUES
  ('90000000-0000-0000-0000-000000000001','SandboxClearing','UAH'),
  ('90000000-0000-0000-0000-000000000002','SandboxClearing','USD'),
  ('90000000-0000-0000-0000-000000000003','FeeRevenue','UAH'),
  ('90000000-0000-0000-0000-000000000004','SandboxMerchant','UAH')
) AS v(id, kind, cur)
WHERE NOT EXISTS (SELECT 1 FROM banking.accounts a WHERE a."Kind" = v.kind AND a."CurrencyCode" = v.cur);

SELECT "Id" AS clearing_uah FROM banking.accounts WHERE "Kind"='SandboxClearing' AND "CurrencyCode"='UAH' ORDER BY "CreatedAt","Id" LIMIT 1 \gset
SELECT "Id" AS clearing_usd FROM banking.accounts WHERE "Kind"='SandboxClearing' AND "CurrencyCode"='USD' ORDER BY "CreatedAt","Id" LIMIT 1 \gset
SELECT "Id" AS fee_uah      FROM banking.accounts WHERE "Kind"='FeeRevenue'      AND "CurrencyCode"='UAH' ORDER BY "CreatedAt","Id" LIMIT 1 \gset
SELECT "Id" AS merchant_uah FROM banking.accounts WHERE "Kind"='SandboxMerchant' AND "CurrencyCode"='UAH' ORDER BY "CreatedAt","Id" LIMIT 1 \gset

-- ---------- Рахунки клієнтів ----------

INSERT INTO banking.accounts ("Id","OwnerId","Iban","Kind","BalanceMinorUnits","CreatedAt","CurrencyCode") VALUES
 ('a1000000-0000-0000-0000-000000000001', :'owner1', 'UA259999990000000000000001001', 'Customer', 0, now() - interval '40 days', 'UAH'),
 ('a1000000-0000-0000-0000-000000000002', :'owner1', 'UA959999990000000000000001002', 'Customer', 0, now() - interval '40 days', 'USD'),
 ('a1000000-0000-0000-0000-000000000003', :'owner2', 'UA889999990000000000000002001', 'Customer', 0, now() - interval '35 days', 'UAH'),
 ('a1000000-0000-0000-0000-000000000004', :'owner1', NULL,                            'Savings',  0, now() - interval '40 days', 'UAH')
ON CONFLICT ("Id") DO NOTHING;

-- ---------- Картки  ----------
INSERT INTO banking.cards ("Id","AccountId","Last4","ProtectedData","Fingerprint","ExpiryMonth","ExpiryYear","Status","CreatedAt","LastSecretsViewedAt")
SELECT v.id::uuid, v.acc::uuid, v.last4, 'seed-placeholder-not-decryptable',
       encode(sha256(convert_to('seed-card-' || v.id, 'UTF8')), 'hex'), v.m, v.y, v.status, now() - interval '30 days', NULL
FROM (VALUES
  ('c1000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001','4242',12,2029,'Active'),
  ('c1000000-0000-0000-0000-000000000002','a1000000-0000-0000-0000-000000000003','1881', 6,2029,'Active'),
  ('c1000000-0000-0000-0000-000000000003','a1000000-0000-0000-0000-000000000001','0007', 3,2028,'Blocked')
) AS v(id, acc, last4, m, y, status)
ON CONFLICT ("Id") DO NOTHING;

-- ---------- Транзакції ----------
INSERT INTO banking.transactions
  ("Id","InitiatorId","IdempotencyKey","RequestFingerprint","Kind","Status","SourceAccountId","DestinationAccountId","DestinationIban",
   "AmountMinorUnits","FeeMinorUnits","CreatedAt","FinishedAt","FailureCode","CurrencyCode","DestinationCurrency","ExchangeRate","RateDate","ReceivedMinorUnits")
SELECT v.id::uuid, v.init::uuid, md5('seed-key-' || v.id)::uuid,
       encode(sha256(convert_to('seed-' || v.id, 'UTF8')), 'hex'),
       v.kind, v.status, v.src::uuid, v.dst::uuid, v.iban,
       v.amount, v.fee, v.ts, v.ts + interval '1 second', v.failure, v.cur, v.dcur, v.rate, v.rdate, v.recv
FROM (VALUES
 ('d1000000-0000-0000-0000-000000000001', :'owner1', :'kind_topup',    'Completed', :'clearing_uah', 'a1000000-0000-0000-0000-000000000001', NULL, 1000000::bigint, 0::bigint, now() - interval '30 days', NULL, 'UAH', NULL, NULL::numeric, NULL::date, NULL::bigint),
 ('d1000000-0000-0000-0000-000000000002', :'owner2', :'kind_topup',    'Completed', :'clearing_uah', 'a1000000-0000-0000-0000-000000000003', NULL,  500000, 0, now() - interval '25 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000003', :'owner1', :'kind_topup',    'Completed', :'clearing_usd', 'a1000000-0000-0000-0000-000000000002', NULL,  100000, 0, now() - interval '20 days', NULL, 'USD', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000004', :'owner1', :'kind_purchase', 'Completed', 'a1000000-0000-0000-0000-000000000001', :'merchant_uah', NULL, 25050, 0, now() - interval '8 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000005', :'owner1', :'kind_purchase', 'Completed', 'a1000000-0000-0000-0000-000000000001', :'merchant_uah', NULL, 120000, 0, now() - interval '6 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000006', :'owner1', :'kind_purchase', 'Completed', 'a1000000-0000-0000-0000-000000000001', :'merchant_uah', NULL, 8990, 0, now() - interval '3 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000007', :'owner1', :'kind_internal', 'Completed', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000003', NULL, 50000, 0, now() - interval '5 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000008', :'owner1', :'kind_iban',     'Completed', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000003', 'UA889999990000000000000002001', 100000, 500, now() - interval '2 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000009', :'owner2', :'kind_iban',     'Rejected',  'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 'UA259999990000000000000001001', 999999999, 0, now() - interval '1 day', 'account.insufficient_funds', 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000010', :'owner2', :'kind_iban',     'Rejected',  'a1000000-0000-0000-0000-000000000003', NULL, 'UA889999990000000000000008888', 1000, 0, now() - interval '20 hours', 'transfer.recipient_not_found', 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000011', :'owner1', :'kind_exchange', 'Completed', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', NULL, 41500, 0, now() - interval '4 days', NULL, 'UAH', 'USD', 41.5, current_date - 4, 1000),
 ('d1000000-0000-0000-0000-000000000012', :'owner1', :'kind_savings',  'Completed', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', NULL, 450000, 0, now() - interval '7 days', NULL, 'UAH', NULL, NULL, NULL, NULL),
 ('d1000000-0000-0000-0000-000000000013', :'owner2', :'kind_purchase', 'Completed', 'a1000000-0000-0000-0000-000000000003', :'merchant_uah', NULL, 30000, 0, now() - interval '3 days', NULL, 'UAH', NULL, NULL, NULL, NULL)
) AS v(id, init, kind, status, src, dst, iban, amount, fee, ts, failure, cur, dcur, rate, rdate, recv)
ON CONFLICT ("Id") DO NOTHING;

-- ---------- Проводки  ----------
INSERT INTO banking.entries ("Id","TransactionId","AccountId","AmountMinorUnits","CreatedAt","CurrencyCode")
SELECT md5('seed-entry-' || v.tx || v.acc)::uuid, v.tx::uuid, v.acc::uuid, v.amt, t."CreatedAt", v.cur
FROM (VALUES
 ('d1000000-0000-0000-0000-000000000001', :'clearing_uah', -1000000::bigint, 'UAH'),
 ('d1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',  1000000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000002', :'clearing_uah',  -500000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000003',   500000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000003', :'clearing_usd',  -100000, 'USD'),
 ('d1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002',   100000, 'USD'),
 ('d1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001',   -25050, 'UAH'),
 ('d1000000-0000-0000-0000-000000000004', :'merchant_uah',                           25050, 'UAH'),
 ('d1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000001',  -120000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000005', :'merchant_uah',                          120000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000001',    -8990, 'UAH'),
 ('d1000000-0000-0000-0000-000000000006', :'merchant_uah',                            8990, 'UAH'),
 ('d1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000001',   -50000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000003',    50000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000001',  -100500, 'UAH'),
 ('d1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000003',   100000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000008', :'fee_uah',                                  500, 'UAH'),
 ('d1000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000001',   -41500, 'UAH'),
 ('d1000000-0000-0000-0000-000000000011', :'clearing_uah',                            41500, 'UAH'),
 ('d1000000-0000-0000-0000-000000000011', :'clearing_usd',                            -1000, 'USD'),
 ('d1000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000002',     1000, 'USD'),
 ('d1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000001',  -450000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000004',   450000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000003',   -30000, 'UAH'),
 ('d1000000-0000-0000-0000-000000000013', :'merchant_uah',                           30000, 'UAH')
) AS v(tx, acc, amt, cur)
JOIN banking.transactions t ON t."Id" = v.tx::uuid
ON CONFLICT ("Id") DO NOTHING;

-- ---------- Котирування обміну ----------
INSERT INTO banking.exchange_quotes
  ("Id","OwnerId","SourceAccountId","DestinationAccountId","SourceCurrency","DestinationCurrency","AmountMinorUnits","ReceivedMinorUnits","Rate","RateDate","CreatedAt","ExpiresAt","TransactionId")
VALUES
 ('b1000000-0000-0000-0000-000000000001', :'owner1', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'UAH','USD', 41500, 1000, 41.5, current_date - 4, now() - interval '4 days' - interval '2 minutes', now() - interval '4 days' + interval '3 minutes', 'd1000000-0000-0000-0000-000000000011'),
 ('b1000000-0000-0000-0000-000000000002', :'owner1', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'UAH','USD', 20750,  500, 41.5, current_date - 1, now() - interval '1 day',                       now() - interval '1 day' + interval '5 minutes',  NULL)
ON CONFLICT ("Id") DO NOTHING;

-- ---------- Ціль накопичення  ----------
INSERT INTO banking.goals
  ("Id","OwnerId","AccountId","FundingAccountId","Name","TargetMinorUnits","Deadline","Mode","Percentage","RoundUpStep","Archived","CreatedAt")
VALUES
 ('f1000000-0000-0000-0000-000000000001', :'owner1', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001',
  'Відпустка', 2000000, current_date + 120, 'Off', 0, 10, false, now() - interval '30 days')
ON CONFLICT ("Id") DO NOTHING;

-- ---------- Баланси = сума проводок  ----------
UPDATE banking.accounts a
SET "BalanceMinorUnits" = COALESCE((SELECT SUM(e."AmountMinorUnits") FROM banking.entries e WHERE e."AccountId" = a."Id"), 0)
WHERE a."Id" IN ('a1000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000002',
                 'a1000000-0000-0000-0000-000000000003','a1000000-0000-0000-0000-000000000004')
   OR a."Kind" IN ('SandboxClearing','FeeRevenue','SandboxMerchant');

COMMIT;

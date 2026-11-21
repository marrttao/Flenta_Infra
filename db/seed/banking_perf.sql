-- Великий набір даних для перевірки швидкості запитів (EXPLAIN) і індексів. Запускається вручну, не автоматично.
-- За замовчуванням 5000 переказів між двома тестовими клієнтами. Кількість можна змінити: -v n=20000


-- АХТУНГ - тригери БД перевіряють баланс кожної проводки, тому великі n (20000+) виконуються довго.

\if :{?n}
\else
  \set n 5000
\endif
\set kind_topup    'TopUp'
\set kind_internal 'InternalTransfer'

BEGIN;

INSERT INTO banking.accounts ("Id","OwnerId","Iban","Kind","BalanceMinorUnits","CreatedAt","CurrencyCode")
SELECT 'ee000000-0000-0000-0000-000000000001'::uuid, NULL, NULL, 'SandboxClearing', 0, now(), 'UAH'
WHERE NOT EXISTS (SELECT 1 FROM banking.accounts WHERE "Kind" = 'SandboxClearing' AND "CurrencyCode" = 'UAH');

SELECT "Id" AS clearing_uah FROM banking.accounts WHERE "Kind"='SandboxClearing' AND "CurrencyCode"='UAH' ORDER BY "CreatedAt","Id" LIMIT 1 \gset

INSERT INTO banking.accounts ("Id","OwnerId","Iban","Kind","BalanceMinorUnits","CreatedAt","CurrencyCode") VALUES
 ('f2000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'UA449999990000000000000009001', 'Customer', 0, now() - interval '400 days', 'UAH'),
 ('f2000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000002', 'UA179999990000000000000009002', 'Customer', 0, now() - interval '400 days', 'UAH')
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO banking.transactions
  ("Id","InitiatorId","IdempotencyKey","RequestFingerprint","Kind","Status","SourceAccountId","DestinationAccountId","AmountMinorUnits","FeeMinorUnits","CreatedAt","FinishedAt")
VALUES
 (md5('perf-topup')::uuid, 'f0000000-0000-0000-0000-000000000001', md5('perf-topup-key')::uuid,
  encode(sha256(convert_to('perf-topup', 'UTF8')), 'hex'), :'kind_topup', 'Completed',
  :'clearing_uah', 'f2000000-0000-0000-0000-000000000001', (:n)::bigint * 10000, 0,
  now() - interval '399 days', now() - interval '399 days' + interval '1 second')
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO banking.entries ("Id","TransactionId","AccountId","AmountMinorUnits","CreatedAt","CurrencyCode")
SELECT md5('perf-topup-e' || v.acc)::uuid, t."Id", v.acc::uuid, v.amt, t."CreatedAt", 'UAH'
FROM banking.transactions t
CROSS JOIN LATERAL (VALUES (:'clearing_uah', -t."AmountMinorUnits"), ('f2000000-0000-0000-0000-000000000001', t."AmountMinorUnits")) AS v(acc, amt)
WHERE t."Id" = md5('perf-topup')::uuid
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO banking.transactions
  ("Id","InitiatorId","IdempotencyKey","RequestFingerprint","Kind","Status","SourceAccountId","DestinationAccountId",
   "AmountMinorUnits","FeeMinorUnits","CreatedAt","FinishedAt")
SELECT md5('perf-tx-' || i)::uuid, 'f0000000-0000-0000-0000-000000000001'::uuid, md5('perf-key-' || i)::uuid,
       encode(sha256(convert_to('perf-' || i, 'UTF8')), 'hex'), :'kind_internal', 'Completed',
       'f2000000-0000-0000-0000-000000000001'::uuid, 'f2000000-0000-0000-0000-000000000002'::uuid,
       100 + (i * 7919 % 9900), 0,
       now() - make_interval(mins => (((:n) - i) * 105)::int),
       now() - make_interval(mins => (((:n) - i) * 105)::int) + interval '1 second'
FROM generate_series(1, :n) AS i
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO banking.entries ("Id","TransactionId","AccountId","AmountMinorUnits","CreatedAt","CurrencyCode")
SELECT md5('perf-e-' || t."Id" || v.acc)::uuid, t."Id", v.acc::uuid, v.amt, t."CreatedAt", 'UAH'
FROM banking.transactions t
CROSS JOIN LATERAL (VALUES ('f2000000-0000-0000-0000-000000000001', -t."AmountMinorUnits"), ('f2000000-0000-0000-0000-000000000002', t."AmountMinorUnits")) AS v(acc, amt)
WHERE t."SourceAccountId" = 'f2000000-0000-0000-0000-000000000001'::uuid AND t."Kind" = :'kind_internal'
ON CONFLICT ("Id") DO NOTHING;

UPDATE banking.accounts a
SET "BalanceMinorUnits" = COALESCE((SELECT SUM(e."AmountMinorUnits") FROM banking.entries e WHERE e."AccountId" = a."Id"), 0)
WHERE a."Id" IN ('f2000000-0000-0000-0000-000000000001','f2000000-0000-0000-0000-000000000002')
   OR a."Kind" = 'SandboxClearing';

COMMIT;

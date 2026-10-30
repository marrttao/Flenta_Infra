-- Тестові дані ТІЛЬКИ для локальної розробки (docker compose --profile local)
 


--USERS
insert into users (id, email, phone, password_hash, first_name, last_name, date_of_birth, tax_id, kyc_status, role, status) values
 ('00000000-0000-0000-0000-000000000001','admin@flenta.test','+380500000001','seed_fake_hash','Admin','Flenta','1990-01-01','1000000001','approved','admin','active'),
 ('00000000-0000-0000-0000-000000000002','ivan@flenta.test', '+380500000002','seed_fake_hash','Іван','Петренко','1998-05-14','2000000002','approved','user','active'),
 ('00000000-0000-0000-0000-000000000003','olena@flenta.test','+380500000003','seed_fake_hash','Олена','Коваль','2000-09-30','3000000003','approved','user','active'),
 ('00000000-0000-0000-0000-000000000004','petro@flenta.test','+380500000004','seed_fake_hash','Петро','Шевченко','2001-02-20','4000000004','pending','user','active')
on conflict (id) do nothing;
 


--USER SETTINGS
insert into user_settings (user_id, language, theme, notifications_enabled) values
 ('00000000-0000-0000-0000-000000000001','en','dark','true'),
 ('00000000-0000-0000-0000-000000000002','uk','system','true'),
 ('00000000-0000-0000-0000-000000000003','uk','light','true'),
 ('00000000-0000-0000-0000-000000000004','en','system','false')
on conflict (user_id) do nothing;
 


--ACCOUNTS 
insert into accounts (id, user_id, iban, currency, balance, status) values
 ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','UA213223130000026007233566001','UAH',12500.00,'active'),
 ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','UA213223130000026007233566002','USD',300.00,'active'),
 ('10000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000003','UA213223130000026007233566003','UAH',8200.00,'active')
on conflict (id) do nothing;
 



--CARDS 
insert into cards (id, account_id, card_number_encrypted, cvv_encrypted, last4, holder_name, expiry_month, expiry_year, status, daily_limit, monthly_limit) values
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','ENC:seed-fake-1','ENC:seed-fake-cvv-1','4242','IVAN PETRENKO',12,2029,'active',50000,200000),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003','ENC:seed-fake-2','ENC:seed-fake-cvv-2','1881','OLENA KOVAL',6,2029,'active',30000,150000),
 ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','ENC:seed-fake-3','ENC:seed-fake-cvv-3','0007','IVAN PETRENKO',3,2028,'blocked_by_user',50000,200000)
on conflict (id) do nothing;
 



--TRANSACTIONS
insert into transactions (id, account_id, card_id, related_account_id, type, amount, currency, fee, exchange_rate, status, category, description, counterparty_iban, counterparty_name, created_at) values
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',null,null,'deposit',5000.00,'UAH',0,null,'completed','income','Поповнення рахунку',null,null, now() - interval '10 days'),
 ('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',null,'payment',250.50,'UAH',0,null,'completed','food','Оплата в супермаркеті',null,'Сільпо', now() - interval '8 days'),
 ('30000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',null,'payment',1200.00,'UAH',0,null,'completed','transport','Поїздка',null,'Uber', now() - interval '6 days'),
 ('30000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001',null,'10000000-0000-0000-0000-000000000003','transfer_internal',500.00,'UAH',0,null,'completed','transfer','Переказ Олені',null,'Олена Коваль', now() - interval '5 days'),
 ('30000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000001',null,'10000000-0000-0000-0000-000000000002','currency_exchange',4150.00,'UAH',20.00,41.50000000,'completed','exchange','UAH -> USD',null,null, now() - interval '4 days'),
 ('30000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000001',null,null,'cashback',29.01,'UAH',0,null,'completed','income','Кешбек за тиждень',null,null, now() - interval '2 days'),
 ('30000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000002',null,'payment',899.00,'UAH',0,null,'completed','shopping','Онлайн-покупка',null,'Rozetka', now() - interval '3 days'),
 ('30000000-0000-0000-0000-000000000008','10000000-0000-0000-0000-000000000003',null,null,'transfer_iban',300.00,'UAH',5.00,null,'pending','transfer','Переказ за IBAN','UA903052992990004149123456789','ФОП Мельник', now() - interval '1 hour')
on conflict (id) do nothing;
 



--CASHBACK
insert into cashback_accruals (id, user_id, transaction_id, rate, amount, currency, status) values
 ('40000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002',0.0200,5.01,'UAH','paid'),
 ('40000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000003',0.0200,24.00,'UAH','paid')
on conflict (id) do nothing;
 



--SAVINGS
insert into savings_goals (id, user_id, account_id, name, target_amount, current_amount, currency, deadline, status) values
 ('50000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','Відпустка',20000,4500,'UAH', current_date + 120,'active'),
 ('50000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000003','Ноутбук',35000,35000,'UAH', current_date - 10,'completed')
on conflict (id) do nothing;
 



-- KYC
insert into kyc_applications (id, user_id, status, rejection_reason, reviewed_by, reviewed_at, submitted_at) values
 ('60000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','approved',null,'00000000-0000-0000-0000-000000000001', now() - interval '20 days', now() - interval '21 days'),
 ('60000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','approved',null,'00000000-0000-0000-0000-000000000001', now() - interval '15 days', now() - interval '16 days'),
 ('60000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004','pending',null,null,null, now() - interval '1 day')
on conflict (id) do nothing;
 
insert into kyc_documents (id, application_id, doc_type, file_url) values
 ('61000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','passport','seed/ivan_passport.png'),
 ('61000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000001','selfie','seed/ivan_selfie.png'),
 ('61000000-0000-0000-0000-000000000003','60000000-0000-0000-0000-000000000003','id_card','seed/petro_id.png'),
 ('61000000-0000-0000-0000-000000000004','60000000-0000-0000-0000-000000000003','selfie','seed/petro_selfie.png')
on conflict (id) do nothing;
 



--NOTIFICATIONS
insert into notifications (id, user_id, type, title, body, is_read) values
 ('70000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','transaction','Переказ виконано','Ви переказали 500.00 UAH',true),
 ('70000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','cashback','Нараховано кешбек','Кешбек 29.01 UAH зараховано',false),
 ('70000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','admin','Нова KYC-заявка','Користувач Петро Шевченко очікує перевірки',false)
on conflict (id) do nothing;
 



--EXCHANGE RATES
insert into exchange_rates (id, base_currency, quote_currency, rate) values
 ('80000000-0000-0000-0000-000000000001','USD','UAH',41.50000000),
 ('80000000-0000-0000-0000-000000000002','EUR','UAH',45.20000000),
 ('80000000-0000-0000-0000-000000000003','UAH','USD',0.02409639),
 ('80000000-0000-0000-0000-000000000004','UAH','EUR',0.02212389)
on conflict do nothing;
 



-- SESSIONS
insert into sessions (id, user_id, refresh_token_hash, device_name, platform, ip_address, expires_at) values
 ('90000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','seed_fake_token_hash','Chrome / Windows','web','127.0.0.1', now() + interval '30 days')
on conflict (id) do nothing;
 


 
--AUDIT
insert into audit_logs (user_id, action, entity_type, entity_id, details)
select '00000000-0000-0000-0000-000000000001','seed_loaded','system','seed','{"note":"test data loaded"}'::jsonb
where not exists (select 1 from audit_logs where action = 'seed_loaded');
 
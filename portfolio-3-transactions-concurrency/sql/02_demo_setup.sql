-- Demo Alice (9000000001) and Demo Bob (9000000002), opening balance 500.00.
-- RE-RUN THIS FILE before each experiment to reset both wallets to 500.00.
-- They have NO ledger lines: the lock experiments touch only accounts.balance.
INSERT INTO customers (first_name, last_name, email, phone, customer_type)
VALUES ('Demo', 'Alice', 'demo.alice@nexora.test', '08200000001', 'INDIVIDUAL'),
       ('Demo', 'Bob',   'demo.bob@nexora.test',   '08200000002', 'INDIVIDUAL')
ON CONFLICT (email) DO NOTHING;

INSERT INTO accounts (customer_id, account_number, balance)
SELECT customer_id, '9000000001', 500 FROM customers WHERE email = 'demo.alice@nexora
.test'
ON CONFLICT (account_number) DO UPDATE SET balance = 500, status = 'ACTIVE';

INSERT INTO accounts (customer_id, account_number, balance)
SELECT customer_id, '9000000002', 500 FROM customers WHERE email = 'demo.bob@nexora.test'
ON CONFLICT (account_number) DO UPDATE SET balance = 500, status = 'ACTIVE';

SELECT account_number, balance FROM accounts
WHERE account_number IN ('9000000001', '9000000002') ORDER BY account_number;

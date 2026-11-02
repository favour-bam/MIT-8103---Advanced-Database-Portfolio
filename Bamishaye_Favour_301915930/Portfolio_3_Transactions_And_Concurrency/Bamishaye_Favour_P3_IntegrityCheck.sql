-- 1. Money is neither created nor destroyed by transfers (demo wallets excluded).
SELECT sum(balance) AS total_money_in_system
FROM accounts
WHERE account_number NOT IN ('9000000001', '9000000002');

-- 2. Stress-test transfers recorded, and their ledger lines (2 per transfer).
SELECT
    (SELECT count(*) FROM transactions
     WHERE idempotency_key LIKE 'pgb-%' AND status = 'COMPLETED') AS stress_transfers,
    (SELECT count(*) FROM ledger_entries l
     JOIN transactions t ON t.transaction_id = l.transaction_id
     WHERE t.idempotency_key LIKE 'pgb-%') AS stress_ledger_lines;

-- 3. Every transaction's debits must equal its credits. Expected: 0
SELECT count(*) AS unbalanced_transactions
FROM (
    SELECT transaction_id
    FROM ledger_entries
    GROUP BY transaction_id
    HAVING SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE -amount END) <> 0
) x;

-- 4. accounts.balance must equal the ledger total for every ledger-backed account.
--    (The settlement account also has its 1,000,000,000,000 opening balance.) Expected: 0
SELECT count(*) AS mismatched_accounts
FROM accounts a
JOIN (
    SELECT account_id,
           SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE -amount END) AS net
    FROM ledger_entries
    GROUP BY account_id
) l ON l.account_id = a.account_id
WHERE a.balance <> l.net + CASE WHEN a.account_number = '1000000000'
                                THEN 1000000000000 ELSE 0 END;

-- 5. No transaction left half-finished. Expected: 0
SELECT count(*) AS stuck_pending_transactions
FROM transactions WHERE status = 'PENDING';
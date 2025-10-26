
***

### Table: customers_raw.csv

| Field Name    | Data Type | Business Definition                                                                                  |
|---------------|-----------|-----------------------------------------------------------------------------------------------------|
| customer_id   | string    | Unique identifier for each customer in the institution.                                             |
| first_name    | string    | Customer's first (given) name as registered.                                                        |
| last_name     | string    | Customer's last (family) name as registered.                                                        |
| date_of_birth | date      | Date when customer was born (YYYY-MM-DD). Used for age and eligibility checks.                      |
| gender        | string    | Customer's gender (male, female, other, unspecified).                                               |
| marital_status| string    | Marital status (single, married, divorced, etc.). Can affect risk, offers, or eligibility.          |
| occupation    | string    | Customer's profession or job. Used for profiling, marketing, and regulatory checks.                 |
| income        | float     | Customer's annual income, self-reported or verified, used for risk and eligibility.                 |
| city          | string    | Customer's city of residence.                                                                       |
| state         | string    | Customer's state or province of residence.                                                          |
| country       | string    | Country where the customer resides (ISO country or text).                                           |
| join_date     | date      | When the customer first became a client. Used for retention/loyalty analysis.                       |

***

### Table: accounts_raw.csv

| Field Name   | Data Type | Business Definition                                                      |
|--------------|-----------|-------------------------------------------------------------------------|
| account_id   | string    | Unique identifier for the bank account.                                 |
| customer_id  | string    | Customer linked to this account (FK to customers table).                |
| account_type | string    | Type of account (checking, savings, credit card, loan, etc.).           |
| branch_code  | string    | Bank branch where account was opened/managed.                           |
| balance      | float     | Current balance in main account currency.                               |
| currency     | string    | Currency code for the account (e.g., USD, EUR, INR).                   |
| open_date    | date      | Date when account was opened.                                           |
| status       | string    | Current account status (Active, Inactive, Closed, Frozen, etc.).        |

***

### Table: transactions_raw.csv

| Field Name        | Data Type | Business Definition                                                        |
|-------------------|-----------|---------------------------------------------------------------------------|
| transaction_id    | string    | Unique identifier for each transaction.                                   |
| account_id        | string    | Account associated with the transaction (FK to accounts).                  |
| transaction_date  | date      | Date and time when the transaction occurred.                               |
| transaction_type  | string    | Type of transaction (deposit, withdrawal, payment, transfer, fee, etc.).   |
| amount            | float     | Transaction amount in account currency (+ credit, - debit).                |
| merchant          | string    | Merchant or counterparty if retail/payment.                                |
| category          | string    | Transaction classification (groceries, utilities, loans, dining, etc.).    |
| city              | string    | City/region where transaction was processed.                               |
| country           | string    | Country of transaction (useful for fraud and compliance).                  |

***

### Table: loans_raw.csv

| Field Name        | Data Type | Business Definition                                               |
|-------------------|-----------|------------------------------------------------------------------|
| loan_id           | string    | Unique identifier for the loan issued.                           |
| customer_id       | string    | The customer who took out the loan (FK to customers).            |
| loan_type         | string    | Type/category of loan (home, auto, personal, education, etc.).   |
| principal_amount  | float     | Original amount of loan principal granted.                       |
| interest_rate     | float     | Interest rate applied to the loan, as a percentage per annum.    |
| start_date        | date      | Date when loan started/funds disbursed.                          |
| end_date          | date      | Date when the loan term ends/completes (or scheduled maturity).  |
| status            | string    | Loan status (Active, Closed, Defaulted, Prepaid, etc.).          |

***

### Table: loan_payments_raw.csv

| Field Name   | Data Type | Business Definition                                                             |
|--------------|-----------|--------------------------------------------------------------------------------|
| payment_id   | string    | Unique identifier for each repayment installment.                               |
| loan_id      | string    | ID of the loan for which this payment was made (FK to loans).                  |
| payment_date | date      | Date payment was received/credited.                                             |
| amount       | float     | Payment amount applied (may include interest, principal, fees).                 |
| status       | string    | Payment status (Completed, Pending, Failed, Reversed, etc.).                   |

***

**can further expand each “Business Definition” as you formalize your system or map specialized business logic and requirements! If you want this as a .docx, .xlsx, or with even more annotation, just say the word.**
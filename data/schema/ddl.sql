
-- Copyright 2025 Amazon.com and its affiliates; all rights reserved.
-- This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

-- Drop existing triggers
DROP TRIGGER IF EXISTS update_merchant_details_updated_at ON merchant_details;
DROP TRIGGER IF EXISTS update_authorizations_updated_at ON authorizations;
DROP TRIGGER IF EXISTS update_settlements_updated_at ON settlements;
DROP TRIGGER IF EXISTS update_merchant_stats_updated_at ON merchant_stats;

-- Drop existing functions
DROP FUNCTION IF EXISTS update_merchant_details_updated_at();
DROP FUNCTION IF EXISTS update_authorizations_updated_at();
DROP FUNCTION IF EXISTS update_settlements_updated_at();
DROP FUNCTION IF EXISTS update_merchant_stats_updated_at();

-- Drop existing tables (in reverse order of creation to avoid foreign key conflicts)
DROP TABLE IF EXISTS merchant_stats;
DROP TABLE IF EXISTS settlements;
DROP TABLE IF EXISTS authorizations;
DROP TABLE IF EXISTS merchant_details;

-- Drop existing indexes
DROP INDEX IF EXISTS idx_merchant_business_name;
DROP INDEX IF EXISTS idx_merchant_aff_name;
DROP INDEX IF EXISTS idx_merchant_category_code;
DROP INDEX IF EXISTS idx_auth_merchant_number;
DROP INDEX IF EXISTS idx_auth_account_number;
DROP INDEX IF EXISTS idx_auth_transaction_datetime;
DROP INDEX IF EXISTS idx_auth_approval_status;
DROP INDEX IF EXISTS idx_auth_account_datetime;
DROP INDEX IF EXISTS idx_settlements_account_number;
DROP INDEX IF EXISTS idx_settlements_transaction_date;
DROP INDEX IF EXISTS idx_settlements_merchant_number;
DROP INDEX IF EXISTS idx_settlements_auth_code;
DROP INDEX IF EXISTS idx_settlements_account_date;
DROP INDEX IF EXISTS idx_merchant_stats_merchant_number;
DROP INDEX IF EXISTS idx_merchant_stats_bucket_date;
DROP INDEX IF EXISTS idx_merchant_stats_merchant_bucket;

CREATE TABLE merchant_details (
    Merchant_Number VARCHAR(20) PRIMARY KEY,
    Merchant_Name VARCHAR(100),
    Address_Line1 VARCHAR(100),
    Address_Line2 VARCHAR(100),
    County VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(20),
    Billing_Address_Line1 VARCHAR(100),
    Billing_Address_Line2 VARCHAR(100),
    Billing_City VARCHAR(50),
    Billing_County VARCHAR(50),
    Billing_Name VARCHAR(100),
    Billing_Phone VARCHAR(20),
    Billing_State VARCHAR(20),
    Billing_Zip_Code VARCHAR(10),
    Business_Contact_Name VARCHAR(100),
    Business_Email VARCHAR(100),
    Business_Phone VARCHAR(20),
    Business_Name VARCHAR(100),
    Business_Zip_Code VARCHAR(10),
    Business_Address_Line1 VARCHAR(100),
    Business_Address_Line2 VARCHAR(100),
    Business_City VARCHAR(50),
    Business_State VARCHAR(50),
    Legal_Contact_Name VARCHAR(100),
    Legal_Phone_Line1 VARCHAR(20),
    Legal_Name VARCHAR(100),
    Country_Code VARCHAR(3),
    Merchant_Category_Code VARCHAR(4),
    Merchant_Category_Description VARCHAR(100),
    Merchant_Website VARCHAR(200),
    Merchant_Phone VARCHAR(20),
    Merchant_Zip_Code VARCHAR(10),
    Standard_Industrial_Classification VARCHAR(100),
    SIC_Code VARCHAR(4),
    Account_Status VARCHAR(10),
    Signature_Amount DECIMAL(12,2),     -- threshold amount, where transactions below it don't require a signature
    Signature_Volume DECIMAL(12,2),     -- the aggregate dollar amount of all transactions processed within a given period that were authenticated by a signature. 
    Terminated_Indicator VARCHAR(10),
    First_Post_Date DATE,
    Installation_Date DATE,
    Last_Cancel_Date DATE,
    Last_Post_Date DATE,
    Last_Status_Date DATE,
    Last_Settlement_Date DATE,
    Business_Address_Change_Date DATE,
    Business_Phone_Change_Date DATE,
    Business_Email_Change_Date DATE,
    Created_At TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    Updated_At TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_merchant_business_name ON merchant_details(Business_Name);
CREATE INDEX idx_merchant_aff_name ON merchant_details(Merchant_Name);
CREATE INDEX idx_merchant_category_code ON merchant_details(Merchant_Category_Code);

CREATE OR REPLACE FUNCTION update_merchant_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_merchant_details_updated_at
    BEFORE UPDATE ON merchant_details
    FOR EACH ROW
    EXECUTE FUNCTION update_merchant_details_updated_at();


CREATE TABLE authorizations (
    id SERIAL PRIMARY KEY,
    Merchant_Number VARCHAR(20),
    account_number VARCHAR(16) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    currency CHAR(3) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    card_expiry_date VARCHAR(5),
    auth_code VARCHAR(20),
    transaction_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    approval_status VARCHAR(20) NOT NULL,
    decline_reason  VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_merchant
        FOREIGN KEY (Merchant_Number) 
        REFERENCES merchant_details(Merchant_Number)
);

CREATE INDEX idx_auth_merchant_number ON authorizations(Merchant_Number);
CREATE INDEX idx_auth_account_number ON authorizations(account_number);
CREATE INDEX idx_auth_transaction_datetime ON authorizations(transaction_datetime);
CREATE INDEX idx_auth_approval_status ON authorizations(approval_status);
CREATE INDEX idx_auth_account_datetime ON authorizations(account_number, transaction_datetime);

CREATE OR REPLACE FUNCTION update_authorizations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_authorizations_updated_at
    BEFORE UPDATE ON authorizations
    FOR EACH ROW
    EXECUTE FUNCTION update_authorizations_updated_at();



CREATE TABLE settlements (
    id SERIAL PRIMARY KEY,
    merchant_number VARCHAR(20),
    account_number VARCHAR(16) NOT NULL,
    same_card VARCHAR(2),
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL,
    processed_amount NUMERIC(12, 2) NOT NULL,
    auth_amount NUMERIC(12, 2),
    tran_id VARCHAR(50) NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    transaction_status VARCHAR(20) NOT NULL,
    card_issue_type VARCHAR(30),
    transaction_mode VARCHAR(30),
    payment_method VARCHAR(30) NOT NULL,
    auth_code VARCHAR(10),
    auth_date TIMESTAMP WITH TIME ZONE,
    card_class VARCHAR(30),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_merchant
        FOREIGN KEY (merchant_number) 
        REFERENCES merchant_details(Merchant_Number)
);

CREATE INDEX idx_settlements_account_number ON settlements(account_number);
CREATE INDEX idx_settlements_transaction_date ON settlements(transaction_date);
CREATE INDEX idx_settlements_merchant_number ON settlements(merchant_number);
CREATE INDEX idx_settlements_auth_code ON settlements(auth_code);
CREATE INDEX idx_settlements_account_date ON settlements(account_number, transaction_date);

CREATE OR REPLACE FUNCTION update_settlements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_settlements_updated_at
    BEFORE UPDATE ON settlements
    FOR EACH ROW
    EXECUTE FUNCTION update_settlements_updated_at();



CREATE TABLE merchant_stats (
    id SERIAL PRIMARY KEY,
    merchant_number VARCHAR(20) NOT NULL,
    bucket_date VARCHAR(50) NOT NULL, -- time bucket of which the data is aggregated
    
    credit_sales_count INTEGER,
    credit_sales_volume NUMERIC(14, 2),
    credit_sales_average_ticket NUMERIC(10, 2),
    credit_refunds_count INTEGER,
    credit_refunds_volume NUMERIC(14, 2),
    credit_refunds_average_ticket NUMERIC(10, 2),
    credit_refunds_percent NUMERIC(5, 2),
    credit_disputes_count INTEGER,
    credit_disputes_volume NUMERIC(14, 2),
    credit_disputes_average_ticket NUMERIC(10, 2),
    credit_disputes_percent NUMERIC(5, 2),
    credit_reversals_count INTEGER,
    credit_reversals_volume NUMERIC(14, 2),
    credit_reversals_percent NUMERIC(5, 2),
    
    entry_method_keyed_percent NUMERIC(5, 2),
    entry_method_ecomm_percent NUMERIC(5, 2),
    entry_method_chipped_percent NUMERIC(5, 2),
    entry_method_swiped_percent NUMERIC(5, 2),
    
    authorizations_count INTEGER,
    authorizations_volume NUMERIC(14, 2),
    authorizations_declines_count INTEGER,
    authorizations_declines_volume NUMERIC(14, 2),
    authorizations_declines_percent NUMERIC(5, 2),
    
    debit_sales_count INTEGER,
    debit_sales_volume NUMERIC(14, 2),
    debit_sales_average_ticket NUMERIC(10, 2),
    debit_refunds_count INTEGER,
    debit_refunds_volume NUMERIC(14, 2),
    debit_refunds_average_ticket NUMERIC(10, 2),
    debit_disputes_count INTEGER,
    debit_disputes_volume NUMERIC(14, 2),
    debit_disputes_percent NUMERIC(5, 2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_merchant
        FOREIGN KEY (merchant_number) 
        REFERENCES merchant_details(Merchant_Number),
    
    CONSTRAINT unique_merchant_date
        UNIQUE (merchant_number, bucket_date)
);

CREATE INDEX idx_merchant_stats_merchant_number ON merchant_stats(merchant_number);
CREATE INDEX idx_merchant_stats_bucket_date ON merchant_stats(bucket_date);
CREATE INDEX idx_merchant_stats_merchant_bucket ON merchant_stats(merchant_number, bucket_date);

CREATE OR REPLACE FUNCTION update_merchant_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_merchant_stats_updated_at
    BEFORE UPDATE ON merchant_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_merchant_stats_updated_at();
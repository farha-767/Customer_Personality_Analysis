
-- create data_quality_rules Table

CREATE TABLE data_quality_rules (
    rule_id TEXT PRIMARY KEY,
    dimension TEXT,
    rule_description TEXT,
    target_column TEXT,
    acceptance_threshold DECIMAL(5,2)
)

-- Insert values to the table
INSERT INTO data_quality_rules VALUES
    ('DQ-01', 'Completeness', 'Income must not be NULL', 'income', 99.0),
    ('DQ-02', 'Validity', 'customer birth year must be >= 1920', 'year_birth', 100.0),
    ('DQ-03', 'Uniqueness', 'Customer ID must be unique', 'id', 100.0),
    ('DQ-04', 'Consistency', 'Customer marital status must be Standardized', 'marital_status', 98.0)

SELECT * FROM data_quality_rules

-- Implement Rule Check

ALTER TABLE customers_cleaned
ADD COLUMN dq_income_complete BOOLEAN,
ADD COLUMN dq_birth_year_valid BOOLEAN,
ADD COLUMN dq_marital_status_valid BOOLEAN;

UPDATE customers_cleaned
SET dq_income_complete = income IS NOT NULL;

UPDATE customers_cleaned
SET dq_birth_year_valid = year_birth >=1920;

UPDATE customers_cleaned
SET dq_marital_status_valid = marital_status IN ('Single','Married','Divorced','Widow','Other');

ALTER TABLE customers_cleaned
ADD COLUMN dq_customer_id_unique BOOLEAN;

UPDATE customers_cleaned
SET dq_customer_id_unique = id NOT IN (
    SELECT id
    FROM customers_cleaned
    GROUP BY id
    HAVING COUNT(*) > 1
);


-- DATA QUALITY SCORES

SELECT 
    'DQ-01 Income Completeness' AS rule,
    ROUND(100 * SUM(CASE WHEN dq_income_complete THEN 1 ELSE 0 END) / COUNT(*), 2) AS quality_score
FROM customers_cleaned;

SELECT
    'DQ-02 Birth Year Validity' AS rule,
    ROUND(100 * SUM(CASE WHEN dq_birth_year_valid THEN 1 ELSE 0 END) / COUNT(*), 2) AS quality_score
FROM customers_cleaned;

SELECT
    'DQ-03 Marital Status Validity' AS rule,
    ROUND(100 * SUM(CASE WHEN dq_marital_status_valid THEN 1 ELSE 0 END) / COUNT(*), 2) AS quality_score
FROM customers_cleaned;


-- Overall Data Quality Score

SELECT 
    ROUND(100.0 * (
        SUM(dq_income_complete::INT)+
        SUM(dq_birth_year_valid::INT)+
        SUM(dq_marital_status_valid::INT)) /
        (COUNT(*) * 3), 2) AS overall_dq_score
FROM customers_cleaned;

-- 99.85%

-- ISSUE REGISTER

CREATE TABLE data_quality_issues (
    issue_type TEXT,
    description TEXT,
    affected_records INT,
    resolution TEXT,
    status TEXT
)

INSERT INTO data_quality_issues
(issue_type, description, affected_records, resolution, status)
VALUES
(
  'Completeness',
  'Income missing in customer records',
  24,
  'Median income imputation with audit flag',
  'Resolved'
),
(
  'Validity',
  'Birth year below accepted threshold (year_birth < 1920)',
  3,
  'Records flagged (age_valid = FALSE) for business review',
  'Open'
),
(
  'Consistency', -- The DQ Dimension
  'Non-standard marital status found (YOLO, Absurd, Alone)', 
  (SELECT COUNT(*) FROM customers_raw WHERE marital_status NOT IN ('Single','Married','Divorced','Widow','Together')), -- Dynamic count
  'Standardized to "Other" or "Single" based on business rules', 
  'Resolved'
)
SELECT * FROM data_quality_issues


--METADATA

CREATE TABLE business_glossary (
    term_id TEXT PRIMARY KEY,
    business_term TEXT NOT NULL,
    definition TEXT NOT NULL,
    source_table TEXT,
    source_column TEXT,
    calculation_logic TEXT,
    data_owner TEXT,
    data_steward TEXT,
    last_updated DATE DEFAULT CURRENT_DATE
);



INSERT INTO business_glossary
(term_id, business_term, definition, source_table, source_column, calculation_logic, data_owner, data_steward)
VALUES
('BG001','Customer ID',
 'Unique identifier assigned to each customer.',
 'customers_cleaned','id',
 'System-generated unique value',
 'IT','Data Steward'),

('BG002','Customer Birth Year',
 'Year in which the customer was born.',
 'customers_cleaned','year_birth',
 'Validated to be >= 1920',
 'Marketing','Data Steward'),

('BG003','Customer Age Valid Flag',
 'Indicates whether customer birth year meets business validity rules.',
 'customers_cleaned','age_valid',
 'TRUE if year_birth >= 1920 else FALSE',
 'Marketing','Data Steward'),

('BG004','Customer Income',
 'Annual household income reported by the customer.',
 'customers_cleaned','income',
 'Median imputed where missing',
 'Finance','Data Steward'),

('BG005','Income Imputed Flag',
 'Indicates whether income was imputed due to missing value.',
 'customers_cleaned','income_imputed',
 'TRUE if income originally NULL',
 'Finance','Data Steward'),

('BG006','Marital Status',
 'Customer marital status used for segmentation.',
 'customers_cleaned','marital_status',
 'Standardized values applied',
 'Marketing','Data Steward'),

('BG007','Customer Recency',
 'Number of days since last purchase.',
 'customers_cleaned','recency',
 'Calculated from last transaction date',
 'Sales','Data Steward'),

('BG008','Data Quality Rule',
 'Business-defined expectation for data correctness.',
 'data_quality_rules',NULL,
 'Defined per rule',
 'Data Governance','Data Steward'),

('BG009','Data Quality Issue',
 'Logged instance of rule violation.',
 'data_quality_issues',NULL,
 'Detected during validation checks',
 'Data Governance','Data Steward'),

('BG010','Overall Data Quality Score',
 'Aggregated score representing data fitness for use.',
 'customers_cleaned',NULL,
 'Calculated using rule pass percentages',
 'Data Governance','Data Steward');


-- DATA DICTIONARY
 CREATE TABLE data_dictionary (
    table_name TEXT,
    column_name TEXT,
    data_type TEXT,
    nullable BOOLEAN,
    description TEXT
);
-- only key columns included
INSERT INTO data_dictionary
VALUES
('customers_cleaned','id','INTEGER',FALSE,'Unique customer identifier'),
('customers_cleaned','year_birth','INTEGER',TRUE,'Customer year of birth'),
('customers_cleaned','income','NUMERIC',TRUE,'Customer annual income'),
('customers_cleaned','age_valid','BOOLEAN',TRUE,'Birth year validity flag'),
('customers_cleaned','income_imputed','BOOLEAN',TRUE,'Income imputation indicator'),
('customers_cleaned','marital_status','TEXT',TRUE,'Standardized marital status');

CREATE VIEW dq_summary AS
SELECT
    COUNT(*) AS total_records,

    ROUND(100.0 * SUM(dq_income_complete::INT) / COUNT(*),2)
        AS income_completeness_pct,

    ROUND(100.0 * SUM(dq_birth_year_valid::INT) / COUNT(*),2)
        AS birth_year_validity_pct,

    ROUND(100.0 * SUM(dq_marital_status_valid::INT) / COUNT(*),2)
        AS marital_status_validity_pct,

    ROUND(100.0 * (
        SUM(dq_income_complete::INT) +
        SUM(dq_birth_year_valid::INT) +
        SUM(dq_marital_status_valid::INT)
    ) / (COUNT(*) * 3),2) AS overall_dq_score

FROM customers_cleaned;

SELECT * FROM dq_summary



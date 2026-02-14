/*
--------------------------------------------------------------------------------
PROJECT     : Customer Personality Analysis
FILE        : 04_data_cleaning_customers.sql
DESCRIPTION : Cleaning outliers, handling NULLs, and formatting dates.
AUTHOR      : Fathima Farha
DATE        : 2026-02-11
--------------------------------------------------------------------------------
*/

-- NOTE: No records are physically deleted in this step.
-- Invalid values are flagged to preserve auditability.

-- 1. CREATE CLEANED TABLE
-- Creating a copy of the raw data to perform cleaning operations safely.
CREATE TABLE customers_cleaned AS 
SELECT * FROM customers_raw;

-- 2. FLAG AGE OUTLIERS
-- Flaging customers born before 1920 as they are likely data entry errors.

ALTER TABLE customers_cleaned
ADD COLUMN age_valid BOOLEAN DEFAULT TRUE;

UPDATE customers_cleaned
SET age_valid = FALSE
WHERE year_birth < 1920;

-- 3. HANDLING NULL INCOME
-- We could fill them with the Median or remove rows where income is null

ALTER TABLE customers_cleaned
ADD COLUMN income_imputed BOOLEAN DEFAULT FALSE;

UPDATE customers_cleaned
SET income = (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY income)
                FROM customers_raw -- We calculate from the original raw data for accuracy
),
    income_imputed = TRUE
WHERE income IS NULL;

--check remaining income null values

SELECT COUNT(*) remaining_null_incomes
FROM customers_cleaned
WHERE income IS NULL;

-- 4. CLEANING MARITAL STATUS
-- Standardizing "Alone", "Absurd", and "YOLO" into a "Single" or "Other" category.
-- Business Rule: Non-standard marital statuses mapped to 'Single'

UPDATE customers_cleaned
SET marital_status = 'Single'
WHERE marital_status IN ('YOLO', 'Alone', 'Absurd');

UPDATE customers_cleaned
SET marital_status = 'Other'
WHERE marital_status = 'Together'

SELECT DISTINCT marital_status FROM customers_cleaned
--check if cleaned

SELECT DISTINCT marital_status
FROM customers_cleaned;


/*
-- Check cleaned table record count
SELECT 
    (SELECT COUNT(*) FROM customers_raw) AS raw_count,
    (SELECT COUNT(*) FROM customers_cleaned) AS cleaned_count,
    (SELECT COUNT(*) FROM customers_raw) - (SELECT COUNT(*) FROM customers_cleaned) AS rows_removed,
    ROUND(
        ((SELECT COUNT(*)::DECIMAL FROM customers_raw) - (SELECT COUNT(*) FROM customers_cleaned)) / 
        (SELECT COUNT(*) FROM customers_raw) * 100, 2
    ) AS percent_removed;

-- How many were removed because of age?
SELECT COUNT(*) FROM customers_raw WHERE year_birth < 1920;

-- How many had NULL income (before you imputed them)?
SELECT COUNT(*) FROM customers_raw WHERE income IS NULL;
*/
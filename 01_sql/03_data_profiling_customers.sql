/*
--------------------------------------------------------------------------------
PROJECT     : Customer Personality Analysis
FILE        : 03_data_profiling_customers.sql
DESCRIPTION : checks for nulls, duplicates, and data anomalies in customers_raw.
AUTHOR      : Fathima Farha
DATE        : 2026-02-11
--------------------------------------------------------------------------------
*/

-- 1. DATA VOLUME CHECK
-- Verify total number of records loaded from the csv file.

SELECT 
    COUNT(*) AS total_records,
    2240 AS expected
FROM customers_raw;
-- Found 2240  total records

--2. SCHEMA AND FORMAT VERIFICATION
-- Checking the first 5 rows to ensure columns and data types align correctly.

SELECT *
FROM customers_raw
LIMIT 5;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'customers_raw';


--3. UNIQUENESS CHECK
-- Identifying duplicate Customer IDs. A result of 0 is the goal.

SELECT id, COUNT(*) AS id_count
FROM customers_raw
GROUP BY id 
HAVING COUNT(*) > 1;
-- no duplicate records
-- identifying null ids if present
SELECT COUNT(*) AS null_ids
FROM customers_raw
WHERE id IS NULL;


--4. NULL VALUE ANALYSIS
-- Identifying columns with missing data that may require cleaning 

SELECT 
    ROUND(100.0 * (COUNT(*) - COUNT(year_birth))/ COUNT(*), 2) AS birth_year_missing_pct,
    ROUND(100.0 * (COUNT(*) - COUNT(income)) / COUNT(*), 2) AS income_missing_pct,
    ROUND(100.0 * (COUNT(*) - COUNT(dt_customer)) / COUNT(*), 2) AS enrollment_date_missing_pct
FROM customers_raw;
-- found 1.07 % of Incomes missing

--5. OUTLIER AND RANGE DETECTION
-- Checking for unrealistic values in key numeric columns.
SELECT 
    MAX(year_birth) AS youngest_customer_birth_year,
    MIN(year_birth) AS oldest_customer_birth_year,
    MAX(income) AS max_income,
    MIN(income) AS min_income,
    MAX(recency) AS max_recency,
    MIN(recency) AS min_recency
FROM customers_raw;

--Logical Birth Year and date Validation
SELECT *
FROM customers_raw
WHERE year_birth<=1920 OR year_birth < EXTRACT(YEAR FROM CURRENT_DATE);

SELECT *
FROM customers_raw
WHERE dt_customer < CURRENT_DATE;

--6. CATEGORICAL CONSISTENCY
-- analyse categorical fields typo errors or inconsistent naming

SELECT 
    education,
    COUNT(*) as cnt,
    LOWER(TRIM(education)) AS standardized_value
FROM customers_raw
GROUP BY 1
ORDER BY 2 DESC;

SELECT 
    marital_status,
    COUNT(*) AS cnt,
    LOWER(TRIM(marital_status)) AS standardized_value
FROM customers_raw
GROUP BY marital_status
ORDER BY cnt DESC;


/* 

--------------------------------------------------------------------------------------

KEY DATA QUALITY FINDINGS (PROFILING SUMMARY):

1. 1.07% income values missing (Completeness issue)

2. Birth years doesnot fall within logical range (Validity check failed)

3. No duplicate customer IDs (Uniqueness passed)

4. Minor inconsistencies in marital status categories (Consistency issue)

------------------------------------------------------------------------------------

*/

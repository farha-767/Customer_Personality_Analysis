
-- Import data from CSV file into the customers_raw table
-- run this in terminal
\copy customers_raw FROM 'C:/Customer_Personality_Analysis/csv_files/marketing_campaign.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t');

SELECT * FROM customers_raw;


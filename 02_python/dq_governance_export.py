import pandas as pd
from sqlalchemy import create_engine
import os

# Create output folder if not exists
os.makedirs("governance", exist_ok=True)

# Database connection
engine = create_engine(
    "postgresql://postgres:farha@localhost:5432/cust_personality_db"
)

# Tables to export
tables = {
    "business_glossary": "governance/business_glossary.xlsx",
    "data_dictionary": "governance/data_dictionary.xlsx",
    "data_quality_rules": "governance/dq_rules.xlsx",
    "data_quality_issues": "governance/issue_register.xlsx"
}

# Export tables
for table, file_path in tables.items():
    df = pd.read_sql(f"SELECT * FROM {table}", engine)
    df.to_excel(file_path, index=False)

print("Governance artifacts exported successfully.")

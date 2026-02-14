import pandas as pd
from sqlalchemy import create_engine

# 1. Create database connection
engine = create_engine(
    "postgresql://postgres:farha@localhost:5432/cust_personality_db"
)

# 2. Read Data Quality Summary
dq_summary = pd.read_sql(
    "SELECT * FROM dq_summary",
    engine
)

# 3. Read Data Quality Issues
dq_issues = pd.read_sql(
    "SELECT * FROM data_quality_issues",
    engine
)

# 4. Save to Excel
with pd.ExcelWriter("data_quality_report.xlsx") as writer:
    dq_summary.to_excel(writer, sheet_name="DQ Summary", index=False)
    dq_issues.to_excel(writer, sheet_name="DQ Issues", index=False)

print("Data Quality report generated successfully.")



# AI_SUCCESS_FEEDBACK Schema Setup Summary

## Status: ✅ SCHEMA AND TABLES CREATED

The following objects have been successfully created in Snowflake:

### Schema
- ✅ `CURSOR_DB.AI_SUCCESS_FEEDBACK` - Created successfully

### Tables (5/5 Created)
1. ✅ `PROBLEMATIC_SQL` - Tracks problematic SQL queries
2. ✅ `RESPONSE_STATUS_PATTERNS` - Tracks status code failures and patterns  
3. ✅ `WARNING_ISSUES` - Tracks recurring warning issues
4. ✅ `FEEDBACK_ANALYSIS` - Detailed feedback tracking
5. ✅ `SQL_QUALITY_DISCREPANCIES` - Tracks quality discrepancies

## Next Steps: EXECUTE SQL SCRIPTS

### To Complete the Setup:

#### Option 1: Execute via SnowSQL (Recommended)

```bash
cd /Users/afeider/AI_SUCCESS_FEEDBACK

# Execute views
snowsql -f 02_CREATE_VIEWS.sql

# Execute procedures and functions
snowsql -f 03_CREATE_PROCEDURES.sql
```

#### Option 2: Execute via Snowflake Web UI

1. Open Snowflake web interface
2. Navigate to Worksheets
3. Copy and paste the contents of each file:
   - `02_CREATE_VIEWS.sql` (creates 11 views)
   - `03_CREATE_PROCEDURES.sql` (creates 6 procedures and 2 functions)
4. Execute each file

#### Option 3: Execute via Python/Snowflake Connector

```python
import snowflake.connector

conn = snowflake.connector.connect(
    user='YOUR_USER',
    password='YOUR_PASSWORD',
    account='YOUR_ACCOUNT',
    warehouse='YOUR_WAREHOUSE',
    database='CURSOR_DB',
    schema='AI_SUCCESS_FEEDBACK'
)

cursor = conn.cursor()

# Execute views
with open('/Users/afeider/AI_SUCCESS_FEEDBACK/02_CREATE_VIEWS.sql', 'r') as f:
    for statement in f.read().split(';'):
        if statement.strip():
            cursor.execute(statement)

# Execute procedures
with open('/Users/afeider/AI_SUCCESS_FEEDBACK/03_CREATE_PROCEDURES.sql', 'r') as f:
    for statement in f.read().split('$$;'):
        if statement.strip():
            cursor.execute(statement + '$$;' if '$$' in statement else statement)

conn.close()
```

### Required Grants (Execute as ACCOUNTADMIN)

Before creating views and procedures, execute these grants:

```sql
USE ROLE ACCOUNTADMIN;

-- AI_QUESTION_INSIGHTS schema grants
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE SVC_CURSOR_ROLE;
GRANT SELECT ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY TO ROLE SVC_CURSOR_ROLE;
GRANT CREATE VIEW ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE SVC_CURSOR_ROLE;

-- AI_SUCCESS_FEEDBACK schema grants  
GRANT CREATE VIEW ON SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT CREATE PROCEDURE ON SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT CREATE FUNCTION ON SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT INSERT ON ALL TABLES IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT UPDATE ON ALL TABLES IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT DELETE ON ALL TABLES IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
```

## Post-Setup Verification

After executing the SQL scripts, verify the setup:

```sql
-- Verify views
SHOW VIEWS IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
-- Expected: 11 views

-- Verify procedures
SHOW PROCEDURES IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
-- Expected: 6 procedures

-- Verify functions
SHOW FUNCTIONS IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
-- Expected: 2 functions

-- Run initial analysis
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(7);
```

## Files Created

### AI_SUCCESS_FEEDBACK Folder
Location: `/Users/afeider/AI_SUCCESS_FEEDBACK/`

1. **00_EXECUTE_ALL.sh** - Shell script to execute all SQL files
2. **01_CREATE_TABLES.sql** - Table creation script (✅ Already executed in Snowflake)
3. **02_CREATE_VIEWS.sql** - View creation script for 7 insights (⏳ Needs execution)
4. **03_CREATE_PROCEDURES.sql** - Procedures and functions (⏳ Needs execution)
5. **README.md** - Comprehensive documentation with sample queries
6. **SETUP_SUMMARY.md** - This file

### AI_QUESTION_INSIGHTS Folder
Location: `/Users/afeider/AI_QUESTION_INSIGHTS/`

1. **00_GRANT_PERMISSIONS.sql** - Permission grants (⚠️ Execute as ACCOUNTADMIN first)
2. **01_CREATE_VIEWS.sql** - Enhanced views for base schema (⏳ Needs execution)

## Current Status

| Component | Status | Action Required |
|-----------|--------|-----------------|
| AI_SUCCESS_FEEDBACK Schema | ✅ Created | None |
| Tables (5) | ✅ Created | None |
| Views (11) | ⏳ Pending | Execute `02_CREATE_VIEWS.sql` |
| Procedures (6) | ⏳ Pending | Execute `03_CREATE_PROCEDURES.sql` |
| Functions (2) | ⏳ Pending | Execute `03_CREATE_PROCEDURES.sql` |
| AI_QUESTION_INSIGHTS Views (9) | ⏳ Pending | Execute `AI_QUESTION_INSIGHTS/01_CREATE_VIEWS.sql` |
| Permissions | ⚠️ Required | Execute `AI_QUESTION_INSIGHTS/00_GRANT_PERMISSIONS.sql` as ACCOUNTADMIN |

## Quick Start

1. **As ACCOUNTADMIN**, execute permissions:
   ```bash
   snowsql -f /Users/afeider/AI_QUESTION_INSIGHTS/00_GRANT_PERMISSIONS.sql
   ```

2. **As SVC_CURSOR_ROLE** (or your user), create views and procedures:
   ```bash
   snowsql -f /Users/afeider/AI_SUCCESS_FEEDBACK/02_CREATE_VIEWS.sql
   snowsql -f /Users/afeider/AI_SUCCESS_FEEDBACK/03_CREATE_PROCEDURES.sql
   snowsql -f /Users/afeider/AI_QUESTION_INSIGHTS/01_CREATE_VIEWS.sql
   ```

3. **Run initial analysis**:
   ```sql
   CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(7);
   ```

4. **Query insights** (see README.md for sample queries)

## Support

For detailed usage instructions and sample queries, see:
- **README.md** - Comprehensive documentation
- **Snowflake Documentation** - https://docs.snowflake.com/

## Troubleshooting

### Issue: CREATE VIEW fails with permission error
**Solution**: Execute the grants in `00_GRANT_PERMISSIONS.sql` as ACCOUNTADMIN

### Issue: Views query fails with "object does not exist"
**Solution**: Verify the base table exists:
```sql
SELECT COUNT(*) FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;
```

### Issue: Procedure execution fails
**Solution**: Ensure all tables and views are created first

---

**Created:** November 13, 2025  
**Database:** CURSOR_DB  
**Schema:** AI_SUCCESS_FEEDBACK




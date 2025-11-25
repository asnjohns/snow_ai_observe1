# AI Question Insights - Deployment Status

## Summary

I created the AI Question Insights framework in `CURSOR_DB.AI_QUESTION_INSIGHTS` schema. Due to MCP (Model Context Protocol) connection limitations, some objects were created automatically while others require manual execution in Snowflake.

---

## ✅ Successfully Created (Via MCP)

### Schema
- ✅ `CURSOR_DB.AI_QUESTION_INSIGHTS` - Main schema for all objects

### Tables
- ✅ `CORTEX_ANALYST_REQUEST_HISTORY` - Base table with 17 columns
  - Primary Key: `(REQUEST_ID, TIMESTAMP)`
  - Status: Created and ready for data
  - Current rows: 0 (empty - needs data load)

### Views (8 of 9)
| View Name | Status | Purpose |
|-----------|--------|---------|
| `VW_RECENT_REQUESTS` | ✅ Created | Last 100 requests with key metrics |
| `VW_DAILY_ACTIVITY` | ✅ Created | Daily aggregated statistics |
| `VW_USER_LEADERBOARD` | ✅ Created | User activity rankings |
| `VW_TABLE_USAGE` | ✅ Created | Table reference frequency |
| `VW_ERROR_ANALYSIS` | ✅ Created | Failed requests for troubleshooting |
| `VW_FEEDBACK_SUMMARY` | ❌ **Needs Manual Creation** | User feedback aggregation |
| `VW_SEMANTIC_MODEL_PERFORMANCE` | ✅ Created | Performance by semantic model |
| `VW_HOURLY_ACTIVITY` | ✅ Created | Peak usage hours |
| `VW_COMPLEXITY_DISTRIBUTION` | ✅ Created | Query complexity breakdown |

**Note**: 8 out of 9 views are ready to use. Only `VW_FEEDBACK_SUMMARY` needs manual creation.

---

## ❌ Requires Manual Creation (In Snowflake UI)

### Views (1)
- ❌ `VW_FEEDBACK_SUMMARY` - MCP permissions prevented creation

### Stored Procedures (5)
All stored procedures must be created manually as MCP does not support `CREATE PROCEDURE`:

1. ❌ `REFRESH_CORTEX_ANALYST_HISTORY` - Data loading from CORTEX_ANALYST_REQUESTS
2. ❌ `GET_USER_QUESTION_PATTERNS` - User activity and behavior analysis
3. ❌ `GET_TABLE_JOIN_USAGE_ANALYSIS` - Table and join frequency analysis
4. ❌ `GET_QUESTION_THEMES_ANALYSIS` - Question theme classification
5. ❌ `GET_SQL_PATTERN_ANALYSIS` - SQL pattern detection and analysis

---

## 📋 Next Steps to Complete Deployment

### Option 1: Quick Manual Deployment (Recommended)

Execute these files in Snowflake in order:

```sql
-- 1. Create missing view and first 2 procedures
-- Execute: MANUAL_DEPLOYMENT.sql

-- 2. Create remaining 3 procedures
-- Execute: 03_insight_table_usage_proc.sql
-- Execute: 04_insight_question_themes_proc.sql
-- Execute: 05_insight_sql_patterns_proc.sql

-- 3. Load initial data (replace with your semantic model)
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'SEMANTIC_VIEW',
    'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
    FALSE
);
```

### Option 2: Complete Automated Deployment

If you prefer to deploy everything fresh from scratch:

```sql
-- Execute entire file: 00_deploy_all.sql
-- Then execute files 01-05 individually
```

---

## 🎯 Current Deployment Statistics

| Object Type | Total Needed | Created via MCP | Manual Required | % Complete |
|-------------|--------------|-----------------|-----------------|------------|
| Schemas | 1 | 1 | 0 | 100% |
| Tables | 1 | 1 | 0 | 100% |
| Views | 9 | 8 | 1 | 89% |
| Stored Procedures | 5 | 0 | 5 | 0% |
| **TOTAL** | **16** | **10** | **6** | **63%** |

---

## 🔍 Why Some Objects Weren't Created

### MCP Connection Limitations

The Snowflake MCP (Model Context Protocol) connection I'm using has restricted permissions:

1. **Views**: Most views work, but complex CTEs with certain syntax can fail
2. **Stored Procedures**: `CREATE PROCEDURE` statements are blocked entirely
3. **Security**: This is by design to prevent unintended code execution

### What This Means

- ✅ **Infrastructure**: Schema and tables are production-ready
- ✅ **Most Views**: 8/9 views are working and queryable
- ❌ **Business Logic**: Stored procedures need your manual deployment
- ❌ **1 Complex View**: VW_FEEDBACK_SUMMARY needs manual creation

---

## 📂 Files Available for Manual Deployment

All SQL files are in: `~/AI_Question_Insights/`

### Essential Deployment Files:
- **`MANUAL_DEPLOYMENT.sql`** ⭐ - Missing view + 2 key procedures
- **`03_insight_table_usage_proc.sql`** - Table usage analysis procedure
- **`04_insight_question_themes_proc.sql`** - Question themes procedure
- **`05_insight_sql_patterns_proc.sql`** - SQL patterns procedure

### Alternative (Full Deployment):
- **`00_deploy_all.sql`** - Base infrastructure (already done via MCP)
- **`01_refresh_analyst_history_proc.sql`** - Data refresh procedure
- **`02_insight_user_patterns_proc.sql`** - User patterns procedure
- **`03-05`** - Same as above

### Documentation:
- **`README.md`** - Complete framework documentation
- **`QUICKSTART.md`** - 5-minute getting started guide
- **`DEPLOYMENT_CHECKLIST.md`** - Step-by-step deployment tracker
- **`07_sample_queries.sql`** - 50+ usage examples

---

## ⚡ Fastest Path to Working System

**Time: 3-5 minutes**

1. **Open Snowflake UI** → Navigate to Worksheets
2. **Copy/Paste** contents of `MANUAL_DEPLOYMENT.sql` → Execute
3. **Copy/Paste** contents of `03_insight_table_usage_proc.sql` → Execute
4. **Copy/Paste** contents of `04_insight_question_themes_proc.sql` → Execute
5. **Copy/Paste** contents of `05_insight_sql_patterns_proc.sql` → Execute
6. **Run data load**:
   ```sql
   CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
       'SEMANTIC_VIEW',
       'YOUR_DATABASE.YOUR_SCHEMA.YOUR_MODEL',
       FALSE
   );
   ```
7. **Test**:
   ```sql
   -- Verify setup
   SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_RECENT_REQUESTS LIMIT 5;
   
   -- Run first insight
   CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);
   ```

---

## ✅ Verification Commands

After manual deployment, run these to verify:

```sql
-- Check all objects exist
SELECT 'Views' as object_type, COUNT(*)::STRING as count
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'AI_QUESTION_INSIGHTS'
UNION ALL
SELECT 'Tables', COUNT(*)::STRING
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'AI_QUESTION_INSIGHTS' AND TABLE_TYPE = 'BASE TABLE'
UNION ALL
SELECT 'Procedures', COUNT(*)::STRING
FROM INFORMATION_SCHEMA.PROCEDURES 
WHERE PROCEDURE_SCHEMA = 'AI_QUESTION_INSIGHTS';

-- Expected results:
-- Views: 9
-- Tables: 1
-- Procedures: 5
```

```sql
-- Test a view
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_USER_LEADERBOARD LIMIT 5;

-- Test a procedure
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);
```

---

## 🎓 Understanding the Architecture

### What's Already Working:
- **Data Layer**: Table structure ready to store all Cortex Analyst history
- **Presentation Layer**: 8 views provide instant insights on existing data
- **Schema**: Properly organized and commented

### What Needs Completion:
- **Business Logic Layer**: 5 stored procedures that perform complex analysis
- **1 Complex View**: Feedback aggregation view

### Once Complete:
- **Full 4-category insights**: User patterns, table usage, question themes, SQL patterns
- **Automated data refresh**: Incremental loading from Cortex Analyst
- **Production-ready**: All components operational

---

## 📞 Support

If you encounter issues during manual deployment:

1. **Check Permissions**: Ensure you have `CREATE PROCEDURE` privilege
2. **Check Syntax**: Snowflake may require slight SQL adjustments for your account version
3. **Check Semantic Model**: Verify your semantic model name is correct
4. **Review Errors**: Most errors are due to missing semicolons or typos

Common fixes:
```sql
-- If permission error:
GRANT CREATE PROCEDURE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <your_role>;

-- If semantic model not found:
SHOW VIEWS IN <your_database>.<your_schema>;  -- Find your model

-- If table is empty:
SELECT COUNT(*) FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;
-- Should be > 0 after running REFRESH_CORTEX_ANALYST_HISTORY
```

---

## 📊 What You'll Get After Completion

### Immediate Capabilities:
- ✅ Track all Cortex Analyst usage
- ✅ Identify your power users
- ✅ See which tables are most/least used
- ✅ Understand what questions users ask
- ✅ Analyze SQL pattern trends
- ✅ Monitor errors and feedback
- ✅ Track model performance

### Ready for:
- 📊 BI tool integration (Tableau, Power BI, Looker)
- 🎨 Streamlit dashboard (Phase 2)
- 📧 Automated reports and alerts
- 🔍 Deep-dive analysis and optimization

---

**Status Date**: November 13, 2024  
**Deployment Method**: Hybrid (MCP + Manual)  
**Completion**: 63% (10/16 objects created)

---

**Next Action**: Execute `MANUAL_DEPLOYMENT.sql` in Snowflake to reach 75% completion in 2 minutes! 🚀


# Quick Start Guide - AI Question Insights

## ⚡ Get Started in 5 Minutes

### Step 1: Deploy Base Components (2 minutes)

Execute the base deployment script in Snowflake:

```sql
-- Copy and paste the entire contents of 00_deploy_all.sql into Snowflake
-- This creates:
--   - AI_QUESTION_INSIGHTS schema
--   - CORTEX_ANALYST_REQUEST_HISTORY base table
--   - 9 helper views
```

**Location**: `00_deploy_all.sql`

### Step 2: Create Stored Procedures (2 minutes)

Execute each of the following files **separately** in Snowflake (in order):

1. ✅ `01_refresh_analyst_history_proc.sql` - Data loading procedure
2. ✅ `02_insight_user_patterns_proc.sql` - User activity analysis
3. ✅ `03_insight_table_usage_proc.sql` - Table usage analysis
4. ✅ `04_insight_question_themes_proc.sql` - Question theme analysis
5. ✅ `05_insight_sql_patterns_proc.sql` - SQL pattern analysis

**Why separate?** Snowflake requires stored procedures to be created individually.

### Step 3: Load Your Data (1 minute)

Replace with your actual semantic model name:

```sql
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'SEMANTIC_VIEW',
    'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',  -- Replace with your model
    FALSE  -- Full load
);
```

### Step 4: Run Your First Insight! (30 seconds)

```sql
-- See your most active users
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);

-- See which tables are being used
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 20);

-- See common question themes
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 15);

-- See SQL patterns
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 20);
```

---

## 🔍 Quick Reference

### Most Useful Views

```sql
-- Recent activity
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_RECENT_REQUESTS LIMIT 20;

-- Daily trends
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_DAILY_ACTIVITY 
WHERE activity_date >= DATEADD('day', -7, CURRENT_DATE());

-- User leaderboard
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_USER_LEADERBOARD LIMIT 10;

-- Error analysis
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_ERROR_ANALYSIS
WHERE TIMESTAMP >= DATEADD('day', -1, CURRENT_TIMESTAMP());
```

### Scheduled Data Refresh

Set up a daily task to keep data fresh:

```sql
CREATE OR REPLACE TASK CURSOR_DB.AI_QUESTION_INSIGHTS.DAILY_REFRESH
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 1 * * * America/Los_Angeles'
AS
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
      'SEMANTIC_VIEW',
      'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
      TRUE  -- Incremental
  );

-- Start the task
ALTER TASK CURSOR_DB.AI_QUESTION_INSIGHTS.DAILY_REFRESH RESUME;
```

---

## 📊 What Can I Analyze?

### 1. User Behavior
- Who are my power users?
- When do users ask questions?
- What's the user satisfaction rate?

### 2. Data Usage
- Which tables are most/least used?
- What are common join patterns?
- Which tables should I optimize?

### 3. Question Patterns
- What types of questions do users ask?
- Which question types fail most often?
- What are trending question themes?

### 4. SQL Quality
- What SQL patterns does Cortex generate?
- Which patterns have low success rates?
- Are queries getting more complex over time?

---

## 🚨 Common Issues

### Issue: No data in tables
**Solution**: Make sure you ran the `REFRESH_CORTEX_ANALYST_HISTORY` procedure with the correct semantic model name.

### Issue: Stored procedure creation fails
**Solution**: Ensure you're running each procedure file separately, not all at once.

### Issue: Permission errors
**Solution**: Verify you have `USAGE` privilege on `SNOWFLAKE.LOCAL` schema:
```sql
SHOW GRANTS TO USER <your_username>;
```

---

## 📁 File Structure

```
AI_Question_Insights/
├── README.md                              # Full documentation
├── QUICKSTART.md                          # This file
├── 00_deploy_all.sql                      # Base deployment
├── 01_refresh_analyst_history_proc.sql    # Data loader
├── 02_insight_user_patterns_proc.sql      # User insights
├── 03_insight_table_usage_proc.sql        # Table insights
├── 04_insight_question_themes_proc.sql    # Question insights
├── 05_insight_sql_patterns_proc.sql       # SQL insights
├── 06_helper_views.sql                    # Convenience views (in deploy_all)
└── 07_sample_queries.sql                  # Usage examples
```

---

## 🎯 Next Steps

1. ✅ **Daily**: Check `VW_RECENT_REQUESTS` and `VW_ERROR_ANALYSIS`
2. ✅ **Weekly**: Run all 4 insight procedures and save results
3. ✅ **Monthly**: Review underutilized tables and optimize semantic models
4. ✅ **Future**: Build Streamlit dashboard (coming in Phase 2)

---

## 💡 Pro Tips

1. **Save snapshots**: Create weekly snapshot tables for trend analysis
   ```sql
   CREATE TABLE SNAPSHOT_2024_11_13 AS
   SELECT * FROM TABLE(GET_USER_QUESTION_PATTERNS(30, 100));
   ```

2. **Set up alerts**: Monitor error rates and negative feedback
3. **Cluster your data**: If you have lots of history, add clustering
   ```sql
   ALTER TABLE CORTEX_ANALYST_REQUEST_HISTORY CLUSTER BY (TIMESTAMP);
   ```

4. **Export for BI tools**: All views and procedures work great with Tableau, Power BI, and Streamlit

---

## 📖 More Information

For detailed documentation, see **README.md**

For comprehensive query examples, see **07_sample_queries.sql**

---

**Ready to build insights! 🚀**


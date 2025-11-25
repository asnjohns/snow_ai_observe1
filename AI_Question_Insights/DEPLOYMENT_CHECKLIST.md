# AI Question Insights - Deployment Checklist

Use this checklist to track your deployment progress.

---

## Pre-Deployment Checklist

- [ ] Snowflake account with Cortex Analyst enabled
- [ ] Database `CURSOR_DB` exists (or modified scripts to use your database)
- [ ] You have the following privileges:
  - [ ] CREATE SCHEMA on database
  - [ ] CREATE TABLE on schema
  - [ ] CREATE VIEW on schema
  - [ ] CREATE PROCEDURE on schema
  - [ ] USAGE on SNOWFLAKE.LOCAL schema
- [ ] At least one Cortex Analyst semantic model or semantic view exists
- [ ] You know the fully qualified name of your semantic model

**Your Semantic Model**: `____________________________________`

---

## Deployment Steps

### Phase 1: Base Infrastructure

- [ ] **Step 1.1**: Open Snowflake in web browser
- [ ] **Step 1.2**: Select appropriate warehouse (e.g., COMPUTE_WH)
- [ ] **Step 1.3**: Open `00_deploy_all.sql` file
- [ ] **Step 1.4**: Copy entire contents to Snowflake worksheet
- [ ] **Step 1.5**: Execute the script
- [ ] **Step 1.6**: Verify success:
  ```sql
  SHOW SCHEMAS IN CURSOR_DB LIKE 'AI_QUESTION_INSIGHTS';
  SHOW TABLES IN CURSOR_DB.AI_QUESTION_INSIGHTS;
  SHOW VIEWS IN CURSOR_DB.AI_QUESTION_INSIGHTS;
  ```
  - Expected: 1 schema, 1 table, 9 views

---

### Phase 2: Stored Procedures

Execute each file separately in order:

- [ ] **Step 2.1**: Execute `01_refresh_analyst_history_proc.sql`
  - [ ] No errors
  - [ ] Procedure created successfully

- [ ] **Step 2.2**: Execute `02_insight_user_patterns_proc.sql`
  - [ ] No errors
  - [ ] Procedure created successfully

- [ ] **Step 2.3**: Execute `03_insight_table_usage_proc.sql`
  - [ ] No errors
  - [ ] Procedure created successfully

- [ ] **Step 2.4**: Execute `04_insight_question_themes_proc.sql`
  - [ ] No errors
  - [ ] Procedure created successfully

- [ ] **Step 2.5**: Execute `05_insight_sql_patterns_proc.sql`
  - [ ] No errors
  - [ ] Procedure created successfully

- [ ] **Step 2.6**: Verify all procedures exist:
  ```sql
  SHOW PROCEDURES IN CURSOR_DB.AI_QUESTION_INSIGHTS;
  ```
  - Expected: 5 procedures

---

### Phase 3: Initial Data Load

- [ ] **Step 3.1**: Identify your semantic model name
  ```sql
  -- For semantic views:
  SHOW VIEWS IN <your_database>.<your_schema>;
  
  -- For file-based models:
  LIST @<your_stage>;
  ```

- [ ] **Step 3.2**: Run first data load (update with your model name):
  ```sql
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
      'SEMANTIC_VIEW',  -- or 'FILE_ON_STAGE'
      'YOUR_DATABASE.YOUR_SCHEMA.YOUR_MODEL',  -- UPDATE THIS
      FALSE  -- Full load
  );
  ```

- [ ] **Step 3.3**: Verify data loaded:
  ```sql
  SELECT COUNT(*), MIN(TIMESTAMP), MAX(TIMESTAMP)
  FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;
  ```
  - Expected: Row count > 0

---

### Phase 4: Validation Testing

Run each insight procedure to verify functionality:

- [ ] **Test 4.1**: User Patterns
  ```sql
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);
  ```
  - [ ] Returns results without errors

- [ ] **Test 4.2**: Table Usage
  ```sql
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 20);
  ```
  - [ ] Returns results without errors

- [ ] **Test 4.3**: Question Themes
  ```sql
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 15);
  ```
  - [ ] Returns results without errors

- [ ] **Test 4.4**: SQL Patterns
  ```sql
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 20);
  ```
  - [ ] Returns results without errors

---

### Phase 5: Helper Views Validation

Test each view:

- [ ] **View 5.1**: Recent Requests
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_RECENT_REQUESTS LIMIT 10;
  ```

- [ ] **View 5.2**: Daily Activity
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_DAILY_ACTIVITY LIMIT 10;
  ```

- [ ] **View 5.3**: User Leaderboard
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_USER_LEADERBOARD LIMIT 10;
  ```

- [ ] **View 5.4**: Table Usage
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_TABLE_USAGE LIMIT 10;
  ```

- [ ] **View 5.5**: Error Analysis
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_ERROR_ANALYSIS LIMIT 10;
  ```

- [ ] **View 5.6**: Feedback Summary
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_FEEDBACK_SUMMARY LIMIT 10;
  ```

- [ ] **View 5.7**: Semantic Model Performance
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_SEMANTIC_MODEL_PERFORMANCE;
  ```

- [ ] **View 5.8**: Hourly Activity
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_HOURLY_ACTIVITY LIMIT 10;
  ```

- [ ] **View 5.9**: Complexity Distribution
  ```sql
  SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_COMPLEXITY_DISTRIBUTION;
  ```

---

### Phase 6: Automation (Optional but Recommended)

- [ ] **Step 6.1**: Create scheduled task for data refresh
  ```sql
  CREATE OR REPLACE TASK CURSOR_DB.AI_QUESTION_INSIGHTS.DAILY_REFRESH
    WAREHOUSE = COMPUTE_WH  -- Update with your warehouse
    SCHEDULE = 'USING CRON 0 1 * * * America/Los_Angeles'  -- Update timezone
  AS
    CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
        'SEMANTIC_VIEW',  -- Update with your model type
        'YOUR_DATABASE.YOUR_SCHEMA.YOUR_MODEL',  -- Update with your model
        TRUE  -- Incremental load
    );
  ```

- [ ] **Step 6.2**: Resume the task
  ```sql
  ALTER TASK CURSOR_DB.AI_QUESTION_INSIGHTS.DAILY_REFRESH RESUME;
  ```

- [ ] **Step 6.3**: Verify task is running
  ```sql
  SHOW TASKS IN CURSOR_DB.AI_QUESTION_INSIGHTS;
  ```

---

## Post-Deployment Checklist

- [ ] Documentation reviewed: `README.md`
- [ ] Quick start guide reviewed: `QUICKSTART.md`
- [ ] Sample queries reviewed: `07_sample_queries.sql`
- [ ] Team members granted access to schema:
  ```sql
  GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <your_role>;
  GRANT SELECT ON ALL TABLES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <your_role>;
  GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <your_role>;
  ```
- [ ] Scheduled reports configured (optional)
- [ ] Dashboard/BI tool connected (optional)
- [ ] Monitoring alerts configured (optional)

---

## Troubleshooting

If you encounter issues during deployment:

### Common Issue 1: Permission Denied
**Error**: `SQL compilation error: Insufficient privileges...`

**Solution**: 
```sql
-- Check your privileges
SHOW GRANTS TO USER CURRENT_USER();

-- Request necessary privileges from your admin
```

### Common Issue 2: Object Already Exists
**Error**: `Object already exists...`

**Solution**: Use `CREATE OR REPLACE` or drop existing object first

### Common Issue 3: No Data After Refresh
**Error**: No error, but COUNT(*) = 0

**Solution**: 
1. Verify semantic model name is correct
2. Check if there's actual Cortex Analyst usage history
3. Verify permissions on SNOWFLAKE.LOCAL schema

---

## Success Criteria

✅ **Deployment is successful when:**
- All 5 stored procedures execute without errors
- All 9 views return data (or empty results if no historical data)
- At least one insight procedure returns meaningful results
- Scheduled task is running (if configured)

---

## Next Steps After Deployment

1. **Week 1**: Familiarize yourself with the views and stored procedures
2. **Week 2**: Start generating weekly reports
3. **Week 3**: Identify optimization opportunities from insights
4. **Week 4**: Begin building Streamlit dashboard (Phase 2)

---

## Deployment Notes

**Deployed by**: `____________________`

**Date**: `____________________`

**Semantic Model(s)**: 
- `____________________________________`
- `____________________________________`

**Warehouse Used**: `____________________`

**Issues Encountered**: 
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Resolution**: 
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sign-Off

- [ ] Deployment completed successfully
- [ ] All tests passed
- [ ] Documentation reviewed
- [ ] Team notified

**Deployed By**: `____________________`  
**Date**: `____________________`  
**Approved By**: `____________________`

---

**🎉 Congratulations on deploying AI Question Insights!**


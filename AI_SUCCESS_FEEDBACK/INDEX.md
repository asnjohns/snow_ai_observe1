# AI_SUCCESS_FEEDBACK - File Index

## Quick Navigation

| File | Purpose | Status | Execute Order |
|------|---------|--------|---------------|
| **INDEX.md** | This file - navigation guide | - |
| **README.md** | Complete documentation | Read First |
| **01_CREATE_TABLES.sql** | Table definitions | Execute 1st  |
| **02_CREATE_VIEWS.sql** | View definitions for 7 insights | Execute 2nd |
| **03_CREATE_PROCEDURES.sql** | Procedures and functions | Execute 3rd |


### Snowflake Web UI
Copy and paste each SQL file's contents into a Snowflake worksheet and execute.

## The 7 Insights

1. **Problematic SQL Analysis** - `VW_PROBLEMATIC_SQL_ANALYSIS`
2. **Response Status Failures** - `VW_RESPONSE_STATUS_FAILURES`, `VW_STATUS_CODE_TRENDS`
3. **Warning Patterns** - `VW_WARNING_PATTERNS`, `VW_WARNING_SUMMARY`
4. **Feedback Rates by Model** - `VW_FEEDBACK_RATES_BY_MODEL`
5. **Question Type Performance** - `VW_POOR_FEEDBACK_BY_QUESTION_TYPE`
6. **Complexity vs Satisfaction** - `VW_COMPLEXITY_SATISFACTION_CORRELATION`, `VW_COMPLEXITY_SATISFACTION_SUMMARY`
7. **Expectation Gaps** - `VW_CORRECTNESS_EXPECTATION_GAPS`, `VW_EXPECTATION_GAP_SUMMARY`

## Quick Start (After Execution)

## File Descriptions

### README.md
Complete documentation including:
- Architecture overview
- Detailed description of 7 insights
- Setup instructions
- Sample queries for each insight
- Streamlit visualization recommendations
- Maintenance procedures
- Troubleshooting guide
- Object reference

### 01_CREATE_TABLES.sql 
Creates 5 tracking tables:
- PROBLEMATIC_SQL
- RESPONSE_STATUS_PATTERNS
- WARNING_ISSUES
- FEEDBACK_ANALYSIS
- SQL_QUALITY_DISCREPANCIES

### 02_CREATE_VIEWS.sql 
Creates 11 analytical views covering all 7 insights:
- Insight 1: VW_PROBLEMATIC_SQL_ANALYSIS
- Insight 2: VW_RESPONSE_STATUS_FAILURES, VW_STATUS_CODE_TRENDS
- Insight 3: VW_WARNING_PATTERNS, VW_WARNING_SUMMARY
- Insight 4: VW_FEEDBACK_RATES_BY_MODEL
- Insight 5: VW_POOR_FEEDBACK_BY_QUESTION_TYPE
- Insight 6: VW_COMPLEXITY_SATISFACTION_CORRELATION, VW_COMPLEXITY_SATISFACTION_SUMMARY
- Insight 7: VW_CORRECTNESS_EXPECTATION_GAPS, VW_EXPECTATION_GAP_SUMMARY

### 03_CREATE_PROCEDURES.sql 
Creates 6 stored procedures and 2 functions:

**Procedures:**
- SP_IDENTIFY_PROBLEMATIC_SQL(LOOKBACK_HOURS)
- SP_ANALYZE_STATUS_PATTERNS(LOOKBACK_DAYS)
- SP_ANALYZE_WARNING_PATTERNS(LOOKBACK_DAYS)
- SP_ANALYZE_FEEDBACK_PATTERNS(LOOKBACK_DAYS)
- SP_IDENTIFY_QUALITY_DISCREPANCIES(LOOKBACK_HOURS)
- SP_RUN_ALL_ANALYSES(LOOKBACK_DAYS) - Master procedure

**Functions:**
- FN_CALCULATE_SQL_COMPLEXITY(SQL_TEXT) - Returns complexity score
- FN_CATEGORIZE_COMPLEXITY(COMPLEXITY_SCORE) - Returns SIMPLE/MODERATE/COMPLEX

## Next Steps After Execution

1. **Verify Setup**
   ```sql
   SHOW VIEWS IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
   SHOW PROCEDURES IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
   SHOW FUNCTIONS IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
   ```

2. **Run Initial Analysis**
   ```sql
   CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(7);
   ```

3. **Query Insights** (See README.md for comprehensive sample queries)

4. **Build Streamlit Dashboard** (See README.md for recommendations)

5. **Schedule Regular Analysis** (Create Snowflake task)
   ```sql
   CREATE TASK CURSOR_DB.AI_SUCCESS_FEEDBACK.DAILY_ANALYSIS
   WAREHOUSE = YOUR_WAREHOUSE
   SCHEDULE = 'USING CRON 0 2 * * * America/Los_Angeles'
   AS
   CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(7);
   ```

## Questions or Issues?

Refer to:
- **README.md** for complete documentation and sample queries
- Snowflake documentation: https://docs.snowflake.com/

---

**Created:** November 13, 2025  
**Database:** CURSOR_DB  
**Schema:** AI_SUCCESS_FEEDBACK  
**Purpose:** AI/ML Success Metrics and Feedback Analytics




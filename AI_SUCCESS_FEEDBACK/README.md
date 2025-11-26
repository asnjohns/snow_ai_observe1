# AI Success Feedback Analytics

## Overview

The `AI_SUCCESS_FEEDBACK` schema provides comprehensive analytics and insights for Cortex Analyst request history, enabling data-driven improvements to AI/ML model performance and user satisfaction.

This schema works in conjunction with the `AI_QUESTION_INSIGHTS` schema, which contains the base `CORTEX_ANALYST_REQUEST_HISTORY` table.

## Architecture

### Schema Structure

```
CURSOR_DB
├── AI_QUESTION_INSIGHTS/          (Base schema with request history)
│   ├── CORTEX_ANALYST_REQUEST_HISTORY (table)
│   └── Views (9 analytical views)
│
└── AI_SUCCESS_FEEDBACK/           (Analytics and feedback schema)
    ├── Tables (5)
    ├── Views (11 for 7 insights)
    ├── Stored Procedures (6)
    └── Functions (2)
```

## Seven Key Insights

### 1. **Problematic SQL Analysis**
Identifies and categorizes SQL queries that fail, have warnings, or are overly complex.

**Key Views:**
- `VW_PROBLEMATIC_SQL_ANALYSIS` - Detailed analysis of problematic queries
- Table: `PROBLEMATIC_SQL` - Tracking table for problem resolution

**Key Metrics:**
- SQL complexity score
- Problem type categorization
- Warning counts
- Feedback correlation

### 2. **Response Status Code Failures and Patterns**
Tracks HTTP response status codes to identify failure patterns and trends.

**Key Views:**
- `VW_RESPONSE_STATUS_FAILURES` - Failure patterns by model and time
- `VW_STATUS_CODE_TRENDS` - Trend analysis over time
- Table: `RESPONSE_STATUS_PATTERNS` - Pattern tracking

**Key Metrics:**
- Failure rate by status code
- Affected users and models
- Temporal patterns

### 3. **Warning Analysis**
Analyzes the `WARNINGS` field for recurring issues and patterns.

**Key Views:**
- `VW_WARNING_PATTERNS` - Detailed warning patterns
- `VW_WARNING_SUMMARY` - Aggregated warning statistics
- Table: `WARNING_ISSUES` - Warning tracking with severity

**Key Metrics:**
- Warning frequency and distribution
- Affected models and users
- Severity classification

### 4. **Feedback Rates by Semantic Model**
Tracks positive vs. negative feedback rates by semantic model using the `FEEDBACK` array.

**Key Views:**
- `VW_FEEDBACK_RATES_BY_MODEL` - Model-level feedback metrics

**Key Metrics:**
- Feedback rate percentage
- Success rate correlation
- User engagement levels

### 5. **Question Type Analysis**
Identifies which types of questions receive poor feedback.

**Key Views:**
- `VW_POOR_FEEDBACK_BY_QUESTION_TYPE` - Question type performance

**Key Metrics:**
- Failure rate by question type
- Average complexity by type
- Question categorization (COUNT, AGGREGATION, TREND, etc.)

### 6. **SQL Complexity vs. User Satisfaction**
Correlates SQL complexity with user satisfaction using the `FEEDBACK` array.

**Key Views:**
- `VW_COMPLEXITY_SATISFACTION_CORRELATION` - Detailed correlation
- `VW_COMPLEXITY_SATISFACTION_SUMMARY` - Aggregated metrics

**Key Metrics:**
- Complexity score calculation
- Dissatisfaction score
- Success rate by complexity category

### 7. **Correctness vs. Expectation Gaps**
Finds discrepancies between technically correct SQL and user expectations.

**Key Views:**
- `VW_CORRECTNESS_EXPECTATION_GAPS` - Detailed gap analysis
- `VW_EXPECTATION_GAP_SUMMARY` - Summary metrics

**Key Metrics:**
- Technically correct but unsatisfactory queries
- Gap rate percentage
- Discrepancy type classification

## Setup Instructions

### Prerequisites

1. **Permissions**: Ensure you have the necessary permissions on `CURSOR_DB` database
2. **SnowSQL**: Install SnowSQL CLI (optional, for batch execution)
3. **Grants**: Execute the grants in `AI_QUESTION_INSIGHTS/00_GRANT_PERMISSIONS.sql` as `ACCOUNTADMIN`

### Installation

#### Option 1: Execute All Scripts at Once (Recommended)

```bash
cd /Users/afeider/AI_SUCCESS_FEEDBACK
./00_EXECUTE_ALL.sh
```

#### Option 2: Manual Execution

Execute the SQL scripts in order:

```sql
-- 1. Create tables
@/Users/afeider/AI_SUCCESS_FEEDBACK/01_CREATE_TABLES.sql

-- 2. Create views
@/Users/afeider/AI_SUCCESS_FEEDBACK/02_CREATE_VIEWS.sql

-- 3. Create procedures and functions
@/Users/afeider/AI_SUCCESS_FEEDBACK/03_CREATE_PROCEDURES.sql
```

### Verification

```sql
-- Verify schema creation
SHOW SCHEMAS IN CURSOR_DB;

-- Verify objects
SHOW TABLES IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
SHOW VIEWS IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
SHOW PROCEDURES IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
SHOW FUNCTIONS IN CURSOR_DB.AI_SUCCESS_FEEDBACK;
```

## Usage Guide

### Running Analyses

#### Initial Full Analysis
```sql
-- Analyze last 7 days of data
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(7);
```

#### Individual Analyses
```sql
-- Identify problematic SQL from last 24 hours
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_IDENTIFY_PROBLEMATIC_SQL(24);

-- Analyze status code patterns from last 30 days
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_STATUS_PATTERNS(30);

-- Analyze warning patterns from last 14 days
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_WARNING_PATTERNS(14);

-- Analyze feedback patterns from last 7 days
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_FEEDBACK_PATTERNS(7);

-- Identify quality discrepancies from last 48 hours
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_IDENTIFY_QUALITY_DISCREPANCIES(48);
```

### Sample Queries

#### Insight 1: Problematic SQL

```sql
-- Get all problematic SQL queries with high complexity
SELECT 
    REQUEST_ID,
    TIMESTAMP,
    SEMANTIC_MODEL_NAME,
    PROBLEM_TYPE,
    SQL_COMPLEXITY_SCORE,
    COMPLEXITY_CATEGORY,
    WARNING_COUNT,
    LATEST_QUESTION,
    GENERATED_SQL
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_PROBLEMATIC_SQL_ANALYSIS
WHERE SQL_COMPLEXITY_SCORE > 15
ORDER BY SQL_COMPLEXITY_SCORE DESC
LIMIT 20;

-- Count problematic queries by type and model
SELECT 
    SEMANTIC_MODEL_NAME,
    PROBLEM_TYPE,
    COMPLEXITY_CATEGORY,
    COUNT(*) AS PROBLEM_COUNT,
    AVG(SQL_COMPLEXITY_SCORE) AS AVG_COMPLEXITY
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_PROBLEMATIC_SQL_ANALYSIS
GROUP BY SEMANTIC_MODEL_NAME, PROBLEM_TYPE, COMPLEXITY_CATEGORY
ORDER BY PROBLEM_COUNT DESC;

-- Track unresolved problems
SELECT 
    PROBLEM_ID,
    REQUEST_ID,
    SEMANTIC_MODEL_NAME,
    PROBLEM_TYPE,
    PROBLEM_DESCRIPTION,
    IDENTIFIED_AT,
    SQL_COMPLEXITY_SCORE
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.PROBLEMATIC_SQL
WHERE RESOLVED = FALSE
ORDER BY IDENTIFIED_AT DESC;
```

#### Insight 2: Response Status Failures

```sql
-- Daily failure trends by status code
SELECT 
    REQUEST_DATE,
    ERROR_CATEGORY,
    OCCURRENCE_COUNT,
    AFFECTED_MODELS,
    AFFECTED_USERS
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_STATUS_CODE_TRENDS
WHERE REQUEST_DATE >= DATEADD(DAY, -30, CURRENT_DATE())
ORDER BY REQUEST_DATE DESC, OCCURRENCE_COUNT DESC;

-- Failures by model and error type
SELECT 
    SEMANTIC_MODEL_NAME,
    ERROR_CATEGORY,
    SUM(FAILURE_COUNT) AS TOTAL_FAILURES,
    SUM(AFFECTED_USERS) AS TOTAL_AFFECTED_USERS,
    MIN(FIRST_FAILURE) AS FIRST_SEEN,
    MAX(LAST_FAILURE) AS LAST_SEEN
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_RESPONSE_STATUS_FAILURES
GROUP BY SEMANTIC_MODEL_NAME, ERROR_CATEGORY
ORDER BY TOTAL_FAILURES DESC;

-- Hourly failure patterns (identify peak problem times)
SELECT 
    HOUR(FAILURE_HOUR) AS HOUR_OF_DAY,
    ERROR_CATEGORY,
    COUNT(*) AS OCCURRENCE_COUNT,
    AVG(FAILURE_COUNT) AS AVG_FAILURES_PER_HOUR
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_RESPONSE_STATUS_FAILURES
WHERE FAILURE_DATE >= DATEADD(DAY, -7, CURRENT_DATE())
GROUP BY HOUR(FAILURE_HOUR), ERROR_CATEGORY
ORDER BY HOUR_OF_DAY, OCCURRENCE_COUNT DESC;
```

#### Insight 3: Warning Analysis

```sql
-- Top recurring warnings
SELECT 
    WARNING_MESSAGE,
    OCCURRENCE_COUNT,
    AFFECTED_MODELS,
    AFFECTED_USERS,
    FIRST_OCCURRENCE,
    LAST_OCCURRENCE
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_WARNING_SUMMARY
ORDER BY OCCURRENCE_COUNT DESC
LIMIT 20;

-- Warning details by model
SELECT 
    SEMANTIC_MODEL_NAME,
    WARNING_DETAIL,
    COUNT(*) AS WARNING_COUNT,
    COUNT(DISTINCT USER_ID) AS AFFECTED_USERS
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_WARNING_PATTERNS
GROUP BY SEMANTIC_MODEL_NAME, WARNING_DETAIL
ORDER BY WARNING_COUNT DESC;

-- Critical warning issues (high severity)
SELECT 
    WARNING_TYPE,
    WARNING_MESSAGE,
    SEMANTIC_MODEL_NAME,
    OCCURRENCE_COUNT,
    SEVERITY,
    ANALYZED_AT
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.WARNING_ISSUES
WHERE SEVERITY IN ('HIGH', 'CRITICAL')
ORDER BY OCCURRENCE_COUNT DESC;
```

#### Insight 4: Feedback Rates

```sql
-- Model performance comparison
SELECT 
    SEMANTIC_MODEL_NAME,
    TOTAL_REQUESTS,
    SUCCESSFUL_REQUESTS,
    SUCCESS_RATE_PCT,
    REQUESTS_WITH_FEEDBACK,
    FEEDBACK_RATE_PCT,
    REQUESTS_WITH_WARNINGS,
    UNIQUE_USERS
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_FEEDBACK_RATES_BY_MODEL
ORDER BY TOTAL_REQUESTS DESC;

-- Models with high feedback rates (indicating issues)
SELECT 
    SEMANTIC_MODEL_NAME,
    FEEDBACK_RATE_PCT,
    SUCCESS_RATE_PCT,
    TOTAL_REQUESTS,
    REQUESTS_WITH_FEEDBACK
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_FEEDBACK_RATES_BY_MODEL
WHERE FEEDBACK_RATE_PCT > 10  -- More than 10% have feedback
ORDER BY FEEDBACK_RATE_PCT DESC;

-- Correlation between success rate and feedback
SELECT 
    CASE 
        WHEN SUCCESS_RATE_PCT < 70 THEN 'LOW (< 70%)'
        WHEN SUCCESS_RATE_PCT < 90 THEN 'MEDIUM (70-90%)'
        ELSE 'HIGH (>= 90%)'
    END AS SUCCESS_CATEGORY,
    COUNT(*) AS MODEL_COUNT,
    AVG(FEEDBACK_RATE_PCT) AS AVG_FEEDBACK_RATE,
    AVG(TOTAL_REQUESTS) AS AVG_REQUESTS
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_FEEDBACK_RATES_BY_MODEL
GROUP BY SUCCESS_CATEGORY
ORDER BY SUCCESS_CATEGORY;
```

#### Insight 5: Question Type Analysis

```sql
-- Question types with highest failure rates
SELECT 
    QUESTION_TYPE,
    SEMANTIC_MODEL_NAME,
    TOTAL_QUESTIONS,
    FAILED_QUESTIONS,
    FAILURE_RATE_PCT,
    QUESTIONS_WITH_FEEDBACK,
    AVG_QUESTION_LENGTH,
    AVG_SQL_LENGTH
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_POOR_FEEDBACK_BY_QUESTION_TYPE
WHERE TOTAL_QUESTIONS >= 10  -- Statistically significant
ORDER BY FAILURE_RATE_PCT DESC
LIMIT 20;

-- Question type distribution
SELECT 
    QUESTION_TYPE,
    COUNT(DISTINCT SEMANTIC_MODEL_NAME) AS MODEL_COUNT,
    SUM(TOTAL_QUESTIONS) AS TOTAL_QUESTIONS,
    AVG(FAILURE_RATE_PCT) AS AVG_FAILURE_RATE,
    AVG(AVG_SQL_LENGTH) AS AVG_SQL_LENGTH
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_POOR_FEEDBACK_BY_QUESTION_TYPE
GROUP BY QUESTION_TYPE
ORDER BY TOTAL_QUESTIONS DESC;

-- Model performance by question type
SELECT 
    SEMANTIC_MODEL_NAME,
    QUESTION_TYPE,
    TOTAL_QUESTIONS,
    FAILURE_RATE_PCT
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_POOR_FEEDBACK_BY_QUESTION_TYPE
WHERE SEMANTIC_MODEL_NAME = 'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL'
ORDER BY FAILURE_RATE_PCT DESC;
```

#### Insight 6: Complexity vs. Satisfaction

```sql
-- Detailed complexity-satisfaction correlation
SELECT 
    REQUEST_ID,
    TIMESTAMP,
    SEMANTIC_MODEL_NAME,
    LATEST_QUESTION,
    SQL_COMPLEXITY_SCORE,
    COMPLEXITY_CATEGORY,
    EXECUTION_STATUS,
    FEEDBACK_COUNT,
    WARNING_COUNT,
    DISSATISFACTION_SCORE
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_COMPLEXITY_SATISFACTION_CORRELATION
WHERE DISSATISFACTION_SCORE > 5
ORDER BY DISSATISFACTION_SCORE DESC, SQL_COMPLEXITY_SCORE DESC
LIMIT 50;

-- Complexity category performance summary
SELECT 
    COMPLEXITY_CATEGORY,
    SEMANTIC_MODEL_NAME,
    TOTAL_QUERIES,
    SUCCESS_RATE_PCT,
    QUERIES_WITH_FEEDBACK,
    QUERIES_WITH_WARNINGS,
    AVG_SQL_LENGTH,
    AVG_COMPLEXITY_SCORE
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_COMPLEXITY_SATISFACTION_SUMMARY
ORDER BY COMPLEXITY_CATEGORY, SEMANTIC_MODEL_NAME;

-- Impact of complexity on success
SELECT 
    COMPLEXITY_CATEGORY,
    COUNT(*) AS TOTAL_QUERIES,
    AVG(CASE WHEN EXECUTION_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) * 100 AS SUCCESS_RATE_PCT,
    AVG(DISSATISFACTION_SCORE) AS AVG_DISSATISFACTION,
    AVG(SQL_COMPLEXITY_SCORE) AS AVG_COMPLEXITY
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_COMPLEXITY_SATISFACTION_CORRELATION
GROUP BY COMPLEXITY_CATEGORY
ORDER BY AVG_COMPLEXITY;
```

#### Insight 7: Correctness vs. Expectation Gaps

```sql
-- Queries with expectation gaps
SELECT 
    REQUEST_ID,
    TIMESTAMP,
    SEMANTIC_MODEL_NAME,
    USER_NAME,
    LATEST_QUESTION,
    TECHNICAL_STATUS,
    DISCREPANCY_TYPE,
    SQL_COMPLEXITY_SCORE,
    FEEDBACK_COUNT,
    WARNING_COUNT
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_CORRECTNESS_EXPECTATION_GAPS
WHERE DISCREPANCY_TYPE != 'NO_DISCREPANCY_DETECTED'
ORDER BY TIMESTAMP DESC
LIMIT 100;

-- Gap rate trends over time
SELECT 
    ANALYSIS_DATE,
    SEMANTIC_MODEL_NAME,
    CORRECT_WITH_FEEDBACK,
    CORRECT_WITH_WARNINGS,
    TOTAL_SUCCESSFUL,
    EXPECTATION_GAP_RATE_PCT
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_EXPECTATION_GAP_SUMMARY
WHERE ANALYSIS_DATE >= DATEADD(DAY, -30, CURRENT_DATE())
ORDER BY ANALYSIS_DATE DESC, EXPECTATION_GAP_RATE_PCT DESC;

-- Models with highest expectation gaps
SELECT 
    SEMANTIC_MODEL_NAME,
    AVG(EXPECTATION_GAP_RATE_PCT) AS AVG_GAP_RATE,
    SUM(CORRECT_WITH_FEEDBACK) AS TOTAL_WITH_FEEDBACK,
    SUM(CORRECT_WITH_WARNINGS) AS TOTAL_WITH_WARNINGS,
    SUM(TOTAL_SUCCESSFUL) AS TOTAL_SUCCESSFUL
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_EXPECTATION_GAP_SUMMARY
GROUP BY SEMANTIC_MODEL_NAME
ORDER BY AVG_GAP_RATE DESC;

-- Track quality discrepancies
SELECT 
    DISCREPANCY_ID,
    REQUEST_ID,
    SEMANTIC_MODEL_NAME,
    LATEST_QUESTION,
    TECHNICAL_STATUS,
    DISCREPANCY_TYPE,
    DISCREPANCY_DESCRIPTION,
    IDENTIFIED_AT
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.SQL_QUALITY_DISCREPANCIES
ORDER BY IDENTIFIED_AT DESC
LIMIT 50;
```

### Advanced Analytics

#### Combined Analysis - Overall Health Dashboard

```sql
-- Executive summary of AI model health
SELECT 
    fm.SEMANTIC_MODEL_NAME,
    fm.TOTAL_REQUESTS,
    fm.SUCCESS_RATE_PCT,
    fm.FEEDBACK_RATE_PCT,
    ps.PROBLEM_COUNT,
    eg.AVG_GAP_RATE
FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_FEEDBACK_RATES_BY_MODEL fm
LEFT JOIN (
    SELECT 
        SEMANTIC_MODEL_NAME,
        COUNT(*) AS PROBLEM_COUNT
    FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_PROBLEMATIC_SQL_ANALYSIS
    GROUP BY SEMANTIC_MODEL_NAME
) ps ON fm.SEMANTIC_MODEL_NAME = ps.SEMANTIC_MODEL_NAME
LEFT JOIN (
    SELECT 
        SEMANTIC_MODEL_NAME,
        AVG(EXPECTATION_GAP_RATE_PCT) AS AVG_GAP_RATE
    FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.VW_EXPECTATION_GAP_SUMMARY
    GROUP BY SEMANTIC_MODEL_NAME
) eg ON fm.SEMANTIC_MODEL_NAME = eg.SEMANTIC_MODEL_NAME
ORDER BY fm.TOTAL_REQUESTS DESC;
```

#### User Experience Metrics

```sql
-- User-level satisfaction analysis
SELECT 
    USER_ID,
    COUNT(*) AS TOTAL_QUERIES,
    SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) AS SUCCESSFUL_QUERIES,
    ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 100 ELSE 0 END), 2) AS SUCCESS_RATE,
    SUM(CASE WHEN FEEDBACK IS NOT NULL AND ARRAY_SIZE(FEEDBACK) > 0 THEN 1 ELSE 0 END) AS QUERIES_WITH_FEEDBACK,
    AVG(CURSOR_DB.AI_SUCCESS_FEEDBACK.FN_CALCULATE_SQL_COMPLEXITY(GENERATED_SQL)) AS AVG_COMPLEXITY
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
WHERE TIMESTAMP >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
GROUP BY USER_ID
HAVING TOTAL_QUERIES >= 10
ORDER BY SUCCESS_RATE ASC, QUERIES_WITH_FEEDBACK DESC;
```

## Data Visualization Recommendations

### Streamlit Application Components

#### 1. **Dashboard Overview**
- Total requests, success rate, failure rate (KPIs)
- Trend charts: Daily request volume, success rate over time
- Model comparison table

#### 2. **Problematic SQL Tab**
- Top problematic queries table with drill-down
- Complexity distribution histogram
- Problem type pie chart

#### 3. **Status Code Analysis Tab**
- Status code distribution bar chart
- Failure trends line chart
- Hourly heatmap of failures

#### 4. **Warning Analysis Tab**
- Warning frequency bar chart
- Warning type word cloud
- Severity distribution

#### 5. **Feedback Analysis Tab**
- Feedback rate by model bar chart
- Question type performance matrix
- User satisfaction scores

#### 6. **Complexity Analysis Tab**
- Scatter plot: Complexity vs. Success Rate
- Box plot: Dissatisfaction score by complexity category
- Correlation matrix

#### 7. **Quality Gaps Tab**
- Gap rate trends line chart
- Discrepancy type distribution
- Example queries with gaps

### Recommended Visualizations

```python
# Sample Streamlit visualization code structure

import streamlit as st
import pandas as pd
import plotly.express as px
from snowflake.connector import connect

# Dashboard KPIs
col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Requests", total_requests, delta_requests)
col2.metric("Success Rate", f"{success_rate}%", delta_success)
col3.metric("Avg Complexity", avg_complexity, delta_complexity)
col4.metric("Gap Rate", f"{gap_rate}%", delta_gap)

# Trend chart
fig = px.line(df_trends, x='REQUEST_DATE', y='SUCCESS_RATE_PCT', 
              color='SEMANTIC_MODEL_NAME', title='Success Rate Trends')
st.plotly_chart(fig)

# Problematic SQL distribution
fig = px.histogram(df_problems, x='COMPLEXITY_CATEGORY', 
                   color='PROBLEM_TYPE', title='Problematic SQL Distribution')
st.plotly_chart(fig)
```

## Maintenance and Best Practices

### Regular Maintenance Tasks

```sql
-- Run weekly analysis (recommended to schedule as a task)
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(7);

-- Clean up old analysis data (keep last 90 days)
DELETE FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.PROBLEMATIC_SQL 
WHERE IDENTIFIED_AT < DATEADD(DAY, -90, CURRENT_TIMESTAMP());

DELETE FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.RESPONSE_STATUS_PATTERNS 
WHERE ANALYZED_AT < DATEADD(DAY, -90, CURRENT_TIMESTAMP());

DELETE FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.WARNING_ISSUES 
WHERE ANALYZED_AT < DATEADD(DAY, -90, CURRENT_TIMESTAMP());
```

### Performance Optimization

```sql
-- Add clustering keys for better performance (optional)
ALTER TABLE CURSOR_DB.AI_SUCCESS_FEEDBACK.PROBLEMATIC_SQL 
CLUSTER BY (SEMANTIC_MODEL_NAME, TIMESTAMP);

ALTER TABLE CURSOR_DB.AI_SUCCESS_FEEDBACK.RESPONSE_STATUS_PATTERNS 
CLUSTER BY (STATUS_CODE, SEMANTIC_MODEL_NAME);
```

## Troubleshooting

### Common Issues

#### Issue: Views return no data
**Solution:** Ensure the `CORTEX_ANALYST_REQUEST_HISTORY` table has data
```sql
SELECT COUNT(*) FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;
```

#### Issue: Permission denied errors
**Solution:** Execute grants as ACCOUNTADMIN
```sql
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
GRANT USAGE ON ALL FUNCTIONS IN SCHEMA CURSOR_DB.AI_SUCCESS_FEEDBACK TO ROLE SVC_CURSOR_ROLE;
```

#### Issue: Procedure execution timeouts
**Solution:** Reduce lookback period or increase warehouse size
```sql
-- Use smaller lookback period
CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(3);  -- 3 days instead of 7

-- Or increase warehouse size temporarily
ALTER WAREHOUSE <your_warehouse> SET WAREHOUSE_SIZE = 'LARGE';
```

## Object Reference

### Tables (5)

| Table Name | Purpose | Key Columns |
|------------|---------|-------------|
| `PROBLEMATIC_SQL` | Track problematic queries | REQUEST_ID, PROBLEM_TYPE, SQL_COMPLEXITY_SCORE, RESOLVED |
| `RESPONSE_STATUS_PATTERNS` | Track status code patterns | STATUS_CODE, ERROR_CATEGORY, OCCURRENCE_COUNT |
| `WARNING_ISSUES` | Track recurring warnings | WARNING_TYPE, WARNING_MESSAGE, SEVERITY |
| `FEEDBACK_ANALYSIS` | Detailed feedback tracking | REQUEST_ID, FEEDBACK_SENTIMENT, QUESTION_TYPE |
| `SQL_QUALITY_DISCREPANCIES` | Track quality gaps | REQUEST_ID, TECHNICAL_STATUS, DISCREPANCY_TYPE |

### Views (11)

| View Name | Insight | Purpose |
|-----------|---------|---------|
| `VW_PROBLEMATIC_SQL_ANALYSIS` | #1 | Identify problematic SQL |
| `VW_RESPONSE_STATUS_FAILURES` | #2 | Failure patterns by model/time |
| `VW_STATUS_CODE_TRENDS` | #2 | Status code trends |
| `VW_WARNING_PATTERNS` | #3 | Detailed warning patterns |
| `VW_WARNING_SUMMARY` | #3 | Aggregated warning stats |
| `VW_FEEDBACK_RATES_BY_MODEL` | #4 | Feedback rates by model |
| `VW_POOR_FEEDBACK_BY_QUESTION_TYPE` | #5 | Question type performance |
| `VW_COMPLEXITY_SATISFACTION_CORRELATION` | #6 | Complexity-satisfaction correlation |
| `VW_COMPLEXITY_SATISFACTION_SUMMARY` | #6 | Complexity summary |
| `VW_CORRECTNESS_EXPECTATION_GAPS` | #7 | Expectation gap details |
| `VW_EXPECTATION_GAP_SUMMARY` | #7 | Gap rate summary |

### Stored Procedures (6)

| Procedure Name | Parameters | Purpose |
|----------------|------------|---------|
| `SP_IDENTIFY_PROBLEMATIC_SQL` | LOOKBACK_HOURS | Identify and log problematic queries |
| `SP_ANALYZE_STATUS_PATTERNS` | LOOKBACK_DAYS | Analyze status code patterns |
| `SP_ANALYZE_WARNING_PATTERNS` | LOOKBACK_DAYS | Analyze warning patterns |
| `SP_ANALYZE_FEEDBACK_PATTERNS` | LOOKBACK_DAYS | Analyze feedback patterns |
| `SP_IDENTIFY_QUALITY_DISCREPANCIES` | LOOKBACK_HOURS | Identify quality gaps |
| `SP_RUN_ALL_ANALYSES` | LOOKBACK_DAYS (default 7) | Run all analyses |

### Functions (2)

| Function Name | Parameters | Returns | Purpose |
|---------------|------------|---------|---------|
| `FN_CALCULATE_SQL_COMPLEXITY` | SQL_TEXT VARCHAR | FLOAT | Calculate SQL complexity score |
| `FN_CATEGORIZE_COMPLEXITY` | COMPLEXITY_SCORE FLOAT | VARCHAR | Categorize complexity (SIMPLE/MODERATE/COMPLEX) |

## Support and Contribution

### Contact
For questions or issues, contact the AI/ML team or data engineering team.

### Enhancement Requests
To request new features or insights:
1. Document the business requirement
2. Define the metrics needed
3. Provide sample queries if possible
4. Submit through the standard change request process

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-13 | Initial release with 7 key insights |

---

**Last Updated:** November 13, 2025  
**Author:** Cursor AI Assistant  
**Database:** CURSOR_DB  
**Schema:** AI_SUCCESS_FEEDBACK




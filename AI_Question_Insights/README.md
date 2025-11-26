# AI Question Insights - Snowflake Cortex Analyst Observability Framework

## Overview

The **AI Question Insights** framework provides comprehensive observability and analytics for Snowflake Cortex Analyst usage. This framework enables data teams to understand user behavior, optimize semantic models, identify patterns in natural language queries, and improve the overall AI agent experience.

## Table of Contents

1. [Architecture](#architecture)
2. [Installation](#installation)
3. [Data Model](#data-model)
4. [Core Components](#core-components)
5. [Insight Categories](#insight-categories)
6. [Usage Guide](#usage-guide)
7. [Best Practices](#best-practices)
8. [Maintenance](#maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Future Enhancements](#future-enhancements)

---

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│  Snowflake Cortex Analyst (Source Data)                     │
│  - SNOWFLAKE.LOCAL.CORTEX_ANALYST_REQUESTS                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Data Ingestion Layer                                        │
│  - REFRESH_CORTEX_ANALYST_HISTORY (Stored Procedure)        │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Base Storage Layer                                          │
│  - CORTEX_ANALYST_REQUEST_HISTORY (Base Table)              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Analytics Layer                                             │
│  - User Pattern Analysis (Stored Procedure)                 │
│  - Table Usage Analysis (Stored Procedure)                  │
│  - Question Theme Analysis (Stored Procedure)               │
│  - SQL Pattern Analysis (Stored Procedure)                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer                                          │
│  - 9 Helper Views for Quick Insights                        │
│  - Sample Queries and Reports                               │
│  - Future: Streamlit Dashboard                              │
└─────────────────────────────────────────────────────────────┘
```

### Schema Structure

All objects are created in the **`CURSOR_DB.AI_QUESTION_INSIGHTS`** schema:

- **Base Table**: 1 table for raw data storage
- **Stored Procedures**: 5 procedures (1 for data refresh, 4 for insights)
- **Views**: 9 views for common analytical queries
- **Sample Queries**: Comprehensive SQL examples

---

## Installation

### Prerequisites

1. **Snowflake Account** with Cortex Analyst enabled
2. **Database**: `CURSOR_DB` (or modify scripts to use your database)
3. **Privileges**: 
   - `CREATE SCHEMA` on database
   - `CREATE TABLE`, `CREATE VIEW`, `CREATE PROCEDURE` on schema
   - `USAGE` on `SNOWFLAKE.LOCAL` schema
4. **Semantic Model**: At least one Cortex Analyst semantic model or semantic view

### Installation Steps

1. **Create the Schema**:
   ```sql
   CREATE SCHEMA IF NOT EXISTS CURSOR_DB.AI_QUESTION_INSIGHTS
   COMMENT = 'Schema for AI observability insights';
   ```

2. **Create the Base Table**:
   ```sql
   -- Execute the CREATE TABLE statement from the provided SQL files
   -- This creates CORTEX_ANALYST_REQUEST_HISTORY
   ```

3. **Deploy Stored Procedures**:
   Execute the following SQL files in order:
   - `01_refresh_analyst_history_proc.sql`
   - `02_insight_user_patterns_proc.sql`
   - `03_insight_table_usage_proc.sql`
   - `04_insight_question_themes_proc.sql`
   - `05_insight_sql_patterns_proc.sql`

4. **Create Helper Views**:
   ```sql
   -- Execute 06_helper_views.sql
   -- Creates 9 convenience views
   ```

5. **Load Initial Data**:
   ```sql
   CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
       'SEMANTIC_VIEW',
       'YOUR_DATABASE.YOUR_SCHEMA.YOUR_SEMANTIC_MODEL',
       FALSE  -- Full load
   );
   ```

---

## Data Model

### Base Table: CORTEX_ANALYST_REQUEST_HISTORY

| Column Name | Data Type | Description |
|------------|-----------|-------------|
| `TIMESTAMP` | TIMESTAMP_NTZ | When the request was made |
| `REQUEST_ID` | VARCHAR | Unique identifier for each request |
| `SEMANTIC_MODEL_TYPE` | VARCHAR | Type: 'SEMANTIC_VIEW' or 'FILE_ON_STAGE' |
| `SEMANTIC_MODEL_NAME` | VARCHAR | Fully qualified name of semantic model |
| `TABLES_REFERENCED` | VARIANT | Array of tables used in the generated SQL |
| `USER_ID` | VARCHAR | Snowflake user ID |
| `USER_NAME` | VARCHAR | Snowflake username |
| `SOURCE` | VARCHAR | Source of the request (UI, API, etc.) |
| `LATEST_QUESTION` | VARCHAR | Natural language question from user |
| `GENERATED_SQL` | VARCHAR | SQL generated by Cortex Analyst |
| `REQUEST_BODY` | VARIANT | Full request payload |
| `RESPONSE_BODY` | VARIANT | Full response payload |
| `RESPONSE_STATUS_CODE` | NUMBER | HTTP status code (200 = success) |
| `WARNINGS` | VARIANT | Array of warnings if any |
| `FEEDBACK` | ARRAY | Array of user feedback (thumbs up/down) |
| `PRIMARY_ROLE_NAME` | VARCHAR | Role used for the request |
| `RESPONSE_METADATA` | VARIANT | Additional response metadata |
| `LOADED_AT` | TIMESTAMP_NTZ | When the record was loaded into this table |

### Primary Key
- `REQUEST_ID`, `TIMESTAMP`

---

## Core Components

### 1. Data Refresh Procedure

**Procedure**: `REFRESH_CORTEX_ANALYST_HISTORY`

**Purpose**: Load data from the Snowflake system table function into the base table.

**Parameters**:
- `SEMANTIC_MODEL_TYPE_PARAM` (VARCHAR): 'SEMANTIC_VIEW' or 'FILE_ON_STAGE'
- `SEMANTIC_MODEL_NAME_PARAM` (VARCHAR): Fully qualified semantic model name
- `INCREMENTAL` (BOOLEAN): TRUE for incremental, FALSE for full refresh

**Example**:
```sql
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'SEMANTIC_VIEW',
    'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
    TRUE
);
```

### 2. Helper Views (9 Views)

| View Name | Purpose |
|-----------|---------|
| `VW_RECENT_REQUESTS` | Last 100 requests with key metrics |
| `VW_DAILY_ACTIVITY` | Daily aggregated statistics |
| `VW_USER_LEADERBOARD` | User activity rankings |
| `VW_TABLE_USAGE` | Table reference frequency |
| `VW_ERROR_ANALYSIS` | Failed requests for troubleshooting |
| `VW_FEEDBACK_SUMMARY` | User feedback aggregation |
| `VW_SEMANTIC_MODEL_PERFORMANCE` | Performance by semantic model |
| `VW_HOURLY_ACTIVITY` | Peak usage hours |
| `VW_COMPLEXITY_DISTRIBUTION` | Query complexity breakdown |

---

## Insight Categories

### Insight 1: User Activity Patterns

**Procedure**: `GET_USER_QUESTION_PATTERNS`

**What It Analyzes**:
- Most active users by question count
- User question patterns and behavior
- Temporal patterns (most active days/hours)
- Success rates per user
- User satisfaction (feedback scores)

**Key Metrics**:
- Total questions per user
- Unique questions (diversity)
- Average questions per day
- Success rate
- Net satisfaction score
- Most active day of week and hour

**Use Cases**:
- Identify power users for case studies
- Target training for users with low success rates
- Understand user engagement patterns
- Measure user satisfaction

**Example**:
```sql
-- Get top 20 users from last 30 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 20);

-- Find users with low success rates
SELECT * FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 100)
)
WHERE SUCCESS_RATE < 0.7;
```

---

### Insight 2: Table and Join Usage Analysis

**Procedure**: `GET_TABLE_JOIN_USAGE_ANALYSIS`

**What It Analyzes**:
- Which tables are frequently referenced
- Which tables are underutilized
- Common join patterns between tables
- Table-level success rates

**Key Metrics**:
- Total references per table
- Average references per day
- Join frequency
- Most common join partners
- Underutilization flag
- Success rate for queries involving each table

**Use Cases**:
- Identify important vs. unused tables
- Optimize semantic models based on table usage
- Understand data relationships
- Deprecate unused tables

**Example**:
```sql
-- Analyze table usage for last 30 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 50);

-- Find underutilized tables
SELECT * FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 100)
)
WHERE IS_UNDERUTILIZED = TRUE;
```

---

### Insight 3: Question Theme Analysis

**Procedure**: `GET_QUESTION_THEMES_ANALYSIS`

**What It Analyzes**:
- Common question themes and categories
- Question intent classification
- Trending vs. declining question types
- Success rates by theme

**Question Categories**:
- **Aggregation**: Total, sum, count questions
- **Trend Analysis**: Over time, by month
- **Comparison**: Compare, versus
- **Ranking**: Top, bottom, highest, lowest
- **Forecasting**: Future predictions
- **Breakdown**: Group by, breakdown
- **Lookup**: Find, search
- **Filtering**: Where clauses
- **Listing**: Show all, list

**Key Metrics**:
- Question count by theme
- Success rate per theme
- Average SQL complexity
- Trend (growing/stable/declining)
- User feedback by theme

**Use Cases**:
- Understand what users are asking about
- Identify themes with low success rates
- Prioritize semantic model improvements
- Track question trend evolution

**Example**:
```sql
-- Analyze question themes
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 25);

-- Find themes with low success
SELECT * FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 30)
)
WHERE SUCCESS_RATE < 0.8;
```

---

### Insight 4: SQL Pattern Analysis

**Procedure**: `GET_SQL_PATTERN_ANALYSIS`

**What It Analyzes**:
- Common SQL constructs and patterns
- Join complexity
- Aggregation patterns
- CTE and subquery usage
- Window function usage

**SQL Patterns Detected**:
- **Join Patterns**: INNER JOIN, LEFT JOIN, multiple joins
- **Aggregation**: GROUP BY, aggregation functions
- **Window Functions**: OVER clause
- **CTEs**: WITH clause
- **Date Functions**: DATE_TRUNC, DATEADD, DATEDIFF
- **String Functions**: SUBSTRING, CONCAT, LOWER, UPPER
- **Subqueries**: IN, EXISTS
- **Conditional Logic**: CASE WHEN

**Key Metrics**:
- Occurrence count per pattern
- Percentage of queries using pattern
- Success rate per pattern
- Complexity indicator
- Recommendations

**Use Cases**:
- Identify common SQL anti-patterns
- Optimize frequently used patterns
- Understand Cortex Analyst's SQL generation tendencies
- Guide semantic model design

**Example**:
```sql
-- Analyze SQL patterns
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 30);

-- Find complex patterns needing optimization
SELECT * FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 50)
)
WHERE IS_COMPLEX_PATTERN = TRUE
  AND AVG_QUERY_COMPLEXITY > 0.7;
```

---

## Usage Guide

### Daily Operations

#### 1. Refresh Data (Daily/Hourly)

```sql
-- Incremental load for a semantic model
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'SEMANTIC_VIEW',
    'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
    TRUE
);
```

Consider creating a **TASK** to automate this:

```sql
CREATE OR REPLACE TASK CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_INSIGHTS_DAILY
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 1 * * * America/Los_Angeles'  -- 1 AM daily
AS
  CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
      'SEMANTIC_VIEW',
      'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
      TRUE
  );

ALTER TASK CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_INSIGHTS_DAILY RESUME;
```

#### 2. Quick Health Check

```sql
-- Check recent activity
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_RECENT_REQUESTS
LIMIT 20;

-- Check errors
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_ERROR_ANALYSIS
WHERE TIMESTAMP >= DATEADD('day', -1, CURRENT_TIMESTAMP());
```

#### 3. Weekly Reporting

```sql
-- Generate user patterns report
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(7, 25);

-- Generate table usage report
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(7, 50);
```

### Advanced Analytics

#### Combining Multiple Insights

```sql
-- Create a comprehensive weekly snapshot
CREATE OR REPLACE TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.WEEKLY_SNAPSHOT_2024_11_13 AS
SELECT 
    'User Patterns' as insight_type,
    OBJECT_CONSTRUCT(*) as insight_data
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(7, 50)
)
UNION ALL
SELECT 
    'Table Usage',
    OBJECT_CONSTRUCT(*)
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(7, 100)
);
```

#### Creating Custom Dashboards

Use the helper views to build custom dashboards:

```sql
-- Executive KPI Dashboard
SELECT 'Total Requests (30d)' as kpi, COUNT(*)::STRING as value
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
WHERE TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
UNION ALL
SELECT 'Success Rate', 
       ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 100.0 ELSE 0.0 END), 1)::STRING || '%'
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
WHERE TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP());
```

---

## Best Practices

### 1. Data Refresh Frequency

- **High-traffic environments**: Hourly refresh
- **Medium-traffic**: Daily refresh
- **Low-traffic**: Weekly refresh

### 2. Performance Optimization

- **Cluster Keys**: Consider clustering `CORTEX_ANALYST_REQUEST_HISTORY` on `TIMESTAMP` if the table grows large:
  ```sql
  ALTER TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
  CLUSTER BY (TIMESTAMP);
  ```

- **Search Optimization**: For text search on questions:
  ```sql
  ALTER TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
  ADD SEARCH OPTIMIZATION ON EQUALITY(LATEST_QUESTION);
  ```

### 3. Data Retention

Implement data retention policy based on your needs:

```sql
-- Delete data older than 1 year
DELETE FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
WHERE TIMESTAMP < DATEADD('year', -1, CURRENT_TIMESTAMP());
```

### 4. Multi-Model Environments

If you have multiple semantic models, refresh each one:

```sql
-- Create a procedure to refresh all models
CREATE OR REPLACE PROCEDURE REFRESH_ALL_MODELS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    CALL REFRESH_CORTEX_ANALYST_HISTORY('SEMANTIC_VIEW', 'DB1.SCHEMA1.MODEL1', TRUE);
    CALL REFRESH_CORTEX_ANALYST_HISTORY('SEMANTIC_VIEW', 'DB1.SCHEMA1.MODEL2', TRUE);
    CALL REFRESH_CORTEX_ANALYST_HISTORY('FILE_ON_STAGE', '@DB1.SCH1.STAGE/model3.yaml', TRUE);
    RETURN 'All models refreshed';
END;
$$;
```

### 5. Monitoring and Alerting

Set up alerts for:
- **High error rates** (>10% in last hour)
- **Negative feedback spikes** (>5 thumbs down in 24h)
- **No activity** (0 requests in 24h, if normally active)

Example alert query:
```sql
-- Alert if error rate > 10% in last hour
SELECT 
    COUNT(*) as error_count,
    COUNT(*) * 100.0 / NULLIF((
        SELECT COUNT(*) 
        FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY 
        WHERE TIMESTAMP >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
    ), 0) as error_rate_pct
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
WHERE TIMESTAMP >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
  AND RESPONSE_STATUS_CODE != 200
HAVING error_rate_pct > 10;
```

---

## Maintenance

### Regular Tasks

| Frequency | Task | SQL Example |
|-----------|------|-------------|
| Hourly | Refresh data | `CALL REFRESH_CORTEX_ANALYST_HISTORY(...)` |
| Daily | Check for errors | `SELECT * FROM VW_ERROR_ANALYSIS` |
| Weekly | Generate reports | Run all 4 insight procedures |
| Monthly | Review underutilized tables | `GET_TABLE_JOIN_USAGE_ANALYSIS` |
| Quarterly | Optimize table clustering | `ALTER TABLE ... RECLUSTER` |
| Annually | Archive old data | `DELETE FROM ... WHERE TIMESTAMP < ...` |

### Troubleshooting Common Issues

#### Issue 1: No Data in Base Table

**Symptom**: Insights return empty results.

**Solution**:
1. Check if data refresh ran successfully:
   ```sql
   SELECT MAX(LOADED_AT), COUNT(*)
   FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;
   ```

2. Verify semantic model name:
   ```sql
   -- List available semantic views
   SELECT * FROM CURSOR_DB.ANALYTICS.INFORMATION_SCHEMA.TABLES
   WHERE TABLE_TYPE = 'VIEW';
   ```

3. Check permissions on `SNOWFLAKE.LOCAL` schema.

#### Issue 2: Slow Query Performance

**Symptom**: Insight procedures take too long.

**Solution**:
1. Add clustering to base table (see Best Practices)
2. Reduce `DAYS_BACK` parameter
3. Limit `TOP_N` or `RESULT_LIMIT` parameters

#### Issue 3: Stored Procedure Errors

**Symptom**: Procedures fail with SQL compilation errors.

**Solution**:
1. Check Snowflake version compatibility
2. Verify all required columns exist in base table
3. Review error messages in `INFORMATION_SCHEMA.QUERY_HISTORY`

---

## Future Enhancements

### Phase 2: Visualization Layer

**Planned**: Streamlit application with:
- Interactive dashboards
- Real-time monitoring
- Drill-down capabilities
- Export to PDF/Excel

**Components**:
- User activity heatmaps
- Table usage network diagrams
- Question theme word clouds
- SQL pattern visualizations

### Phase 3: Advanced Analytics

**Planned Features**:
- **Anomaly Detection**: Identify unusual patterns in user behavior
- **Predictive Analytics**: Forecast question trends
- **Semantic Model Recommendations**: AI-driven suggestions for model improvements
- **User Clustering**: Group users by behavior patterns

### Phase 4: Automation

**Planned**:
- Automated semantic model tuning
- Self-healing for common error patterns
- Proactive user training recommendations
- Automated documentation generation

---

## Contributing

To extend this framework:

1. **Add New Insights**: Create additional stored procedures following the existing pattern
2. **Add New Views**: Create views for specific use cases
3. **Enhance Existing Procedures**: Add parameters or metrics to existing procedures
4. **Create Integrations**: Connect to BI tools, alerting systems, or orchestration platforms

### Example: Adding a New Insight

```sql
-- Template for new insight procedure
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_QUESTION_INSIGHTS.GET_NEW_INSIGHT(
    DAYS_BACK INTEGER DEFAULT 30
)
RETURNS TABLE (...)
LANGUAGE SQL
AS
$$
BEGIN
    RETURN TABLE (
        WITH base_data AS (
            SELECT ...
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= DATEADD('day', -:DAYS_BACK, CURRENT_TIMESTAMP())
        )
        SELECT ...
        FROM base_data
    );
END;
$$;
```

---

## Support and Resources

### Documentation References
- [Snowflake Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Snowflake Stored Procedures](https://docs.snowflake.com/en/sql-reference/stored-procedures)
- [Snowflake Table Functions](https://docs.snowflake.com/en/sql-reference/functions-table)

### Sample Queries
- See `07_sample_queries.sql` for comprehensive examples
- All procedures include inline documentation

### Contact
For questions or issues with this framework, please contact Ashley Feider.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-11-13 | Initial release with 4 insight categories and 9 views |

---

## License

This framework is provided as-is for use within your Snowflake environment. Modify and extend as needed for your use cases.

---

**Built with ❄️ for Snowflake Cortex Analyst**


-- ============================================================================
-- AI QUESTION INSIGHTS - COMPLETE DEPLOYMENT SCRIPT
-- ============================================================================
-- This script deploys all components of the AI Question Insights framework
-- 
-- Prerequisites:
--   1. Database CURSOR_DB exists (or modify database name throughout)
--   2. User has CREATE SCHEMA, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE privileges
--   3. User has USAGE on SNOWFLAKE.LOCAL schema
--   4. At least one Cortex Analyst semantic model exists
--
-- Deployment Steps:
--   1. Create schema
--   2. Create base table
--   3. Create stored procedures (you'll need to run these separately as CREATE PROCEDURE isn't supported in multi-statement blocks)
--   4. Create helper views
--   5. Load initial data
--
-- Note: Due to Snowflake limitations, stored procedures must be created 
-- separately. Execute files 01-05 individually after running this base script.
-- ============================================================================

USE DATABASE CURSOR_DB;

-- ============================================================================
-- STEP 1: Create Schema
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS AI_QUESTION_INSIGHTS
COMMENT = 'Schema for AI observability insights including user patterns, SQL analysis, and question themes from Cortex Analyst usage';

USE SCHEMA AI_QUESTION_INSIGHTS;

-- ============================================================================
-- STEP 2: Create Base Table
-- ============================================================================
CREATE OR REPLACE TABLE CORTEX_ANALYST_REQUEST_HISTORY (
    TIMESTAMP TIMESTAMP_NTZ,
    REQUEST_ID VARCHAR,
    SEMANTIC_MODEL_TYPE VARCHAR,
    SEMANTIC_MODEL_NAME VARCHAR,
    TABLES_REFERENCED VARIANT,
    USER_ID VARCHAR,
    USER_NAME VARCHAR,
    SOURCE VARCHAR,
    LATEST_QUESTION VARCHAR,
    GENERATED_SQL VARCHAR,
    REQUEST_BODY VARIANT,
    RESPONSE_BODY VARIANT,
    RESPONSE_STATUS_CODE NUMBER,
    WARNINGS VARIANT,
    FEEDBACK ARRAY,
    PRIMARY_ROLE_NAME VARCHAR,
    RESPONSE_METADATA VARIANT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_request_history PRIMARY KEY (REQUEST_ID, TIMESTAMP)
)
COMMENT = 'Materialized history of Cortex Analyst requests for analysis and insights';

-- ============================================================================
-- STEP 3: Create Helper Views
-- ============================================================================

-- View 1: Recent Requests Summary
CREATE OR REPLACE VIEW VW_RECENT_REQUESTS AS
SELECT 
    TIMESTAMP,
    USER_NAME,
    LATEST_QUESTION,
    RESPONSE_STATUS_CODE,
    CASE 
        WHEN RESPONSE_STATUS_CODE = 200 THEN 'Success'
        WHEN RESPONSE_STATUS_CODE >= 400 AND RESPONSE_STATUS_CODE < 500 THEN 'Client Error'
        WHEN RESPONSE_STATUS_CODE >= 500 THEN 'Server Error'
        ELSE 'Unknown'
    END as status_category,
    SEMANTIC_MODEL_NAME,
    ARRAY_SIZE(TABLES_REFERENCED) as table_count,
    LENGTH(GENERATED_SQL) as sql_length,
    ARRAY_SIZE(WARNINGS) as warning_count,
    ARRAY_SIZE(FEEDBACK) as feedback_count
FROM CORTEX_ANALYST_REQUEST_HISTORY
ORDER BY TIMESTAMP DESC
LIMIT 100;

-- View 2: Daily Activity Summary
CREATE OR REPLACE VIEW VW_DAILY_ACTIVITY AS
SELECT 
    DATE_TRUNC('day', TIMESTAMP) as activity_date,
    COUNT(*) as total_requests,
    COUNT(DISTINCT USER_NAME) as unique_users,
    COUNT(DISTINCT LATEST_QUESTION) as unique_questions,
    ROUND(AVG(LENGTH(GENERATED_SQL)), 0) as avg_sql_length,
    SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) as successful_requests,
    ROUND(successful_requests * 100.0 / NULLIF(total_requests, 0), 1) as success_rate_pct,
    SUM(CASE WHEN ARRAY_SIZE(WARNINGS) > 0 THEN 1 ELSE 0 END) as requests_with_warnings,
    SUM(CASE WHEN ARRAY_SIZE(FEEDBACK) > 0 THEN 1 ELSE 0 END) as requests_with_feedback
FROM CORTEX_ANALYST_REQUEST_HISTORY
GROUP BY DATE_TRUNC('day', TIMESTAMP)
ORDER BY activity_date DESC;

-- View 3: User Leaderboard
CREATE OR REPLACE VIEW VW_USER_LEADERBOARD AS
SELECT 
    USER_NAME,
    COUNT(*) as total_questions,
    COUNT(DISTINCT LATEST_QUESTION) as unique_questions,
    COUNT(DISTINCT DATE_TRUNC('day', TIMESTAMP)) as active_days,
    MIN(TIMESTAMP) as first_activity,
    MAX(TIMESTAMP) as last_activity,
    ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1.0 ELSE 0.0 END), 3) as success_rate,
    SUM(CASE WHEN ARRAY_SIZE(FEEDBACK) > 0 THEN 1 ELSE 0 END) as feedback_provided_count,
    RANK() OVER (ORDER BY COUNT(*) DESC) as activity_rank
FROM CORTEX_ANALYST_REQUEST_HISTORY
GROUP BY USER_NAME
ORDER BY total_questions DESC;

-- View 4: Table Usage Summary
CREATE OR REPLACE VIEW VW_TABLE_USAGE AS
WITH exploded_tables AS (
    SELECT 
        TIMESTAMP,
        REQUEST_ID,
        USER_NAME,
        t.value::STRING as table_name,
        RESPONSE_STATUS_CODE
    FROM CORTEX_ANALYST_REQUEST_HISTORY,
         LATERAL FLATTEN(input => TABLES_REFERENCED) t
)
SELECT 
    table_name,
    COUNT(*) as reference_count,
    COUNT(DISTINCT REQUEST_ID) as unique_queries,
    COUNT(DISTINCT USER_NAME) as unique_users,
    MIN(TIMESTAMP) as first_used,
    MAX(TIMESTAMP) as last_used,
    DATEDIFF('day', first_used, last_used) as days_in_use,
    ROUND(COUNT(*) * 1.0 / NULLIF(days_in_use, 0), 2) as avg_refs_per_day,
    ROUND(SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 1) as success_rate_pct
FROM exploded_tables
GROUP BY table_name
ORDER BY reference_count DESC;

-- View 5: Error Analysis
CREATE OR REPLACE VIEW VW_ERROR_ANALYSIS AS
SELECT 
    TIMESTAMP,
    USER_NAME,
    LATEST_QUESTION,
    RESPONSE_STATUS_CODE,
    GENERATED_SQL,
    WARNINGS,
    SEMANTIC_MODEL_NAME,
    TABLES_REFERENCED,
    CASE 
        WHEN RESPONSE_STATUS_CODE = 400 THEN 'Bad Request'
        WHEN RESPONSE_STATUS_CODE = 401 THEN 'Unauthorized'
        WHEN RESPONSE_STATUS_CODE = 403 THEN 'Forbidden'
        WHEN RESPONSE_STATUS_CODE = 404 THEN 'Not Found'
        WHEN RESPONSE_STATUS_CODE = 500 THEN 'Internal Server Error'
        WHEN RESPONSE_STATUS_CODE = 503 THEN 'Service Unavailable'
        ELSE 'Other Error'
    END as error_type
FROM CORTEX_ANALYST_REQUEST_HISTORY
WHERE RESPONSE_STATUS_CODE != 200
ORDER BY TIMESTAMP DESC;

-- View 6: Feedback Summary
CREATE OR REPLACE VIEW VW_FEEDBACK_SUMMARY AS
WITH feedback_exploded AS (
    SELECT 
        REQUEST_ID,
        TIMESTAMP,
        USER_NAME,
        LATEST_QUESTION,
        SEMANTIC_MODEL_NAME,
        f.value:feedback_type::STRING as feedback_type,
        f.value:timestamp::TIMESTAMP as feedback_timestamp
    FROM CORTEX_ANALYST_REQUEST_HISTORY,
         LATERAL FLATTEN(input => FEEDBACK) f
)
SELECT 
    DATE_TRUNC('day', TIMESTAMP) as feedback_date,
    feedback_type,
    COUNT(*) as feedback_count,
    COUNT(DISTINCT USER_NAME) as unique_users,
    COUNT(DISTINCT SEMANTIC_MODEL_NAME) as semantic_models_affected
FROM feedback_exploded
GROUP BY DATE_TRUNC('day', TIMESTAMP), feedback_type
ORDER BY feedback_date DESC, feedback_type;

-- View 7: Semantic Model Performance
CREATE OR REPLACE VIEW VW_SEMANTIC_MODEL_PERFORMANCE AS
SELECT 
    SEMANTIC_MODEL_NAME,
    COUNT(*) as total_requests,
    COUNT(DISTINCT USER_NAME) as unique_users,
    COUNT(DISTINCT LATEST_QUESTION) as unique_questions,
    ROUND(AVG(LENGTH(GENERATED_SQL)), 0) as avg_sql_length,
    SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) as successful_requests,
    ROUND(successful_requests * 100.0 / NULLIF(total_requests, 0), 1) as success_rate_pct,
    SUM(CASE WHEN ARRAY_SIZE(WARNINGS) > 0 THEN 1 ELSE 0 END) as warnings_count,
    ROUND(warnings_count * 100.0 / NULLIF(total_requests, 0), 1) as warning_rate_pct,
    MIN(TIMESTAMP) as first_used,
    MAX(TIMESTAMP) as last_used
FROM CORTEX_ANALYST_REQUEST_HISTORY
GROUP BY SEMANTIC_MODEL_NAME
ORDER BY total_requests DESC;

-- View 8: Hourly Activity Pattern
CREATE OR REPLACE VIEW VW_HOURLY_ACTIVITY AS
SELECT 
    HOUR(TIMESTAMP) as hour_of_day,
    DAYNAME(TIMESTAMP) as day_of_week,
    COUNT(*) as request_count,
    COUNT(DISTINCT USER_NAME) as unique_users,
    ROUND(AVG(LENGTH(GENERATED_SQL)), 0) as avg_sql_length,
    ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1.0 ELSE 0.0 END), 3) as success_rate
FROM CORTEX_ANALYST_REQUEST_HISTORY
GROUP BY HOUR(TIMESTAMP), DAYNAME(TIMESTAMP)
ORDER BY request_count DESC;

-- View 9: Query Complexity Distribution
CREATE OR REPLACE VIEW VW_COMPLEXITY_DISTRIBUTION AS
WITH complexity_calc AS (
    SELECT 
        REQUEST_ID,
        TIMESTAMP,
        USER_NAME,
        LATEST_QUESTION,
        GENERATED_SQL,
        RESPONSE_STATUS_CODE,
        LENGTH(GENERATED_SQL) as sql_length,
        ARRAY_SIZE(REGEXP_SUBSTR_ALL(GENERATED_SQL, 'JOIN', 1, 1, 'i')) as join_count,
        ARRAY_SIZE(REGEXP_SUBSTR_ALL(GENERATED_SQL, 'CASE', 1, 1, 'i')) as case_count,
        ARRAY_SIZE(REGEXP_SUBSTR_ALL(GENERATED_SQL, 'WITH', 1, 1, 'i')) as cte_count,
        ARRAY_SIZE(TABLES_REFERENCED) as table_count,
        (sql_length / 100.0) + (join_count * 2) + (case_count * 1.5) + (cte_count * 3) + (table_count * 1) as complexity_score
    FROM CORTEX_ANALYST_REQUEST_HISTORY
    WHERE GENERATED_SQL IS NOT NULL
)
SELECT 
    CASE 
        WHEN complexity_score < 5 THEN 'Simple'
        WHEN complexity_score < 15 THEN 'Moderate'
        WHEN complexity_score < 30 THEN 'Complex'
        ELSE 'Very Complex'
    END as complexity_category,
    COUNT(*) as query_count,
    COUNT(DISTINCT USER_NAME) as unique_users,
    ROUND(AVG(sql_length), 0) as avg_sql_length,
    ROUND(AVG(join_count), 1) as avg_joins,
    ROUND(AVG(table_count), 1) as avg_tables,
    ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1.0 ELSE 0.0 END), 3) as success_rate
FROM complexity_calc
GROUP BY complexity_category
ORDER BY 
    CASE complexity_category
        WHEN 'Simple' THEN 1
        WHEN 'Moderate' THEN 2
        WHEN 'Complex' THEN 3
        WHEN 'Very Complex' THEN 4
    END;

-- ============================================================================
-- DEPLOYMENT COMPLETE - BASE COMPONENTS
-- ============================================================================

SELECT 'Base deployment complete! Now execute the stored procedure scripts:' as status
UNION ALL SELECT '1. Execute 01_refresh_analyst_history_proc.sql'
UNION ALL SELECT '2. Execute 02_insight_user_patterns_proc.sql'
UNION ALL SELECT '3. Execute 03_insight_table_usage_proc.sql'
UNION ALL SELECT '4. Execute 04_insight_question_themes_proc.sql'
UNION ALL SELECT '5. Execute 05_insight_sql_patterns_proc.sql'
UNION ALL SELECT ''
UNION ALL SELECT 'Then load initial data with:'
UNION ALL SELECT 'CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY('
UNION ALL SELECT '    ''SEMANTIC_VIEW'','
UNION ALL SELECT '    ''YOUR_DATABASE.YOUR_SCHEMA.YOUR_SEMANTIC_MODEL'','
UNION ALL SELECT '    FALSE'
UNION ALL SELECT ');';


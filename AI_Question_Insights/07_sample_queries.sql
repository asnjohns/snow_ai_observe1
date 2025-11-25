-- ============================================================================
-- AI QUESTION INSIGHTS - Sample Queries and Usage Examples
-- ============================================================================
-- This file contains sample queries demonstrating how to use the stored
-- procedures and views in the AI_QUESTION_INSIGHTS schema.
-- ============================================================================

-- ============================================================================
-- SECTION 1: Data Loading
-- ============================================================================

-- Sample 1.1: Refresh data from a semantic view (incremental load)
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'SEMANTIC_VIEW',
    'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
    TRUE  -- Incremental = only load new records
);

-- Sample 1.2: Full refresh (reload all data)
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'SEMANTIC_VIEW',
    'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
    FALSE  -- Full refresh
);

-- Sample 1.3: Load from a YAML file semantic model
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    'FILE_ON_STAGE',
    '@CURSOR_DB.ANALYTICS.MY_STAGE/my_semantic_model.yaml',
    TRUE
);


-- ============================================================================
-- SECTION 2: Insight 1 - User Activity Patterns
-- ============================================================================

-- Sample 2.1: Get top 10 most active users from last 30 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);

-- Sample 2.2: Get top 25 most active users from last 90 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(90, 25);

-- Sample 2.3: Get top 5 users from last 7 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(7, 5);

-- Sample 2.4: Save user patterns to a table for further analysis
CREATE OR REPLACE TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.USER_PATTERNS_SNAPSHOT AS
SELECT * FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 50)
);

-- Sample 2.5: Find users with low success rates
SELECT 
    USER_NAME,
    TOTAL_QUESTIONS,
    SUCCESS_RATE,
    NET_SATISFACTION_SCORE,
    MOST_COMMON_QUESTION_PATTERN
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 100)
)
WHERE SUCCESS_RATE < 0.7
ORDER BY TOTAL_QUESTIONS DESC;


-- ============================================================================
-- SECTION 3: Insight 2 - Table and Join Usage Analysis
-- ============================================================================

-- Sample 3.1: Get table usage analysis for last 30 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 50);

-- Sample 3.2: Get extended analysis (100 tables, last 60 days)
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(60, 100);

-- Sample 3.3: Identify underutilized tables
SELECT 
    TABLE_NAME,
    DATABASE_NAME,
    SCHEMA_NAME,
    TOTAL_REFERENCES,
    AVG_REFERENCES_PER_DAY,
    LAST_USED,
    SAMPLE_QUESTIONS
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 100)
)
WHERE IS_UNDERUTILIZED = TRUE
ORDER BY LAST_USED DESC;

-- Sample 3.4: Find most frequently joined tables
SELECT 
    TABLE_NAME,
    JOIN_COUNT,
    AVG_TABLES_JOINED_WITH,
    MOST_COMMON_JOIN_PARTNER,
    UNIQUE_USERS_ACCESSING
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 50)
)
WHERE JOIN_COUNT > 0
ORDER BY JOIN_COUNT DESC
LIMIT 20;

-- Sample 3.5: Compare table usage across databases
SELECT 
    DATABASE_NAME,
    COUNT(DISTINCT TABLE_NAME) as table_count,
    SUM(TOTAL_REFERENCES) as total_refs,
    ROUND(AVG(SUCCESS_RATE_FOR_TABLE), 3) as avg_success_rate,
    SUM(UNIQUE_USERS_ACCESSING) as total_unique_users
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 200)
)
GROUP BY DATABASE_NAME
ORDER BY total_refs DESC;


-- ============================================================================
-- SECTION 4: Insight 3 - Question Themes Analysis
-- ============================================================================

-- Sample 4.1: Get question themes for last 30 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 25);

-- Sample 4.2: Get all themes from last 90 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(90, 50);

-- Sample 4.3: Find themes with low success rates
SELECT 
    THEME_CATEGORY,
    QUESTION_COUNT,
    SUCCESS_RATE,
    AVG_SQL_COMPLEXITY_SCORE,
    HAS_WARNINGS_PCT,
    POSITIVE_FEEDBACK_RATE,
    SAMPLE_QUESTIONS
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 30)
)
WHERE SUCCESS_RATE < 0.8
ORDER BY QUESTION_COUNT DESC;

-- Sample 4.4: Identify growing vs declining themes
SELECT 
    THEME_CATEGORY,
    QUESTION_COUNT,
    TREND,
    UNIQUE_USERS,
    FIRST_ASKED,
    LAST_ASKED,
    QUESTION_KEYWORDS[0]::STRING as top_keyword_1,
    QUESTION_KEYWORDS[1]::STRING as top_keyword_2,
    QUESTION_KEYWORDS[2]::STRING as top_keyword_3
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 30)
)
WHERE TREND IN ('Growing', 'Declining')
ORDER BY 
    CASE TREND WHEN 'Growing' THEN 1 ELSE 2 END,
    QUESTION_COUNT DESC;

-- Sample 4.5: Compare question complexity across themes
SELECT 
    THEME_CATEGORY,
    QUESTION_COUNT,
    AVG_QUESTION_LENGTH,
    AVG_SQL_COMPLEXITY_SCORE,
    SUCCESS_RATE,
    ARRAY_SIZE(MOST_REFERENCED_TABLES) as table_diversity
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 30)
)
ORDER BY AVG_SQL_COMPLEXITY_SCORE DESC;


-- ============================================================================
-- SECTION 5: Insight 4 - SQL Pattern Analysis
-- ============================================================================

-- Sample 5.1: Get SQL pattern analysis for last 30 days
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 30);

-- Sample 5.2: Get extended pattern analysis (60 days, 50 patterns)
CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(60, 50);

-- Sample 5.3: Find patterns with low success rates
SELECT 
    PATTERN_TYPE,
    PATTERN_NAME,
    OCCURRENCE_COUNT,
    PERCENTAGE_OF_QUERIES,
    SUCCESS_RATE,
    IS_COMPLEX_PATTERN,
    RECOMMENDATION
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 50)
)
WHERE SUCCESS_RATE < 0.8
ORDER BY OCCURRENCE_COUNT DESC;

-- Sample 5.4: Analyze JOIN patterns specifically
SELECT 
    PATTERN_NAME,
    OCCURRENCE_COUNT,
    PERCENTAGE_OF_QUERIES,
    AVG_QUERY_COMPLEXITY,
    SUCCESS_RATE,
    UNIQUE_USERS_USING,
    SAMPLE_SQL[0]::STRING as sample_1
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 50)
)
WHERE PATTERN_TYPE = 'Join Pattern'
ORDER BY OCCURRENCE_COUNT DESC;

-- Sample 5.5: Find complex patterns that need optimization
SELECT 
    PATTERN_TYPE,
    PATTERN_NAME,
    OCCURRENCE_COUNT,
    AVG_QUERY_COMPLEXITY,
    SUCCESS_RATE,
    RECOMMENDATION,
    RELATED_QUESTIONS[0]::STRING as sample_question
FROM TABLE(
    CURSOR_DB.AI_QUESTION_INSIGHTS.GET_SQL_PATTERN_ANALYSIS(30, 50)
)
WHERE IS_COMPLEX_PATTERN = TRUE
  AND AVG_QUERY_COMPLEXITY > 0.7
ORDER BY OCCURRENCE_COUNT DESC;


-- ============================================================================
-- SECTION 6: Using Helper Views
-- ============================================================================

-- Sample 6.1: Check recent activity
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_RECENT_REQUESTS
LIMIT 20;

-- Sample 6.2: Monitor daily trends
SELECT 
    activity_date,
    total_requests,
    unique_users,
    success_rate_pct,
    requests_with_feedback
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_DAILY_ACTIVITY
WHERE activity_date >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY activity_date DESC;

-- Sample 6.3: View user leaderboard
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_USER_LEADERBOARD
LIMIT 25;

-- Sample 6.4: Analyze table usage
SELECT 
    table_name,
    reference_count,
    unique_users,
    avg_refs_per_day,
    success_rate_pct,
    days_in_use
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_TABLE_USAGE
WHERE success_rate_pct < 90
ORDER BY reference_count DESC;

-- Sample 6.5: Review errors
SELECT 
    TIMESTAMP,
    USER_NAME,
    LATEST_QUESTION,
    ERROR_TYPE,
    RESPONSE_STATUS_CODE
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_ERROR_ANALYSIS
WHERE TIMESTAMP >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY TIMESTAMP DESC;

-- Sample 6.6: Track feedback sentiment
SELECT 
    feedback_date,
    feedback_type,
    feedback_count,
    unique_users
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_FEEDBACK_SUMMARY
WHERE feedback_date >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY feedback_date DESC, feedback_type;

-- Sample 6.7: Compare semantic model performance
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_SEMANTIC_MODEL_PERFORMANCE
ORDER BY total_requests DESC;

-- Sample 6.8: Identify peak usage hours
SELECT 
    hour_of_day,
    day_of_week,
    request_count,
    unique_users
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_HOURLY_ACTIVITY
WHERE request_count > 10
ORDER BY request_count DESC
LIMIT 20;

-- Sample 6.9: Analyze query complexity distribution
SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_COMPLEXITY_DISTRIBUTION
ORDER BY 
    CASE complexity_category
        WHEN 'Simple' THEN 1
        WHEN 'Moderate' THEN 2
        WHEN 'Complex' THEN 3
        WHEN 'Very Complex' THEN 4
    END;


-- ============================================================================
-- SECTION 7: Combined Analysis Examples
-- ============================================================================

-- Sample 7.1: Executive Dashboard Query
-- Combine multiple insights for a comprehensive overview
SELECT 
    'Total Requests' as metric,
    COUNT(*)::STRING as value
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
UNION ALL
SELECT 
    'Unique Users',
    COUNT(DISTINCT USER_NAME)::STRING
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
UNION ALL
SELECT 
    'Success Rate',
    ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 100.0 ELSE 0.0 END), 1)::STRING || '%'
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
UNION ALL
SELECT 
    'Avg Questions per User',
    ROUND(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT USER_NAME), 0), 1)::STRING
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;

-- Sample 7.2: Weekly Activity Report
-- Compare this week vs last week
WITH this_week AS (
    SELECT COUNT(*) as requests, COUNT(DISTINCT USER_NAME) as users
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATE_TRUNC('week', CURRENT_DATE())
),
last_week AS (
    SELECT COUNT(*) as requests, COUNT(DISTINCT USER_NAME) as users
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD('week', -1, DATE_TRUNC('week', CURRENT_DATE()))
      AND TIMESTAMP < DATE_TRUNC('week', CURRENT_DATE())
)
SELECT 
    'This Week' as period,
    tw.requests,
    tw.users,
    ROUND((tw.requests - lw.requests) * 100.0 / NULLIF(lw.requests, 0), 1) as requests_change_pct,
    ROUND((tw.users - lw.users) * 100.0 / NULLIF(lw.users, 0), 1) as users_change_pct
FROM this_week tw, last_week lw
UNION ALL
SELECT 
    'Last Week',
    lw.requests,
    lw.users,
    NULL,
    NULL
FROM last_week lw;

-- Sample 7.3: Power User Analysis
-- Identify power users and their patterns
WITH power_users AS (
    SELECT USER_NAME
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    GROUP BY USER_NAME
    HAVING COUNT(*) >= 20  -- 20+ questions in last 30 days
)
SELECT 
    h.USER_NAME,
    COUNT(*) as total_questions,
    COUNT(DISTINCT h.LATEST_QUESTION) as unique_questions,
    ROUND(AVG(LENGTH(h.GENERATED_SQL)), 0) as avg_sql_length,
    MODE(HOUR(h.TIMESTAMP)) as preferred_hour,
    MODE(DAYNAME(h.TIMESTAMP)) as preferred_day,
    ARRAY_AGG(DISTINCT t.value::STRING) as tables_accessed
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY h
INNER JOIN power_users pu ON h.USER_NAME = pu.USER_NAME
LEFT JOIN LATERAL FLATTEN(input => h.TABLES_REFERENCED) t ON TRUE
WHERE h.TIMESTAMP >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY h.USER_NAME
ORDER BY total_questions DESC;


-- ============================================================================
-- SECTION 8: Scheduled Monitoring Queries
-- ============================================================================
-- These queries are useful for scheduled reports or alerts

-- Sample 8.1: Daily Health Check
-- Run this daily to monitor system health
SELECT 
    CURRENT_DATE() as report_date,
    COUNT(*) as requests_last_24h,
    COUNT(DISTINCT USER_NAME) as active_users,
    ROUND(AVG(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 100.0 ELSE 0.0 END), 1) as success_rate_pct,
    SUM(CASE WHEN RESPONSE_STATUS_CODE != 200 THEN 1 ELSE 0 END) as error_count,
    SUM(CASE WHEN ARRAY_SIZE(WARNINGS) > 0 THEN 1 ELSE 0 END) as warning_count
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
WHERE TIMESTAMP >= DATEADD('day', -1, CURRENT_TIMESTAMP());

-- Sample 8.2: Error Alert Query
-- Identify if error rate is abnormally high
WITH recent_errors AS (
    SELECT 
        COUNT(*) as error_count,
        COUNT(*) * 100.0 / NULLIF(
            (SELECT COUNT(*) 
             FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY 
             WHERE TIMESTAMP >= DATEADD('hour', -1, CURRENT_TIMESTAMP())), 
            0
        ) as error_rate_pct
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
      AND RESPONSE_STATUS_CODE != 200
)
SELECT 
    error_count,
    ROUND(error_rate_pct, 2) as error_rate_pct,
    CASE 
        WHEN error_rate_pct > 10 THEN 'ALERT: High error rate'
        WHEN error_rate_pct > 5 THEN 'WARNING: Elevated error rate'
        ELSE 'OK'
    END as status
FROM recent_errors;

-- Sample 8.3: Feedback Alert Query
-- Identify if negative feedback is increasing
SELECT 
    COUNT(*) as negative_feedback_count,
    ARRAY_AGG(LATEST_QUESTION) as problematic_questions
FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY,
     LATERAL FLATTEN(input => FEEDBACK) f
WHERE TIMESTAMP >= DATEADD('day', -1, CURRENT_TIMESTAMP())
  AND f.value:feedback_type = 'thumbs_down'
HAVING COUNT(*) > 5;  -- Alert if more than 5 negative feedbacks in 24h


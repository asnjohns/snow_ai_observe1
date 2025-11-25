-- ============================================================================
-- Stored Procedure: GET_USER_QUESTION_PATTERNS
-- Purpose: Analyze most active users and their question patterns
-- 
-- Returns: Result set with user activity metrics including:
--   - User identification and activity counts
--   - Question patterns and themes
--   - Temporal patterns (day of week, hour)
--   - Success rates and feedback scores
-- 
-- Usage: CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);
-- ============================================================================

CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(
    DAYS_BACK INTEGER DEFAULT 30,
    TOP_N_USERS INTEGER DEFAULT 10
)
RETURNS TABLE (
    USER_NAME VARCHAR,
    USER_ID VARCHAR,
    TOTAL_QUESTIONS INTEGER,
    UNIQUE_QUESTIONS INTEGER,
    AVG_QUESTIONS_PER_DAY FLOAT,
    MOST_COMMON_QUESTION_PATTERN VARCHAR,
    SUCCESS_RATE FLOAT,
    AVG_RESPONSE_TIME_SECONDS FLOAT,
    POSITIVE_FEEDBACK_COUNT INTEGER,
    NEGATIVE_FEEDBACK_COUNT INTEGER,
    NET_SATISFACTION_SCORE FLOAT,
    MOST_ACTIVE_DAY_OF_WEEK VARCHAR,
    MOST_ACTIVE_HOUR INTEGER,
    FIRST_QUESTION_DATE TIMESTAMP_NTZ,
    LAST_QUESTION_DATE TIMESTAMP_NTZ,
    SEMANTIC_MODELS_USED ARRAY
)
LANGUAGE SQL
COMMENT = 'Analyze user activity patterns, question behavior, and satisfaction metrics'
AS
$$
DECLARE
    start_date TIMESTAMP_NTZ;
    result_set RESULTSET;
BEGIN
    -- Calculate start date based on DAYS_BACK parameter
    start_date := DATEADD('day', -:DAYS_BACK, CURRENT_TIMESTAMP());
    
    -- Build comprehensive user pattern analysis query
    result_set := (
        WITH user_base AS (
            -- Base user metrics and question counts
            SELECT 
                USER_NAME,
                USER_ID,
                COUNT(*) as total_questions,
                COUNT(DISTINCT LATEST_QUESTION) as unique_questions,
                MIN(TIMESTAMP) as first_question_date,
                MAX(TIMESTAMP) as last_question_date,
                DATEDIFF('day', MIN(TIMESTAMP), MAX(TIMESTAMP)) + 1 as days_active,
                ARRAY_AGG(DISTINCT SEMANTIC_MODEL_NAME) as semantic_models_used
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= :start_date
            GROUP BY USER_NAME, USER_ID
        ),
        user_success AS (
            -- Calculate success rates based on response codes
            SELECT 
                USER_NAME,
                COUNT(*) as total_requests,
                SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) as successful_requests,
                ROUND(successful_requests / NULLIF(total_requests, 0), 3) as success_rate
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= :start_date
            GROUP BY USER_NAME
        ),
        user_feedback AS (
            -- Analyze user feedback patterns
            SELECT 
                USER_NAME,
                SUM(CASE WHEN f.value:feedback_type = 'thumbs_up' THEN 1 ELSE 0 END) as positive_feedback,
                SUM(CASE WHEN f.value:feedback_type = 'thumbs_down' THEN 1 ELSE 0 END) as negative_feedback,
                ROUND((positive_feedback - negative_feedback) / NULLIF(positive_feedback + negative_feedback, 0), 3) as net_satisfaction
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY,
                 LATERAL FLATTEN(input => FEEDBACK) f
            WHERE TIMESTAMP >= :start_date
            GROUP BY USER_NAME
        ),
        user_temporal AS (
            -- Identify temporal patterns (most active day/hour)
            SELECT 
                USER_NAME,
                MODE(DAYNAME(TIMESTAMP)) as most_active_day,
                MODE(HOUR(TIMESTAMP)) as most_active_hour
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= :start_date
            GROUP BY USER_NAME
        ),
        user_question_patterns AS (
            -- Identify common question patterns using first 3 words
            SELECT 
                USER_NAME,
                MODE(
                    REGEXP_SUBSTR(LOWER(LATEST_QUESTION), '^\\w+\\s+\\w+\\s+\\w+')
                ) as most_common_pattern
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= :start_date
              AND LATEST_QUESTION IS NOT NULL
            GROUP BY USER_NAME
        ),
        user_response_time AS (
            -- Calculate average response time from request/response metadata
            SELECT 
                USER_NAME,
                ROUND(AVG(
                    DATEDIFF('millisecond', 
                        TRY_TO_TIMESTAMP(REQUEST_BODY:timestamp::STRING),
                        TRY_TO_TIMESTAMP(RESPONSE_BODY:timestamp::STRING)
                    ) / 1000.0
                ), 2) as avg_response_seconds
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= :start_date
              AND REQUEST_BODY:timestamp IS NOT NULL
              AND RESPONSE_BODY:timestamp IS NOT NULL
            GROUP BY USER_NAME
        )
        -- Combine all metrics into final result set
        SELECT 
            ub.USER_NAME,
            ub.USER_ID,
            ub.total_questions,
            ub.unique_questions,
            ROUND(ub.total_questions / NULLIF(ub.days_active, 0), 2) as avg_questions_per_day,
            uqp.most_common_pattern as most_common_question_pattern,
            COALESCE(us.success_rate, 0) as success_rate,
            COALESCE(urt.avg_response_seconds, 0) as avg_response_time_seconds,
            COALESCE(uf.positive_feedback, 0) as positive_feedback_count,
            COALESCE(uf.negative_feedback, 0) as negative_feedback_count,
            COALESCE(uf.net_satisfaction, 0) as net_satisfaction_score,
            ut.most_active_day as most_active_day_of_week,
            ut.most_active_hour as most_active_hour,
            ub.first_question_date,
            ub.last_question_date,
            ub.semantic_models_used
        FROM user_base ub
        LEFT JOIN user_success us ON ub.USER_NAME = us.USER_NAME
        LEFT JOIN user_feedback uf ON ub.USER_NAME = uf.USER_NAME
        LEFT JOIN user_temporal ut ON ub.USER_NAME = ut.USER_NAME
        LEFT JOIN user_question_patterns uqp ON ub.USER_NAME = uqp.USER_NAME
        LEFT JOIN user_response_time urt ON ub.USER_NAME = urt.USER_NAME
        ORDER BY ub.total_questions DESC
        LIMIT :TOP_N_USERS
    );
    
    RETURN TABLE(result_set);
END;
$$;


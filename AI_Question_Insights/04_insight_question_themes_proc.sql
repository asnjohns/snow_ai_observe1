-- ============================================================================
-- Stored Procedure: GET_QUESTION_THEMES_ANALYSIS
-- Purpose: Analyze common question themes and patterns from user queries
-- 
-- Returns: Result set with question theme metrics including:
--   - Common question patterns and keywords
--   - Question categories and intent classification
--   - Question complexity metrics
--   - Success rates by question type
-- 
-- Usage: CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(30, 25);
-- ============================================================================

CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_QUESTION_INSIGHTS.GET_QUESTION_THEMES_ANALYSIS(
    DAYS_BACK INTEGER DEFAULT 30,
    TOP_N_THEMES INTEGER DEFAULT 25
)
RETURNS TABLE (
    THEME_CATEGORY VARCHAR,
    QUESTION_COUNT INTEGER,
    UNIQUE_USERS INTEGER,
    AVG_QUESTION_LENGTH INTEGER,
    SUCCESS_RATE FLOAT,
    AVG_SQL_COMPLEXITY_SCORE FLOAT,
    MOST_REFERENCED_TABLES ARRAY,
    SAMPLE_QUESTIONS ARRAY,
    QUESTION_KEYWORDS ARRAY,
    FIRST_ASKED TIMESTAMP_NTZ,
    LAST_ASKED TIMESTAMP_NTZ,
    TREND VARCHAR,
    HAS_WARNINGS_PCT FLOAT,
    POSITIVE_FEEDBACK_RATE FLOAT
)
LANGUAGE SQL
COMMENT = 'Analyze common question themes, patterns, and intent from user queries'
AS
$$
DECLARE
    start_date TIMESTAMP_NTZ;
    result_set RESULTSET;
BEGIN
    start_date := DATEADD('day', -:DAYS_BACK, CURRENT_TIMESTAMP());
    
    result_set := (
        WITH questions_base AS (
            -- Base question data with classifications
            SELECT 
                REQUEST_ID,
                TIMESTAMP,
                USER_NAME,
                LATEST_QUESTION,
                GENERATED_SQL,
                RESPONSE_STATUS_CODE,
                TABLES_REFERENCED,
                WARNINGS,
                FEEDBACK,
                -- Classify questions by intent keywords
                CASE 
                    WHEN LOWER(LATEST_QUESTION) LIKE '%total%' OR LOWER(LATEST_QUESTION) LIKE '%sum%' OR LOWER(LATEST_QUESTION) LIKE '%count%' 
                        THEN 'Aggregation'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%trend%' OR LOWER(LATEST_QUESTION) LIKE '%over time%' OR LOWER(LATEST_QUESTION) LIKE '%by month%' 
                        THEN 'Trend Analysis'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%compare%' OR LOWER(LATEST_QUESTION) LIKE '%versus%' OR LOWER(LATEST_QUESTION) LIKE '%vs%' 
                        THEN 'Comparison'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%top%' OR LOWER(LATEST_QUESTION) LIKE '%bottom%' OR LOWER(LATEST_QUESTION) LIKE '%highest%' OR LOWER(LATEST_QUESTION) LIKE '%lowest%' 
                        THEN 'Ranking'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%forecast%' OR LOWER(LATEST_QUESTION) LIKE '%predict%' OR LOWER(LATEST_QUESTION) LIKE '%future%' 
                        THEN 'Forecasting'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%breakdown%' OR LOWER(LATEST_QUESTION) LIKE '%by%' OR LOWER(LATEST_QUESTION) LIKE '%group%' 
                        THEN 'Breakdown'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%find%' OR LOWER(LATEST_QUESTION) LIKE '%search%' OR LOWER(LATEST_QUESTION) LIKE '%lookup%' 
                        THEN 'Lookup'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%filter%' OR LOWER(LATEST_QUESTION) LIKE '%where%' OR LOWER(LATEST_QUESTION) LIKE '%with%' 
                        THEN 'Filtering'
                    WHEN LOWER(LATEST_QUESTION) LIKE '%list%' OR LOWER(LATEST_QUESTION) LIKE '%show%' OR LOWER(LATEST_QUESTION) LIKE '%all%' 
                        THEN 'Listing'
                    ELSE 'Other'
                END as theme_category,
                -- Calculate question length
                LENGTH(LATEST_QUESTION) as question_length,
                -- Calculate SQL complexity score (simple heuristic)
                (LENGTH(GENERATED_SQL) / 100.0) 
                    + (ARRAY_SIZE(REGEXP_SUBSTR_ALL(GENERATED_SQL, 'JOIN', 1, 1, 'i')) * 2) 
                    + (ARRAY_SIZE(REGEXP_SUBSTR_ALL(GENERATED_SQL, 'CASE', 1, 1, 'i')) * 1.5)
                    + (ARRAY_SIZE(REGEXP_SUBSTR_ALL(GENERATED_SQL, 'SUBQUERY|WITH', 1, 1, 'i')) * 3)
                    as sql_complexity_score
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
            WHERE TIMESTAMP >= :start_date
              AND LATEST_QUESTION IS NOT NULL
        ),
        theme_metrics AS (
            -- Calculate metrics by theme category
            SELECT 
                theme_category,
                COUNT(*) as question_count,
                COUNT(DISTINCT USER_NAME) as unique_users,
                ROUND(AVG(question_length), 0) as avg_question_length,
                ROUND(SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 3) as success_rate,
                ROUND(AVG(sql_complexity_score), 2) as avg_sql_complexity,
                MIN(TIMESTAMP) as first_asked,
                MAX(TIMESTAMP) as last_asked,
                SUM(CASE WHEN WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0 THEN 1 ELSE 0 END) as warnings_count
            FROM questions_base
            GROUP BY theme_category
        ),
        theme_tables AS (
            -- Identify most referenced tables by theme
            SELECT 
                qb.theme_category,
                ARRAY_AGG(DISTINCT t.value::STRING) WITHIN GROUP (ORDER BY COUNT(*) DESC) as most_referenced_tables
            FROM questions_base qb,
                 LATERAL FLATTEN(input => qb.TABLES_REFERENCED) t
            GROUP BY qb.theme_category
        ),
        theme_samples AS (
            -- Collect sample questions for each theme
            SELECT 
                theme_category,
                ARRAY_AGG(LATEST_QUESTION) WITHIN GROUP (ORDER BY TIMESTAMP DESC) as sample_questions
            FROM (
                SELECT 
                    theme_category,
                    LATEST_QUESTION,
                    TIMESTAMP,
                    ROW_NUMBER() OVER (PARTITION BY theme_category ORDER BY TIMESTAMP DESC) as rn
                FROM questions_base
            )
            WHERE rn <= 5  -- Keep up to 5 samples per theme
            GROUP BY theme_category
        ),
        theme_keywords AS (
            -- Extract common keywords from questions by theme
            SELECT 
                theme_category,
                ARRAY_AGG(DISTINCT keyword) as keywords
            FROM (
                SELECT 
                    theme_category,
                    TRIM(LOWER(word.value::STRING)) as keyword
                FROM questions_base,
                     LATERAL FLATTEN(input => SPLIT(LATEST_QUESTION, ' ')) word
                WHERE LENGTH(TRIM(word.value::STRING)) > 4  -- Only words longer than 4 chars
                  AND TRIM(LOWER(word.value::STRING)) NOT IN ('what', 'when', 'where', 'which', 'there', 'their', 'about', 'would', 'could', 'should')
            )
            GROUP BY theme_category
        ),
        theme_feedback AS (
            -- Calculate feedback metrics by theme
            SELECT 
                qb.theme_category,
                COUNT(*) as total_with_feedback,
                SUM(CASE WHEN f.value:feedback_type = 'thumbs_up' THEN 1 ELSE 0 END) as positive_feedback
            FROM questions_base qb,
                 LATERAL FLATTEN(input => qb.FEEDBACK) f
            GROUP BY qb.theme_category
        ),
        theme_trends AS (
            -- Calculate trend (growing, stable, declining) based on recent vs older questions
            SELECT 
                theme_category,
                SUM(CASE WHEN TIMESTAMP >= DATEADD('day', -7, CURRENT_TIMESTAMP()) THEN 1 ELSE 0 END) as recent_count,
                SUM(CASE WHEN TIMESTAMP < DATEADD('day', -7, CURRENT_TIMESTAMP()) 
                         AND TIMESTAMP >= DATEADD('day', -14, CURRENT_TIMESTAMP()) THEN 1 ELSE 0 END) as prior_count,
                CASE 
                    WHEN recent_count > prior_count * 1.2 THEN 'Growing'
                    WHEN recent_count < prior_count * 0.8 THEN 'Declining'
                    ELSE 'Stable'
                END as trend
            FROM questions_base
            GROUP BY theme_category
        )
        -- Combine all theme metrics
        SELECT 
            tm.theme_category,
            tm.question_count,
            tm.unique_users,
            tm.avg_question_length,
            tm.success_rate,
            tm.avg_sql_complexity as avg_sql_complexity_score,
            COALESCE(ARRAY_SLICE(tt.most_referenced_tables, 0, 10), ARRAY_CONSTRUCT()) as most_referenced_tables,
            COALESCE(ts.sample_questions, ARRAY_CONSTRUCT()) as sample_questions,
            COALESCE(ARRAY_SLICE(tk.keywords, 0, 20), ARRAY_CONSTRUCT()) as question_keywords,
            tm.first_asked,
            tm.last_asked,
            COALESCE(ttr.trend, 'Unknown') as trend,
            ROUND(tm.warnings_count / NULLIF(tm.question_count, 0) * 100, 1) as has_warnings_pct,
            ROUND(COALESCE(tf.positive_feedback / NULLIF(tf.total_with_feedback, 0), 0), 3) as positive_feedback_rate
        FROM theme_metrics tm
        LEFT JOIN theme_tables tt ON tm.theme_category = tt.theme_category
        LEFT JOIN theme_samples ts ON tm.theme_category = ts.theme_category
        LEFT JOIN theme_keywords tk ON tm.theme_category = tk.theme_category
        LEFT JOIN theme_feedback tf ON tm.theme_category = tf.theme_category
        LEFT JOIN theme_trends ttr ON tm.theme_category = ttr.theme_category
        ORDER BY tm.question_count DESC
        LIMIT :TOP_N_THEMES
    );
    
    RETURN TABLE(result_set);
END;
$$;


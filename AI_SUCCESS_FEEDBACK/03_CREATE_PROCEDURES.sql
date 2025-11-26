-- ============================================================================
-- AI_SUCCESS_FEEDBACK Schema - Stored Procedures and Functions
-- ============================================================================
-- Purpose: Create procedures/functions to support automated analysis
-- ============================================================================

USE DATABASE CURSOR_DB;
USE SCHEMA AI_SUCCESS_FEEDBACK;

-- ============================================================================
-- Procedure 1: Identify and Log Problematic SQL
-- ============================================================================
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_IDENTIFY_PROBLEMATIC_SQL(
    LOOKBACK_HOURS NUMBER
)
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Insert problematic SQL queries into tracking table
    INSERT INTO CURSOR_DB.AI_SUCCESS_FEEDBACK.PROBLEMATIC_SQL (
        REQUEST_ID,
        TIMESTAMP,
        SEMANTIC_MODEL_NAME,
        USER_ID,
        LATEST_QUESTION,
        GENERATED_SQL,
        PROBLEM_TYPE,
        PROBLEM_DESCRIPTION,
        RESPONSE_STATUS_CODE,
        SQL_COMPLEXITY_SCORE,
        IDENTIFIED_AT,
        RESOLVED
    )
    SELECT 
        REQUEST_ID,
        TIMESTAMP,
        SEMANTIC_MODEL_NAME,
        USER_ID,
        LATEST_QUESTION,
        GENERATED_SQL,
        CASE 
            WHEN RESPONSE_STATUS_CODE != 200 THEN 'EXECUTION_ERROR'
            WHEN WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0 THEN 'HAS_WARNINGS'
            WHEN LENGTH(GENERATED_SQL) > 5000 THEN 'COMPLEX_SQL'
            ELSE 'OTHER'
        END AS PROBLEM_TYPE,
        CASE 
            WHEN RESPONSE_STATUS_CODE != 200 THEN 'SQL execution failed with status code: ' || RESPONSE_STATUS_CODE
            WHEN WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0 THEN 'SQL has ' || ARRAY_SIZE(WARNINGS) || ' warnings'
            WHEN LENGTH(GENERATED_SQL) > 5000 THEN 'SQL is overly complex (' || LENGTH(GENERATED_SQL) || ' chars)'
            ELSE 'Potential quality issue detected'
        END AS PROBLEM_DESCRIPTION,
        RESPONSE_STATUS_CODE,
        (COALESCE(LENGTH(GENERATED_SQL), 0) / 100.0) + 
        (REGEXP_COUNT(GENERATED_SQL, 'JOIN', 1, 'i') * 2) +
        (REGEXP_COUNT(GENERATED_SQL, 'GROUP BY', 1, 'i') * 2) AS SQL_COMPLEXITY_SCORE,
        CURRENT_TIMESTAMP() AS IDENTIFIED_AT,
        FALSE AS RESOLVED
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD(HOUR, -LOOKBACK_HOURS, CURRENT_TIMESTAMP())
      AND (RESPONSE_STATUS_CODE != 200 
           OR (WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0)
           OR LENGTH(GENERATED_SQL) > 5000)
      AND REQUEST_ID NOT IN (SELECT REQUEST_ID FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.PROBLEMATIC_SQL);
    
    RETURN 'Identified and logged problematic SQL queries from last ' || LOOKBACK_HOURS || ' hours';
END;
$$;

-- ============================================================================
-- Procedure 2: Analyze Response Status Patterns
-- ============================================================================
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_STATUS_PATTERNS(
    LOOKBACK_DAYS NUMBER
)
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Clear existing patterns for the lookback period
    DELETE FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.RESPONSE_STATUS_PATTERNS
    WHERE ANALYZED_AT >= DATEADD(DAY, -LOOKBACK_DAYS, CURRENT_TIMESTAMP());
    
    -- Insert new pattern analysis
    INSERT INTO CURSOR_DB.AI_SUCCESS_FEEDBACK.RESPONSE_STATUS_PATTERNS (
        STATUS_CODE,
        ERROR_CATEGORY,
        SEMANTIC_MODEL_NAME,
        OCCURRENCE_COUNT,
        FIRST_OCCURRENCE,
        LAST_OCCURRENCE,
        SAMPLE_REQUEST_IDS,
        PATTERN_DESCRIPTION,
        ANALYZED_AT
    )
    SELECT 
        RESPONSE_STATUS_CODE,
        CASE 
            WHEN RESPONSE_STATUS_CODE = 200 THEN 'SUCCESS'
            WHEN RESPONSE_STATUS_CODE = 400 THEN 'BAD_REQUEST'
            WHEN RESPONSE_STATUS_CODE = 401 THEN 'UNAUTHORIZED'
            WHEN RESPONSE_STATUS_CODE = 403 THEN 'FORBIDDEN'
            WHEN RESPONSE_STATUS_CODE = 404 THEN 'NOT_FOUND'
            WHEN RESPONSE_STATUS_CODE = 500 THEN 'INTERNAL_SERVER_ERROR'
            WHEN RESPONSE_STATUS_CODE = 503 THEN 'SERVICE_UNAVAILABLE'
            ELSE 'OTHER_ERROR'
        END AS ERROR_CATEGORY,
        SEMANTIC_MODEL_NAME,
        COUNT(*) AS OCCURRENCE_COUNT,
        MIN(TIMESTAMP) AS FIRST_OCCURRENCE,
        MAX(TIMESTAMP) AS LAST_OCCURRENCE,
        ARRAY_AGG(REQUEST_ID) WITHIN GROUP (ORDER BY TIMESTAMP DESC) AS SAMPLE_REQUEST_IDS,
        'Status code ' || RESPONSE_STATUS_CODE || ' occurred ' || COUNT(*) || ' times for model ' || SEMANTIC_MODEL_NAME AS PATTERN_DESCRIPTION,
        CURRENT_TIMESTAMP() AS ANALYZED_AT
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD(DAY, -LOOKBACK_DAYS, CURRENT_TIMESTAMP())
      AND RESPONSE_STATUS_CODE != 200
    GROUP BY RESPONSE_STATUS_CODE, SEMANTIC_MODEL_NAME;
    
    RETURN 'Analyzed response status patterns for last ' || LOOKBACK_DAYS || ' days';
END;
$$;

-- ============================================================================
-- Procedure 3: Analyze Warning Patterns
-- ============================================================================
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_WARNING_PATTERNS(
    LOOKBACK_DAYS NUMBER
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_inserted NUMBER;
BEGIN
    -- Clear existing warning patterns for the lookback period
    DELETE FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.WARNING_ISSUES
    WHERE ANALYZED_AT >= DATEADD(DAY, -LOOKBACK_DAYS, CURRENT_TIMESTAMP());
    
    -- Insert new warning pattern analysis
    INSERT INTO CURSOR_DB.AI_SUCCESS_FEEDBACK.WARNING_ISSUES (
        WARNING_TYPE,
        WARNING_MESSAGE,
        SEMANTIC_MODEL_NAME,
        OCCURRENCE_COUNT,
        FIRST_OCCURRENCE,
        LAST_OCCURRENCE,
        AFFECTED_REQUEST_IDS,
        SEVERITY,
        ANALYZED_AT
    )
    WITH warning_details AS (
        SELECT 
            r.SEMANTIC_MODEL_NAME,
            r.REQUEST_ID,
            r.TIMESTAMP,
            w.value::STRING AS WARNING_MESSAGE
        FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY r,
        LATERAL FLATTEN(input => r.WARNINGS) w
        WHERE r.TIMESTAMP >= DATEADD(DAY, -LOOKBACK_DAYS, CURRENT_TIMESTAMP())
          AND r.WARNINGS IS NOT NULL 
          AND ARRAY_SIZE(r.WARNINGS) > 0
    )
    SELECT 
        'GENERAL' AS WARNING_TYPE,
        WARNING_MESSAGE,
        SEMANTIC_MODEL_NAME,
        COUNT(*) AS OCCURRENCE_COUNT,
        MIN(TIMESTAMP) AS FIRST_OCCURRENCE,
        MAX(TIMESTAMP) AS LAST_OCCURRENCE,
        ARRAY_AGG(REQUEST_ID) WITHIN GROUP (ORDER BY TIMESTAMP DESC) AS AFFECTED_REQUEST_IDS,
        CASE 
            WHEN COUNT(*) > 100 THEN 'CRITICAL'
            WHEN COUNT(*) > 50 THEN 'HIGH'
            WHEN COUNT(*) > 10 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS SEVERITY,
        CURRENT_TIMESTAMP() AS ANALYZED_AT
    FROM warning_details
    GROUP BY WARNING_MESSAGE, SEMANTIC_MODEL_NAME;
    
    rows_inserted := SQLROWCOUNT;
    
    RETURN 'Analyzed warning patterns for last ' || LOOKBACK_DAYS || ' days. Inserted ' || rows_inserted || ' warning patterns.';
END;
$$;

-- ============================================================================
-- Procedure 4: Analyze Feedback Patterns
-- ============================================================================
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_FEEDBACK_PATTERNS(
    LOOKBACK_DAYS NUMBER
)
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Clear existing feedback analysis for the lookback period
    DELETE FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.FEEDBACK_ANALYSIS
    WHERE ANALYZED_AT >= DATEADD(DAY, -LOOKBACK_DAYS, CURRENT_TIMESTAMP());
    
    -- Insert new feedback analysis
    INSERT INTO CURSOR_DB.AI_SUCCESS_FEEDBACK.FEEDBACK_ANALYSIS (
        REQUEST_ID,
        TIMESTAMP,
        SEMANTIC_MODEL_NAME,
        USER_ID,
        QUESTION_TYPE,
        FEEDBACK_SENTIMENT,
        FEEDBACK_DETAILS,
        SQL_COMPLEXITY_SCORE,
        RESPONSE_STATUS_CODE,
        ANALYZED_AT
    )
    SELECT 
        REQUEST_ID,
        TIMESTAMP,
        SEMANTIC_MODEL_NAME,
        USER_ID,
        CASE 
            WHEN LATEST_QUESTION ILIKE '%how many%' OR LATEST_QUESTION ILIKE '%count%' THEN 'COUNT_QUERY'
            WHEN LATEST_QUESTION ILIKE '%sum%' OR LATEST_QUESTION ILIKE '%total%' THEN 'AGGREGATION_QUERY'
            WHEN LATEST_QUESTION ILIKE '%average%' OR LATEST_QUESTION ILIKE '%avg%' THEN 'AVERAGE_QUERY'
            WHEN LATEST_QUESTION ILIKE '%top%' OR LATEST_QUESTION ILIKE '%highest%' THEN 'TOP_N_QUERY'
            WHEN LATEST_QUESTION ILIKE '%trend%' OR LATEST_QUESTION ILIKE '%over time%' THEN 'TREND_QUERY'
            ELSE 'OTHER_QUERY'
        END AS QUESTION_TYPE,
        'NEUTRAL' AS FEEDBACK_SENTIMENT,  -- Can be enhanced with sentiment analysis
        FEEDBACK AS FEEDBACK_DETAILS,
        (COALESCE(LENGTH(GENERATED_SQL), 0) / 100.0) + 
        (REGEXP_COUNT(GENERATED_SQL, 'JOIN', 1, 'i') * 2) +
        (REGEXP_COUNT(GENERATED_SQL, 'GROUP BY', 1, 'i') * 2) AS SQL_COMPLEXITY_SCORE,
        RESPONSE_STATUS_CODE,
        CURRENT_TIMESTAMP() AS ANALYZED_AT
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD(DAY, -LOOKBACK_DAYS, CURRENT_TIMESTAMP())
      AND FEEDBACK IS NOT NULL 
      AND ARRAY_SIZE(FEEDBACK) > 0;
    
    RETURN 'Analyzed feedback patterns for last ' || LOOKBACK_DAYS || ' days';
END;
$$;

-- ============================================================================
-- Procedure 5: Identify Quality Discrepancies
-- ============================================================================
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_IDENTIFY_QUALITY_DISCREPANCIES(
    LOOKBACK_HOURS NUMBER
)
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Insert quality discrepancies
    INSERT INTO CURSOR_DB.AI_SUCCESS_FEEDBACK.SQL_QUALITY_DISCREPANCIES (
        REQUEST_ID,
        TIMESTAMP,
        SEMANTIC_MODEL_NAME,
        USER_ID,
        LATEST_QUESTION,
        GENERATED_SQL,
        TECHNICAL_STATUS,
        USER_EXPECTATION,
        DISCREPANCY_TYPE,
        DISCREPANCY_DESCRIPTION,
        IDENTIFIED_AT
    )
    SELECT 
        REQUEST_ID,
        TIMESTAMP,
        SEMANTIC_MODEL_NAME,
        USER_ID,
        LATEST_QUESTION,
        GENERATED_SQL,
        CASE 
            WHEN RESPONSE_STATUS_CODE = 200 AND GENERATED_SQL IS NOT NULL THEN 'EXECUTES_SUCCESSFULLY'
            WHEN RESPONSE_STATUS_CODE = 200 THEN 'SYNTACTICALLY_CORRECT'
            ELSE 'ERROR'
        END AS TECHNICAL_STATUS,
        'Expected correct and satisfactory results' AS USER_EXPECTATION,
        CASE 
            WHEN FEEDBACK IS NOT NULL AND ARRAY_SIZE(FEEDBACK) > 0 THEN 'INCORRECT_LOGIC'
            WHEN WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0 THEN 'INCOMPLETE_RESULTS'
            ELSE 'OTHER'
        END AS DISCREPANCY_TYPE,
        CASE 
            WHEN FEEDBACK IS NOT NULL AND ARRAY_SIZE(FEEDBACK) > 0 THEN 'Technically correct but user provided feedback indicating issues'
            WHEN WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0 THEN 'Executed successfully but generated ' || ARRAY_SIZE(WARNINGS) || ' warnings'
            ELSE 'Other discrepancy detected'
        END AS DISCREPANCY_DESCRIPTION,
        CURRENT_TIMESTAMP() AS IDENTIFIED_AT
    FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    WHERE TIMESTAMP >= DATEADD(HOUR, -LOOKBACK_HOURS, CURRENT_TIMESTAMP())
      AND RESPONSE_STATUS_CODE = 200
      AND ((FEEDBACK IS NOT NULL AND ARRAY_SIZE(FEEDBACK) > 0)
           OR (WARNINGS IS NOT NULL AND ARRAY_SIZE(WARNINGS) > 0))
      AND REQUEST_ID NOT IN (SELECT REQUEST_ID FROM CURSOR_DB.AI_SUCCESS_FEEDBACK.SQL_QUALITY_DISCREPANCIES);
    
    RETURN 'Identified quality discrepancies from last ' || LOOKBACK_HOURS || ' hours';
END;
$$;

-- ============================================================================
-- Procedure 6: Master Analysis Procedure - Run All Analyses
-- ============================================================================
CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_RUN_ALL_ANALYSES(
    LOOKBACK_DAYS NUMBER DEFAULT 7
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    result1 STRING;
    result2 STRING;
    result3 STRING;
    result4 STRING;
    result5 STRING;
BEGIN
    -- Run all analysis procedures
    CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_IDENTIFY_PROBLEMATIC_SQL(LOOKBACK_DAYS * 24) INTO :result1;
    CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_STATUS_PATTERNS(LOOKBACK_DAYS) INTO :result2;
    CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_WARNING_PATTERNS(LOOKBACK_DAYS) INTO :result3;
    CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_ANALYZE_FEEDBACK_PATTERNS(LOOKBACK_DAYS) INTO :result4;
    CALL CURSOR_DB.AI_SUCCESS_FEEDBACK.SP_IDENTIFY_QUALITY_DISCREPANCIES(LOOKBACK_DAYS * 24) INTO :result5;
    
    RETURN 'All analyses completed for last ' || LOOKBACK_DAYS || ' days:\n' ||
           '1. ' || result1 || '\n' ||
           '2. ' || result2 || '\n' ||
           '3. ' || result3 || '\n' ||
           '4. ' || result4 || '\n' ||
           '5. ' || result5;
END;
$$;

-- ============================================================================
-- Function: Calculate SQL Complexity Score
-- ============================================================================
CREATE OR REPLACE FUNCTION CURSOR_DB.AI_SUCCESS_FEEDBACK.FN_CALCULATE_SQL_COMPLEXITY(
    SQL_TEXT VARCHAR
)
RETURNS FLOAT
LANGUAGE SQL
AS
$$
    (COALESCE(LENGTH(SQL_TEXT), 0) / 100.0) + 
    (REGEXP_COUNT(SQL_TEXT, 'JOIN', 1, 'i') * 2) +
    (REGEXP_COUNT(SQL_TEXT, 'WHERE', 1, 'i') * 1) +
    (REGEXP_COUNT(SQL_TEXT, 'GROUP BY', 1, 'i') * 2) +
    (REGEXP_COUNT(SQL_TEXT, 'HAVING', 1, 'i') * 2) +
    (REGEXP_COUNT(SQL_TEXT, 'CASE', 1, 'i') * 1.5) +
    (REGEXP_COUNT(SQL_TEXT, 'UNION', 1, 'i') * 3) +
    (REGEXP_COUNT(SQL_TEXT, 'SUBQUERY|\\(SELECT', 1, 'i') * 2.5)
$$;

-- ============================================================================
-- Function: Categorize SQL Complexity
-- ============================================================================
CREATE OR REPLACE FUNCTION CURSOR_DB.AI_SUCCESS_FEEDBACK.FN_CATEGORIZE_COMPLEXITY(
    COMPLEXITY_SCORE FLOAT
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    CASE 
        WHEN COMPLEXITY_SCORE < 5 THEN 'SIMPLE'
        WHEN COMPLEXITY_SCORE < 15 THEN 'MODERATE'
        ELSE 'COMPLEX'
    END
$$;

SELECT 'All procedures and functions created successfully' AS STATUS;




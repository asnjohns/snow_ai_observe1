-- ============================================================================
-- Stored Procedure: REFRESH_CORTEX_ANALYST_HISTORY
-- Purpose: Load data from CORTEX_ANALYST_REQUESTS table function into base table
-- Usage: CALL CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
--          'SEMANTIC_VIEW', 
--          'CURSOR_DB.ANALYTICS.CURSOR_DEMO_ANALYST_MODEL',
--          TRUE
--        );
-- ============================================================================

CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_QUESTION_INSIGHTS.REFRESH_CORTEX_ANALYST_HISTORY(
    SEMANTIC_MODEL_TYPE_PARAM VARCHAR,
    SEMANTIC_MODEL_NAME_PARAM VARCHAR,
    INCREMENTAL BOOLEAN DEFAULT TRUE
)
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Refresh the Cortex Analyst request history table from the CORTEX_ANALYST_REQUESTS table function'
AS
$$
DECLARE
    rows_inserted INTEGER DEFAULT 0;
    last_timestamp TIMESTAMP_NTZ;
BEGIN
    -- If incremental load, get the last timestamp from the table
    IF (INCREMENTAL) THEN
        SELECT MAX(TIMESTAMP) INTO :last_timestamp 
        FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
        WHERE SEMANTIC_MODEL_NAME = :SEMANTIC_MODEL_NAME_PARAM;
        
        -- If no records exist, set to old date
        IF (last_timestamp IS NULL) THEN
            last_timestamp := TO_TIMESTAMP_NTZ('1900-01-01');
        END IF;
    ELSE
        last_timestamp := TO_TIMESTAMP_NTZ('1900-01-01');
    END IF;
    
    -- Insert new records from CORTEX_ANALYST_REQUESTS table function
    INSERT INTO CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY
    (
        TIMESTAMP, REQUEST_ID, SEMANTIC_MODEL_TYPE, SEMANTIC_MODEL_NAME,
        TABLES_REFERENCED, USER_ID, USER_NAME, SOURCE, LATEST_QUESTION,
        GENERATED_SQL, REQUEST_BODY, RESPONSE_BODY, RESPONSE_STATUS_CODE,
        WARNINGS, FEEDBACK, PRIMARY_ROLE_NAME, RESPONSE_METADATA
    )
    SELECT 
        TIMESTAMP, REQUEST_ID, SEMANTIC_MODEL_TYPE, SEMANTIC_MODEL_NAME,
        TABLES_REFERENCED, USER_ID, USER_NAME, SOURCE, LATEST_QUESTION,
        GENERATED_SQL, REQUEST_BODY, RESPONSE_BODY, RESPONSE_STATUS_CODE,
        WARNINGS, FEEDBACK, PRIMARY_ROLE_NAME, RESPONSE_METADATA
    FROM TABLE(SNOWFLAKE.LOCAL.CORTEX_ANALYST_REQUESTS(
        :SEMANTIC_MODEL_TYPE_PARAM,
        :SEMANTIC_MODEL_NAME_PARAM
    ))
    WHERE TIMESTAMP > :last_timestamp;
    
    -- Get count of rows inserted
    rows_inserted := SQLROWCOUNT;
    
    -- Return success message
    RETURN 'Successfully loaded ' || rows_inserted || ' new records for semantic model: ' || SEMANTIC_MODEL_NAME_PARAM;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error loading data: ' || SQLERRM;
END;
$$;


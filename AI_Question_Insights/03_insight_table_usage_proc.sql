-- ============================================================================
-- Stored Procedure: GET_TABLE_JOIN_USAGE_ANALYSIS
-- Purpose: Analyze which tables and joins are frequently or rarely used
-- 
-- Returns: Result set with table usage metrics including:
--   - Table reference frequency
--   - Join patterns and complexity
--   - Tables that are underutilized
--   - Common table combinations
-- 
-- Usage: CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(30, 50);
-- ============================================================================

CREATE OR REPLACE PROCEDURE CURSOR_DB.AI_QUESTION_INSIGHTS.GET_TABLE_JOIN_USAGE_ANALYSIS(
    DAYS_BACK INTEGER DEFAULT 30,
    RESULT_LIMIT INTEGER DEFAULT 50
)
RETURNS TABLE (
    TABLE_NAME VARCHAR,
    DATABASE_NAME VARCHAR,
    SCHEMA_NAME VARCHAR,
    TOTAL_REFERENCES INTEGER,
    UNIQUE_QUERIES INTEGER,
    FIRST_USED TIMESTAMP_NTZ,
    LAST_USED TIMESTAMP_NTZ,
    AVG_REFERENCES_PER_DAY FLOAT,
    JOIN_COUNT INTEGER,
    AVG_TABLES_JOINED_WITH FLOAT,
    MOST_COMMON_JOIN_PARTNER VARCHAR,
    SUCCESS_RATE_FOR_TABLE FLOAT,
    UNIQUE_USERS_ACCESSING INTEGER,
    IS_UNDERUTILIZED BOOLEAN,
    SAMPLE_QUESTIONS ARRAY
)
LANGUAGE SQL
COMMENT = 'Analyze table and join usage patterns to identify frequently and rarely used tables'
AS
$$
DECLARE
    start_date TIMESTAMP_NTZ;
    result_set RESULTSET;
BEGIN
    start_date := DATEADD('day', -:DAYS_BACK, CURRENT_TIMESTAMP());
    
    result_set := (
        WITH exploded_tables AS (
            -- Explode the TABLES_REFERENCED array to get individual table references
            SELECT 
                REQUEST_ID,
                TIMESTAMP,
                USER_NAME,
                LATEST_QUESTION,
                GENERATED_SQL,
                RESPONSE_STATUS_CODE,
                t.value::STRING as full_table_name
            FROM CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY,
                 LATERAL FLATTEN(input => TABLES_REFERENCED) t
            WHERE TIMESTAMP >= :start_date
              AND TABLES_REFERENCED IS NOT NULL
        ),
        parsed_tables AS (
            -- Parse table names into database, schema, table components
            SELECT 
                REQUEST_ID,
                TIMESTAMP,
                USER_NAME,
                LATEST_QUESTION,
                GENERATED_SQL,
                RESPONSE_STATUS_CODE,
                full_table_name,
                SPLIT_PART(full_table_name, '.', 1) as database_name,
                SPLIT_PART(full_table_name, '.', 2) as schema_name,
                SPLIT_PART(full_table_name, '.', 3) as table_name
            FROM exploded_tables
        ),
        table_metrics AS (
            -- Calculate basic table usage metrics
            SELECT 
                table_name,
                database_name,
                schema_name,
                COUNT(*) as total_references,
                COUNT(DISTINCT REQUEST_ID) as unique_queries,
                MIN(TIMESTAMP) as first_used,
                MAX(TIMESTAMP) as last_used,
                COUNT(DISTINCT USER_NAME) as unique_users,
                ROUND(COUNT(*) / NULLIF(DATEDIFF('day', MIN(TIMESTAMP), MAX(TIMESTAMP)) + 1, 0), 2) as avg_refs_per_day,
                ROUND(SUM(CASE WHEN RESPONSE_STATUS_CODE = 200 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 3) as success_rate
            FROM parsed_tables
            GROUP BY table_name, database_name, schema_name
        ),
        join_analysis AS (
            -- Analyze JOIN patterns: count how many times tables appear with other tables
            SELECT 
                pt1.table_name,
                pt1.database_name,
                pt1.schema_name,
                COUNT(DISTINCT pt1.REQUEST_ID) as join_count,
                COUNT(DISTINCT pt2.table_name) as distinct_join_partners,
                ROUND(COUNT(DISTINCT pt2.table_name) / NULLIF(COUNT(DISTINCT pt1.REQUEST_ID), 0), 2) as avg_tables_joined
            FROM parsed_tables pt1
            INNER JOIN parsed_tables pt2 
                ON pt1.REQUEST_ID = pt2.REQUEST_ID 
                AND pt1.full_table_name != pt2.full_table_name
            GROUP BY pt1.table_name, pt1.database_name, pt1.schema_name
        ),
        most_common_joins AS (
            -- Find the most common join partner for each table
            SELECT 
                pt1.table_name,
                pt1.database_name,
                pt1.schema_name,
                MODE(pt2.table_name) as most_common_partner
            FROM parsed_tables pt1
            INNER JOIN parsed_tables pt2 
                ON pt1.REQUEST_ID = pt2.REQUEST_ID 
                AND pt1.full_table_name != pt2.full_table_name
            GROUP BY pt1.table_name, pt1.database_name, pt1.schema_name
        ),
        sample_questions_agg AS (
            -- Collect sample questions for each table
            SELECT 
                table_name,
                database_name,
                schema_name,
                ARRAY_AGG(DISTINCT LATEST_QUESTION) WITHIN GROUP (ORDER BY TIMESTAMP DESC) as sample_questions
            FROM (
                SELECT 
                    table_name,
                    database_name,
                    schema_name,
                    LATEST_QUESTION,
                    TIMESTAMP,
                    ROW_NUMBER() OVER (PARTITION BY table_name, database_name, schema_name ORDER BY TIMESTAMP DESC) as rn
                FROM parsed_tables
                WHERE LATEST_QUESTION IS NOT NULL
            )
            WHERE rn <= 5  -- Keep up to 5 sample questions per table
            GROUP BY table_name, database_name, schema_name
        ),
        underutilization_check AS (
            -- Identify underutilized tables (less than 1 reference per week on average)
            SELECT 
                table_name,
                database_name,
                schema_name,
                CASE 
                    WHEN avg_refs_per_day < (1.0 / 7.0) THEN TRUE  -- Less than 1 use per week
                    ELSE FALSE 
                END as is_underutilized
            FROM table_metrics
        )
        -- Combine all metrics into final result
        SELECT 
            tm.table_name,
            tm.database_name,
            tm.schema_name,
            tm.total_references,
            tm.unique_queries,
            tm.first_used,
            tm.last_used,
            tm.avg_refs_per_day,
            COALESCE(ja.join_count, 0) as join_count,
            COALESCE(ja.avg_tables_joined, 0) as avg_tables_joined_with,
            mcj.most_common_partner as most_common_join_partner,
            tm.success_rate as success_rate_for_table,
            tm.unique_users as unique_users_accessing,
            uc.is_underutilized,
            COALESCE(sqa.sample_questions, ARRAY_CONSTRUCT()) as sample_questions
        FROM table_metrics tm
        LEFT JOIN join_analysis ja 
            ON tm.table_name = ja.table_name 
            AND tm.database_name = ja.database_name 
            AND tm.schema_name = ja.schema_name
        LEFT JOIN most_common_joins mcj 
            ON tm.table_name = mcj.table_name 
            AND tm.database_name = mcj.database_name 
            AND tm.schema_name = mcj.schema_name
        LEFT JOIN sample_questions_agg sqa 
            ON tm.table_name = sqa.table_name 
            AND tm.database_name = sqa.database_name 
            AND tm.schema_name = sqa.schema_name
        LEFT JOIN underutilization_check uc 
            ON tm.table_name = uc.table_name 
            AND tm.database_name = uc.database_name 
            AND tm.schema_name = uc.schema_name
        ORDER BY tm.total_references DESC
        LIMIT :RESULT_LIMIT
    );
    
    RETURN TABLE(result_set);
END;
$$;


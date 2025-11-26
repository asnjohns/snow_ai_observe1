-- ============================================================================
-- AI_SUCCESS_FEEDBACK Schema - Table Definitions
-- ============================================================================
-- Purpose: Create tables to support 7 key insights for AI success feedback
-- ============================================================================

USE DATABASE CURSOR_DB;
USE SCHEMA AI_SUCCESS_FEEDBACK;

-- ============================================================================
-- Table 1: PROBLEMATIC_SQL - Track problematic SQL queries
-- ============================================================================
CREATE TABLE IF NOT EXISTS CURSOR_DB.AI_SUCCESS_FEEDBACK.PROBLEMATIC_SQL (
    PROBLEM_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    REQUEST_ID VARCHAR(16777216) NOT NULL,
    TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    SEMANTIC_MODEL_NAME VARCHAR(16777216),
    USER_ID VARCHAR(16777216),
    LATEST_QUESTION VARCHAR(16777216),
    GENERATED_SQL VARCHAR(16777216),
    PROBLEM_TYPE VARCHAR(100),  -- 'SYNTAX_ERROR', 'EXECUTION_ERROR', 'INCORRECT_RESULT', 'POOR_PERFORMANCE', etc.
    PROBLEM_DESCRIPTION VARCHAR(16777216),
    RESPONSE_STATUS_CODE NUMBER(38,0),
    SQL_COMPLEXITY_SCORE FLOAT,
    IDENTIFIED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    RESOLVED BOOLEAN DEFAULT FALSE,
    RESOLUTION_NOTES VARCHAR(16777216),
    RESOLVED_AT TIMESTAMP_NTZ,
    COMMENT 'Tracks problematic SQL queries for pattern analysis and improvement'
);

-- ============================================================================
-- Table 2: RESPONSE_STATUS_PATTERNS - Track status code patterns
-- ============================================================================
CREATE TABLE IF NOT EXISTS CURSOR_DB.AI_SUCCESS_FEEDBACK.RESPONSE_STATUS_PATTERNS (
    PATTERN_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    STATUS_CODE NUMBER(38,0) NOT NULL,
    ERROR_CATEGORY VARCHAR(100),
    SEMANTIC_MODEL_NAME VARCHAR(16777216),
    OCCURRENCE_COUNT NUMBER(38,0),
    FIRST_OCCURRENCE TIMESTAMP_NTZ,
    LAST_OCCURRENCE TIMESTAMP_NTZ,
    SAMPLE_REQUEST_IDS ARRAY,
    PATTERN_DESCRIPTION VARCHAR(16777216),
    ANALYZED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    COMMENT 'Tracks response status code failures and patterns over time'
);

-- ============================================================================
-- Table 3: WARNING_ISSUES - Track recurring warning issues
-- ============================================================================
CREATE TABLE IF NOT EXISTS CURSOR_DB.AI_SUCCESS_FEEDBACK.WARNING_ISSUES (
    WARNING_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    WARNING_TYPE VARCHAR(200),
    WARNING_MESSAGE VARCHAR(16777216),
    SEMANTIC_MODEL_NAME VARCHAR(16777216),
    OCCURRENCE_COUNT NUMBER(38,0),
    FIRST_OCCURRENCE TIMESTAMP_NTZ,
    LAST_OCCURRENCE TIMESTAMP_NTZ,
    AFFECTED_REQUEST_IDS ARRAY,
    SEVERITY VARCHAR(50),  -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    ANALYZED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    COMMENT 'Tracks recurring warning issues for pattern analysis'
);

-- ============================================================================
-- Table 4: FEEDBACK_ANALYSIS - Detailed feedback tracking
-- ============================================================================
CREATE TABLE IF NOT EXISTS CURSOR_DB.AI_SUCCESS_FEEDBACK.FEEDBACK_ANALYSIS (
    FEEDBACK_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    REQUEST_ID VARCHAR(16777216) NOT NULL,
    TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    SEMANTIC_MODEL_NAME VARCHAR(16777216),
    USER_ID VARCHAR(16777216),
    QUESTION_TYPE VARCHAR(100),
    FEEDBACK_SENTIMENT VARCHAR(50),  -- 'POSITIVE', 'NEGATIVE', 'NEUTRAL'
    FEEDBACK_DETAILS VARIANT,
    SQL_COMPLEXITY_SCORE FLOAT,
    RESPONSE_STATUS_CODE NUMBER(38,0),
    ANALYZED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    COMMENT 'Detailed feedback analysis for correlation with SQL complexity and question types'
);

-- ============================================================================
-- Table 5: SQL_QUALITY_DISCREPANCIES - Track technically correct but unsatisfactory SQL
-- ============================================================================
CREATE TABLE IF NOT EXISTS CURSOR_DB.AI_SUCCESS_FEEDBACK.SQL_QUALITY_DISCREPANCIES (
    DISCREPANCY_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    REQUEST_ID VARCHAR(16777216) NOT NULL,
    TIMESTAMP TIMESTAMP_NTZ NOT NULL,
    SEMANTIC_MODEL_NAME VARCHAR(16777216),
    USER_ID VARCHAR(16777216),
    LATEST_QUESTION VARCHAR(16777216),
    GENERATED_SQL VARCHAR(16777216),
    TECHNICAL_STATUS VARCHAR(50),  -- 'SYNTACTICALLY_CORRECT', 'EXECUTES_SUCCESSFULLY'
    USER_EXPECTATION VARCHAR(16777216),
    DISCREPANCY_TYPE VARCHAR(100),  -- 'INCORRECT_LOGIC', 'INCOMPLETE_RESULTS', 'PERFORMANCE_ISSUE'
    DISCREPANCY_DESCRIPTION VARCHAR(16777216),
    IDENTIFIED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    COMMENT 'Tracks discrepancies between technically correct SQL and user expectations'
);

SELECT 'Tables created successfully' AS STATUS;




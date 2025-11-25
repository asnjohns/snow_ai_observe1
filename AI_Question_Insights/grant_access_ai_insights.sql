-- ============================================================================
-- AI QUESTION INSIGHTS - ACCESS GRANTS
-- ============================================================================
-- Purpose: Grant access to AI_QUESTION_INSIGHTS schema and all objects
-- Run as: ACCOUNTADMIN or role with MANAGE GRANTS privilege
-- ============================================================================

-- Prerequisites: Replace <TARGET_ROLE> with the actual role name you want to grant to
-- Examples: PUBLIC, ANALYST_ROLE, DATA_TEAM_ROLE, etc.

-- ============================================================================
-- OPTION 1: GRANT TO A SPECIFIC ROLE (RECOMMENDED)
-- ============================================================================
-- Replace <TARGET_ROLE> with your actual role name

-- Grant USAGE on the database (required to see the schema)
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE <TARGET_ROLE>;

-- Grant USAGE on the schema (required to see objects)
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <TARGET_ROLE>;

-- Grant SELECT on the base table
GRANT SELECT ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY TO ROLE <TARGET_ROLE>;

-- Grant SELECT on all existing views
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <TARGET_ROLE>;

-- Grant SELECT on future views (automatic for new views)
GRANT SELECT ON FUTURE VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <TARGET_ROLE>;

-- Grant USAGE on all existing procedures (required to execute them)
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <TARGET_ROLE>;

-- Grant USAGE on future procedures (automatic for new procedures)
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE <TARGET_ROLE>;

-- Optional: Grant INSERT/UPDATE/DELETE on base table (if users need to modify data)
-- GRANT INSERT, UPDATE, DELETE ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY TO ROLE <TARGET_ROLE>;


-- ============================================================================
-- OPTION 2: GRANT TO MULTIPLE ROLES AT ONCE
-- ============================================================================
-- Uncomment and modify as needed

/*
-- Example: Grant to data analyst team
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE ANALYST_ROLE;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYST_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYST_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYST_ROLE;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYST_ROLE;
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYST_ROLE;

-- Example: Grant to data engineering team
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE DATA_ENGINEER_ROLE;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
GRANT INSERT, UPDATE, DELETE ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY TO ROLE DATA_ENGINEER_ROLE;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
*/


-- ============================================================================
-- OPTION 3: GRANT READ-ONLY ACCESS TO PUBLIC (USE WITH CAUTION)
-- ============================================================================
-- This makes the schema visible to all users in your account
-- Only use if this is intended for company-wide access

/*
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE PUBLIC;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE PUBLIC;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE PUBLIC;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE PUBLIC;
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE PUBLIC;
*/


-- ============================================================================
-- OPTION 4: GRANT FULL CONTROL TO ADMIN ROLE
-- ============================================================================
-- For roles that need to manage and modify the schema

/*
GRANT ALL PRIVILEGES ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
GRANT ALL PRIVILEGES ON FUTURE PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ADMIN_ROLE;
*/


-- ============================================================================
-- OPTION 5: GRANT TO SPECIFIC USERS (NOT RECOMMENDED - USE ROLES INSTEAD)
-- ============================================================================
-- Granting to roles is best practice, but if needed:

/*
GRANT USAGE ON DATABASE CURSOR_DB TO USER john_doe;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO USER john_doe;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO USER john_doe;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO USER john_doe;
*/


-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify grants were applied correctly

-- 1. Show grants on the schema
SHOW GRANTS ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS;

-- 2. Show grants on all views
SHOW GRANTS ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS;

-- 3. Show grants on the base table
SHOW GRANTS ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY;

-- 4. Show grants on all procedures
SHOW GRANTS ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS;

-- 5. Show what a specific role has access to
-- SHOW GRANTS TO ROLE <TARGET_ROLE>;

-- 6. Test access as the granted role (switch context)
-- USE ROLE <TARGET_ROLE>;
-- SELECT * FROM CURSOR_DB.AI_QUESTION_INSIGHTS.VW_RECENT_REQUESTS LIMIT 5;
-- CALL CURSOR_DB.AI_QUESTION_INSIGHTS.GET_USER_QUESTION_PATTERNS(30, 10);


-- ============================================================================
-- REVOKE ACCESS (IF NEEDED)
-- ============================================================================
-- Use these commands to remove access

/*
-- Revoke from a specific role
REVOKE USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS FROM ROLE <TARGET_ROLE>;
REVOKE SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS FROM ROLE <TARGET_ROLE>;
REVOKE USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS FROM ROLE <TARGET_ROLE>;

-- Revoke future grants
REVOKE SELECT ON FUTURE VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS FROM ROLE <TARGET_ROLE>;
REVOKE USAGE ON FUTURE PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS FROM ROLE <TARGET_ROLE>;
*/


-- ============================================================================
-- COMMON ACCESS PATTERNS
-- ============================================================================

-- Pattern 1: Read-Only Analytics Users
-- Can view data and run insights, but cannot modify
/*
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE ANALYTICS_USER_ROLE;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYTICS_USER_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYTICS_USER_ROLE;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE ANALYTICS_USER_ROLE;
*/

-- Pattern 2: Data Engineers
-- Can read, write, and refresh data
/*
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE DATA_ENGINEER_ROLE;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY TO ROLE DATA_ENGINEER_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE DATA_ENGINEER_ROLE;
*/

-- Pattern 3: BI Tools / Service Accounts
-- Typically read-only with procedure execution
/*
GRANT USAGE ON DATABASE CURSOR_DB TO ROLE BI_SERVICE_ROLE;
GRANT USAGE ON SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE BI_SERVICE_ROLE;
GRANT SELECT ON TABLE CURSOR_DB.AI_QUESTION_INSIGHTS.CORTEX_ANALYST_REQUEST_HISTORY TO ROLE BI_SERVICE_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE BI_SERVICE_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE BI_SERVICE_ROLE;
GRANT USAGE ON ALL PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE BI_SERVICE_ROLE;
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA CURSOR_DB.AI_QUESTION_INSIGHTS TO ROLE BI_SERVICE_ROLE;
*/


-- ============================================================================
-- WAREHOUSE GRANTS (REQUIRED FOR QUERY EXECUTION)
-- ============================================================================
-- Users need USAGE on a warehouse to run queries and procedures

-- Grant warehouse access to roles
-- GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE <TARGET_ROLE>;
-- GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE <TARGET_ROLE>;  -- Optional: allows suspend/resume


-- ============================================================================
-- SUMMARY OF PRIVILEGE LEVELS
-- ============================================================================
/*
Privilege Level | Schema | Table/View | Procedure | Use Case
----------------|--------|------------|-----------|---------------------------
USAGE           | ✅     | -          | ✅        | Required to see and execute
SELECT          | -      | ✅         | -         | Read data
INSERT/UPDATE   | -      | ✅         | -         | Modify data
ALL PRIVILEGES  | ✅     | ✅         | ✅        | Full control (admin)

Note: USAGE on schema is ALWAYS required before any object-level grants work.
*/


-- ============================================================================
-- BEST PRACTICES
-- ============================================================================
/*
1. ✅ Always grant to ROLES, not individual users
2. ✅ Use FUTURE grants for automatic access to new objects
3. ✅ Follow principle of least privilege (start with read-only)
4. ✅ Document who has access and why
5. ✅ Regularly review and audit grants
6. ✅ Use separate roles for different access levels
7. ⚠️ Be careful with PUBLIC role (visible to entire account)
8. ⚠️ Test grants by switching to the role and attempting access
*/


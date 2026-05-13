----------------------------------------------------------------------
-- NatWest HR/Reward Cortex Hands-on Lab
-- SETUP SCRIPT: Run this FIRST to create the data foundation
----------------------------------------------------------------------
-- This script creates all infrastructure. After running it, you will
-- manually upload the CSV file via the Snowsight UI.
----------------------------------------------------------------------

----------------------------------------------------------------------
-- STEP 1: Set context
----------------------------------------------------------------------
USE ROLE SYSADMIN;

----------------------------------------------------------------------
-- STEP 2: Create database and schema
----------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS NATWEST_HR_LAB
    COMMENT = 'NatWest HR/Reward Cortex Hands-on Lab';

CREATE SCHEMA IF NOT EXISTS NATWEST_HR_LAB.REWARD
    COMMENT = 'Compensation and reward analytics';

USE DATABASE NATWEST_HR_LAB;
USE SCHEMA REWARD;

----------------------------------------------------------------------
-- STEP 3: Create warehouse (XSmall is sufficient for Cortex AI)
----------------------------------------------------------------------
CREATE OR REPLACE WAREHOUSE NATWEST_LAB_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    COMMENT = 'Lab warehouse for Cortex AI functions';

USE WAREHOUSE NATWEST_LAB_WH;

----------------------------------------------------------------------
-- STEP 4: Create the target table
----------------------------------------------------------------------
CREATE OR REPLACE TABLE REWARD_DATA (
    PYTHON_NUMBER       VARCHAR     COMMENT 'Unique employee identifier',
    CEO_1               VARCHAR     COMMENT 'Level 1 reporting line (CEO direct report)',
    CEO_2               VARCHAR     COMMENT 'Level 2 reporting line',
    CEO_3               VARCHAR     COMMENT 'Level 3 reporting line',
    LEVEL               VARCHAR     COMMENT 'Grade band: A (junior) to F (senior)',
    GENDER              VARCHAR     COMMENT 'Employee gender',
    AGE                 VARCHAR     COMMENT 'Age band (e.g. 31 - 40)',
    ETHNICITY           VARCHAR     COMMENT 'Detailed ethnicity',
    ETHNICITY_2         VARCHAR     COMMENT 'Grouped ethnicity (BAME / White / undisclosed)',
    COUNTRY             VARCHAR     COMMENT 'Country of employment',
    JOB_PROFILE         VARCHAR     COMMENT 'Job title / role profile',
    WORKING_PATTERN     VARCHAR     COMMENT 'Full time or Part time',
    CURRENT_SALARY      FLOAT       COMMENT 'Current annual salary in GBP',
    SALARY_INCREASE_PCT FLOAT       COMMENT 'Salary increase as decimal (0.04 = 4%)',
    NEW_SALARY_FTE      FLOAT       COMMENT 'New salary on FTE basis',
    NEW_SALARY          FLOAT       COMMENT 'New salary (actual, pro-rated if part-time)',
    CURRENT_SALARY_FOR_THOSE_WITH_INCREASE FLOAT COMMENT 'Salary for those who received increase',
    HAS_SALARY_INCREASE INTEGER     COMMENT '1 = received increase, 0 = no increase',
    SALARY_ELIGIBLE     VARCHAR     COMMENT 'Eligible for salary review (Yes/No)',
    BONUS_ELIGIBLE      VARCHAR     COMMENT 'Eligible for bonus (Yes/No)',
    SALARY_MAVP_FOR_DISCRETIONARY_AWARD FLOAT COMMENT 'Salary/MAVP basis for discretionary calc',
    DISCRETIONARY_RATIONALE VARCHAR COMMENT 'Rationale: Performing / Underperforming / Disciplinary',
    DISCRETIONARY_AMOUNT FLOAT      COMMENT 'Discretionary bonus amount in GBP',
    DISCRETIONARY_BONUS_PCT FLOAT   COMMENT 'Discretionary bonus as % of salary',
    BONUS_OPPORTUNITY   FLOAT       COMMENT 'Target bonus opportunity (0.25 = 25%)',
    DIVISION            VARCHAR     COMMENT 'Business division'
)
COMMENT = 'Synthetic NatWest employee compensation and reward data (~60K records)';

----------------------------------------------------------------------
-- STEP 5: Create file format for CSV upload
----------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT REWARD_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('', 'NULL', 'null', 'NaN')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

----------------------------------------------------------------------
-- STEP 6: Create internal stage for file upload
----------------------------------------------------------------------
CREATE OR REPLACE STAGE REWARD_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    FILE_FORMAT = REWARD_CSV_FORMAT
    COMMENT = 'Stage for uploading reward CSV data';

----------------------------------------------------------------------
-- STEP 7: Create stage for semantic model YAML (Module 3)
----------------------------------------------------------------------
CREATE OR REPLACE STAGE SEMANTIC_MODEL_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    COMMENT = 'Stage for Cortex Analyst semantic model';

----------------------------------------------------------------------
-- ✅ SETUP COMPLETE
----------------------------------------------------------------------
-- The data foundation is ready. Now upload the data file:
--
-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  HOW TO UPLOAD THE DATA (Snowsight UI)                          ║
-- ╠═══════════════════════════════════════════════════════════════════╣
-- ║                                                                   ║
-- ║  1. In Snowsight, go to: Data > Databases                        ║
-- ║  2. Navigate to: NATWEST_HR_LAB > REWARD > Tables > REWARD_DATA  ║
-- ║  3. Click the "Load Data" button (top right)                      ║
-- ║  4. Select warehouse: NATWEST_LAB_WH                              ║
-- ║  5. Click "Browse" and select: reward_data.csv                    ║
-- ║  6. File format: select REWARD_CSV_FORMAT from the dropdown       ║
-- ║     (Database: NATWEST_HR_LAB, Schema: REWARD)                    ║
-- ║  7. Click "Load"                                                  ║
-- ║  8. Wait for confirmation (~60K rows loaded)                      ║
-- ║                                                                   ║
-- ╚═══════════════════════════════════════════════════════════════════╝
--
-- ALTERNATIVE: Upload via stage (for larger files or scripted approach)
--
--   Option A - Snowsight Stage Upload:
--     1. Go to: Data > Databases > NATWEST_HR_LAB > REWARD > Stages
--     2. Click on REWARD_STAGE
--     3. Click "+ Files" and upload reward_data.csv
--     4. Then run the COPY INTO below
--
--   Option B - SnowSQL / CLI:
--     PUT file:///path/to/reward_data.csv @NATWEST_HR_LAB.REWARD.REWARD_STAGE;
--     Then run the COPY INTO below
----------------------------------------------------------------------

----------------------------------------------------------------------
-- STEP 8: Run AFTER uploading via stage (Options A or B above only)
-- Skip this if you used the "Load Data" button on the table directly.
----------------------------------------------------------------------
/*
COPY INTO REWARD_DATA
FROM @REWARD_STAGE
FILE_FORMAT = REWARD_CSV_FORMAT
PATTERN = '.*reward_data.*[.]csv.*'
ON_ERROR = 'CONTINUE';
*/

----------------------------------------------------------------------
-- STEP 9: Validate the data load (run after upload)
----------------------------------------------------------------------
SELECT '1. Row count' AS check_name, COUNT(*) AS result FROM REWARD_DATA
UNION ALL
SELECT '2. Distinct employees', COUNT(DISTINCT PYTHON_NUMBER) FROM REWARD_DATA
UNION ALL
SELECT '3. Divisions', COUNT(DISTINCT DIVISION) FROM REWARD_DATA;

SELECT
    LEVEL,
    COUNT(*) AS headcount,
    ROUND(AVG(CURRENT_SALARY), 0) AS avg_salary,
    ROUND(AVG(SALARY_INCREASE_PCT) * 100, 2) AS avg_increase_pct
FROM REWARD_DATA
GROUP BY LEVEL
ORDER BY LEVEL;

SELECT
    DIVISION,
    COUNT(*) AS headcount,
    ROUND(AVG(CURRENT_SALARY), 0) AS avg_salary
FROM REWARD_DATA
GROUP BY DIVISION
ORDER BY headcount DESC
LIMIT 10;

----------------------------------------------------------------------
-- STEP 10: Grant access (if running as a shared lab environment)
----------------------------------------------------------------------
-- Uncomment and adjust if you need to grant access to lab participants:
/*
USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS NATWEST_LAB_ROLE;
GRANT USAGE ON DATABASE NATWEST_HR_LAB TO ROLE NATWEST_LAB_ROLE;
GRANT USAGE ON SCHEMA NATWEST_HR_LAB.REWARD TO ROLE NATWEST_LAB_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA NATWEST_HR_LAB.REWARD TO ROLE NATWEST_LAB_ROLE;
GRANT USAGE ON WAREHOUSE NATWEST_LAB_WH TO ROLE NATWEST_LAB_ROLE;
GRANT READ ON STAGE NATWEST_HR_LAB.REWARD.SEMANTIC_MODEL_STAGE TO ROLE NATWEST_LAB_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE NATWEST_LAB_ROLE;
-- GRANT ROLE NATWEST_LAB_ROLE TO USER <participant_username>;
*/

----------------------------------------------------------------------
-- NatWest HR/Reward Cortex Hands-on Lab
-- Module 3: Cortex Analyst - Natural Language Q&A Setup
----------------------------------------------------------------------

USE DATABASE NATWEST_HR_LAB;
USE SCHEMA REWARD;
USE WAREHOUSE NATWEST_LAB_WH;

----------------------------------------------------------------------
-- Step 1: Upload the semantic model YAML to the stage
----------------------------------------------------------------------
-- The SEMANTIC_MODEL_STAGE was already created in 01_setup.sql.
-- Upload the file via Snowsight UI:
--   1. Go to: Data > Databases > NATWEST_HR_LAB > REWARD > Stages
--   2. Click on SEMANTIC_MODEL_STAGE
--   3. Click "+ Files" and upload reward_semantic_model.yaml
--
-- OR via SnowSQL / CLI:
-- PUT file:///path/to/reward_semantic_model.yaml @SEMANTIC_MODEL_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

----------------------------------------------------------------------
-- Step 2: Verify the file is uploaded
----------------------------------------------------------------------
LIST @SEMANTIC_MODEL_STAGE;

----------------------------------------------------------------------
-- Step 3: Create a Semantic View
----------------------------------------------------------------------
-- A Semantic View wraps the YAML model as a first-class Snowflake object.
-- This enables access via the Cortex Analyst playground in Snowsight.

CREATE OR REPLACE SEMANTIC VIEW REWARD_SEMANTIC_VIEW
  FROM @SEMANTIC_MODEL_STAGE/reward_semantic_model.yaml;

-- Verify it exists:
SHOW SEMANTIC VIEWS IN SCHEMA REWARD;

----------------------------------------------------------------------
-- Step 4: Use Cortex Analyst in Snowsight
----------------------------------------------------------------------
-- 1. In Snowsight, navigate to: AI & ML > Cortex Analyst
-- 2. Select "REWARD_SEMANTIC_VIEW" from the dropdown
-- 3. You'll see onboarding questions (from verified_queries in the YAML)
-- 4. Try asking questions in natural language!
--
-- The playground will:
--   - Interpret your question
--   - Generate SQL using the semantic model
--   - Execute the SQL and show results
--   - Offer suggested follow-up questions

----------------------------------------------------------------------
-- Questions to try in the Cortex Analyst playground:
----------------------------------------------------------------------
-- 1. "What is the average salary increase percentage by level?"
-- 2. "Show me the gender pay gap by division"
-- 3. "How many employees received no salary increase?"
-- 4. "Which division has the highest discretionary bonus spend?"
-- 5. "What is the pay gap between BAME and White employees?"
-- 6. "Compare salaries between part time and full time employees"
-- 7. "What's the headcount in Retail Banking by level?"
-- 8. "Show me the top 5 divisions by average salary"
-- 9. "How many people work in each country?"
-- 10. "What percentage of employees at Level D received a bonus?"

----------------------------------------------------------------------
-- Step 5 (Optional): Grant access to the semantic view
----------------------------------------------------------------------
-- If participants need access via a shared role:
/*
GRANT SELECT ON SEMANTIC VIEW REWARD_SEMANTIC_VIEW TO ROLE NATWEST_LAB_ROLE;
*/

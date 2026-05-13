----------------------------------------------------------------------
-- NatWest HR/Reward Cortex Hands-on Lab
-- TEARDOWN: Run after the lab to clean up resources
----------------------------------------------------------------------

USE ROLE SYSADMIN;

-- Drop the lab database (removes all schemas, tables, stages, views)
DROP DATABASE IF EXISTS NATWEST_HR_LAB;

-- Drop the warehouse
DROP WAREHOUSE IF EXISTS NATWEST_LAB_WH;

-- Drop the lab role (if created)
USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS NATWEST_LAB_ROLE;

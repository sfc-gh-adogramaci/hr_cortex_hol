----------------------------------------------------------------------
-- NatWest HR/Reward Cortex Hands-on Lab
-- Module 2: Cortex AI Functions for HR Analytics
----------------------------------------------------------------------

USE DATABASE NATWEST_HR_LAB;
USE SCHEMA REWARD;
USE WAREHOUSE NATWEST_LAB_WH;

----------------------------------------------------------------------
-- Exercise 2.1: Job Role Classification with AI_CLASSIFY
-- Business Value: Automate job taxonomy mapping (currently takes weeks)
----------------------------------------------------------------------

SELECT
    JOB_PROFILE,
    AI_CLASSIFY(
        JOB_PROFILE,
        ['Operations', 'Technology', 'Risk & Compliance', 'Client Facing', 'Support', 'Management', 'Finance', 'Legal']
    ) AS ROLE_CATEGORY
FROM REWARD_DATA
WHERE JOB_PROFILE IS NOT NULL
LIMIT 20;

-- Scale it: classify all roles and see distribution
SELECT
    AI_CLASSIFY(
        JOB_PROFILE,
        ['Operations', 'Technology', 'Risk & Compliance', 'Client Facing', 'Support', 'Management', 'Finance', 'Legal']
    ) AS ROLE_CATEGORY,
    COUNT(*) AS HEADCOUNT,
    ROUND(AVG(CURRENT_SALARY), 0) AS AVG_SALARY
FROM REWARD_DATA
WHERE JOB_PROFILE IS NOT NULL
GROUP BY ROLE_CATEGORY
ORDER BY HEADCOUNT DESC;

----------------------------------------------------------------------
-- Exercise 2.2: Structured Extraction with AI_EXTRACT
-- Business Value: Parse org hierarchy from unstructured text fields
----------------------------------------------------------------------

SELECT
    CEO_1,
    AI_EXTRACT(CEO_1, ['person_name', 'function']) AS EXTRACTED_INFO
FROM REWARD_DATA
WHERE CEO_1 IS NOT NULL
GROUP BY CEO_1
LIMIT 15;

----------------------------------------------------------------------
-- Exercise 2.3: AI_COMPLETE for Pay Narrative Generation
-- Business Value: Auto-generate compensation statements & reward letters
----------------------------------------------------------------------

SELECT
    PYTHON_NUMBER,
    LEVEL,
    CURRENT_SALARY,
    SALARY_INCREASE_PCT,
    AI_COMPLETE(
        'mistral-large2',
        CONCAT(
            'You are an HR compensation specialist at a UK bank. ',
            'Write a brief, professional one-paragraph compensation summary for this employee. ',
            'Include context on their position relative to peers. ',
            'Employee details: Level ', LEVEL,
            ', Current Salary: £', ROUND(CURRENT_SALARY, 0)::VARCHAR,
            ', Salary Increase: ', ROUND(SALARY_INCREASE_PCT * 100, 2)::VARCHAR, '%',
            ', New Salary: £', ROUND(NEW_SALARY, 0)::VARCHAR,
            ', Division: ', DIVISION,
            ', Working Pattern: ', WORKING_PATTERN,
            ', Bonus Opportunity: ', ROUND(BONUS_OPPORTUNITY * 100, 0)::VARCHAR, '%',
            ', Discretionary Status: ', COALESCE(DISCRETIONARY_RATIONALE, 'Standard performer')
        )
    ) AS COMPENSATION_NARRATIVE
FROM REWARD_DATA
WHERE HAS_SALARY_INCREASE = 1
  AND SALARY_INCREASE_PCT > 0.03
LIMIT 5;

----------------------------------------------------------------------
-- Exercise 2.4: AI_COMPLETE for Pay Equity Analysis
-- Business Value: Rapid DEI-compliant pay gap screening
----------------------------------------------------------------------

WITH PAY_STATS AS (
    SELECT
        GENDER,
        LEVEL,
        COUNT(*) AS HEADCOUNT,
        ROUND(AVG(CURRENT_SALARY), 2) AS AVG_SALARY,
        ROUND(MEDIAN(CURRENT_SALARY), 2) AS MEDIAN_SALARY,
        ROUND(AVG(SALARY_INCREASE_PCT), 4) AS AVG_INCREASE_PCT
    FROM REWARD_DATA
    WHERE GENDER IS NOT NULL
    GROUP BY GENDER, LEVEL
)
SELECT AI_COMPLETE(
    'mistral-large2',
    CONCAT(
        'You are a UK HR analytics specialist focused on gender pay equity. ',
        'Analyse the following compensation statistics by gender and level. ',
        'Identify any potential pay gaps, highlight areas of concern, and suggest actions. ',
        'Format your response with clear headers. Data: ',
        (SELECT ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'gender', GENDER,
                'level', LEVEL,
                'headcount', HEADCOUNT,
                'avg_salary', AVG_SALARY,
                'median_salary', MEDIAN_SALARY,
                'avg_increase_pct', AVG_INCREASE_PCT
            )
        ) FROM PAY_STATS)::VARCHAR
    )
) AS PAY_EQUITY_ANALYSIS;

----------------------------------------------------------------------
-- Exercise 2.5: AI_AGG for Divisional Reward Summaries
-- Business Value: Instant exec summaries (currently hours of manual work)
----------------------------------------------------------------------

SELECT
    DIVISION,
    COUNT(*) AS HEADCOUNT,
    ROUND(AVG(SALARY_INCREASE_PCT) * 100, 2) AS AVG_INCREASE_PCT,
    AI_AGG(
        CONCAT(
            'Level: ', LEVEL,
            ', Salary: £', ROUND(CURRENT_SALARY, 0)::VARCHAR,
            ', Increase: ', ROUND(SALARY_INCREASE_PCT * 100, 2)::VARCHAR, '%',
            ', Pattern: ', WORKING_PATTERN,
            ', Discretionary: ', COALESCE(DISCRETIONARY_RATIONALE, 'N/A')
        ),
        'Summarise the key reward patterns for this division in 2-3 sentences. Note any concerns about equity or outliers.'
    ) AS DIVISION_SUMMARY
FROM REWARD_DATA
WHERE HAS_SALARY_INCREASE = 1
GROUP BY DIVISION
ORDER BY HEADCOUNT DESC
LIMIT 10;

----------------------------------------------------------------------
-- Exercise 2.6: AI_CLASSIFY for Ethnicity Pay Gap Flagging
-- Business Value: Proactive BAME pay equity monitoring
----------------------------------------------------------------------

WITH ETHNICITY_STATS AS (
    SELECT
        ETHNICITY_2,
        LEVEL,
        COUNT(*) AS HEADCOUNT,
        ROUND(AVG(CURRENT_SALARY), 0) AS AVG_SALARY,
        ROUND(AVG(SALARY_INCREASE_PCT) * 100, 2) AS AVG_INCREASE_PCT,
        ROUND(AVG(BONUS_OPPORTUNITY) * 100, 0) AS AVG_BONUS_OPP_PCT
    FROM REWARD_DATA
    WHERE ETHNICITY_2 != 'undisclosed'
    GROUP BY ETHNICITY_2, LEVEL
)
SELECT AI_COMPLETE(
    'mistral-large2',
    CONCAT(
        'You are a UK bank DEI analyst. Review these ethnicity pay statistics and flag any gaps ',
        'between BAME and White employees. Comment on salary, increases, and bonus opportunity. ',
        'Be specific about which levels show the largest gaps. Data: ',
        (SELECT ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'ethnicity_group', ETHNICITY_2,
                'level', LEVEL,
                'headcount', HEADCOUNT,
                'avg_salary', AVG_SALARY,
                'avg_increase_pct', AVG_INCREASE_PCT,
                'avg_bonus_opportunity_pct', AVG_BONUS_OPP_PCT
            )
        ) FROM ETHNICITY_STATS)::VARCHAR
    )
) AS ETHNICITY_PAY_ANALYSIS;

----------------------------------------------------------------------
-- Exercise 2.7: AI_FILTER for Anomaly Detection
-- Business Value: Flag unusual compensation decisions for audit
----------------------------------------------------------------------

SELECT
    PYTHON_NUMBER,
    DIVISION,
    LEVEL,
    CURRENT_SALARY,
    SALARY_INCREASE_PCT,
    DISCRETIONARY_RATIONALE,
    DISCRETIONARY_AMOUNT
FROM REWARD_DATA
WHERE AI_FILTER(
    PROMPT(
        'Is this compensation decision unusual or potentially concerning? Employee at level {0} with salary £{1} received a {2}% increase with discretionary status: {3}',
        LEVEL,
        ROUND(CURRENT_SALARY, 0)::VARCHAR,
        ROUND(SALARY_INCREASE_PCT * 100, 1)::VARCHAR,
        COALESCE(DISCRETIONARY_RATIONALE, 'Standard')
    )
) = TRUE
LIMIT 20;

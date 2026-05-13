# NatWest HR/Reward – Snowflake Cortex Hands-on Lab Guide

## Overview
This hands-on lab demonstrates how Snowflake Cortex AI can transform HR, Reward, and People Analytics workflows. Participants will work with ~60,000 synthetic employee compensation records to experience AI-powered classification, summarisation, natural language querying, and app development.

**Duration**: ~2.5 hours  
**Audience**: HR, Reward, and People Employment teams  
**Prerequisites**: Snowflake trial account (or provisioned lab account)  

---

## Lab Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Snowflake Platform                    │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Raw Data │→ │ Cortex AI    │→ │ Streamlit    │  │
│  │ (Table)  │  │ Functions    │  │ Dashboard    │  │
│  └──────────┘  └──────────────┘  └──────────────┘  │
│                        │                             │
│                        ▼                             │
│              ┌──────────────────┐                    │
│              │ Cortex Analyst   │                    │
│              │ (Natural Lang)   │                    │
│              └──────────────────┘                    │
│                                                      │
│  🔒 All AI processing within Snowflake perimeter    │
└─────────────────────────────────────────────────────┘
```

---

## Module 1: Environment Setup (15 min)

### Step 1: Create the lab environment
Run the script `scripts/01_setup.sql` to create:
- Database: `NATWEST_HR_LAB`
- Schema: `REWARD`
- Warehouse: `NATWEST_LAB_WH` (X-Small)
- Table: `REWARD_DATA`
- Stage + File Format for data loading

### Step 2: Upload data via Snowsight UI
1. In Snowsight, go to **Data > Databases > NATWEST_HR_LAB > REWARD > Tables > REWARD_DATA**
2. Click the **"Load Data"** button (top right)
3. Select warehouse: **NATWEST_LAB_WH**
4. Click **Browse** and select `reward_data.csv`
5. For File Format, select **REWARD_CSV_FORMAT** (Database: NATWEST_HR_LAB, Schema: REWARD)
6. Click **Load** and wait for confirmation

### Step 3: Validate
```sql
SELECT COUNT(*) FROM REWARD_DATA;
-- Expected: 59,901 rows
```

### Data Description
| Column | Description |
|--------|-------------|
| PYTHON_NUMBER | Unique employee ID |
| CEO_1/2/3 | Organisational hierarchy (leader name + function) |
| LEVEL | Grade A (junior) to F (senior) |
| GENDER | Male/Female |
| AGE | Age band (e.g., "31 - 40") |
| ETHNICITY / ETHNICITY_2 | Detailed / grouped ethnicity |
| DIVISION | Business unit (23 divisions) |
| CURRENT_SALARY | Current annual salary (£) |
| SALARY_INCREASE_PCT | Increase as decimal (0.04 = 4%) |
| NEW_SALARY | Post-increase salary |
| BONUS_OPPORTUNITY | Target bonus % (0.25 = 25%) |
| DISCRETIONARY_RATIONALE | Performance-based bonus status |

---

## Module 2: Cortex AI Functions (45 min)

Run `scripts/02_cortex_ai_functions.sql` exercise by exercise.

### Exercise 2.1 – AI_CLASSIFY: Job Role Taxonomy
**The problem**: Manually categorising 4,000+ job profiles into reporting taxonomies takes weeks.  
**The solution**: `AI_CLASSIFY` does it instantly with a single SQL statement.

```sql
SELECT JOB_PROFILE,
       AI_CLASSIFY(JOB_PROFILE, ['Operations','Technology','Risk & Compliance','Client Facing','Support','Management','Finance','Legal']) AS ROLE_CATEGORY
FROM REWARD_DATA LIMIT 20;
```

**Discussion**: How accurate is the classification? What categories would you add?

### Exercise 2.2 – AI_EXTRACT: Parse Org Hierarchy
**The problem**: Org data is stored as free text (e.g., "Customer & Operations (James Holian)").  
**The solution**: `AI_EXTRACT` pulls structured fields from unstructured text.

### Exercise 2.3 – AI_COMPLETE: Compensation Narratives
**The problem**: Writing 60K personalised reward summaries is impossible manually.  
**The solution**: Generate human-quality narratives from structured data.

**Key talking point**: The LLM never sees real employee data in production – this is synthetic data for demonstration. In production, all processing stays within Snowflake's security perimeter.

### Exercise 2.4 – AI_COMPLETE: Pay Equity Analysis
**The problem**: Pay equity reporting requires complex analysis AND narrative interpretation.  
**The solution**: Combine SQL aggregations with LLM interpretation for instant insights.

### Exercise 2.5 – AI_AGG: Divisional Summaries
**The problem**: Creating exec summaries for 23 divisions takes days.  
**The solution**: `AI_AGG` aggregates insights across thousands of records in seconds.

### Exercise 2.6 – Ethnicity Pay Gap Analysis
**The problem**: BAME pay gap monitoring is a regulatory requirement but manual.  
**The solution**: Automated gap detection with AI-generated recommendations.

### Exercise 2.7 – AI_FILTER: Anomaly Detection
**The problem**: Auditing compensation decisions requires manual review.  
**The solution**: `AI_FILTER` flags unusual decisions for targeted review.

---

## Module 3: Cortex Analyst – Natural Language Q&A (45 min)

### Step 1: Upload semantic model
1. In Snowsight, go to **Data > Databases > NATWEST_HR_LAB > REWARD > Stages > SEMANTIC_MODEL_STAGE**
2. Click **+ Files** and upload `semantic_model/reward_semantic_model.yaml`
3. Run `scripts/03_cortex_analyst_setup.sql` to create the Semantic View

### Step 2: Open Cortex Analyst Playground
1. In Snowsight: **AI & ML > Cortex Analyst**
2. Select `REWARD_SEMANTIC_VIEW`
3. Try the onboarding questions that appear

### Step 3: Ask questions
Try these (and make up your own):
- "What is the average salary increase percentage by level?"
- "Show me the gender pay gap by division"
- "How many employees received no salary increase?"
- "Which division has the highest discretionary bonus spend?"
- "What is the pay gap between BAME and White employees?"
- "Compare part time and full time salaries by level"
- "How many people work in each country?"
- "What's the average bonus opportunity for Level D?"

### Discussion Points
- How does this compare to your current reporting process?
- What questions would your stakeholders ask?
- How could verified queries ensure accuracy for critical metrics?

---

## Module 4: Streamlit Dashboard (30 min)

### Step 1: Deploy the Streamlit app
1. In Snowsight: **Projects > Streamlit**
2. Create new app: "NatWest Reward Analytics"
3. Copy the code from `streamlit_app/app.py`
4. Set warehouse to `NATWEST_LAB_WH`

### Step 2: Explore the dashboard
- **Tab 1**: Compensation Overview with key metrics and charts
- **Tab 2**: Pay Equity Monitor with AI-generated narratives
- **Tab 3**: Natural language Q&A interface (Cortex Analyst integration)
- **Tab 4**: Personalised reward letter generator

### Step 3: Generate a reward letter
1. Select a division and level
2. Pick an employee
3. Choose a tone
4. Click "Generate Reward Letter"
5. Discuss: How would this integrate with your current comms process?

---

## Key Messages for Facilitator

### Art of the Possible – Before & After

| Current Way of Working | With Snowflake Cortex |
|---|---|
| Weeks to classify 4,000+ job profiles | AI_CLASSIFY: seconds, one SQL statement |
| Manual Excel analysis of 60K rows | AI_AGG: instant divisional summaries |
| Days writing reward narratives | AI_COMPLETE: personalised at scale |
| Static dashboards, limited self-service | Cortex Analyst: ask in English, get SQL |
| Data exported to external AI tools | All AI within Snowflake security perimeter |
| Separate tools for data + analytics + AI | Single governed platform |

### Governance & Security
- All Cortex AI functions run **within Snowflake** – data never leaves the platform
- Standard Snowflake RBAC controls who can access what data
- Audit trails for all AI function usage
- No fine-tuning or training on customer data

### Next Steps
1. **Pilot**: Pick one high-value use case (e.g., reward letter generation or pay equity monitoring)
2. **Data**: Identify what data is already in Snowflake or can be loaded
3. **Build**: Start with SQL-based Cortex functions, then add Cortex Analyst for self-service
4. **Scale**: Deploy as Streamlit apps for broader team access

---

## Troubleshooting

| Issue | Solution |
|---|---|
| AI functions not available | Check region supports Cortex. Enable cross-region inference if needed. |
| Slow AI function responses | Normal – LLM inference takes 2-10 seconds. Use XSMALL warehouse. |
| Cortex Analyst gives wrong SQL | Add verified queries to the semantic model. Check column descriptions. |
| Streamlit app errors | Ensure warehouse is running. Check table/schema names match. |

---

## Files Included

```
hr_cortex_hol/
├── scripts/
│   ├── 01_setup.sql               -- Database & table creation, data load
│   ├── 02_cortex_ai_functions.sql -- Module 2 exercises
│   ├── 03_cortex_analyst_setup.sql -- Semantic model deployment
│   └── 04_teardown.sql            -- Clean up lab resources
├── semantic_model/
│   └── reward_semantic_model.yaml -- Cortex Analyst semantic model
├── streamlit_app/
│   └── app.py                     -- Streamlit dashboard application
├── reward_data.csv                -- Synthetic data (upload to stage)
└── README.md                      -- This file
```

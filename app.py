import streamlit as st
import pandas as pd
import json
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="NatWest Reward Analytics", page_icon="📊", layout="wide")

session = get_active_session()

@st.cache_data(ttl=600)
def get_summary_stats():
    return session.sql("""
        SELECT
            COUNT(DISTINCT PYTHON_NUMBER) AS total_employees,
            ROUND(AVG(CURRENT_SALARY), 0) AS avg_salary,
            ROUND(AVG(SALARY_INCREASE_PCT) * 100, 2) AS avg_increase_pct,
            ROUND(SUM(DISCRETIONARY_AMOUNT), 0) AS total_discretionary,
            COUNT(DISTINCT DIVISION) AS num_divisions
        FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
    """).to_pandas()

st.title("🏦 NatWest Reward Analytics")
st.markdown("*Powered by Snowflake Cortex AI*")

tab1, tab2, tab3, tab4 = st.tabs([
    "📊 Compensation Overview",
    "⚖️ Pay Equity Monitor",
    "💬 Ask Your Data",
    "📝 Reward Letter Generator"
])

with tab1:
    st.header("Compensation Overview")

    stats = get_summary_stats()
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total Employees", f"{stats['TOTAL_EMPLOYEES'].iloc[0]:,.0f}")
    col2.metric("Avg Salary", f"£{stats['AVG_SALARY'].iloc[0]:,.0f}")
    col3.metric("Avg Increase", f"{stats['AVG_INCREASE_PCT'].iloc[0]:.2f}%")
    col4.metric("Total Discretionary", f"£{stats['TOTAL_DISCRETIONARY'].iloc[0]:,.0f}")

    st.subheader("Salary Distribution by Level")
    level_data = session.sql("""
        SELECT LEVEL,
               ROUND(AVG(CURRENT_SALARY), 0) AS AVG_SALARY,
               ROUND(MEDIAN(CURRENT_SALARY), 0) AS MEDIAN_SALARY,
               COUNT(DISTINCT PYTHON_NUMBER) AS HEADCOUNT
        FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
        GROUP BY LEVEL ORDER BY LEVEL
    """).to_pandas()
    st.bar_chart(level_data.set_index("LEVEL")[["AVG_SALARY", "MEDIAN_SALARY"]])
    st.dataframe(level_data, use_container_width=True)

    st.subheader("Increase Distribution by Division")
    div_data = session.sql("""
        SELECT DIVISION,
               ROUND(AVG(SALARY_INCREASE_PCT) * 100, 2) AS AVG_INCREASE_PCT,
               COUNT(DISTINCT PYTHON_NUMBER) AS HEADCOUNT
        FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
        WHERE HAS_SALARY_INCREASE = 1
        GROUP BY DIVISION
        ORDER BY AVG_INCREASE_PCT DESC
    """).to_pandas()
    st.bar_chart(div_data.set_index("DIVISION")["AVG_INCREASE_PCT"])

with tab2:
    st.header("Pay Equity Monitor")

    analysis_type = st.selectbox("Select Analysis", ["Gender Pay Gap", "Ethnicity Pay Gap", "Age Band Analysis"])

    if analysis_type == "Gender Pay Gap":
        gap_data = session.sql("""
            SELECT DIVISION,
                   ROUND(AVG(CASE WHEN GENDER = 'Male' THEN CURRENT_SALARY END), 0) AS AVG_MALE,
                   ROUND(AVG(CASE WHEN GENDER = 'Female' THEN CURRENT_SALARY END), 0) AS AVG_FEMALE,
                   ROUND((AVG(CASE WHEN GENDER = 'Male' THEN CURRENT_SALARY END) -
                          AVG(CASE WHEN GENDER = 'Female' THEN CURRENT_SALARY END)) /
                         NULLIF(AVG(CASE WHEN GENDER = 'Male' THEN CURRENT_SALARY END), 0) * 100, 2) AS GAP_PCT
            FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
            WHERE GENDER IS NOT NULL
            GROUP BY DIVISION
            ORDER BY GAP_PCT DESC
        """).to_pandas()
        st.dataframe(gap_data, use_container_width=True)

        if st.button("🤖 Generate AI Pay Equity Narrative", key="gender_ai"):
            with st.spinner("Generating AI analysis..."):
                data_summary = gap_data.to_csv(index=False).replace("'", "''")
                result = session.sql(f"""
                    SELECT AI_COMPLETE('mistral-large2',
                        'You are a UK HR pay equity analyst. Analyse this gender pay gap data and provide a brief executive summary with key findings and recommended actions. Data:\n{data_summary}'
                    ) AS analysis
                """).to_pandas()
                st.markdown(result["ANALYSIS"].iloc[0])

    elif analysis_type == "Ethnicity Pay Gap":
        eth_data = session.sql("""
            SELECT LEVEL,
                   ROUND(AVG(CASE WHEN ETHNICITY_2 = 'White' THEN CURRENT_SALARY END), 0) AS AVG_WHITE,
                   ROUND(AVG(CASE WHEN ETHNICITY_2 = 'BAME' THEN CURRENT_SALARY END), 0) AS AVG_BAME,
                   ROUND((AVG(CASE WHEN ETHNICITY_2 = 'White' THEN CURRENT_SALARY END) -
                          AVG(CASE WHEN ETHNICITY_2 = 'BAME' THEN CURRENT_SALARY END)) /
                         NULLIF(AVG(CASE WHEN ETHNICITY_2 = 'White' THEN CURRENT_SALARY END), 0) * 100, 2) AS GAP_PCT
            FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
            WHERE ETHNICITY_2 IN ('BAME', 'White')
            GROUP BY LEVEL ORDER BY LEVEL
        """).to_pandas()
        st.dataframe(eth_data, use_container_width=True)

        if st.button("🤖 Generate AI Ethnicity Pay Analysis", key="eth_ai"):
            with st.spinner("Generating AI analysis..."):
                data_summary = eth_data.to_csv(index=False).replace("'", "''")
                result = session.sql(f"""
                    SELECT AI_COMPLETE('mistral-large2',
                        'You are a UK bank DEI analyst. Analyse this ethnicity pay gap data by level (BAME vs White) and provide findings and recommendations. Data:\n{data_summary}'
                    ) AS analysis
                """).to_pandas()
                st.markdown(result["ANALYSIS"].iloc[0])

    else:
        age_data = session.sql("""
            SELECT AGE AS AGE_BAND, LEVEL,
                   ROUND(AVG(CURRENT_SALARY), 0) AS AVG_SALARY,
                   ROUND(AVG(SALARY_INCREASE_PCT) * 100, 2) AS AVG_INCREASE_PCT,
                   COUNT(DISTINCT PYTHON_NUMBER) AS HEADCOUNT
            FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
            WHERE AGE IS NOT NULL
            GROUP BY AGE, LEVEL ORDER BY AGE, LEVEL
        """).to_pandas()
        st.dataframe(age_data, use_container_width=True)

with tab3:
    st.header("Ask Your Data")
    st.markdown("""
    Ask questions about compensation data in natural language.
    Powered by **Cortex Analyst** using the Reward semantic model.

    > **Note**: This tab demonstrates how Cortex Analyst works. For the full interactive
    > experience, use the **Cortex Analyst Playground** in Snowsight
    > (AI & ML > Cortex Analyst > REWARD_SEMANTIC_VIEW).
    """)

    question = st.text_input(
        "Ask a question about reward data:",
        placeholder="e.g., What is the average salary increase by level?"
    )

    suggested = st.columns(3)
    with suggested[0]:
        if st.button("Gender pay gap by division"):
            question = "Show me the gender pay gap by division"
    with suggested[1]:
        if st.button("Bonus distribution by level"):
            question = "What is the bonus opportunity distribution across levels?"
    with suggested[2]:
        if st.button("Who got no increase?"):
            question = "How many employees received no salary increase?"

    if question:
        with st.spinner("Querying with Cortex Analyst..."):
            try:
                escaped_question = question.replace("'", "''")
                response = session.sql(f"""
                    SELECT SNOWFLAKE.CORTEX.COMPLETE(
                        'mistral-large2',
                        'You are a compensation data analyst. Convert this question to SQL against a table called NATWEST_HR_LAB.REWARD.REWARD_DATA. '
                        || 'The table has columns: PYTHON_NUMBER, CEO_1, CEO_2, CEO_3, LEVEL (A-F grades), GENDER, AGE, ETHNICITY, ETHNICITY_2 (BAME/White/undisclosed), '
                        || 'COUNTRY, JOB_PROFILE, WORKING_PATTERN, CURRENT_SALARY (GBP), SALARY_INCREASE_PCT (decimal e.g. 0.04=4%), NEW_SALARY_FTE, NEW_SALARY, '
                        || 'HAS_SALARY_INCREASE (1/0), SALARY_ELIGIBLE, BONUS_ELIGIBLE, DISCRETIONARY_RATIONALE, DISCRETIONARY_AMOUNT, DISCRETIONARY_BONUS_PCT, '
                        || 'BONUS_OPPORTUNITY (decimal e.g. 0.25=25%), DIVISION. '
                        || 'Return ONLY the SQL query, no explanation. Question: {escaped_question}'
                    ) AS generated_sql
                """).to_pandas()

                generated_sql = response["GENERATED_SQL"].iloc[0].strip()
                if generated_sql.startswith("```"):
                    generated_sql = generated_sql.split("\n", 1)[1].rsplit("```", 1)[0].strip()

                st.code(generated_sql, language="sql")

                try:
                    sql_result = session.sql(generated_sql).to_pandas()
                    st.dataframe(sql_result, use_container_width=True)
                except Exception as e:
                    st.error(f"Error executing generated SQL: {e}")
                    st.info("Try rephrasing your question or use the Cortex Analyst playground for best results.")
            except Exception as e:
                st.error(f"Error: {e}")

with tab4:
    st.header("Reward Letter Generator")
    st.markdown("Generate personalised compensation communications using **Cortex AI**.")

    col1, col2 = st.columns(2)
    with col1:
        divisions = session.sql("""
            SELECT DISTINCT DIVISION FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
            WHERE DIVISION IS NOT NULL ORDER BY DIVISION
        """).to_pandas()["DIVISION"].tolist()
        selected_division = st.selectbox("Division", divisions)
    with col2:
        selected_level = st.selectbox("Level", ["A", "B", "C", "D", "E", "F"])

    escaped_div = selected_division.replace("'", "''")
    employees = session.sql(f"""
        SELECT PYTHON_NUMBER, JOB_PROFILE, CURRENT_SALARY, SALARY_INCREASE_PCT,
               NEW_SALARY, BONUS_OPPORTUNITY, DISCRETIONARY_RATIONALE, WORKING_PATTERN
        FROM NATWEST_HR_LAB.REWARD.REWARD_DATA
        WHERE DIVISION = '{escaped_div}' AND LEVEL = '{selected_level}'
          AND HAS_SALARY_INCREASE = 1
          AND SALARY_INCREASE_PCT > 0
        LIMIT 20
    """).to_pandas()

    if not employees.empty:
        selected_emp = st.selectbox(
            "Select Employee",
            employees["PYTHON_NUMBER"].tolist(),
            format_func=lambda x: f"{x} - {employees[employees['PYTHON_NUMBER']==x]['JOB_PROFILE'].iloc[0]}"
        )

        emp = employees[employees["PYTHON_NUMBER"] == selected_emp].iloc[0]

        st.markdown("**Employee Details:**")
        det_col1, det_col2, det_col3 = st.columns(3)
        det_col1.metric("Current Salary", f"£{emp['CURRENT_SALARY']:,.0f}")
        det_col2.metric("Increase", f"{emp['SALARY_INCREASE_PCT']*100:.2f}%")
        det_col3.metric("New Salary", f"£{emp['NEW_SALARY']:,.0f}")

        tone = st.selectbox("Letter Tone", ["Professional & Warm", "Formal", "Concise"])

        if st.button("✉️ Generate Reward Letter"):
            with st.spinner("Generating personalised letter..."):
                perf = emp['DISCRETIONARY_RATIONALE'] if pd.notna(emp['DISCRETIONARY_RATIONALE']) else 'Standard performer'
                prompt = (
                    f"You are an HR Reward specialist at NatWest Group, a major UK bank. "
                    f"Write a {tone.lower()} reward letter for this employee informing them of their compensation review outcome. "
                    f"Employee Details: Job Profile: {emp['JOB_PROFILE']}, Level: {selected_level}, "
                    f"Division: {selected_division}, Working Pattern: {emp['WORKING_PATTERN']}, "
                    f"Current Salary: £{emp['CURRENT_SALARY']:,.0f}, "
                    f"Salary Increase: {emp['SALARY_INCREASE_PCT']*100:.2f}%, "
                    f"New Salary: £{emp['NEW_SALARY']:,.0f}, "
                    f"Bonus Opportunity: {emp['BONUS_OPPORTUNITY']*100:.0f}%, "
                    f"Performance: {perf}. "
                    f"The letter should: 1) Thank the employee for their contribution, "
                    f"2) Clearly state the salary increase and new salary, "
                    f"3) Reference their bonus opportunity, "
                    f"4) Be appropriate for a UK banking context, "
                    f"5) Be around 200 words."
                ).replace("'", "''")

                result = session.sql(f"""
                    SELECT AI_COMPLETE('mistral-large2', '{prompt}') AS letter
                """).to_pandas()

                st.markdown("---")
                st.markdown(result["LETTER"].iloc[0])
    else:
        st.info("No employees found matching the selected criteria with a salary increase.")

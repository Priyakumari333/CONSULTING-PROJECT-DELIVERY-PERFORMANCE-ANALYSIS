-- ============================================================================
-- CONSULTING PROJECT DELIVERY ANALYSIS
-- DAY 2 - PART 4: ANALYSIS, BENCHMARKS & SCENARIO PLANNING
-- ============================================================================
-- Author  : Priya Kumari
-- Date    : February 2026
-- Platform: MySQL
-- Purpose : Run hypothesis testing, benchmark comparison and scenario analysis
--           on the cleaned dataset (projects_clean).
--
-- STRUCTURE:
--   Section A — Analytical Views
--   Section B — Benchmark Comparison
--   Section C — Hypothesis Testing (H1, H2, H3)
--   Section D — Scenario & Sensitivity Analysis
--   Section E — Financial Impact
--   Section F — Risk Scoring
--   Section G — Overall Summary
-- ============================================================================

USE consulting_analysis;


-- ============================================================================
-- SECTION A: ANALYTICAL VIEWS
-- ============================================================================

DROP VIEW IF EXISTS vw_project_performance;
DROP VIEW IF EXISTS vw_service_line_performance;

-- View 1: Full project performance with categories
CREATE VIEW vw_project_performance AS
SELECT
    p.project_id,
    p.project_name,
    sl.service_line_name,
    p.client_name,
    p.planned_duration_months,
    p.team_size,
    p.planned_cost_eur,
    p.actual_cost_eur,
    p.cost_overrun_pct,
    p.utilization_pct,
    p.delay_days,
    p.status,
    -- Utilisation category (Deltek 2025 thresholds)
    CASE
        WHEN p.utilization_pct < 70   THEN 'Below Target (<70%)'
        WHEN p.utilization_pct < 75   THEN 'Acceptable (70-75%)'
        WHEN p.utilization_pct <= 85  THEN 'Optimal (75-85%)'
        ELSE                               'High (>85%)'
    END AS utilization_category,
    -- Cost performance category (SPI Research thresholds)
    CASE
        WHEN p.cost_overrun_pct <= 7.8  THEN 'High Performer'
        WHEN p.cost_overrun_pct <= 15.0 THEN 'Average'
        ELSE                                 'Below Average'
    END AS cost_performance_category,
    -- Risk score (composite of utilisation + cost overrun)
    CASE
        WHEN p.utilization_pct < 65 AND p.cost_overrun_pct > 20 THEN 'High Risk'
        WHEN p.utilization_pct < 72 AND p.cost_overrun_pct > 15 THEN 'Medium Risk'
        ELSE                                                          'Low Risk'
    END AS risk_category,
    p.data_quality_note
FROM projects_clean p
JOIN service_lines sl ON p.service_line_id = sl.service_line_id;


-- View 2: Service line summary
CREATE VIEW vw_service_line_performance AS
SELECT
    sl.service_line_name,
    COUNT(p.project_id)                                                      AS total_projects,
    ROUND(AVG(p.utilization_pct), 1)                                         AS avg_utilization_pct,
    ROUND(AVG(p.cost_overrun_pct), 1)                                        AS avg_cost_overrun_pct,
    ROUND(AVG(p.delay_days), 1)                                              AS avg_delay_days,
    ROUND(SUM(CASE WHEN p.delay_days = 0 THEN 1 ELSE 0 END) * 100.0
          / COUNT(*), 1)                                                      AS on_time_pct,
    ROUND(SUM(p.actual_cost_eur - p.planned_cost_eur), 0)                    AS total_overrun_eur,
    ROUND(AVG(p.team_size), 1)                                               AS avg_team_size
FROM projects_clean p
JOIN service_lines sl ON p.service_line_id = sl.service_line_id
GROUP BY sl.service_line_name;


-- ============================================================================
-- SECTION B: INDUSTRY BENCHMARK COMPARISON
-- ============================================================================
-- Sources:
--   Deltek 2025 Professional Services Benchmarks
--   SPI Research Professional Services Maturity Benchmark
--   CSO Ireland Labour Force Survey Q3 2024
-- ============================================================================

SELECT 'SECTION B: BENCHMARK COMPARISON' AS section_header;

SELECT
    metric,
    ROUND(our_value, 1)                 AS our_firm_value,
    industry_average,
    top_performer_benchmark,
    our_target,
    CASE
        WHEN metric = 'Cost Overrun %' AND our_value <= our_target        THEN 'Meeting Target'
        WHEN metric = 'Cost Overrun %' AND our_value <= industry_average  THEN 'At Industry Average'
        WHEN metric = 'Cost Overrun %'                                    THEN 'Above Target - Needs Improvement'
        WHEN metric = 'Avg Delay Days' AND our_value <= our_target        THEN 'Meeting Target'
        WHEN metric = 'Avg Delay Days'                                    THEN 'Above Target - Needs Improvement'
        WHEN our_value >= our_target                                      THEN 'Meeting Target'
        WHEN our_value >= industry_average                                THEN 'At Industry Average'
        ELSE                                                                   'Below Target - Needs Improvement'
    END                                 AS performance_status,
    source
FROM (
    SELECT
        'Utilisation Rate %'                                    AS metric,
        (SELECT AVG(utilization_pct)  FROM projects_clean)     AS our_value,
        68.9                                                    AS industry_average,
        74.5                                                    AS top_performer_benchmark,
        75.0                                                    AS our_target,
        'Deltek 2025 Professional Services Benchmarks'         AS source

    UNION ALL SELECT
        'Cost Overrun %',
        (SELECT AVG(cost_overrun_pct) FROM projects_clean),
        11.3, 7.8, 10.0,
        'Deltek 2025 Professional Services Benchmarks'

    UNION ALL SELECT
        'On-Time Delivery %',
        (SELECT SUM(CASE WHEN delay_days = 0 THEN 1 ELSE 0 END) * 100.0
         / COUNT(*) FROM projects_clean),
        73.4, 85.7, 90.0,
        'SPI Research via Deltek 2025'

    UNION ALL SELECT
        'Avg Delay Days',
        (SELECT AVG(CASE WHEN delay_days > 0 THEN delay_days ELSE NULL END)
         FROM projects_clean),
        12.0, 5.0, 7.0,
        'SPI Research Professional Services Maturity'
) AS benchmark_data;


-- ============================================================================
-- SECTION C: HYPOTHESIS TESTING
-- ============================================================================

SELECT 'SECTION C: HYPOTHESIS TESTING' AS section_header;

-- ─────────────────────────────────────────────
-- H1: Low Utilisation leads to Higher Delays and Overruns
-- ─────────────────────────────────────────────

SELECT 'H1: UTILISATION vs DELAYS AND COST OVERRUN' AS hypothesis;

SELECT
    CASE
        WHEN utilization_pct < 70   THEN '1. Low (<70%)'
        WHEN utilization_pct < 75   THEN '2. Acceptable (70-75%)'
        WHEN utilization_pct <= 85  THEN '3. Optimal (75-85%)'
        ELSE                             '4. High (>85%)'
    END                                                             AS utilization_band,
    COUNT(*)                                                        AS projects,
    ROUND(AVG(utilization_pct), 1)                                  AS avg_utilization_pct,
    ROUND(AVG(delay_days), 1)                                       AS avg_delay_days,
    ROUND(AVG(cost_overrun_pct), 1)                                 AS avg_cost_overrun_pct,
    ROUND(SUM(CASE WHEN delay_days = 0 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                    AS on_time_pct
FROM projects_clean
GROUP BY
    CASE
        WHEN utilization_pct < 70   THEN '1. Low (<70%)'
        WHEN utilization_pct < 75   THEN '2. Acceptable (70-75%)'
        WHEN utilization_pct <= 85  THEN '3. Optimal (75-85%)'
        ELSE                             '4. High (>85%)'
    END
ORDER BY utilization_band;

-- H1 Verdict
SELECT
    CASE
        WHEN (SELECT AVG(delay_days) FROM projects_clean WHERE utilization_pct < 70)
           > (SELECT AVG(delay_days) FROM projects_clean WHERE utilization_pct >= 75)
        THEN 'H1 SUPPORTED: Low utilisation projects have higher average delays'
        ELSE 'H1 NOT SUPPORTED: No clear pattern between utilisation and delays'
    END AS h1_verdict;


-- ─────────────────────────────────────────────
-- H2: Cost Overruns Driven by Effort Underestimation
-- ─────────────────────────────────────────────

SELECT 'H2: ESTIMATION QUALITY vs COST OVERRUN' AS hypothesis;

SELECT
    CASE
        WHEN cost_overrun_pct <= 7.8  THEN '1. Good Estimation (<=7.8%)'
        WHEN cost_overrun_pct <= 15.0 THEN '2. Moderate Estimation (7.8-15%)'
        ELSE                               '3. Poor Estimation (>15%)'
    END                                                             AS estimation_quality,
    COUNT(*)                                                        AS projects,
    ROUND(AVG(cost_overrun_pct), 1)                                 AS avg_cost_overrun_pct,
    ROUND(AVG(utilization_pct), 1)                                  AS avg_utilization_pct,
    ROUND(AVG(delay_days), 1)                                       AS avg_delay_days,
    ROUND(SUM(actual_cost_eur - planned_cost_eur), 0)               AS total_overrun_eur
FROM projects_clean
GROUP BY
    CASE
        WHEN cost_overrun_pct <= 7.8  THEN '1. Good Estimation (<=7.8%)'
        WHEN cost_overrun_pct <= 15.0 THEN '2. Moderate Estimation (7.8-15%)'
        ELSE                               '3. Poor Estimation (>15%)'
    END
ORDER BY estimation_quality;

-- Top 5 worst cost overrun projects
SELECT
    p.project_id,
    p.project_name,
    sl.service_line_name,
    ROUND(p.cost_overrun_pct, 1)                    AS cost_overrun_pct,
    ROUND(p.actual_cost_eur - p.planned_cost_eur, 0) AS overrun_eur,
    ROUND(p.utilization_pct, 1)                     AS utilization_pct,
    p.delay_days,
    p.status
FROM projects_clean p
JOIN service_lines sl ON p.service_line_id = sl.service_line_id
ORDER BY p.cost_overrun_pct DESC
LIMIT 5;


-- ─────────────────────────────────────────────
-- H3: Service Line Performance Variance
-- ─────────────────────────────────────────────

SELECT 'H3: SERVICE LINE PERFORMANCE VARIANCE' AS hypothesis;

SELECT * FROM vw_service_line_performance
ORDER BY avg_cost_overrun_pct;

-- H3 Verdict
SELECT
    ROUND(MAX(avg_cost_overrun_pct) - MIN(avg_cost_overrun_pct), 1)  AS overrun_spread_pct,
    ROUND(MAX(avg_utilization_pct)  - MIN(avg_utilization_pct), 1)   AS utilization_spread_pct,
    CASE
        WHEN MAX(avg_cost_overrun_pct) - MIN(avg_cost_overrun_pct) > 10
        THEN 'H3 SUPPORTED: Significant variance across service lines (spread >10%)'
        ELSE 'H3 PARTIALLY SUPPORTED: Some variance exists between service lines'
    END AS h3_verdict
FROM vw_service_line_performance;


-- ============================================================================
-- SECTION D: SCENARIO & SENSITIVITY ANALYSIS
-- ============================================================================

SELECT 'SECTION D: SCENARIO AND SENSITIVITY ANALYSIS' AS section_header;

-- D1. Best / Base / Worst Case Scenarios
SELECT 'SCENARIO ANALYSIS: BEST / BASE / WORST CASE' AS analysis;

SELECT
    scenario,
    assumed_utilization_pct,
    assumed_overrun_pct,
    assumed_ontime_pct,
    ROUND(total_planned_cost * (1 + assumed_overrun_pct / 100.0), 0)  AS projected_actual_cost_eur,
    ROUND(total_planned_cost * (assumed_overrun_pct / 100.0), 0)      AS projected_overrun_eur,
    ROUND(
        total_planned_cost * (assumed_overrun_pct / 100.0)
        - (SELECT SUM(actual_cost_eur - planned_cost_eur) FROM projects_clean),
        0
    )                                                                  AS vs_current_state_eur
FROM (
    SELECT
        'Base Case (Current State)'             AS scenario,
        72.0                                    AS assumed_utilization_pct,
        13.0                                    AS assumed_overrun_pct,
        72.0                                    AS assumed_ontime_pct,
        (SELECT SUM(planned_cost_eur) FROM projects_clean) AS total_planned_cost
    UNION ALL SELECT
        'Best Case (Target: 75% utilisation)',   75.0, 9.0,  85.0,
        (SELECT SUM(planned_cost_eur) FROM projects_clean)
    UNION ALL SELECT
        'Worst Case (65% utilisation)',           65.0, 20.0, 55.0,
        (SELECT SUM(planned_cost_eur) FROM projects_clean)
) AS scenarios;


-- D2. Sensitivity: Impact of improving utilisation to 75%
SELECT 'SENSITIVITY: UTILISATION IMPROVEMENT IMPACT' AS analysis;

SELECT
    'Projects currently below 75% utilisation'          AS finding,
    COUNT(*)                                            AS project_count,
    ROUND(AVG(cost_overrun_pct), 1)                     AS avg_current_overrun_pct,
    ROUND(SUM(actual_cost_eur - planned_cost_eur), 0)   AS current_total_overrun_eur,
    ROUND(SUM(planned_cost_eur) * (0.17 - 0.10), 0)    AS estimated_saving_if_target_met_eur
FROM projects_clean
WHERE utilization_pct < 75;


-- D3. Sensitivity: If Process Transformation matched Analytics performance
SELECT 'SENSITIVITY: IF PROCESS TRANSFORMATION MATCHED ANALYTICS' AS analysis;

SELECT
		'Current Process Transformation overrun'                        AS scenario,
    ROUND(SUM(actual_cost_eur - planned_cost_eur), 0)               AS overrun_eur
FROM projects_clean p
JOIN service_lines sl ON p.service_line_id = sl.service_line_id
WHERE sl.service_line_name = 'Process Transformation'

UNION ALL

SELECT
    'If Process Transformation had Analytics avg overrun (8.4%)',
    ROUND(SUM(planned_cost_eur) * 0.084, 0)
FROM projects_clean p
JOIN service_lines sl ON p.service_line_id = sl.service_line_id
WHERE sl.service_line_name = 'Process Transformation'

UNION ALL

SELECT
    'Potential saving (difference)',
    ROUND(
        SUM(actual_cost_eur - planned_cost_eur)
        - SUM(planned_cost_eur) * 0.084,
        0
    )
FROM projects_clean p
JOIN service_lines sl ON p.service_line_id = sl.service_line_id
WHERE sl.service_line_name = 'Process Transformation';


-- ============================================================================
-- SECTION E: FINANCIAL IMPACT
-- ============================================================================

SELECT 'SECTION E: FINANCIAL IMPACT' AS section_header;

-- E1. Overall financial exposure
SELECT
    COUNT(*)                                            AS total_projects,
    ROUND(SUM(planned_cost_eur), 0)                     AS total_planned_budget_eur,
    ROUND(SUM(actual_cost_eur), 0)                      AS total_actual_cost_eur,
    ROUND(SUM(actual_cost_eur - planned_cost_eur), 0)   AS total_overrun_eur,
    ROUND(AVG(cost_overrun_pct), 1)                     AS avg_overrun_pct
FROM projects_clean;

-- E2. Overrun by service line with share of total
SELECT
    v.service_line_name,
    v.total_projects,
    ROUND(v.total_overrun_eur, 0)                           AS total_overrun_eur,
    ROUND(v.total_overrun_eur
          / (SELECT SUM(actual_cost_eur - planned_cost_eur)
             FROM projects_clean) * 100, 1)                 AS pct_of_total_overrun,
    v.avg_cost_overrun_pct,
    v.avg_utilization_pct
FROM vw_service_line_performance v
ORDER BY v.total_overrun_eur DESC;

-- E3. Delayed projects — budget at risk
SELECT
    COUNT(*)                                            AS delayed_projects,
    ROUND(AVG(delay_days), 1)                           AS avg_delay_days,
    ROUND(SUM(planned_cost_eur), 0)                     AS budget_at_risk_eur
FROM projects_clean
WHERE delay_days > 0;


-- ============================================================================
-- SECTION F: PROJECT RISK SCORING
-- ============================================================================

SELECT 'SECTION F: PROJECT RISK SCORING' AS section_header;

-- Risk summary by category
SELECT
    risk_category,
    COUNT(*)                                                AS projects,
    ROUND(AVG(utilization_pct), 1)                          AS avg_utilization_pct,
    ROUND(AVG(cost_overrun_pct), 1)                         AS avg_overrun_pct,
    ROUND(AVG(delay_days), 1)                               AS avg_delay_days,
    ROUND(SUM(actual_cost_eur - planned_cost_eur), 0)       AS total_overrun_eur
FROM vw_project_performance
GROUP BY risk_category
ORDER BY
    CASE risk_category
        WHEN 'High Risk'   THEN 1
        WHEN 'Medium Risk' THEN 2
        ELSE 3
    END;

-- High risk projects detail
SELECT
    'HIGH RISK PROJECT'             AS alert,
    project_id,
    project_name,
    service_line_name,
    utilization_pct,
    cost_overrun_pct,
    delay_days,
    status
FROM vw_project_performance
WHERE risk_category = 'High Risk'
ORDER BY cost_overrun_pct DESC;


-- ============================================================================
-- SECTION G: OVERALL PERFORMANCE SUMMARY
-- ============================================================================

SELECT 'SECTION G: OVERALL PERFORMANCE SUMMARY' AS section_header;

SELECT
    COUNT(*)                                                            AS total_projects,
    ROUND(AVG(utilization_pct), 1)                                      AS avg_utilization_pct,
    ROUND(AVG(cost_overrun_pct), 1)                                     AS avg_cost_overrun_pct,
    ROUND(AVG(delay_days), 1)                                           AS avg_delay_days,
    ROUND(SUM(CASE WHEN delay_days = 0 THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                        AS on_time_delivery_pct,
    ROUND(SUM(actual_cost_eur - planned_cost_eur), 0)                   AS total_overrun_eur,
    SUM(CASE WHEN risk_category = 'High Risk'   THEN 1 ELSE 0 END)      AS high_risk_projects,
    SUM(CASE WHEN risk_category = 'Medium Risk' THEN 1 ELSE 0 END)      AS medium_risk_projects,
    SUM(CASE WHEN risk_category = 'Low Risk'    THEN 1 ELSE 0 END)      AS low_risk_projects
FROM vw_project_performance;

-- ============================================================================
-- END OF ANALYSIS
-- ============================================================================
-- RUN ORDER:
--   1. mysql_day2_01_raw_data.sql        → Creates database + raw messy dataset
--   2. mysql_day2_02_data_exploration.sql → Identifies all 11 data quality issues
--   3. mysql_day2_03_data_cleaning.sql   → Fixes all issues → projects_clean
--   4. mysql_day2_04_analysis.sql        → This file — full analysis & scenarios
-- ============================================================================

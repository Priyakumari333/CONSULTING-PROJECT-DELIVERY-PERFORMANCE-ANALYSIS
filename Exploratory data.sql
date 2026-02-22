-- ============================================================================
-- CONSULTING PROJECT DELIVERY ANALYSIS
-- DAY 2 - PART 2: DATA EXPLORATION & QUALITY AUDIT
-- ============================================================================
-- Author  : Priya Kumari
-- Date    : February 2026
-- Platform: MySQL
-- Purpose : Identify every data quality issue in raw_projects before analysis.
--
-- STRUCTURE:
--   Section A — Basic Overview
--   Section B — NULL / Missing Value Audit
--   Section C — Duplicate Detection
--   Section D — Consistency Checks
--   Section E — Outlier Detection
--   Section F — Data Quality Summary Report
-- ============================================================================

USE consulting_analysis;


-- ============================================================================
-- SECTION A: BASIC OVERVIEW
-- ============================================================================

SELECT 'SECTION A: BASIC DATASET OVERVIEW' AS section_header;

-- A1. Total row count (expect 26)
SELECT
    'Total Rows in raw_projects'   AS metric,
    COUNT(*)                       AS value
FROM raw_projects;

-- A2. Distinct project IDs (expect 25)
SELECT
    'Distinct Project IDs'         AS metric,
    COUNT(DISTINCT project_id)     AS value
FROM raw_projects;

-- A3. Projects per service line
SELECT
    sl.service_line_name,
    COUNT(DISTINCT r.project_id)   AS project_count
FROM raw_projects r
JOIN service_lines sl ON r.service_line_id = sl.service_line_id
GROUP BY sl.service_line_name
ORDER BY sl.service_line_name;  

-- A4. Date range of dataset
SELECT
    MIN(start_date)                AS earliest_start,
    MAX(actual_end_date)           AS latest_end
FROM raw_projects;


-- ============================================================================
-- SECTION B: NULL / MISSING VALUE AUDIT
-- ============================================================================

SELECT 'SECTION B: NULL AND MISSING VALUE AUDIT' AS section_header;

-- B1. Count NULLs and blank strings per column
SELECT 'project_name'      AS column_name, COUNT(*) AS null_or_blank_count FROM raw_projects WHERE project_name   IS NULL OR TRIM(project_name)   = '' UNION ALL
SELECT 'client_name',                       COUNT(*) FROM raw_projects WHERE client_name    IS NULL UNION ALL
SELECT 'actual_cost_eur',                   COUNT(*) FROM raw_projects WHERE actual_cost_eur  IS NULL UNION ALL
SELECT 'cost_overrun_pct',                  COUNT(*) FROM raw_projects WHERE cost_overrun_pct IS NULL UNION ALL
SELECT 'utilization_pct',                   COUNT(*) FROM raw_projects WHERE utilization_pct  IS NULL UNION ALL
SELECT 'delay_days',                        COUNT(*) FROM raw_projects WHERE delay_days        IS NULL UNION ALL
SELECT 'status',                            COUNT(*) FROM raw_projects WHERE status             IS NULL;

-- B2. Show the actual NULL / blank records
SELECT
    'NULL or BLANK RECORD'     AS issue_type,
    project_id,
    project_name,
    client_name,
    actual_cost_eur,
    cost_overrun_pct,
    utilization_pct,
    delay_days,
    status
FROM raw_projects
WHERE
    actual_cost_eur  IS NULL OR
    cost_overrun_pct IS NULL OR
    utilization_pct  IS NULL OR
    delay_days       IS NULL OR
    status           IS NULL OR
    client_name      IS NULL OR
    TRIM(IFNULL(project_name,'')) = ''
ORDER BY project_id;


-- ============================================================================
-- SECTION C: DUPLICATE DETECTION
-- ============================================================================

SELECT 'SECTION C: DUPLICATE DETECTION' AS section_header;

-- C1. Find duplicate project_ids
SELECT
    'DUPLICATE PROJECT ID'         AS issue_type,
    project_id,
    COUNT(*)                       AS occurrence_count
FROM raw_projects
GROUP BY project_id
HAVING COUNT(*) > 1
ORDER BY project_id;

-- C2. Show full duplicate rows
SELECT
    'FULL DUPLICATE ROWS'          AS issue_type,
    project_id,
    project_name,
    start_date,
    planned_cost_eur,
    actual_cost_eur,
    status
FROM raw_projects
WHERE project_id IN (
    SELECT project_id
    FROM raw_projects
    GROUP BY project_id
    HAVING COUNT(*) > 1
)
ORDER BY project_id;


-- ============================================================================
-- SECTION D: CONSISTENCY CHECKS
-- ============================================================================

SELECT 'SECTION D: CONSISTENCY CHECKS' AS section_header;

-- D1. Status vs delay_days mismatch
--     Rule: delay_days = 0        → 'On-Time'
--           delay_days 1–7        → 'Minor Delay'
--           delay_days > 7        → 'Delayed'
SELECT
    'STATUS vs DELAY_DAYS MISMATCH'   AS issue_type,
    project_id,
    project_name,
    delay_days,
    status,
    CASE
        WHEN delay_days = 0              THEN 'Should be: On-Time'
        WHEN delay_days BETWEEN 1 AND 7  THEN 'Should be: Minor Delay'
        WHEN delay_days > 7              THEN 'Should be: Delayed'
    END AS expected_status
FROM raw_projects
WHERE status IS NOT NULL
  AND delay_days IS NOT NULL
  AND (
        (delay_days = 0             AND BINARY TRIM(status) != 'On-Time')
     OR (delay_days BETWEEN 1 AND 7 AND BINARY TRIM(status) != 'Minor Delay')
     OR (delay_days > 7             AND BINARY TRIM(status) != 'Delayed')
  )
ORDER BY project_id;

-- D2. Non-standard status values
SELECT
    'NON-STANDARD STATUS VALUE'       AS issue_type,
    project_id,
    status,
    'Valid values: On-Time, Minor Delay, Delayed' AS note
FROM raw_projects
WHERE BINARY status NOT IN ('On-Time', 'Minor Delay', 'Delayed')
  AND status IS NOT NULL
ORDER BY project_id;

-- D3. Cost overrun % inconsistency
--     Rule: cost_overrun_pct = (actual - planned) / planned * 100
SELECT
    'COST OVERRUN PCT MISMATCH'       AS issue_type,
    project_id,
    project_name,
    planned_cost_eur,
    actual_cost_eur,
    cost_overrun_pct                  AS recorded_overrun_pct,
    ROUND(
        (actual_cost_eur - planned_cost_eur)
        / planned_cost_eur * 100, 1
    )                                 AS calculated_overrun_pct,
    ROUND(
        ABS(cost_overrun_pct -
            (actual_cost_eur - planned_cost_eur) / planned_cost_eur * 100),
        1
    )                                 AS discrepancy
FROM raw_projects
WHERE actual_cost_eur  IS NOT NULL
  AND planned_cost_eur IS NOT NULL
  AND planned_cost_eur > 0
  AND ABS(
        cost_overrun_pct -
        (actual_cost_eur - planned_cost_eur) / planned_cost_eur * 100
      ) > 1.0
ORDER BY discrepancy DESC;

-- D4. Wrong date logic — actual_end_date before start_date
SELECT
    'ACTUAL END BEFORE START DATE'    AS issue_type,
    project_id,
    project_name,
    start_date,
    actual_end_date,
    'actual_end_date is before start_date' AS reason
FROM raw_projects
WHERE actual_end_date < start_date
ORDER BY project_id;

-- D5. delay_days doesn't match date difference
--     Using MySQL DATEDIFF instead of JULIANDAY
SELECT
    'DELAY DAYS vs DATE DIFFERENCE MISMATCH'  AS issue_type,
    project_id,
    planned_end_date,
    actual_end_date,
    delay_days                                AS recorded_delay_days,
    DATEDIFF(actual_end_date, planned_end_date) AS calculated_delay_days
FROM raw_projects
WHERE delay_days    IS NOT NULL
  AND actual_end_date IS NOT NULL
  AND ABS(
        delay_days - DATEDIFF(actual_end_date, planned_end_date)
      ) > 1
  AND actual_end_date > start_date
ORDER BY project_id;


-- ============================================================================
-- SECTION E: OUTLIER DETECTION
-- ============================================================================

SELECT 'SECTION E: OUTLIER DETECTION' AS section_header;

-- E1. Utilisation > 100% or < 0%
SELECT
    'IMPOSSIBLE UTILISATION VALUE'    AS issue_type,
    project_id,
    project_name,
    utilization_pct,
    'Valid range: 0 to 100%'          AS note
FROM raw_projects
WHERE utilization_pct > 100
   OR utilization_pct < 0
ORDER BY project_id;

-- E2. Negative costs
SELECT
    'NEGATIVE COST VALUE'             AS issue_type,
    project_id,
    project_name,
    planned_cost_eur,
    actual_cost_eur,
    'Costs must be positive'          AS note
FROM raw_projects
WHERE planned_cost_eur < 0
   OR actual_cost_eur  < 0
ORDER BY project_id;

-- E3. Statistical outliers — cost_overrun_pct > mean + 3 standard deviations
SELECT
    'STATISTICAL OUTLIER (Cost Overrun > mean + 3 SD)' AS issue_type,
    project_id,
    project_name,
    cost_overrun_pct,
    ROUND(stats.mean_val, 1)          AS dataset_mean,
    ROUND(stats.upper_3sd, 1)         AS upper_3sd_threshold
FROM raw_projects
CROSS JOIN (
    SELECT
        AVG(cost_overrun_pct)                          AS mean_val,
        AVG(cost_overrun_pct) + 3 * STDDEV(cost_overrun_pct) AS upper_3sd
    FROM raw_projects
    WHERE cost_overrun_pct IS NOT NULL
) AS stats
WHERE cost_overrun_pct IS NOT NULL
  AND cost_overrun_pct > stats.upper_3sd
ORDER BY cost_overrun_pct DESC;


-- ============================================================================
-- SECTION F: DATA QUALITY SUMMARY REPORT
-- ============================================================================

SELECT 'SECTION F: DATA QUALITY SUMMARY REPORT' AS section_header;

SELECT issue_type, project_id, description
FROM (

    -- NULL values
    SELECT 'NULL Value'           AS issue_type, project_id,
           'actual_cost, cost_overrun_pct or utilization_pct is NULL' AS description
    FROM raw_projects
    WHERE actual_cost_eur IS NULL OR cost_overrun_pct IS NULL OR utilization_pct IS NULL

    UNION ALL

    -- Blank project name
    SELECT 'Blank Project Name',  project_id,
           'project_name is an empty string'
    FROM raw_projects
    WHERE TRIM(IFNULL(project_name,'')) = ''

    UNION ALL

    -- NULL client name
    SELECT 'NULL Client Name',    project_id,
           'client_name was not recorded at project setup'
    FROM raw_projects
    WHERE client_name IS NULL

    UNION ALL

    -- NULL delay and status
    SELECT 'NULL Status and Delay', project_id,
           'Both delay_days and status are NULL'
    FROM raw_projects
    WHERE delay_days IS NULL AND status IS NULL

    UNION ALL

    -- Duplicates
    SELECT 'Duplicate Project ID', project_id,
           'project_id appears more than once in the dataset'
    FROM raw_projects
    GROUP BY project_id
    HAVING COUNT(*) > 1

    UNION ALL

    -- Non-standard status
    SELECT 'Non-Standard Status',  project_id,
           CONCAT('status value ''', status, ''' is not in allowed list')
    FROM raw_projects
    WHERE status NOT IN ('On-Time','Minor Delay','Delayed')
      AND status IS NOT NULL

    UNION ALL

    -- Status vs delay mismatch
    SELECT 'Status Mismatch',      project_id,
           'status does not match the delay_days value'
    FROM raw_projects
    WHERE status IS NOT NULL AND delay_days IS NOT NULL
      AND (
            (delay_days = 0             AND BINARY TRIM(status) != 'On-Time')
         OR (delay_days BETWEEN 1 AND 7 AND BINARY TRIM(status) != 'Minor Delay')
         OR (delay_days > 7             AND BINARY TRIM(status) != 'Delayed')
      )

    UNION ALL

    -- Cost overrun mismatch
    SELECT 'Cost Overrun Pct Mismatch', project_id,
           CONCAT('Recorded: ', cost_overrun_pct,
                  '% | Calculated: ',
                  ROUND((actual_cost_eur-planned_cost_eur)/planned_cost_eur*100,1), '%')
    FROM raw_projects
    WHERE actual_cost_eur IS NOT NULL AND planned_cost_eur > 0
      AND ABS(cost_overrun_pct -
              (actual_cost_eur-planned_cost_eur)/planned_cost_eur*100) > 1.0

    UNION ALL

    -- Wrong date
    SELECT 'Wrong Date Logic',     project_id,
           'actual_end_date is before start_date — clear data entry error'
    FROM raw_projects
    WHERE actual_end_date < start_date

    UNION ALL

    -- Impossible utilisation
    SELECT 'Impossible Utilisation', project_id,
           CONCAT('utilization_pct = ', utilization_pct, '% — must be between 0 and 100')
    FROM raw_projects
    WHERE utilization_pct > 100 OR utilization_pct < 0

    UNION ALL

    -- Negative cost
    SELECT 'Negative Cost',        project_id,
           CONCAT('planned_cost_eur = ', planned_cost_eur, ' — must be positive')
    FROM raw_projects
    WHERE planned_cost_eur < 0 OR actual_cost_eur < 0

) AS all_issues
ORDER BY project_id, issue_type;


-- Total issues count
SELECT
    COUNT(*) AS total_issues_found,
    'Run mysql_day2_03_data_cleaning.sql to resolve all issues' AS next_step
FROM (
    SELECT project_id FROM raw_projects WHERE actual_cost_eur IS NULL OR cost_overrun_pct IS NULL OR utilization_pct IS NULL
    UNION ALL SELECT project_id FROM raw_projects WHERE TRIM(IFNULL(project_name,'')) = ''
    UNION ALL SELECT project_id FROM raw_projects WHERE client_name IS NULL
    UNION ALL SELECT project_id FROM raw_projects WHERE delay_days IS NULL AND status IS NULL
    UNION ALL SELECT project_id FROM raw_projects GROUP BY project_id HAVING COUNT(*) > 1
    UNION ALL SELECT project_id FROM raw_projects WHERE BINARY status NOT IN ('On-Time','Minor Delay','Delayed') AND status IS NOT NULL
    UNION ALL SELECT project_id FROM raw_projects WHERE actual_cost_eur IS NOT NULL AND planned_cost_eur > 0
              AND ABS(cost_overrun_pct-(actual_cost_eur-planned_cost_eur)/planned_cost_eur*100) > 1.0
    UNION ALL SELECT project_id FROM raw_projects WHERE actual_end_date < start_date
    UNION ALL SELECT project_id FROM raw_projects WHERE utilization_pct > 100 OR utilization_pct < 0
    UNION ALL SELECT project_id FROM raw_projects WHERE planned_cost_eur < 0 OR actual_cost_eur < 0
) AS issue_counts;

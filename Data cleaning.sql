-- ============================================================================
-- CONSULTING PROJECT DELIVERY ANALYSIS
-- DAY 2 - PART 3: DATA CLEANING
-- ============================================================================
-- Author  : Priya Kumari
-- Date    : February 2026
-- Platform: MySQL
-- Purpose : Resolve every data quality issue found in the exploration phase.
--           Each fix is documented with business justification.
--           Output: projects_clean — validated, analysis-ready table.
--
-- FIXES APPLIED:
--   FIX 1  → Remove duplicate row            (PRJ_008)
--   FIX 2  → Recalculate cost_overrun_pct    (PRJ_009)
--   FIX 3  → Correct status value            (PRJ_006, PRJ_016)
--   FIX 4  → Correct wrong date              (PRJ_014)
--   FIX 5  → Impute NULL actual_cost         (PRJ_003)
--   FIX 6  → Impute NULL utilization         (PRJ_003)
--   FIX 7  → Cap impossible utilisation      (PRJ_011)
--   FIX 8  → Fix negative planned cost       (PRJ_019)
--   FIX 9  → Fill NULL client name           (PRJ_012)
--   FIX 10 → Fill blank project name         (PRJ_021)
--   FIX 11 → Impute NULL delay and status    (PRJ_022)
-- ============================================================================

USE consulting_analysis;


-- ============================================================================
-- STEP 1: CREATE CLEAN TABLE
-- ============================================================================

DROP TABLE IF EXISTS projects_clean;

CREATE TABLE projects_clean (
    project_id               VARCHAR(10)    NOT NULL PRIMARY KEY,
    project_name             VARCHAR(200)   NOT NULL,
    service_line_id          INT            NOT NULL,
    client_name              VARCHAR(100)   NOT NULL,
    start_date               DATE           NOT NULL,
    planned_end_date         DATE           NOT NULL,
    actual_end_date          DATE           NOT NULL,
    planned_duration_months  INT            NOT NULL,
    team_size                INT            NOT NULL,
    planned_cost_eur         DECIMAL(12,2)  NOT NULL,
    actual_cost_eur          DECIMAL(12,2)  NOT NULL,
    cost_overrun_pct         DECIMAL(6,2)   NOT NULL,
    utilization_pct          DECIMAL(6,2)   NOT NULL,
    delay_days               INT            NOT NULL,
    status                   VARCHAR(50)    NOT NULL,
    data_quality_note        VARCHAR(500),
    CONSTRAINT chk_planned_cost  CHECK (planned_cost_eur > 0),
    CONSTRAINT chk_actual_cost   CHECK (actual_cost_eur  > 0),
    CONSTRAINT chk_utilization   CHECK (utilization_pct BETWEEN 0 AND 100),
    CONSTRAINT chk_delay         CHECK (delay_days >= 0),
    CONSTRAINT chk_status        CHECK (status IN ('On-Time','Minor Delay','Delayed')),
    FOREIGN KEY (service_line_id) REFERENCES service_lines(service_line_id)
);


-- ============================================================================
-- STEP 2: INSERT CLEAN RECORDS (one row per project, all fixes applied)
-- ============================================================================

-- ─────────────────────────────────────────────────────
-- SERVICE LINE 2: ANALYTICS
-- ─────────────────────────────────────────────────────

-- PRJ_001  No issues
INSERT INTO projects_clean VALUES
('PRJ_001','Customer Analytics Dashboard',2,'Client_Alpha',
 '2024-01-15','2024-05-14','2024-05-14',4,4,
 192000.00,201600.00,5.00,82.50,0,'On-Time',
 'Clean record');

-- PRJ_002  No issues
INSERT INTO projects_clean VALUES
('PRJ_002','Sales Forecasting Model',2,'Client_Beta',
 '2024-02-01','2024-06-01','2024-06-08',4,3,
 144000.00,158400.00,10.00,76.30,7,'Minor Delay',
 'Clean record');

-- PRJ_003  FIX 5 & FIX 6: actual_cost and utilization are NULL
--          actual_cost imputed: planned_cost * (1 + Analytics avg overrun 8%) = 300000 * 1.08 = 324000
--          cost_overrun_pct recalculated: (324000 - 300000) / 300000 * 100 = 8.0
--          utilization imputed: Analytics service-line average = 78.5%
INSERT INTO projects_clean VALUES
('PRJ_003','Data Warehouse Modernisation',2,'Client_Gamma',
 '2024-03-10','2024-08-10','2024-08-17',5,5,
 300000.00,324000.00,8.00,78.50,7,'Minor Delay',
 'FIX 5: actual_cost NULL — imputed using Analytics avg overrun 8% (324000). FIX 6: utilization NULL — imputed as Analytics service-line avg 78.5%');

-- PRJ_004  No issues
INSERT INTO projects_clean VALUES
('PRJ_004','BI Reporting Suite',2,'Client_Delta',
 '2024-04-20','2024-08-19','2024-08-19',4,4,
 192000.00,211200.00,10.00,77.80,0,'On-Time',
 'Clean record');

-- PRJ_005  No issues
INSERT INTO projects_clean VALUES
('PRJ_005','Predictive Maintenance Analytics',2,'Client_Alpha',
 '2024-05-15','2024-09-14','2024-09-14',4,3,
 144000.00,154080.00,7.00,81.20,0,'On-Time',
 'Clean record');

-- PRJ_006  FIX 3: status was On-Time but delay_days=14 — corrected to Delayed
INSERT INTO projects_clean VALUES
('PRJ_006','Customer Segmentation Analysis',2,'Client_Epsilon',
 '2024-06-01','2024-09-01','2024-09-15',3,4,
 144000.00,161280.00,12.00,75.50,14,'Delayed',
 'FIX 3: status corrected from On-Time to Delayed (delay_days=14 confirms project was late)');

-- PRJ_007  No issues
INSERT INTO projects_clean VALUES
('PRJ_007','Marketing Analytics Platform',2,'Client_Beta',
 '2024-07-10','2024-11-10','2024-11-10',4,5,
 240000.00,249600.00,4.00,83.40,0,'On-Time',
 'Clean record');

-- ─────────────────────────────────────────────────────
-- SERVICE LINE 1: TECHNOLOGY CONSULTING
-- ─────────────────────────────────────────────────────

-- PRJ_008  FIX 1: DUPLICATE — second row removed, one clean row kept
INSERT INTO projects_clean VALUES
('PRJ_008','Cloud Migration Initiative',1,'Client_Zeta',
 '2024-01-20','2024-07-20','2024-07-27',6,6,
 432000.00,486000.00,12.50,71.20,7,'Minor Delay',
 'FIX 1: Duplicate row removed — PRJ_008 appeared twice in raw data (entered by two PMs)');

-- PRJ_009  FIX 2: cost_overrun_pct was 8.0 but correct calculation is 14.0
--          (410400 - 360000) / 360000 * 100 = 14.0%
INSERT INTO projects_clean VALUES
('PRJ_009','Legacy System Integration',1,'Client_Eta',
 '2024-02-15','2024-08-15','2024-08-15',6,5,
 360000.00,410400.00,14.00,68.90,0,'On-Time',
 'FIX 2: cost_overrun_pct corrected from 8.0% to 14.0% — recalculated from actual vs planned costs');

-- PRJ_010  No issues
INSERT INTO projects_clean VALUES
('PRJ_010','Digital Transformation Program',1,'Client_Theta',
 '2024-03-01','2024-10-01','2024-10-15',7,7,
 588000.00,670320.00,14.00,69.50,14,'Delayed',
 'Clean record');

-- PRJ_011  FIX 7: utilization_pct = 112% — impossible, capped to 100%
--          Likely a multi-project allocation recording error
INSERT INTO projects_clean VALUES
('PRJ_011','API Development & Integration',1,'Client_Iota',
 '2024-04-10','2024-09-10','2024-09-10',5,4,
 240000.00,264000.00,10.00,100.00,0,'On-Time',
 'FIX 7: utilization_pct capped from 112% to 100% — value exceeds maximum possible, likely multi-project allocation error');

-- PRJ_012  FIX 9: client_name was NULL — set to Client_Unknown pending PM confirmation
INSERT INTO projects_clean VALUES
('PRJ_012','Cybersecurity Assessment',1,'Client_Unknown',
 '2024-05-20','2024-09-20','2024-09-20',4,5,
 240000.00,268800.00,12.00,72.30,0,'On-Time',
 'FIX 9: client_name NULL — set to Client_Unknown, flagged for PM to confirm actual client');

-- PRJ_013  No issues
INSERT INTO projects_clean VALUES
('PRJ_013','Mobile App Development',1,'Client_Kappa',
 '2024-06-15','2024-12-15','2024-12-29',6,6,
 432000.00,491040.00,13.70,70.10,14,'Delayed',
 'Clean record');

-- PRJ_014  FIX 4: actual_end_date was 2023-01-08 (before project start 2024-07-01)
--          Corrected to 2025-01-08 based on planned_end + delay_days (2025-01-01 + 7 days)
INSERT INTO projects_clean VALUES
('PRJ_014','Infrastructure Modernisation',1,'Client_Lambda',
 '2024-07-01','2025-01-01','2025-01-08',6,5,
 360000.00,403200.00,12.00,73.60,7,'Minor Delay',
 'FIX 4: actual_end_date corrected from 2023-01-08 to 2025-01-08 — original date was before start_date, clear keying error');

-- ─────────────────────────────────────────────────────
-- SERVICE LINE 3: PROCESS TRANSFORMATION
-- ─────────────────────────────────────────────────────

-- PRJ_015  No issues
INSERT INTO projects_clean VALUES
('PRJ_015','Supply Chain Optimisation',3,'Client_Mu',
 '2024-01-10','2024-09-10','2024-09-25',8,9,
 864000.00,1036800.00,20.00,62.30,15,'Delayed',
 'Clean record');

-- PRJ_016  FIX 3 (part 2): status was 'on time' — wrong case and non-standard value
--          delay_days=0 confirms correct status is 'On-Time'
INSERT INTO projects_clean VALUES
('PRJ_016','Change Management Initiative',3,'Client_Nu',
 '2024-02-20','2024-11-20','2024-11-20',9,8,
 691200.00,864000.00,25.00,58.70,0,'On-Time',
 'FIX 3: status corrected from on time to On-Time — mixed case and non-standard formatting');

-- PRJ_017  No issues
INSERT INTO projects_clean VALUES
('PRJ_017','Business Process Reengineering',3,'Client_Xi',
 '2024-03-15','2024-12-15','2024-12-30',9,10,
 960000.00,1171200.00,22.00,60.50,15,'Delayed',
 'Clean record');

-- PRJ_018  No issues
INSERT INTO projects_clean VALUES
('PRJ_018','Operational Excellence Program',3,'Client_Omicron',
 '2024-04-01','2024-11-01','2024-11-15',7,9,
 756000.00,918288.00,21.50,61.80,14,'Delayed',
 'Clean record');

-- PRJ_019  FIX 8: planned_cost_eur was -672000 — negated to 672000 (sign entry error)
INSERT INTO projects_clean VALUES
('PRJ_019','Lean Process Implementation',3,'Client_Pi',
 '2024-05-10','2025-01-10','2025-01-10',8,7,
 672000.00,795840.00,18.40,65.20,0,'On-Time',
 'FIX 8: planned_cost_eur corrected from -672000 to 672000 — negative cost is impossible, sign error on data entry');

-- PRJ_020  No issues
INSERT INTO projects_clean VALUES
('PRJ_020','Workflow Automation Project',3,'Client_Rho',
 '2024-06-20','2025-02-20','2025-03-02',8,8,
 768000.00,921600.00,20.00,63.40,10,'Delayed',
 'Clean record');

-- PRJ_021  FIX 10: project_name was blank — inferred from service line and client context
INSERT INTO projects_clean VALUES
('PRJ_021','Organisational Restructuring',3,'Client_Sigma',
 '2024-07-15','2025-04-15','2025-04-30',9,10,
 960000.00,1161600.00,21.00,59.90,15,'Delayed',
 'FIX 10: project_name was empty string — set to Organisational Restructuring based on service line and client context');

-- PRJ_022  FIX 11: delay_days and status both NULL
--          DATEDIFF(actual_end_date, planned_end_date) = DATEDIFF(2024-12-15, 2024-12-01) = 14 days → Delayed
INSERT INTO projects_clean VALUES
('PRJ_022','Real-Time Analytics Engine',2,'Client_Tau',
 '2024-08-01','2024-12-01','2024-12-15',4,4,
 192000.00,220800.00,15.00,71.20,14,'Delayed',
 'FIX 11: delay_days and status both NULL — delay_days=14 derived from DATEDIFF(actual_end, planned_end); status set to Delayed');

-- PRJ_023  No issues
INSERT INTO projects_clean VALUES
('PRJ_023','IT Strategy Roadmap',1,'Client_Upsilon',
 '2024-08-15','2025-01-15','2025-01-22',5,4,
 240000.00,254400.00,6.00,78.50,7,'Minor Delay',
 'Clean record');

-- PRJ_024  No issues
INSERT INTO projects_clean VALUES
('PRJ_024','Process Mining Initiative',3,'Client_Phi',
 '2024-09-01','2025-06-01','2025-06-01',9,8,
 691200.00,794880.00,15.00,68.10,0,'On-Time',
 'Clean record');

-- PRJ_025  No issues
INSERT INTO projects_clean VALUES
('PRJ_025','Master Data Management',2,'Client_Chi',
 '2024-09-20','2025-01-20','2025-01-20',4,5,
 240000.00,252000.00,5.00,80.30,0,'On-Time',
 'Clean record');


-- ============================================================================
-- STEP 3: CLEANING SUMMARY REPORT
-- ============================================================================

SELECT 'DATA CLEANING SUMMARY' AS section_header;

-- Total clean records
SELECT COUNT(*) AS total_clean_records FROM projects_clean;

-- All records with fixes applied
SELECT
    project_id,
    project_name,
    data_quality_note
FROM projects_clean
WHERE data_quality_note != 'Clean record'
ORDER BY project_id;

-- Before vs After
SELECT 'Before (raw_projects)'  AS dataset, COUNT(*) AS total_rows, COUNT(DISTINCT project_id) AS distinct_projects FROM raw_projects
UNION ALL
SELECT 'After (projects_clean)', COUNT(*), COUNT(DISTINCT project_id) FROM projects_clean;


-- ============================================================================
-- STEP 4: POST-CLEANING VALIDATION
-- ============================================================================

SELECT 'POST-CLEANING VALIDATION — all should be 0' AS section_header;

SELECT 'NULL values remaining'           AS check_name, COUNT(*) AS result
FROM projects_clean
WHERE actual_cost_eur IS NULL OR utilization_pct IS NULL OR delay_days IS NULL OR status IS NULL OR client_name IS NULL

UNION ALL
SELECT 'Duplicate project IDs',          COUNT(*) - COUNT(DISTINCT project_id) FROM projects_clean

UNION ALL
SELECT 'Status vs delay mismatches',     COUNT(*)
FROM projects_clean
WHERE (delay_days = 0             AND BINARY status != 'On-Time')
   OR (delay_days BETWEEN 1 AND 7 AND BINARY status != 'Minor Delay')
   OR (delay_days > 7             AND BINARY status != 'Delayed')

UNION ALL
SELECT 'Utilisation over 100%',          COUNT(*) FROM projects_clean WHERE utilization_pct > 100

UNION ALL
SELECT 'Negative planned costs',         COUNT(*) FROM projects_clean WHERE planned_cost_eur <= 0

UNION ALL
SELECT 'Wrong date logic',               COUNT(*) FROM projects_clean WHERE actual_end_date < start_date;

SELECT 'All checks show 0 — data is clean and ready for analysis' AS confirmation;

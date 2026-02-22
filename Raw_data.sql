-- ============================================================================
-- CONSULTING PROJECT DELIVERY ANALYSIS
-- DAY 2 - PART 1: RAW MESSY DATASET
-- ============================================================================
-- Author  : Priya Kumari
-- Date    : February 2026
-- Platform: MySQL
-- Purpose : Simulate a real-world internal consulting dataset as it would
--           arrive from multiple data entry sources — with all the typical
--           quality issues a Business Analyst must identify and resolve.
--
-- INTENTIONAL DATA QUALITY ISSUES EMBEDDED:
--   1. NULL values        → Missing actual_cost, cost_overrun_pct, utilization
--   2. Duplicate rows     → Same project entered twice (PRJ_008)
--   3. Status mismatch    → delay_days vs status inconsistent (PRJ_006, PRJ_016)
--   4. Cost inconsistency → cost_overrun_pct doesn't match actual/planned (PRJ_009)
--   5. Outlier values     → Impossible utilization >100% (PRJ_011)
--   6. Wrong date logic   → actual_end_date before start_date (PRJ_014)
--   7. Blank string       → Empty project_name (PRJ_021)
--   8. Mixed case status  → 'on time' instead of 'On-Time' (PRJ_016)
--   9. NULL client name   → Not captured at setup (PRJ_012)
--  10. Negative cost      → planned_cost entered as negative (PRJ_019)
--  11. NULL delay/status  → Both fields missing (PRJ_022)
-- ============================================================================


-- ============================================================================
-- CREATE & USE DATABASE
-- ============================================================================

DROP DATABASE IF EXISTS consulting_analysis;
CREATE DATABASE consulting_analysis;
USE consulting_analysis;


-- ============================================================================
-- TABLE 1: SERVICE_LINES
-- ============================================================================

CREATE TABLE service_lines (
    service_line_id          INT           PRIMARY KEY,
    service_line_name        VARCHAR(100)  NOT NULL,
    complexity_level         VARCHAR(20)   NOT NULL,
    typical_duration_months  INT,
    typical_team_size        INT
);

INSERT INTO service_lines VALUES
(1, 'Technology Consulting', 'Medium', 6, 6),
(2, 'Analytics',             'Medium', 4, 4),
(3, 'Process Transformation','High',   8, 9);


-- ============================================================================
-- TABLE 2: RAW_PROJECTS  (messy — as received from source systems)
-- ============================================================================

CREATE TABLE raw_projects (
    project_id               VARCHAR(10),
    project_name             VARCHAR(200),
    service_line_id          INT,
    client_name              VARCHAR(100),
    start_date               DATE,
    planned_end_date         DATE,
    actual_end_date          DATE,
    planned_duration_months  INT,
    team_size                INT,
    planned_cost_eur         DECIMAL(12,2),
    actual_cost_eur          DECIMAL(12,2),
    cost_overrun_pct         DECIMAL(6,2),
    utilization_pct          DECIMAL(6,2),
    delay_days               INT,
    status                   VARCHAR(50)
);


-- ============================================================================
-- INSERT RAW DATA (25 projects + 1 duplicate = 26 rows)
-- ============================================================================

-- ─────────────────────────────────────────────────────
-- SERVICE LINE 2: ANALYTICS  (best performers)
-- Benchmarks: ~78% utilisation, ~9% overrun, ~79% on-time
-- ─────────────────────────────────────────────────────

-- PRJ_001  Clean record
INSERT INTO raw_projects VALUES
('PRJ_001','Customer Analytics Dashboard',2,'Client_Alpha',
 '2024-01-15','2024-05-14','2024-05-14',4,4,
 192000.00,201600.00,5.00,82.50,0,'On-Time');

-- PRJ_002  Clean record — minor delay
INSERT INTO raw_projects VALUES
('PRJ_002','Sales Forecasting Model',2,'Client_Beta',
 '2024-02-01','2024-06-01','2024-06-08',4,3,
 144000.00,158400.00,10.00,76.30,7,'Minor Delay');

-- PRJ_003  ⚠ ISSUE 1: NULL values — actual_cost, cost_overrun_pct, utilization not logged
INSERT INTO raw_projects VALUES
('PRJ_003','Data Warehouse Modernisation',2,'Client_Gamma',
 '2024-03-10','2024-08-10','2024-08-17',5,5,
 300000.00,NULL,NULL,NULL,7,'Minor Delay');

-- PRJ_004  Clean record
INSERT INTO raw_projects VALUES
('PRJ_004','BI Reporting Suite',2,'Client_Delta',
 '2024-04-20','2024-08-19','2024-08-19',4,4,
 192000.00,211200.00,10.00,77.80,0,'On-Time');

-- PRJ_005  Clean record
INSERT INTO raw_projects VALUES
('PRJ_005','Predictive Maintenance Analytics',2,'Client_Alpha',
 '2024-05-15','2024-09-14','2024-09-14',4,3,
 144000.00,154080.00,7.00,81.20,0,'On-Time');

-- PRJ_006  ⚠ ISSUE 2: STATUS MISMATCH — delay_days=14 but status='On-Time'
INSERT INTO raw_projects VALUES
('PRJ_006','Customer Segmentation Analysis',2,'Client_Epsilon',
 '2024-06-01','2024-09-01','2024-09-15',3,4,
 144000.00,161280.00,12.00,75.50,14,'On-Time');

-- PRJ_007  Clean record
INSERT INTO raw_projects VALUES
('PRJ_007','Marketing Analytics Platform',2,'Client_Beta',
 '2024-07-10','2024-11-10','2024-11-10',4,5,
 240000.00,249600.00,4.00,83.40,0,'On-Time');

-- ─────────────────────────────────────────────────────
-- SERVICE LINE 1: TECHNOLOGY CONSULTING  (average performers)
-- Benchmarks: ~72% utilisation, ~13% overrun, ~69% on-time
-- ─────────────────────────────────────────────────────

-- PRJ_008  ⚠ ISSUE 3: DUPLICATE ROW — entered twice by two project managers
INSERT INTO raw_projects VALUES
('PRJ_008','Cloud Migration Initiative',1,'Client_Zeta',
 '2024-01-20','2024-07-20','2024-07-27',6,6,
 432000.00,486000.00,12.50,71.20,7,'Minor Delay');

INSERT INTO raw_projects VALUES
('PRJ_008','Cloud Migration Initiative',1,'Client_Zeta',
 '2024-01-20','2024-07-20','2024-07-27',6,6,
 432000.00,486000.00,12.50,71.20,7,'Minor Delay');

-- PRJ_009  ⚠ ISSUE 4: COST INCONSISTENCY
--          actual=410400, planned=360000 → real overrun = 14.0%
--          but cost_overrun_pct recorded as 8.0 (wrong manual entry)
INSERT INTO raw_projects VALUES
('PRJ_009','Legacy System Integration',1,'Client_Eta',
 '2024-02-15','2024-08-15','2024-08-15',6,5,
 360000.00,410400.00,8.00,68.90,0,'On-Time');

-- PRJ_010  Clean record — delayed
INSERT INTO raw_projects VALUES
('PRJ_010','Digital Transformation Program',1,'Client_Theta',
 '2024-03-01','2024-10-01','2024-10-15',7,7,
 588000.00,670320.00,14.00,69.50,14,'Delayed');

-- PRJ_011  ⚠ ISSUE 5: OUTLIER — utilization = 112% (impossible value)
INSERT INTO raw_projects VALUES
('PRJ_011','API Development & Integration',1,'Client_Iota',
 '2024-04-10','2024-09-10','2024-09-10',5,4,
 240000.00,264000.00,10.00,112.00,0,'On-Time');

-- PRJ_012  ⚠ ISSUE 6: NULL client_name — not captured at project setup
INSERT INTO raw_projects VALUES
('PRJ_012','Cybersecurity Assessment',1,NULL,
 '2024-05-20','2024-09-20','2024-09-20',4,5,
 240000.00,268800.00,12.00,72.30,0,'On-Time');

-- PRJ_013  Clean record — delayed
INSERT INTO raw_projects VALUES
('PRJ_013','Mobile App Development',1,'Client_Kappa',
 '2024-06-15','2024-12-15','2024-12-29',6,6,
 432000.00,491040.00,13.70,70.10,14,'Delayed');

-- PRJ_014  ⚠ ISSUE 7: WRONG DATE — actual_end_date is before start_date
--          actual_end recorded as '2023-01-08', project started '2024-07-01'
INSERT INTO raw_projects VALUES
('PRJ_014','Infrastructure Modernisation',1,'Client_Lambda',
 '2024-07-01','2025-01-01','2023-01-08',6,5,
 360000.00,403200.00,12.00,73.60,7,'Minor Delay');

-- ─────────────────────────────────────────────────────
-- SERVICE LINE 3: PROCESS TRANSFORMATION  (worst performers)
-- Benchmarks: ~64% utilisation, ~20% overrun, ~43% on-time
-- ─────────────────────────────────────────────────────

-- PRJ_015  Clean record — severely delayed
INSERT INTO raw_projects VALUES
('PRJ_015','Supply Chain Optimisation',3,'Client_Mu',
 '2024-01-10','2024-09-10','2024-09-25',8,9,
 864000.00,1036800.00,20.00,62.30,15,'Delayed');

-- PRJ_016  ⚠ ISSUE 8: MIXED CASE — status='on time' instead of 'On-Time'
INSERT INTO raw_projects VALUES
('PRJ_016','Change Management Initiative',3,'Client_Nu',
 '2024-02-20','2024-11-20','2024-11-20',9,8,
 691200.00,864000.00,25.00,58.70,0,'on time');

-- PRJ_017  Clean record — delayed, high overrun
INSERT INTO raw_projects VALUES
('PRJ_017','Business Process Reengineering',3,'Client_Xi',
 '2024-03-15','2024-12-15','2024-12-30',9,10,
 960000.00,1171200.00,22.00,60.50,15,'Delayed');

-- PRJ_018  Clean record — delayed
INSERT INTO raw_projects VALUES
('PRJ_018','Operational Excellence Program',3,'Client_Omicron',
 '2024-04-01','2024-11-01','2024-11-15',7,9,
 756000.00,918288.00,21.50,61.80,14,'Delayed');

-- PRJ_019  ⚠ ISSUE 9: NEGATIVE PLANNED COST — sign error on data entry
INSERT INTO raw_projects VALUES
('PRJ_019','Lean Process Implementation',3,'Client_Pi',
 '2024-05-10','2025-01-10','2025-01-10',8,7,
 -672000.00,795840.00,18.40,65.20,0,'On-Time');

-- PRJ_020  Clean record — delayed
INSERT INTO raw_projects VALUES
('PRJ_020','Workflow Automation Project',3,'Client_Rho',
 '2024-06-20','2025-02-20','2025-03-02',8,8,
 768000.00,921600.00,20.00,63.40,10,'Delayed');

-- PRJ_021  ⚠ ISSUE 10: BLANK PROJECT NAME — empty string recorded
INSERT INTO raw_projects VALUES
('PRJ_021','',3,'Client_Sigma',
 '2024-07-15','2025-04-15','2025-04-30',9,10,
 960000.00,1161600.00,21.00,59.90,15,'Delayed');

-- PRJ_022  ⚠ ISSUE 11: NULL delay_days AND NULL status — incomplete record
INSERT INTO raw_projects VALUES
('PRJ_022','Real-Time Analytics Engine',2,'Client_Tau',
 '2024-08-01','2024-12-01','2024-12-15',4,4,
 192000.00,220800.00,15.00,71.20,NULL,NULL);

-- PRJ_023  Clean record
INSERT INTO raw_projects VALUES
('PRJ_023','IT Strategy Roadmap',1,'Client_Upsilon',
 '2024-08-15','2025-01-15','2025-01-22',5,4,
 240000.00,254400.00,6.00,78.50,7,'Minor Delay');

-- PRJ_024  Clean record
INSERT INTO raw_projects VALUES
('PRJ_024','Process Mining Initiative',3,'Client_Phi',
 '2024-09-01','2025-06-01','2025-06-01',9,8,
 691200.00,794880.00,15.00,68.10,0,'On-Time');

-- PRJ_025  Clean record
INSERT INTO raw_projects VALUES
('PRJ_025','Master Data Management',2,'Client_Chi',
 '2024-09-20','2025-01-20','2025-01-20',4,5,
 240000.00,252000.00,5.00,80.30,0,'On-Time');


-- ============================================================================
-- QUICK RECORD COUNT CHECK
-- ============================================================================

SELECT
    'raw_projects rows (expect 26 — 25 projects + 1 duplicate)' AS check_label,
    COUNT(*) AS row_count
FROM raw_projects;
select * from raw_projects;


# 📊 Consulting Project Delivery Performance Analysis

**Tools:** SQL · Power BI Desktop  
**Author:** Priya Kumari  
**Domain:** Business Analysis | Operations Strategy  
**Status:** Completed  
**Date:** February 2026

---

## 📌 Business Problem

> *A mid-sized Irish consulting firm operating across three service lines- Analytics, Technology Consulting, and Process Transformation is experiencing systematic operational challenges affecting both financial performance and client relationships. What is driving the cost overruns and delivery delays, and what should leadership do about it?*

A full diagnostic analysis covering 25 projects, benchmarked against industry standards, with actionable recommendations and a 12-month implementation roadmap.

---

## 🎯 Objectives

- Quantify performance gaps against industry benchmarks (Deltek 2025, SPI Research)
- Identify and validate root causes of cost overruns and delivery delays
- Perform rigorous data quality management on a real-world messy dataset
- Test three core hypotheses using statistical analysis
- Deliver executive-ready recommendations with projected financial impact

---

## 📊 Dataset Overview

| Parameter | Detail |
|-----------|--------|
| Projects Analysed | 25 projects |
| Analysis Period | January-September 2024 |
| Service Lines | Analytics, Technology Consulting, Process Transformation |
| Total Planned Budget | €11,042,400 |
| Total Actual Cost | €12,845,328 |
| Total Cost Overruns | €1,802,928 |
| Data Quality Issues Found | 11 issues across 44% of dataset |
| Validation Pass Rate | 100% after cleaning |

---

## 📈 Key Performance Metrics vs Benchmarks

| Metric | Our Firm | Industry Average | Top 25% | Target | Gap |
|--------|----------|-----------------|---------|--------|-----|
| On-Time Delivery | 44.0% | 73.4% | 85.7% | 90.0% | -46 pts |
| Cost Overrun % | 13.3% | 11.3% | 7.8% | 10.0% | -3.3 pts |
| Utilisation Rate | 72.4% | 68.9% | 74.5% | 75.0% | -2.6 pts |

**Critical finding:** On-time delivery at 44% is the most severe gap-46 percentage points below target and 29 points below industry average.

---

## 🔍 Key Findings

### Service Line Performance

| Service Line | Projects | Avg Utilisation | Avg Overrun | On-Time | Total Overrun | % of Total |
|-------------|----------|----------------|-------------|---------|---------------|------------|
| Analytics | 9 (36%) | 78.5% | 8.4% | 55.6% | €144,960 | 8.0% |
| Technology Consulting | 8 (32%) | 75.5% | 11.8% | 37.5% | €356,160 | 19.8% |
| Process Transformation | 8 (32%) | 62.5% | 20.4% | 37.5% | €1,301,808 | 72.2% |

**Process Transformation accounts for 72% of all cost overruns despite representing only 32% of projects.**

### Risk Categorisation

| Risk Category | Projects | Avg Utilisation | Avg Overrun |
|--------------|----------|----------------|-------------|
| High Risk | 4 (16%) | 60.2% | 22.4% |
| Medium Risk | 3 (12%) | 63.6% | 19.5% |
| Low Risk | 18 (72%) | 76.6% | 10.3% |

All 4 High Risk projects belong to the Process Transformation service line.

---

## 🧪 Hypothesis Testing Results

### H1- Low Utilisation Correlates with Poor Performance
**Verdict: Partially Supported**
- Optimal utilisation (75%+) shows 7.7% average overrun vs 19.1% for low utilisation
- However, utilisation alone does not fully explain delivery delays- estimation quality and project complexity are stronger drivers

### H2- Cost Overruns Driven by Delay Days
**Verdict: Partially Supported**
- Delayed projects account for 60.4% of total overruns while representing 36% of projects
- On-time projects still contribute 31.3% of overruns- scope creep and poor estimation also significant

### H3- Significant Performance Variance Exists Between Service Lines
**Verdict: Strongly Supported**
- 12 percentage point spread in cost overrun between Analytics (8.4%) and Process Transformation (20.4%)
- 16 percentage point spread in utilisation
- Estimated annual savings of €765,000 if Process Transformation matched Analytics performance

---

## 💡 Root Causes Identified

1. Structural weaknesses in Process Transformation delivery model
2. Delay-driven cost escalation (60.4% of overruns tied to delayed projects)
3. Inconsistent estimation discipline and variance control
4. Weak risk governance on high-complexity projects

---

## 📋 Recommendations & Financial Impact

### Immediate (0–3 Months)
- Process Transformation forensic review + mandatory senior PM oversight
- Weekly project health reviews with early warning triggers (budget variance >5%, schedule slip >3 days)
- Executive dashboard deployment for real-time visibility

### Medium Term (3–6 Months)
- Data-driven estimation playbook + peer review process
- Formal scope governance and change order system
- Real-time utilisation dashboards

### Strategic (6–12 Months)
- Monthly re-forecasting for all PT projects
- High-complexity project safeguard framework
- Performance-linked PM accountability (15–20% KPI score tied to margin outcome)

### Projected Financial Impact

| Scenario | Projected Annual Overrun | vs Current |
|----------|------------------------|------------|
| Current | €1,802,928 | Baseline |
| Base Case | €1,435,512 | €367,416 savings |
| Best Case | €993,816 | €809,112 savings (45%) |
| Worst Case | €2,208,480 | €405,552 additional |

**Conservative to aggressive annual savings: €400,000- €750,000**

---

## 🛠️ Tools & Techniques

| Area | Detail |
|------|--------|
| Data Cleaning | SQL- multi-phase pipeline with automated validation |
| Analysis | SQL-based hypothesis testing, statistical variance analysis |
| Benchmarking | Deltek 2025, SPI Research, CSO Ireland, PMI |
| Visualisation | Power BI Desktop — KPI cards, bar charts, scatter plots, risk tables |
| Reporting | Executive-level written report with scenario modelling |

---

## 🔧 Data Quality Management Process

**Phase 1- Exploration**
Systematic audit across 6 dimensions: NULLs, duplicates, consistency, outliers, date logic, statistical anomalies. Result: 11 distinct issues identified across 44% of dataset.

**Phase 2- Cleaning**
Business justification documented for every fix. Imputation based on service line averages. All fixes traceable via data_quality_note field.

**Phase 3- Validation**
6 automated validation checks executed. Result: 100% pass rate. Cross-validated all metrics against SQL query results.

---

## 📁 Dashboard Pages

1. **Background & Objective**- business context, key challenges
2. **Executive Summary**- KPI cards, benchmark comparison, service line table
3. **Hypothesis Testing**- H1 scatter, H2 bar chart, H3 service line comparison
4. **Financial Impact**- overrun by service line, planned vs actual cost waterfall
5. **Scenario Planning**- interactive scenario selector, target achievement gauges
6. **Full Project Details & Risk**- project-level table with risk categorisation
7. **Recommendations & Action Plan**- priorities, timeline, projected savings

---

## 📈 Business Skills Demonstrated

- End-to-end business analysis from problem definition to executive recommendation
- SQL pipeline engineering and data quality management
- Hypothesis-driven analytical framework
- Industry benchmark research and application (Deltek, SPI Research, CSO)
- Financial impact quantification and scenario modelling
- Risk categorisation and mitigation planning
- Stakeholder-ready written report and Power BI dashboard delivery

---

## 🚀 How to Use

1. Open Power BI Desktop
2. Load the provided dataset (Excel or CSV file)
3. Run the SQL cleaning script first to ensure data integrity
4. Navigate dashboard pages sequentially
5. Use the Scenario Planning page interactively to model different performance outcomes
6. Refer to the full written report for detailed methodology and findings


---

## 📚 Data Sources & Benchmarks

- Deltek Professional Services Benchmarks (2025)
- SPI Research Professional Services Maturity Benchmark (2024)
- CSO Ireland Labour Force Survey Q3 2024
- Eurostat Productivity Statistics (2024)
- Project Management Institute (PMI) Research

---

## 🔗 Connect

**Priya Kumari**  
MSc Business Analytics | University of Limerick  
[LinkedIn](https://www.linkedin.com/in/priyakumari62) · priyamahato2024@gmail.com

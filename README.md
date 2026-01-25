## Table of Contents
- [Project Overview](#Project-Overview)
- [Business Problem](#Business-Problem)
- [Project Objectives](#Project-Objectives)
- [Project Illustration](#Project-Illustration)
- [Project Walkthrough](#Project-Walkthrough)
- [Deliverables](#Deliverables)
- [Tools & Technologies](#Tools-&-Technologies)


# 📊  NBFC Loan Risk & Collections Analytics System
## Project Overview

The NBFC Loan Risk & Collections Analytics System is a strategic analytics initiative designed to help Non-Banking Financial Companies (NBFCs proactively manage credit risk, reduce delinquencies, and improve collections efficiency.

This system provides a centralized, data-driven framework to monitor loan portfolio health, detect early warning signals of default, track borrower repayment behavior, and evaluate the effectiveness of collection efforts across agents, branches, products, and geographies.

Rising early-stage delinquencies (0–30 DPD) and poor visibility into roll-forward risk often result in avoidable NPAs and inefficient collections. This project addresses those gaps by transforming raw operational data into actionable insights for credit, risk, and collections teams.

## Business Problem

NBFCs typically manage large and diverse loan portfolios across multiple products and regions. However, many institutions face challenges such as:

- Limited visibility into early delinquency signals

- Reactive handling of accounts once they reach 60–90+ DPD

- Inability to track DPD bucket migration patterns

- Poor measurement of collection effectiveness

- Lack of agent- and branch-level performance accountability

Operational data exists across loan systems, repayment logs, and collection activity records—but remains underutilized for analytical decision-making.

This results in:

- Higher credit losses

- Increased collection costs

- Missed opportunities for early intervention

## Project Objectives

The primary objective of this system is to enable proactive risk management and data-driven collections strategy. Key goals include:

- Early Risk Identification
Detect high-risk loan accounts before they migrate into severe delinquency buckets.

- DPD Migration Analysis
Track and analyze borrower movement across DPD stages (0–30 → 30–60 → 60–90+).

- Early Warning Signals
Identify behavioral red flags such as missed EMIs, broken PTPs, and low contactability.

- Collections Performance Evaluation
Measure agent, branch, and channel effectiveness using standardized KPIs.

- Portfolio Health Monitoring
Provide leadership with a real-time view of loan book quality.

## Project Illustration – System Workflow
### Example Scenario
#### Loan Account: LA10234
#### Product: Personal Loan
#### Current DPD: 12 days
#### EMI Amount: ₹8,500

### Step 1: Portfolio Monitoring

The system ingests loan account data, repayment history, and collection activity on a daily basis.

### Step 2: Risk Signal Detection

The borrower misses the EMI due date and shows:

- No payment within the grace period

- Multiple failed contact attempts

- No Promise-to-Pay (PTP) commitment

These signals increase the risk score of the account.

### Step 3: DPD Migration Tracking

The account moves from Current → 1–30 DPD, triggering inclusion in the early delinquency watchlist.

### Step 4: Collections Action Analysis

Collection actions (calls, visits, PTPs) are tracked to evaluate:

- Contact success

- PTP kept vs broken

- Recovery outcome

### Step 5: Performance & Escalation

If unresolved, the system flags the account as high-risk, enabling escalation or strategy change before it reaches 60+ DPD.

## Project Walkthrough
### Step 1: Data Ingestion

Operational datasets are loaded into an analytical database, including:

- Loan master data

- Repayment transactions

- Collection activity logs

- Agent and branch mappings

### Step 2: Loan Status & Delinquency Calculation

Using SQL and analytical logic:

- Current DPD is calculated per loan

- Loans are bucketed into standard delinquency ranges

- Clean vs delinquent loan classification is derived

### Step 3: DPD Migration Analysis

Historical snapshots are used to track:

- Month-over-month DPD movement

- Roll-rate percentages

- Transition probabilities between delinquency buckets

### Step 4: Collections Funnel Analysis

Collection effectiveness is measured across stages:

- Contact Attempt → Contact Success

- Contact → Promise-to-Pay (PTP)

- PTP → Actual Payment

### Step 5: KPI Computation & Visualization

Key KPIs are calculated using DAX and SQL and visualized in Power BI dashboards for different stakeholders.

## Deliverables
#### Loan Risk Analytics Platform

- Portfolio health dashboard

- DPD aging and trend analysis

- Early delinquency watchlists

#### Collections Performance Dashboard

- Agent-wise and branch-wise metrics

- PTP conversion analysis

- Recovery rate tracking

#### Analytical Data Model

- Fact and dimension tables optimized for reporting

- Time-based analysis using a date dimension

- Flexible slicing by product, geography, and agent

## Key KPIs Tracked

- Delinquent Loans Count

- Clean Loans Percentage

- Recovery Rate

- Contact Rate

- Promise-to-Pay (PTP) Conversion Rate

- Roll Rate (DPD Migration %)

- Average Days to Resolution

- Agent Productivity Metrics

## Tools & Technologies

- SQL – Data modeling and KPI logic

- Python (Pandas) – Data generation and preprocessing

- Power BI – Dashboards, DAX measures, insights

- Excel – Data validation and exploratory analysis

- GitHub – Version control and documentation

## Expected Outcomes & Benefits

- Reduced Credit Losses
Early identification prevents accounts from slipping into NPAs.

- Improved Collections Efficiency
Focused efforts on high-risk and high-impact accounts.

- Better Decision-Making
Management gains a clear, data-backed view of portfolio health.

- Operational Accountability
Transparent performance measurement at agent and branch levels.

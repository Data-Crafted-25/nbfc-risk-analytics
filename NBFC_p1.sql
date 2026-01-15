CREATE DATABASE NBFC_COLLECTIONS
USE NBFC_COLLECTIONS

--DELIVERABLE 1 : PORTFOLIO HEALTH & DELIQUENCY

--1.CURRENT DELIQUENCY DISTRIBUTION

select delinquency_bucket,count(*) as loan_count ,
case delinquency_bucket when '0-30' then 'Bucket_1'
WHEN '31-60' THEN 'Bucket_2'
when '61-90' then 'Bucket_3'
else  'NPA'
END as BUCKET_LABEL
from fact_loan_account
group by delinquency_bucket order by 
case delinquency_bucket when '0-30' then 1
WHEN '31-60' THEN 2
when '61-90' then 3
else  4
END

--2.High-Risk Outstanding Exposure

SELECT ROUND(SUM(outstanding_principal),0) AS HIGH_RISK_OUTSTANDING
FROM fact_loan_account
WHERE current_dpd =90

--3.Year-wise Loan Disbursement Trend

SELECT YEAR(DISBURSEMENT_DATE) AS DISBURSEMENT_YEAR,COUNT(*) AS LOAN_COUNT
FROM fact_loan_account GROUP BY YEAR(DISBURSEMENT_DATE)
ORDER BY DISBURSEMENT_YEAR

--4.Worst Ever DPD Per Loan

SELECT LOAN_ACCOUNT_ID ,MAX(MAX_DPD_EVER) AS MAX_DPD FROM fact_loan_account 
GROUP BY LOAN_ACCOUNT_ID

--5.Loans Never Delinquent

SELECT LOAN_ACCOUNT_ID FROM fact_loan_account WHERE current_dpd =0

---DELIVERABLE 2: Early Risk & DPD Migration

--6.Early-Warning Accounts (0–30 DPD)

WITH MISSED_EMI AS 
(
SELECT LOAN_ACCOUNT_ID,COUNT(*) AS MISSED_COUNT FROM fact_repayment 
WHERE payment_status= 'MISSED' GROUP BY loan_account_id),
BROKEN_PTP AS 
(
SELECT LOAN_ACCOUNT_ID,COUNT(*) AS BROKEN_PTP_COUNT FROM fact_ptp
WHERE ptp_status='BROKEN' GROUP BY loan_account_id)

SELECT DISTINCT F.loan_account_id 
FROM fact_loan_account AS F LEFT JOIN MISSED_EMI AS M ON F.loan_account_id=M.LOAN_ACCOUNT_ID
LEFT JOIN BROKEN_PTP AS B ON F.LOAN_ACCOUNT_ID =B.LOAN_ACCOUNT_ID
WHERE F.current_dpd BETWEEN 1 AND 30  
AND  (ISNULL(M.MISSED_COUNT,0)>1 
OR ISNULL(B.BROKEN_PTP_COUNT,0)>=1)

--7.DPD Bucket Migration Detection

WITH DPD_CHANGE AS(
SELECT loan_account_id,DPD ,
LAG(DPD)OVER(PARTITION BY loan_account_id ORDER BY SNAPSHOT_DATE) AS PREVIOUS_DPD
FROM fact_dpd_snapshot)

SELECT DISTINCT loan_account_id,DPD,PREVIOUS_DPD FROM DPD_CHANGE
WHERE PREVIOUS_DPD BETWEEN 1 AND 30 AND DPD>=60

--8.Consecutive DPD Increase

WITH DPD_SEQ AS (
SELECT *,
CASE WHEN DPD>LAG(DPD)OVER (PARTITION BY LOAN_ACCOUNT_ID ORDER BY SNAPSHOT_DATE) THEN 1 ELSE 0
END AS DPD_INCREASE  FROM fact_dpd_snapshot),
GRP AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY LOAN_ACCOUNT_ID ORDER BY SNAPSHOT_DATE)-
ROW_NUMBER() OVER (PARTITION BY LOAN_ACCOUNT_ID,DPD_INCREASE ORDER BY SNAPSHOT_DATE) AS GRP_ID
FROM DPD_SEQ
)
SELECT DISTINCT LOAN_ACCOUNT_ID FROM GRP WHERE DPD_INCREASE=1
GROUP BY loan_account_id,GRP_ID HAVING COUNT(*)>=3

--9.First Date Loan Crossed 30 DPD

SELECT LOAN_ACCOUNT_ID, CAST(MIN(SNAPSHOT_DATE) AS date) AS FIRST_TIME_DPD
FROM fact_dpd_snapshot WHERE dpd>30
GROUP BY loan_account_id

--10.Portfolio Roll Rate

WITH DPD_TRANSITIONS AS (
SELECT LOAN_ACCOUNT_ID,
LAG(DPD)OVER (PARTITION BY LOAN_ACCOUNT_ID ORDER BY SNAPSHOT_DATE) AS PREV_DPD,DPD
FROM fact_dpd_snapshot )

SELECT 
CAST (ROUND(COUNT (DISTINCT CASE WHEN PREV_DPD BETWEEN 30 AND 60 AND DPD>61 THEN LOAN_ACCOUNT_ID END)*100.0/
COUNT (DISTINCT CASE WHEN PREV_DPD BETWEEN 30 AND 60 THEN LOAN_ACCOUNT_ID END ),2)AS decimal(10,2)) AS ROLL_RATE_PERCENT
FROM DPD_TRANSITIONS

--DELIVERABLE 3: Collections Effectiveness KPIs

--11.Portfolio Recovery Rate

SELECT ROUND(SUM(recovered_amount)*100/SUM(outstanding_principal),2) AS RECOVERY_RATE
FROM fact_resolution FR INNER JOIN fact_loan_account FL 
ON FR.loan_account_id=FL.loan_account_id

--12.Recovery Rate by Product Type

SELECT product_type,ROUND(SUM(recovered_amount)*100/SUM(outstanding_principal),2) AS RECOVERY_RATE
FROM fact_loan_account AS FL INNER JOIN fact_resolution AS FR 
ON FL.loan_account_id=FR.loan_account_id 
GROUP BY product_type

--13.Contact Rate for Delinquent Loans

SELECT 
CAST(ROUND(COUNT(DISTINCT CASE WHEN FC.contact_outcome='Connected' THEN FC.LOAN_ACCOUNT_ID END)*100.0 /
COUNT(DISTINCT FL.LOAN_ACCOUNT_ID ),2) AS int) AS CONNECTED_RATE,
CAST(ROUND(COUNT(DISTINCT CASE WHEN FC.contact_outcome='No Answer' THEN FC.LOAN_ACCOUNT_ID END)*100.0/
COUNT(DISTINCT FL.LOAN_ACCOUNT_ID),2) AS INT) AS Not_CONNECTED_RATE,
CAST(ROUND(COUNT(DISTINCT CASE WHEN FC.contact_outcome='Switched Off' THEN FC.LOAN_ACCOUNT_ID END)*100.0/
COUNT(DISTINCT FL.LOAN_ACCOUNT_ID ),2) AS INT) AS SWITCH_OFF_RATE
FROM 
fact_loan_account AS FL INNER JOIN fact_collection_contact AS FC 
ON FL.loan_account_id = FC.loan_account_id
WHERE current_dpd>0

--14.PTP Adherence Rate

SELECT CAST(COUNT(CASE WHEN ptp_status='Kept' THEN 1 END)*100.0/COUNT(*) AS INT) AS PTP_ADHERENCE_RATE 
FROM fact_ptp

--15.Average Resolution Turnaround Time

SELECT AVG(resolution_tat_days) AS AVG_TAT FROM fact_resolution 

--DELIVERABLE 4: Agent, Branch & Region Performance

--16.Agent-wise Recovery Ranking

SELECT AGENT_ID,AGENT_NAME,CAST (SUM(RECOVERED_AMOUNT) AS INT) AS POS_RECOVERED FROM 
fact_resolution AS FR INNER JOIN dim_agent AS DA 
ON FR.loan_account_id = DA.LOAN_ACCOUNT_ID 
GROUP BY agent_id,agent_name

--17.Bottom 10% Performing Agents

with cte_1 as (
SELECT AGENT_ID,AGENT_NAME,CAST (SUM(RECOVERED_AMOUNT) AS INT) AS POS_RECOVERED FROM 
fact_resolution AS FR INNER JOIN dim_agent AS DA 
ON FR.loan_account_id = DA.LOAN_ACCOUNT_ID 
GROUP BY agent_id,agent_name
)
SELECT AGENT_ID,AGENT_NAME,Bucket
FROM (
SELECT AGENT_ID,AGENT_NAME,
NTILE(10)over (order by POS_RECOVERED ) as Bucket 
from cte_1 ) AS SUB
where bucket =1


--18.Agents with Low PTP Adherence
WITH CTE_1 AS (
SELECT DM.agent_id,DM.agent_name,
CAST(COUNT(CASE WHEN ptp_status='Kept' THEN 1 END)*100.0/COUNT(*) AS INT) AS PTP_ADHERENCE_RATE 
FROM fact_ptp AS FP INNER JOIN dim_agent AS DM 
ON FP.agent_id=DM.agent_id GROUP BY DM.agent_id,DM.agent_name
)
SELECT agent_id,AGENT_NAME,PTP_ADHERENCE_RATE 
FROM CTE_1 WHERE PTP_ADHERENCE_RATE<
(SELECT AVG(PTP_ADHERENCE_RATE) FROM CTE_1)

--19.Branch-wise Delinquency Rate

SELECT DB.branch_id,DB.branch_name, 
CAST(ROUND(COUNT(CASE WHEN CURRENT_DPD>1 THEN 1 END)*1.0/COUNT(*),2) AS decimal(10,2)) AS DELIQUENCY_RATE
FROM dim_agent AS DA INNER JOIN fact_loan_account AS FL 
ON DA.LOAN_ACCOUNT_ID=FL.loan_account_id
INNER JOIN dim_branch AS DB 
ON DA.branch_id=DB.branch_id
GROUP BY DB.branch_id,DB.branch_name
ORDER BY DELIQUENCY_RATE DESC

--20.Region-wise Recovery Comparison

SELECT REGION ,CAST(SUM(RECOVERED_AMOUNT) AS int) AS POS_SAVED
FROM fact_resolution AS FR INNER  JOIN dim_agent AS DA
ON FR.loan_account_id=DA.loan_account_id INNER JOIN dim_branch AS DB
ON DA.branch_id=DB.branch_id GROUP BY REGION 
ORDER BY POS_SAVED DESC

--DELIVERABLE 5: Resource Optimisation & Decision Support

--21.High-Priority Allocation List

SELECT DISTINCT FA.loan_account_id,CAST(FA.outstanding_principal AS INT)AS POS,FA.current_dpd,FA.delinquency_bucket
FROM 
fact_loan_account AS FA LEFT JOIN fact_repayment AS FP 
ON FA.loan_account_id=FP.loan_account_id LEFT JOIN 
fact_ptp AS FT ON FA.loan_account_id=FT.loan_account_id
WHERE FA.outstanding_principal>(
SELECT AVG(outstanding_principal) FROM fact_loan_account) AND 
FA.current_dpd BETWEEN 1 AND 60 AND 
(FP.payment_status='MISSED' OR FT.ptp_status='BROKEN')

--22.Low-Yield Recovery Accounts

SELECT FL.loan_account_id,CAST(FR.recovered_amount AS int) AS POS FROM 
fact_loan_account AS FL INNER JOIN fact_resolution AS FR 
ON FL.loan_account_id=FR.loan_account_id
WHERE recovered_amount<0.31*FL.outstanding_principal -- THERSOLD LEVEL SET TO 30%

--23.No-Contact High-Risk Loans

SELECT FL.loan_account_id FROM
fact_loan_account AS FL LEFT JOIN fact_collection_contact AS FC
ON FL.loan_account_id=FC.loan_account_id 
AND TRY_CONVERT(DATE, FC.contact_date)>=DATEADD(DAY,-60,GETDATE())
WHERE FL.current_dpd>30 
GROUP BY FL.loan_account_id
HAVING COUNT(FC.contact_id)=0

--24.Risk Segmentation

SELECT 
CASE 
WHEN CURRENT_DPD > 60 THEN 'HIGH RISK'
WHEN CURRENT_DPD BETWEEN 30 AND 60 THEN 'MEDIUM RISK'
ELSE 'LOW RISK' 
END AS [RISK SEGMENT],
COUNT(LOAN_ACCOUNT_ID) AS TOTAL_ACCOUNTS 
FROM 
FACT_LOAN_ACCOUNT 
GROUP BY 
CASE 
WHEN CURRENT_DPD > 60 THEN 'HIGH RISK'
WHEN CURRENT_DPD BETWEEN 30 AND 60 THEN 'MEDIUM RISK'
ELSE 'LOW RISK' 
END
ORDER BY TOTAL_ACCOUNTS DESC

--25.Daily Agent Allocation View

CREATE VIEW daily_agent_allocation AS
SELECT FL.LOAN_ACCOUNT_ID,DA.AGENT_ID,DA.AGENT_NAME ,DA.ROLE,
CASE 
WHEN CURRENT_DPD >60 THEN 'FIELD'
ELSE 'TELECALLER'
END AS CHANNEL_TYPE
FROM 
FACT_LOAN_ACCOUNT AS FL INNER JOIN DIM_AGENT AS DA
ON DA.ROLE=
CASE 
WHEN CURRENT_DPD >60 THEN 'FIELD'
ELSE 'TELECALLER'
END

select * from daily_agent_allocation
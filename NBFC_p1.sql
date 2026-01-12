CREATE DATABASE NBFC_COLLECTIONS
USE NBFC_COLLECTIONS

--DELIVERABLE 1 : PORTFOLIO HEALTH & DELIQUENCY

--CURRENT DELIQUENCY DISTRIBUTION

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

--High-Risk Outstanding Exposure

SELECT ROUND(SUM(outstanding_principal),0) AS HIGH_RISK_OUTSTANDING
FROM fact_loan_account
WHERE current_dpd =90

--Year-wise Loan Disbursement Trend

SELECT YEAR(DISBURSEMENT_DATE) AS DISBURSEMENT_YEAR,COUNT(*) AS LOAN_COUNT
FROM fact_loan_account GROUP BY YEAR(DISBURSEMENT_DATE)
ORDER BY DISBURSEMENT_YEAR

--Worst Ever DPD Per Loan

SELECT LOAN_ACCOUNT_ID ,MAX(MAX_DPD_EVER) AS MAX_DPD FROM fact_loan_account 
GROUP BY LOAN_ACCOUNT_ID

-- Loans Never Delinquent

SELECT LOAN_ACCOUNT_ID FROM fact_loan_account WHERE current_dpd =0

---DELIVERABLE 2: Early Risk & DPD Migration

--Early-Warning Accounts (0–30 DPD)

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

--DPD Bucket Migration Detection

WITH DPD_CHANGE AS(
SELECT loan_account_id,DPD ,
LAG(DPD)OVER(PARTITION BY loan_account_id ORDER BY SNAPSHOT_DATE) AS PREVIOUS_DPD
FROM fact_dpd_snapshot)

SELECT DISTINCT loan_account_id,DPD,PREVIOUS_DPD FROM DPD_CHANGE
WHERE PREVIOUS_DPD BETWEEN 1 AND 30 AND DPD>=60


SELECT *
FROM RFM_sale_data

-- Check distinct value in the data
SELECT DISTINCT(status) FROM dbo.RFM_sale_data
SELECT DISTINCT(YEAR_ID) FROM dbo.RFM_sale_data
SELECT DISTINCT(PRODUCTLINE) FROM dbo.RFM_sale_data
SELECT DISTINCT(COUNTRY) FROM dbo.RFM_sale_data
SELECT DISTINCT(DEALSIZE) FROM dbo.RFM_sale_data
SELECT DISTINCT(TERRITORY) FROM dbo.RFM_sale_data


-- Explore Data Analysis
-- Question 1: Sales by productline
SELECT productline, ROUND(SUM(Sales),2) as Revenue
FROM dbo.RFM_sale_data
GROUP BY PRODUCTLINE
ORDER BY Revenue DESC


SELECT YEAR_ID, ROUND(SUM(Sales),2) as Revenue
FROM dbo.RFM_sale_data
GROUP BY YEAR_ID
ORDER BY Revenue DESC


SELECT DEALSIZE, ROUND(SUM(Sales),2) as Revenue
FROM dbo.RFM_sale_data
GROUP BY DEALSIZE
ORDER BY Revenue DESC


-- Question 2: What was the best month for sales in 2003? How much was the revenue?
SELECT  MONTH_ID, ROUND(SUM(Sales),2) as Revenue, COUNT(ORDERNUMBER) as Quantity
FROM dbo.RFM_sale_data
WHERE YEAR_ID = 2003 
GROUP BY MONTH_ID
ORDER BY Revenue DESC


--Question 3: What products they sold in the best month of 2003?
SELECT  MONTH_ID, PRODUCTLINE,ROUND(SUM(Sales),2) as Revenue, COUNT(ORDERNUMBER) as Quantity
FROM dbo.RFM_sale_data
WHERE YEAR_ID = 2003 and MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY Revenue DESC


--Question 4: Who were the best customer of company?


DROP TABLE IF EXISTS #rfm
;WITH RFM as
(
	SELECT
		CUSTOMERNAME,
		SUM(SALES) as Revenue,
		COUNT(ORDERNUMBER) as Frequency,
		MAX(ORDERDATE) as Latest_Date,
		(SELECT MAX(ORDERDATE) FROM dbo.RFM_sale_data) as Max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM dbo.RFM_sale_data)) Recency
	FROM dbo.RFM_sale_data
	GROUP BY CUSTOMERNAME
),
rfm_cal as
(
	SELECT r.*,
		NTILE(4) OVER( ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER( ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER( ORDER BY Revenue) rfm_monetary
	FROM RFM r
)

SELECT c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CAST( rfm_recency as varchar) + CAST( rfm_frequency as varchar) + CAST( rfm_monetary as varchar) as rfm_cell_str
INTO #rfm
FROM rfm_cal c


SELECT CUSTOMERNAME, rfm_recency , rfm_frequency , rfm_monetary, rfm_cell_str,
	CASE 
		WHEN rfm_cell_str in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost' 
		WHEN rfm_cell_str in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping' 
		WHEN rfm_cell_str in (311, 411, 331) THEN 'new'
		WHEN rfm_cell_str in (222, 223, 233, 322) THEN 'potential'
		WHEN rfm_cell_str in (323, 333,321, 422, 332, 432) THEN 'active' 
		WHEN rfm_cell_str in (433, 434, 443, 444) THEN 'loyal'
	END rfm_segment

FROM #rfm

-- What product often sold together? 
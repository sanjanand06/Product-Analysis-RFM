--Importing data--
SELECT TOP (1000) [ORDERNUMBER]
      ,[QUANTITYORDERED]
      ,[PRICEEACH]
      ,[ORDERLINENUMBER]
      ,[SALES]
      ,[ORDERDATE]
      ,[STATUS]
      ,[QTR_ID]
      ,[MONTH_ID]
      ,[YEAR_ID]
      ,[PRODUCTLINE]
      ,[MSRP]
      ,[PRODUCTCODE]
      ,[CUSTOMERNAME]
      ,[PHONE]
      ,[ADDRESSLINE1]
      ,[ADDRESSLINE2]
      ,[CITY]
      ,[STATE]
      ,[POSTALCODE]
      ,[COUNTRY]
      ,[TERRITORY]
      ,[CONTACTLASTNAME]
      ,[CONTACTFIRSTNAME]
      ,[DEALSIZE]
  FROM [PortfolioDB].[dbo].[sales_data_sample]

--Checking unique values--
SELECT DISTINCT STATUS FROM [PortfolioDB].[dbo].[sales_data_sample]
SELECT DISTINCT YEAR_ID FROM [PortfolioDB].[dbo].[sales_data_sample]
SELECT DISTINCT PRODUCTLINE FROM [PortfolioDB].[dbo].[sales_data_sample]
SELECT DISTINCT COUNTRY FROM [PortfolioDB].[dbo].[sales_data_sample]
SELECT DISTINCT DEALSIZE FROM [PortfolioDB].[dbo].[sales_data_sample]
SELECT DISTINCT TERRITORY FROM [PortfolioDB].[dbo].[sales_data_sample]

--Sales by product line--
SELECT PRODUCTLINE, ROUND(SUM(Sales),2) as Revenue
FROM [PortfolioDB].[dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY Revenue DESC

--Sales by year--
SELECT YEAR_ID, ROUND(SUM(Sales),2) as Revenue_year
FROM [PortfolioDB].[dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY Revenue_year DESC

--Sales by dealsize--
SELECT DEALSIZE, ROUND(SUM(Sales),2) AS Revenue_deal
FROM [PortfolioDB].[dbo].[sales_data_sample]
GROUP BY DEALSIZE 
ORDER BY Revenue_deal DESC

--What is the best month for sales in a specific year based on number of orders too?--
SELECT MONTH_ID,
CASE
WHEN MONTH_ID = 1 THEN 'Jan'
WHEN MONTH_ID = 2 THEN 'Feb'
WHEN MONTH_ID = 3 THEN 'Mar'
WHEN MONTH_ID = 4 THEN 'Apr'
WHEN MONTH_ID = 5 THEN 'May'
WHEN MONTH_ID = 6 THEN 'Jun'
WHEN MONTH_ID = 7 THEN 'Jul'
WHEN MONTH_ID = 8 THEN 'Aug'
WHEN MONTH_ID = 9 THEN 'Sept'
WHEN MONTH_ID = 10 THEN 'Oct'
WHEN MONTH_ID = 11 THEN 'Nov'
WHEN MONTH_ID = 12 THEN 'Dec'
END AS "Month",
ROUND(SUM(Sales),2) AS Revenue_month, COUNT(OrderNumber) as Num_of_orders
FROM [PortfolioDB].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2005 --change year--
GROUP BY MONTH_ID
ORDER BY 3 DESC

--We see that in 2003 and 2004, November had best sales--


--Which product in the month November is sold more?---
SELECT MONTH_ID, PRODUCTLINE, SUM(Sales) AS Revenue, COUNT(*) as num_orders
FROM [PortfolioDB].[dbo].[sales_data_sample]
WHERE YEAR_ID=2003 and MONTH_ID=11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY Revenue DESC


--Turns out classic cars are most sold product in the month of November--

--Who is the best customer? Using RFM analysis--
DROP TABLE IF EXISTS #RFM
;WITH RFM AS(
	SELECT CUSTOMERNAME, 
		SUM(SALES) AS MonetaryValue,
		AVG(SALES) AS AvgMonetaryValue,
		COUNT(SALES) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM [PortfolioDB].[dbo].[sales_data_sample]) AS max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [PortfolioDB].[dbo].[sales_data_sample])) AS Recency

	FROM [PortfolioDB].[dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
),
RFM_CALC AS(
SELECT r.*,
	NTILE(4) OVER(ORDER BY Recency DESC) rfm_recency,
	NTILE(4) OVER(ORDER BY Frequency DESC) rfm_frequency,
	NTILE(4) OVER(ORDER BY MonetaryValue DESC) rfm_monetary
FROM RFM r
)
SELECT 
c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary as varchar) as rfm_cell_string
into #RFM
from RFM_CALC AS c

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
	WHEN rfm_cell_string in (111,112,121,122, 123,132,211,212,114, 141) THEN 'lost customers'
	WHEN rfm_cell_string in (133, 134,143, 244,334,343, 344) THEN 'slipping away, cannot lose'
	WHEN rfm_cell_string in (311,411,331) THEN 'new customers'
	WHEN rfm_cell_string in (222,223,233,322) THEN 'potential churners'
	WHEN rfm_cell_string in (323,333,321,422,332, 432) THEN 'active'
	WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
	END AS rfm_segment
FROM #RFM







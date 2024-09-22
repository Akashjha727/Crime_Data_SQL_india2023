SELECT TOP (1000) [Report_Number]
      ,[Date_Reported]
      ,[Date_of_Occurrence]
      ,[Time_of_Occurrence]
      ,[City]
      ,[Crime_Code]
      ,[Crime_Description]
      ,[Victim_Age]
      ,[Victim_Gender]
      ,[Weapon_Used]
      ,[Crime_Domain]
      ,[Police_Deployed]
      ,[Case_Closed]
      ,[Date_Case_Closed]
  FROM [Crime_India_2023].[dbo].[crime]


--- BASIC INFORMATION ABOUT DATA.

--- Total Crimes by City

SELECT City,COUNT(*) AS Total_Crime_Reported
FROM crime
GROUP BY City
ORDER BY 2 DESC;

--- Crimes by Type (Crime Description) across Cities

SELECT Crime_Description,COUNT(*) AS Total
FROM crime
GROUP BY Crime_Description
ORDER BY 2 DESC;

---- Crime Distribution by Gender

SELECT Victim_Gender,COUNT(*) AS Total_Victim
FROM crime
GROUP BY Victim_Gender
ORDER BY 2 DESC;

---- Top 5 Cities with Most Violent Crimes

SELECT TOP 5 City,COUNT(*) AS Violent_Crime
FROM crime
WHERE Crime_Domain = 'Violent Crime'
GROUP BY City
ORDER BY 2 DESC;

--Crimes Involving Weapons

SELECT Weapon_Used,count(*) as Weapon_Cnt
FROM crime
WHERE Weapon_Used <> 'None'
GROUP BY Weapon_Used
ORDER BY 2 DESC;

--- Average Age of Victims by Crime Type

SELECT Crime_Description,AVG(Victim_Age) as Avg_Victim_Age 
FROM crime
GROUP BY Crime_Description
ORDER BY 2 DESC;

--Crimes Involving Police Deployment Over 10 Officers

SELECT City,Crime_Description,Count(*) as Heavy_Deployment
FROM crime
WHERE Police_Deployed > 10
GROUP BY City,Crime_Description
ORDER BY City , 3 DESC;


--Monthly year-wise Crime Trends

SELECT MONTH(Date_Reported) as mnth,YEAR(Date_Reported) as Yr ,COUNT(*) as crime 
FROM crime
GROUP BY YEAR(Date_Reported),MONTH(Date_Reported)
ORDER BY mnth,Yr;

-- Year-over-Year Crime Growth Rate

SELECT YEAR(Date_Reported) as Yr, COUNT(*) as Total_Crime,
	   LAG(COUNT(*),1) OVER (ORDER BY YEAR(Date_Reported)) AS Prev_Year_Crime,
	   CAST (100.00 * (COUNT(*) - LAG(COUNT(*),1) OVER (ORDER BY YEAR(Date_Reported)))/
	   (LAG(COUNT(*),1) OVER (ORDER BY YEAR(Date_Reported))) as decimal(10,2)) as Yr_Variance
FROM crime
GROUP BY YEAR(Date_Reported)
ORDER BY Yr

--- Top 3 Crime Types in Each City by Year
with cte as (
SELECT City,YEAR(Date_Reported) as Yr,Crime_Description,
	   COUNT(*) as Total_Crime,
	   DENSE_RANK() OVER (PARTITION BY City,YEAR(Date_Reported) ORDER BY COUNT(*) DESC) as rnk
FROM Crime
GROUP BY City,YEAR(Date_Reported),Crime_Description)
SELECT * FROM cte
WHERE rnk <=3;


--Crimes by Time of Day (Hourly Analysis)

SELECT DATEPART(HOUR,Time_of_Occurrence) Hr_of_Day, COUNT(*) AS Crime_Count,
       Concat (CAST ((100.0 * COUNT(*)) / (SELECT Count(*) FROM crime) as decimal (10,2)),' %') as ratio_of_crime
FROM crime
GROUP BY DATEPART(HOUR,Time_of_Occurrence)
ORDER BY DATEPART(HOUR,Time_of_Occurrence);

---Crimes by Victim Age Group Over Time
with cte as (
SELECT YEAR(Date_Reported) as Yr,
       CASE WHEN Victim_Age BETWEEN 0 AND 18 THEN '0-18'
	        WHEN Victim_Age BETWEEN 19 AND 35 THEN '19-35'
			WHEN Victim_Age BETWEEN 36 AND 60 THEN '36-60'
			ELSE '60+'
			END as Age_Group
FROM crime) 
SELECT Yr,Age_Group,COUNT(*) as total_Crime_Against
FROM cte
GROUP BY Yr, Age_Group
ORDER BY Yr, Age_Group;

---Cumulative Crime Count Over Time

SELECT MONTH(Date_Reported) As Date,COUNT(*) as Total_Crime,
       SUM(Count(*)) OVER (ORDER BY MONTH(Date_Reported)) as cumulative_total_crime
FROM crime
GROUP BY MONTH(Date_Reported);

---Police Deployment Impact: Crimes Solved by More Officers
ALTER TABLE crime
ALTER COLUMN Case_Closed integer;

SELECT Police_Deployed,COUNT(*) as Total_Crime,
       SUM (CAST (Case_Closed AS integer)) as Closed_Case,
	   CONCAT (CAST((100.0 * SUM (CAST (Case_Closed AS integer))) / (COUNT(*)) as decimal (10,2)), ' %') AS Solved_Ratio
FROM crime
WHERE Police_Deployed > 5
GROUP BY Police_Deployed
ORDER BY Police_Deployed DESC;

---TOP 5 SOlVED CRIME RATIO IN EVERY CITY..

With SOLVED_CRIME as
(SELECT CITY,Crime_Description,COUNT(*) as Total_crime,
      SUM(Case_Closed) as Closed_Case,
	  CAST ((100.0 * SUM(Case_Closed)) / (COUNT(*)) as decimal (10,2)) AS Solved_Ratio
FROM crime
GROUP BY CITY,Crime_Description),
Ranked as (
SELECT *,DENSE_RANK() OVER (PARTITION BY CITY ORDER BY Solved_Ratio DESC) as rnk
FROM SOLVED_CRIME)
SELECT CITY,Crime_Description,Total_crime,Closed_Case,Solved_Ratio
FROM Ranked
WHERE rnk <=5 ;

---Crimes by City and Gender Over Time

SELECT City,Victim_Gender,YEAR(Date_Reported) as Yr,COUNT(*) as Total_Crime
FROM Crime
GROUP BY City,Victim_Gender,YEAR(Date_Reported)
ORDER BY YEAR(Date_Reported),Total_Crime DESC;

---Crime Clearance Time (From Report to Case Closure)

SELECT City,AVG(DATEDIFF(day,Date_Reported,Date_Case_Closed)) as Avg_Days_to_Close_Case
FROM crime
WHERE Case_Closed = 1 AND Date_Case_Closed is not null
GROUP BY City
ORDER BY Avg_Days_to_Close_Case DESC;

---Crimes by Victim Gender with Annual Growth

SELECT Victim_Gender,YEAR(Date_Reported) as Yr,
	   Count(*) As Crime_Count,
	   LAG(COUNT(*),1) OVER (PARTITION BY Victim_Gender ORDER BY YEAR(Date_Reported)) As Previous_Year,
	   CAST (100.0 * (COUNT(*) - LAG(COUNT(*),1) OVER (PARTITION BY Victim_Gender ORDER BY YEAR(Date_Reported))) / 
	   (LAG(COUNT(*),1) OVER (PARTITION BY Victim_Gender ORDER BY YEAR(Date_Reported))) as decimal(10,2)) As Growth_Percentage
FROM crime
GROUP BY Victim_Gender,YEAR(Date_Reported);

--Weapon Used Over Time

SELECT YEAR(Date_Reported) as Yr , Weapon_Used,COUNT(*) as Weapon_Crime_Count
FROM crime
WHERE Weapon_Used <> 'None'
GROUP BY YEAR(Date_Reported) , Weapon_Used
ORDER BY YEAR(Date_Reported);

-- Average Crime Count in First Half vs. Second Half of the Year

SELECT 
	  CASE WHEN MONTH(Date_Reported) <=6 THEN 'FIRST_HALF_YEAR' ELSE 'SECOND_HALF_YEAR' END AS HALF_OF_YEAR,
	  AVG(COUNT(*)) OVER (PARTITION BY CASE WHEN MONTH(Date_Reported) <=6 THEN 'FIRST_HALF_YEAR' ELSE 'SECOND_HALF_YEAR' END) AS AVG_HALF_YEAR_CNT
FROM crime
GROUP BY CASE WHEN MONTH(Date_Reported) <=6 THEN 'FIRST_HALF_YEAR' ELSE 'SECOND_HALF_YEAR' END;

---Crimes Reported Near Midnight (10 PM to 2 AM)

SELECT DATEPART(hour,Time_of_Occurrence) as Mid_Night_time,COUNT(*) as Night_Crime_Cnt
FROM crime
WHERE DATEPART(hour,Time_of_Occurrence) IN (22,23,24,0,1,2)
GROUP BY DATEPART(hour,Time_of_Occurrence)
;











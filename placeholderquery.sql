-- Create custom date ranges for quarterly analysis
Select location, 
       DatePart(quarter, dateConverted) as Quarter,
       Year(dateConverted) as Year,
       Sum(total_cases) as TotalCases
From SQL.dbo.CovidDeaths
Group by location, Year(dateConverted), DatePart(quarter, dateConverted);

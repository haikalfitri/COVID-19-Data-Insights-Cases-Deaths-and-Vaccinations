Overview
Select *
From SQL.dbo.CovidDeaths
Where continent is not null

Select *
From SQL.dbo.CovidVaccinations
Where continent is not null

Select Count(*)AS records 
From  SQL.dbo.CovidDeaths;

Select Count(*) AS records
From SQL.dbo.CovidVaccinations

--Clean date and replace format for Covid Death tables 
Select *
From SQL.dbo.CovidDeaths

ALTER TABLE SQL.dbo.CovidDeaths
Add  dateConverted  Date;

Update SQL.dbo.CovidDeaths
SET dateConverted  = CONVERT(Date,[date])

Select dateConverted
From SQL.dbo.CovidDeaths

ALTER TABLE SQL.dbo.CovidDeaths
DROP COLUMN date;

--Clean date and replace format  for  Covid Vac tables 
Select *
From SQL.dbo.CovidVaccinations

ALTER TABLE SQL.dbo.CovidVaccinations
Add  dateConverted  Date;

Update SQL.dbo.CovidVaccinations
SET dateConverted  = CONVERT(Date,[date])

Select dateConverted
From SQL.dbo.CovidVaccinations

ALTER TABLE SQL.dbo.CovidVaccinations
DROP COLUMN date;

--New Cases vs New Deaths by Monthly and Yearly Comparison
Select CurrentTable.year, CurrentTable.Month,
	   CurrentTable.total_cases - Coalesce (PrevTable.total_cases, 0) as NewCasesReported,
	   CurrentTable.total_deaths - Coalesce (PrevTable.total_deaths, 0) as NewDeathsReported
From (
	/*Subquery 1*/
	Select year (dateConverted) as year,
		   month (dateConverted) as month,
		   Sum (cast (total_cases as bigint)) as total_cases,
		   Sum (cast(total_deaths as bigint)) as total_deaths
	From SQL.dbo.CovidDeaths
	Where continent is not null
	Group by year (dateConverted), month (dateConverted)
	) CurrentTable

	/*Subquery 2*/
	Left Join (
	Select year (dateConverted) as Year,
		   month (dateConverted) as Month,
		   Sum (cast (total_cases as bigint)) as total_cases,
		   Sum (cast(total_deaths as bigint)) as total_deaths
	From SQL.dbo.CovidDeaths
	Where continent is not null
	Group by year (dateConverted), month (dateConverted)
	) PrevTable

	On CurrentTable.year = PrevTable.year
	And CurrentTable.month = PrevTable.month + 1

	Order by CurrentTable.year, CurrentTable.month;

--(CTE) New Cases vs New Deaths by Monthly and Yearly Comparison
	With PrevMonthTable as (
		Select 
			Year (dateConverted) as year,
			Month (dateConverted) as month,
			Sum (cast(total_cases as bigint)) as total_cases,
			Sum (cast(total_deaths as bigint)) as total_deaths
		From SQL.dbo.CovidDeaths
		Where continent IS NOT NULL
		Group by year(dateConverted), month(dateConverted)
		)
	Select CurrentTable.year, CurrentTable.month, CurrentTable.total_cases, CurrentTable.total_deaths,
		   (CurrentTable.total_cases - Coalesce (prev.total_cases, 0)) as New_Cases_Reported,
		   (CurrentTable.total_deaths - Coalesce (prev.total_deaths,0)) as New_Deaths_Reported
	From PrevMonthTable as CurrentTable 
	Left join
		PrevMonthTable AS Prev
	ON 
		CurrentTable.year = Prev.year and CurrentTable.month = Prev.month + 1
		or (CurrentTable.year = Prev.year + 1 and CurrentTable.month = 1 and Prev.month = 12)
	Order by
		CurrentTable.year, CurrentTable.month;

--Total Cases vs Total Deaths with Mortality Rate by each Continents
Select continent,
       Sum(cast(new_cases as bigint)) as total_cases,
       Sum(cast(new_deaths as bigint)) as total_deaths,
       Round ((cast(Sum(cast(total_deaths as bigint)) as float) / cast(Sum(cast(total_cases as bigint)) as float)) * 100,2) AS MortalityRate
From SQL.dbo.CovidDeaths
Where continent IS NOT NULL
Group by continent
Order by continent;

--Total Cases vs Total Deaths with Mortality Rate by each Location
Select location,
       Sum(cast(new_cases as bigint)) as total_cases,
       Sum(cast(new_deaths as bigint)) as total_deaths,
       Round((cast(Sum(cast(total_deaths as bigint)) as float) / cast(Sum(cast(total_cases as bigint)) as float)) * 100,2) AS MortalityRate	
From SQL.dbo.CovidDeaths
Where continent IS NOT NULL
Group by location
Order by location;

--Continents with Highest Infection Rate based on Population
Select continent,
	   Max (total_cases) as HighestInfectionRate, 
	   Round (Max ((total_cases/population) *100),2) as PopulationInfectedPercentage
From SQL.dbo.CovidDeaths
Where continent is not null
Group by continent 
order by PopulationInfectedPercentage desc;

--Countries with Highest Infection Rate based on Population
Select location, population, 
	   Max (total_cases) as HighestInfectionRate, 
	   Round (Max ((total_cases/population) *100),2) as PopulationInfectedPercentage
From SQL.dbo.CovidDeaths
Where continent is not null
Group by location, population 
order by PopulationInfectedPercentage desc;

--Continents with Highest Death Count
Select continent, 
	   Sum (cast(new_deaths as int)) as DeathsCount
From SQL.dbo.CovidDeaths
Where continent is not null
Group by continent
Order by DeathsCount desc

--Countries with Highest Death Count
Select location,
	   Max (cast(total_deaths as int)) as DeathsCount
From SQL.dbo.CovidDeaths
Where continent is not null
Group by location
Order by DeathsCount desc

--Global Cases and Deaths
Select Sum (new_cases) as total_cases, 
	   Sum (cast (new_deaths as int)) as total_deaths, 
	   Round (Sum (cast (new_deaths as int)) /Sum (new_cases)*100,2) as DeathPercentage
From SQL.dbo.CovidDeaths
Where continent is not null

-- Total People Vaccinated
Create View TotalPeopleVaccinatedView as 
Select cd.continent,cd.location, cd.dateConverted, cd.population, cvac.new_vaccinations, Sum(cast(cvac.new_vaccinations as int)) 
OVER (Partition by cd.location Order by cd.location, cd.dateConverted) as TotalPeopleVaccinated
From SQL.dbo.CovidDeaths cd
Join SQL.dbo.CovidVaccinations cvac
	on cd.location = cvac.location
	and cd.dateConverted = cvac.dateConverted
Where cd.continent is not null

/*Showing view
SELECT * from dbo.TotalPeopleVaccinatedView;
*/

DROP VIEW IF EXISTS dbo.TotalPeopleVaccinatedView;


--Total People Vaccinated by each Countries
Select location, Max(TotalPeopleVaccinated) as TotalVaccinated
From dbo.TotalPeopleVaccinatedView
Where continent is not null
Group by location
Order by location


/* 
Select cd.continent,cd.location, cd.dateConverted, cd.population, cvac.new_vaccinations, Sum(cast(cvac.new_vaccinations as int)) 
Over (Partition by cd.location Order by cd.location, cd.dateConverted) as TotalPeopleVaccinated
From SQL.dbo.CovidDeaths cd
Join SQL.dbo.CovidVaccinations cvac
	on cd.location = cvac.location
	and cd.dateConverted = cvac.dateConverted
Where cd.continent is not null;
*/

--Percentage People Vaccinated by each Countries
Select location, population,
	   Max (TotalPeopleVaccinated) as TotalVaccinated,
	   Round (( Max (TotalPeopleVaccinated) * 100.00) / population,2) as VaccinationPercentage
From dbo.TotalPeopleVaccinatedView
Where continent is not null
Group by location, population
Order by location;


--Using CTE, Percentage People Vaccinated for each date
With CteVac (continent, location, dateConverted, population, new_vaccination, TotalPeopleVaccinated)
as (

Select cd.continent, cd.location, cd.dateConverted, cd.population, cvac.new_vaccinations, 
       Sum(cast(cvac.new_vaccinations as int)) 

OVER(Partition by cd.location 
	   Order by cd.location, cd.dateConverted) as TotalPeopleVaccinated

From SQL.dbo.CovidDeaths cd

Join SQL.dbo.CovidVaccinations cvac
	 on cd.location = cvac.location
	 and cd.dateConverted = cvac.dateConverted

Where cd.continent is not null
)

Select *, Round ((TotalPeopleVaccinated/population)*100,2) as PercentagePeopleVac
From CTEVac

-- Using Temp Table to perform Calculation on Partition By in previous query
--Drop Table if exists #PopulationVaccinatedPercentage
Create Table #PopulationVaccinatedPercentage (
	continent nvarchar(255),
	location nvarchar(255),
	dateConverted date,
	population numeric,
	new_vaccination numeric,
	TotalPeopleVaccinated numeric
)

Insert into #PopulationVaccinatedPercentage

Select cd.continent,cd.location, cd.dateConverted, cd.population, cvac.new_vaccinations, 
	   Sum(cast(cvac.new_vaccinations as int)) 

OVER (Partition by cd.location Order by cd.location, cd.dateConverted) as TotalPeopleVaccinated

From SQL.dbo.CovidDeaths cd

Join SQL.dbo.CovidVaccinations cvac
	on cd.location = cvac.location
	and cd.dateConverted = cvac.dateConverted
Where cd.continent is not null

Select *, (TotalPeopleVaccinated/population)*100 as PercentagePeopleVac
From #PopulationVaccinatedPercentage

-- Compare total cases and total vaccinations by location (country)
Select cd.location, 
       Max(cast(cd.total_cases as bigint)) as total_cases, 
       Max(cast(cvac.total_vaccinations as bigint)) as total_vaccinations
From SQL.dbo.CovidDeaths cd

Join SQL.dbo.CovidVaccinations cvac 
On cd.location = cvac.location

Where cd.location not in ('World', 'Asia', 'Africa', 'Oceania', 'North America', 'South America', 'Europe') 
Group by cd.location
Order by total_cases desc;



--1. New Cases vs New Deaths by Monthly and Yearly Comparison

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

--2. Total Cases vs Total Deaths with Mortality Rate by each Continents
Select continent,
       Sum(cast(new_cases as bigint)) as total_cases,
       Sum(cast(new_deaths as bigint)) as total_deaths,
       Round ((cast(Sum(cast(total_deaths as bigint)) as float) / cast(Sum(cast(total_cases as bigint)) as float)) * 100,2) AS MortalityRate
From SQL.dbo.CovidDeaths
Where continent IS NOT NULL
Group by continent
Order by continent;

--3. Total Cases vs Total Deaths with Mortality Rate by each Location
Select location,
       Sum(cast(new_cases as bigint)) as total_cases,
       Sum(cast(new_deaths as bigint)) as total_deaths,
       Round((cast(Sum(cast(total_deaths as bigint)) as float) / cast(Sum(cast(total_cases as bigint)) as float)) * 100,2) AS MortalityRate	
From SQL.dbo.CovidDeaths
Where continent IS NOT NULL
Group by location
Order by location;

--4. Continents with Highest Infection Rate based on Population
Select continent,
	   Max (total_cases) as HighestInfectionRate, 
	   Round (Max ((total_cases/population) *100),2) as PopulationInfectedPercentage
From SQL.dbo.CovidDeaths
Where continent is not null
Group by continent 
order by PopulationInfectedPercentage desc;

--5. Countries with Highest Infection Rate based on Population
Select location, population, 
	   Max (total_cases) as HighestInfectionRate, 
	   Round (Max ((total_cases/population) *100),2) as PopulationInfectedPercentage
From SQL.dbo.CovidDeaths
Where continent is not null
Group by location, population 
order by PopulationInfectedPercentage desc;

--6. Continents with Highest Death Count
Select continent, 
	   Sum (cast(new_deaths as int)) as DeathsCount
From SQL.dbo.CovidDeaths
Where continent is not null
Group by continent
Order by DeathsCount desc

--7. Countries with Highest Death Count
Select location,
	   Max (cast(total_deaths as int)) as DeathsCount
From SQL.dbo.CovidDeaths
Where continent is not null
Group by location
Order by DeathsCount desc

--8. Global Cases and Deaths
Select Sum (new_cases) as total_cases, 
	   Sum (cast (new_deaths as int)) as total_deaths, 
	   Round (Sum (cast (new_deaths as int)) /Sum (new_cases)*100,2) as DeathPercentage
From SQL.dbo.CovidDeaths
Where continent is not null

--9. Total People Vaccinated
Create View TotalPeopleVaccinatedView as 
Select cd.continent,cd.location, cd.dateConverted, cd.population, cvac.new_vaccinations, Sum(cast(cvac.new_vaccinations as int)) 
OVER (Partition by cd.location Order by cd.location, cd.dateConverted) as TotalPeopleVaccinated
From SQL.dbo.CovidDeaths cd
Join SQL.dbo.CovidVaccinations cvac
	on cd.location = cvac.location
	and cd.dateConverted = cvac.dateConverted
Where cd.continent is not null

SELECT * from dbo.TotalPeopleVaccinatedView;




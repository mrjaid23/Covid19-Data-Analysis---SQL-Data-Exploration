/*
Covid 19 Data Exploration 

Skills used: CASE Statements, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- RENAMING TABLES
EXEC sp_rename '[dbo].[CovidDeaths$]', 'CovidDeaths';
EXEC sp_rename '[dbo].[CovidVaccinations$]', 'CovidVaccinations'

--EXPLORING DATA FROM EACH TABLE
SELECT * 
FROM CovidDeaths

SELECT *
FROM CovidVaccinations

-- SELECTING REQUIRED DATA FROM dbo.CovidDeaths FOR EXPLORATION

SELECT Continent, Location, Date, Total_cases, New_cases, Total_deaths, Population
FROM CovidDeaths
ORDER BY 1,2,3;

-- FILTERING OFF CONTINENTS WITH NULL VALUES

SELECT Continent, Location, Date, Total_cases, New_cases, Total_deaths, Population
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2,3;

-- LIKELIHOOD OF DIEING DUE TO COVID (Total_case Vs Total_deaths) as DeathRateduetoCovid

SELECT Continent, Location, Date, Total_cases, Total_deaths, (Total_deaths/Total_cases)*100 AS PercentageDeathRateDuetoCovid
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2,3;

SELECT continent, Location, date, total_cases, total_deaths, 
CASE 
     WHEN total_cases = 0 THEN 0 
     ELSE (total_deaths / total_cases) * 100 END AS PercentageDeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2,3;

-- EXPLORING DATA FOR SPECIFIC REGION e.g; United Kingdom

SELECT continent, Location, date, total_cases, total_deaths, 
CASE 
     WHEN total_cases = 0 THEN 0 
     ELSE (total_deaths / total_cases) * 100 END AS PercentageDeathRate
FROM CovidDeaths
WHERE continent IS NOT NULL AND Location like '%kingdom%' 
ORDER BY 1,2,3;

-- PREVALENCE RATE of COVID per Day - Total Cases vs Population 

SELECT continent, Location, date, total_cases, population, (total_cases/population)*100 AS PrevalenceRate
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2,3;

--The United Kingdom's PREVALENCE RATE of COVID per Day 

SELECT continent, Location, date, total_cases, population, (total_cases/population)*100 AS PrevalenceRate
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL AND Location like '%Kingdom'
ORDER BY 1,2,3;

-- COUNTRIES WITH HIGHEST INFECTION RATE PER POPULATION

SELECT continent, Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationINfected
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent, Location, Population
ORDER BY 4 DESC;

-- COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION

SELECT continent, Location, MAX(cast(total_deaths as bigint)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent, Location
ORDER BY 3 DESC;

-- DEATH RATE BY CONTINENT

SELECT continent, MAX(cast(total_deaths as bigint)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

--GLOBAL NUMBERS PER DAY

SELECT Date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0 
	ELSE SUM(cast(new_deaths as int))/ SUM(new_cases)*100
	END AS PercentageDeathRate
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY Date;


-- EXPLORE VACCINATION TABLE

SELECT *
FROM [dbo].[CovidVaccinations]

-- JOIN BOTH TABLES

SELECT *
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- Looking at Total Population vs Vaccination / day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Vaccination Overview of The UK

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location like '%Kingdom%'
ORDER BY 2,3;

-- PARTITIONING VACCINATION COUNT BY LOCATION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS TotalVaccinationCount
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS TotalVaccinationCount
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopVac (continent, location, date, Population, new_vaccinations, TotalVaccinationCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS TotalVaccinationCount
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date
--GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
)
SELECT *, (TotalVaccinationCount/population)*100 AS PercentageVacRatePerPop
FROM PopVac

-- CREATING TABLE & INSERTING DATA

DROP TABLE IF EXISTS PercentageVacRatePerPop
CREATE TABLE PercentageVacRatePerPop
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
TotalVaccinationCount numeric
)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS TotalVaccinationCount
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date
--GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
SELECT *, (TotalVaccinationCount/population)*100 AS PercentageVacRatePerPop
FROM PopVac

-- CREATING A VIEW TABLE TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentageVacRatePerPop_2 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CummulatedVaccinations
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

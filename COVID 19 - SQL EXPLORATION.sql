SELECT *
FROM [dbo].[CovidDeaths$]

SELECT *
FROM [dbo].[CovidVaccinations$]

-- RENAMING THE TABLES

EXEC sp_rename '[dbo].[CovidDeaths$]', 'CovidDeaths';

EXEC sp_rename '[dbo].[CovidVaccinations$]', 'CovidVaccinations';


SELECT *
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- DATA EXPLORATION

-- SELECTING THE REQUIERED DATA

SELECT continent, Location, date, total_cases, new_cases, total_deaths, population
FROM [dbo].[CovidDeaths]
ORDER BY 1,2,3;

-- Total Cases vs. Total Deaths

SELECT continent, Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentageDeathRate
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1,2,3;

-- CHECKING FOR SPECIFIC REGION e.g; United Kingdom

SELECT continent, Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS PercentageDeathRate
FROM [dbo].[CovidDeaths]
WHERE Location like '%kingdom%' AND continent IS NOT NULL
ORDER BY 1,2,3;

-- Total Cases vs Population (United Kingdom)
-- PREVALENCE RATE COVID
SELECT continent, Location, date, total_cases, population, (total_cases/population)*100 AS CaseRate
FROM [dbo].[CovidDeaths]
WHERE Location like '%kingdom%'AND continent IS NOT NULL
ORDER BY 1,2,3;

-- COUNTRIES WITH HIGHEST INFECTION RATE PER POPULATION
SELECT continent, Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationINfected
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent, Location, Population
ORDER BY 4 DESC;

-- SHOWING THE COUNTRIES WITH THE HIGHEST DEATH COUNT PER POPULATION
SELECT continent, Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent, Location
ORDER BY 3 DESC;

-- DEATH RATE BY CONTINENT

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

-- CONTINENT WITH THE HIGHEST DEATH COUNT
SELECT continent, MAX(cast(total_deaths as int)) AS CONTotalDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;


--GLOBAL NUMBERS PER DAY
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS PercentageDeathRate
FROM [dbo].[CovidDeaths]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;


--SELECT *
--FROM [dbo].[CovidVaccinations]


-- JOIN BOTH TABLES
SELECT *
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date


-- Looking at Total Population vs Vaccination

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

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS TotalVaccinationCount
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- VACCINATION RATE PER POPULATION USING CTE

WITH Pop_vs_Vac (continent, location, Population, new_vaccinations, CummulatedVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CummulatedVaccinations
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1,2
)
SELECT *, (CummulatedVaccinations/population)*100 AS PercentageVacRatePerPop
FROM Pop_vs_Vac


-- CREATING TABLE & INSERTING DATA

DROP TABLE IF EXISTS PercentageVacRatePerPop
CREATE TABLE PercentageVacRatePerPop
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
CummulatedVaccinations numeric
)

INSERT INTO PercentageVacRatePerPop
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CummulatedVaccinations
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
SELECT *, (CummulatedVaccinations/population)*100 
FROM PercentageVacRatePerPop


-- CREATING A VIEW TABLE TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentageVacRatePerPop_2 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CummulatedVaccinations
FROM [dbo].[CovidDeaths] AS dea
JOIN [dbo].[CovidVaccinations] AS vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentageVacRatePerPop_2



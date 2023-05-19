/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * 
FROM PortfolioProject.dbo.CovidDeaths
WHERE TRIM(continent) > ''
ORDER BY 3,4


-- Select the data to start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE TRIM(continent) > '' 
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float)*100) AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE total_cases > 0 
AND location LIKE '%states%'
AND TRIM(continent) > ''
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population contracted Covid

SELECT location, date, population, total_cases, (CAST(total_cases AS float)/CAST(population AS float)*100) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


-- Showing Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(CAST(total_cases AS float)/CAST(population AS float)*100) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing Countries with highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE TRIM(continent) > '' 
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Showing Contintents with the highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE TRIM(continent) = '' 
AND location NOT LIKE '%income%'
AND location NOT LIKE 'World'
GROUP BY location
ORDER BY TotalDeathCount DESC


--SELECT continent, MAX(total_deaths) AS TotalDeathCount
--FROM PortfolioProject.dbo.CovidDeaths
--WHERE TRIM(continent) > '' 
--AND location NOT LIKE '%income%'
--GROUP BY continent
--ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(CAST(new_deaths as float))/SUM(CAST(new_cases as float))*100 as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE TRIM(continent) > ''
HAVING SUM(new_cases) > 0
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows percentage of population that has received at least one Covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE TRIM(dea.continent) > ''
ORDER BY 2,3


-- Using CTE to perform calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE TRIM(dea.continent) > ''
)
SELECT *, (CAST(RollingPeopleVaccinated as float)/CAST(population as float))*100 AS PercentagePopulationVaccinated
FROM PopvsVac


-- Using Temp Table to perform calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE TRIM(dea.continent) > ''

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentagePopulationVaccinated
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations 

USE PortfolioProject GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea
JOIN PortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE TRIM(dea.continent) > ''


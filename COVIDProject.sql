
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * 
FROM PortfolioProject..[CovidVaccinations(CovidVaccinations)]
WHERE continent is NOT NULL 
order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, total_deaths, population
FROM PortfolioProject..[CovidDeaths(CovidDeaths)]
order by 1,2

--Looking at total cases vs. total deaths
Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
from PortfolioProject..[CovidDeaths(CovidDeaths)]
where continent is NOT NULL
order by 2

--Looking at total cases vs. population
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, population), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..[CovidDeaths(CovidDeaths)]
ORDER BY 1, 2;

-- Looking at countries with highest infection rate compared to Population

SELECT location,population,MAX(total_cases) as HighestInfectionCount, 
MAX(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..[CovidDeaths(CovidDeaths)]
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Countries with Highest Death Count per population 

SELECT location, MAX(CAST (total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..[CovidDeaths(CovidDeaths)]
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..[CovidDeaths(CovidDeaths)]
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


select continent, sum(cast(new_deaths as int)) as TotalDeatCount
from PortfolioProject..[CovidDeaths(CovidDeaths)]
where continent is not null
group by continent

--Global Numbers

SELECT 
    SUM(CAST(new_cases AS float)) AS total_cases, 
    SUM(CAST(new_deaths AS float)) AS total_deaths,
    (SUM(CAST(new_deaths AS float)) / NULLIF(SUM(CAST(new_cases AS float)), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..[CovidDeaths(CovidDeaths)]
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Total Population vs. Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..[CovidDeaths(CovidDeaths)] dea
JOIN PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

-- Rolling People Vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CAST (vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..[CovidDeaths(CovidDeaths)] dea
JOIN PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent is NOT NULL	
ORDER BY 2,3

-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        CAST(dea.population AS BIGINT) AS population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..[CovidDeaths(CovidDeaths)] dea
    JOIN 
        PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / NULLIF(CAST(population AS BIGINT), 0)) * 100 AS PercentVaccinated
FROM PopvsVac
ORDER BY location, date

--TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255),
    location  nvarchar(255),
    date      datetime,
    population numeric,
    RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    CAST(dea.population AS BIGINT) AS population, 
    SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..[CovidDeaths(CovidDeaths)] dea
JOIN 
    PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / NULLIF(CAST(population AS BIGINT), 0)) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated


-- Daily Vaccination Change

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    LAG(CAST(vac.new_vaccinations AS FLOAT), 1) OVER (PARTITION BY dea.location ORDER BY dea.date) AS PreviousDayVaccinations,
    CAST(vac.new_vaccinations AS FLOAT) - LAG(CAST(vac.new_vaccinations AS FLOAT), 1) OVER (PARTITION BY dea.location ORDER BY dea.date) AS DailyVaccinationChange
FROM 
    PortfolioProject..[CovidDeaths(CovidDeaths)] dea
JOIN 
    PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;


-- Creating View to store data for visualizations

USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CAST (vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..[CovidDeaths(CovidDeaths)] dea
JOIN PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent is NOT NULL	
--ORDER BY 2,3
-------------------------
USE PortfolioProject
GO
CREATE VIEW DailyVaccinationChange AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    LAG(CAST(vac.new_vaccinations AS FLOAT), 1) OVER (PARTITION BY dea.location ORDER BY dea.date) AS PreviousDayVaccinations,
    CAST(vac.new_vaccinations AS FLOAT) - LAG(CAST(vac.new_vaccinations AS FLOAT), 1) OVER (PARTITION BY dea.location ORDER BY dea.date) AS DailyVaccinationChange
FROM 
    PortfolioProject..[CovidDeaths(CovidDeaths)] dea
JOIN 
    PortfolioProject..[CovidVaccinations(CovidVaccinations)] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

--------------------
USE PortfolioProject
GO
CREATE VIEW CasesvsDeaths AS
SELECT 
    SUM(CAST(new_cases AS float)) AS total_cases, 
    SUM(CAST(new_deaths AS float)) AS total_deaths,
    (SUM(CAST(new_deaths AS float)) / NULLIF(SUM(CAST(new_cases AS float)), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..[CovidDeaths(CovidDeaths)]
WHERE continent IS NOT NULL
GROUP BY date
--ORDER BY 1, 2
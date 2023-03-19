
--1. Select data to start with 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY location, date


--2. Total Cases vs Total Deaths (UK) 
-- Shows death rate in the UK
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate 
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Kingdom%'
and continent is not null
ORDER BY location, date


--3. Total Cases vs Population
-- Shows what perccentage of population infected with Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY location, date


--4. Countries with Highest Infection Rate
SELECT location, population, max(total_cases) AS max_cases, max(total_cases/population)*100 AS infection_rate
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY infection_rate DESC


--5. Countries with Highest Death Count 
SELECT location, max(cast(total_deaths as int)) AS death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY death_count DESC


--6. Continent breakdown 
-- Shows continents with the highest death count per population
SELECT continent, max(cast(total_deaths as int)) AS death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY death_count DESC


--7. Global numbers - total cases, total deaths, death rate
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_rate 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null


--8. Rolling count of daily vaccinations by country (Join, Partion by)
SELECT dea.continent, dea.population, dea.location, dea.date, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) 
OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  and dea.date = vac.date

WHERE dea.continent is not null
ORDER BY location,date


--9. Use CTE to calculate rolling vaccination percentage on partition by in previous query
WITH Rollingvac as (

SELECT dea.continent, dea.population, dea.location, dea.date, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) 
OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (rolling_vaccinations/population)*100 as rolling_vaccination_percentage
FROM Rollingvac


--10. Use Temp Table to calculate rolling vaccination percentage on partition by in previous query
DROP Table if exists #Vac_rate 
CREATE TABLE #Vac_rate
(
continent nvarchar(255),
population numeric,
location nvarchar(255),
date datetime,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #Vac_rate

SELECT dea.continent, dea.population, dea.location, dea.date, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) 
OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (rolling_vaccinations/population)*100 as rolling_vaccination_percentage
FROM #Vac_rate


--11. Create View to store data for later visualization
Create View Vac_rate as
SELECT dea.continent, dea.population, dea.location, dea.date, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) 
OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent is not null
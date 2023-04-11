-- SELECT the data you need 
SELECT location,date,total_cases,new_cases,total_deaths,population
 FROM CovidDeaths
 ORDER BY 1,2
 --look at Total cases VS Total Deaths to find the death rate
 --change datatype for selected columns from int to float
 --Percentage of people that succumbed 
 SELECT location, date, total_cases, total_deaths,
(CAST(total_deaths AS float)/CAST(total_cases AS float)*100)AS death_rate
FROM CovidDeaths
WHERE location = 'AFRICA'
ORDER BY 1, 2

 --Percentage of people that succumbed(death rate) and people that recovered (recovery rate)
  SELECT location, date, total_cases, total_deaths,
(CAST(total_deaths AS float)/CAST(total_cases AS float)*100)AS death_rate,
((CAST(total_cases AS float)- CAST(total_deaths AS float)) /CAST(total_cases AS FLOAT)*100)AS recovery_rate
FROM CovidDeaths
WHERE location = 'AFRICA'
ORDER BY 1, 2

-- percentage of population that contracted covid(total_cases, population)
SELECT location, date, total_cases, population,
((CAST(total_cases AS float)/CAST(population AS float))*100) AS contraction_rate
FROM CovidDeaths
WHERE location = 'AFRICA'

-- countries with highest contraction rate and compare it to population
SELECT location, MAX(total_cases) as max_total_cases, population,
((CAST(MAX(total_cases) AS float)/CAST(population AS float))*100) AS percentage_infected
FROM CovidDeaths
--WHERE location = 'Kenya'
GROUP BY location,population
ORDER BY percentage_infected DESC

--Countries with highest death count per population
 SELECT location, MAX(total_deaths) as max_total_deaths, population,
(CAST(MAX(total_deaths) AS float)/ CAST(population AS float))AS Death_count
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY max_total_deaths desc

-- BREAK things down by continents
SELECT continent, SUM(CAST(total_deaths AS int)) as Total_death_count,
MAX(CAST(total_deaths AS int)) AS Max_death_Count
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY Total_death_count DESC

--total Death percentagee globally
 SELECT SUM(CAST(new_cases AS float)) as total_new_cases, 
       SUM(CAST(new_deaths AS float)) as total_new_deaths, 
       SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float)) *100 as DeathPercentage
FROM CovidDeaths
ORDER BY 1, 2;
 
-- JOIN covid deaths and covid vaccinations
SELECT * 
FROM CovidDeaths dea INNER JOIN  CovidVaccinations vac 
ON  dea.date = vac.date and dea.location = vac.location
ORDER BY 1,2

--TOTAL population vs TOTAL VACCINATIONS
SELECT dea.continent,
SUM(CAST(vac.total_vaccinations as float)) AS total_vaccinations_globally,
SUM(CAST(dea.population as float)) as total_population,
SUM(CAST(vac.total_vaccinations as float))/SUM(CAST(dea.population as float)) * 100 as Vaccinated_percentage
FROM CovidDeaths dea INNER JOIN  CovidVaccinations vac 
ON  dea.date = vac.date and dea.location = vac.location
WHERE dea.continent is not NULL
GROUP BY dea.continent
ORDER by Vaccinated_percentage DESC
--
SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
--adds the new vaccinations simultaneoulsy as per the location
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,dea.date) as total_new_vaccinations
FROM CovidDeaths dea INNER JOIN  CovidVaccinations vac 
ON  dea.date = vac.date and dea.location = vac.location
GROUP BY dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
Order by 1,2


--
WITH PopVsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    --adds the new vaccinations simultaneously as per the location
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,dea.date) as total_new_vaccinations
    FROM CovidDeaths dea INNER JOIN CovidVaccinations vac 
    ON dea.date = vac.date and dea.location = vac.location
    WHERE dea.continent IS NOT NULL
)
SELECT *, CAST(total_new_vaccinations AS FLOAT) / population * 100 AS percentage
FROM PopVsVac
ORDER BY location, date;

----Using CTE
WITH PopvsVAc AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    --adds the new vaccinations simultaneously as per the location
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,dea.date) as total_new_vaccinations
    FROM CovidDeaths dea INNER JOIN CovidVaccinations vac 
    ON dea.date = vac.date and dea.location = vac.location
    WHERE dea.continent IS NOT NULL
)
SELECT *, CAST(total_new_vaccinations AS FLOAT) / population * 100 AS percentage_people_vaccinated
FROM PopvsVAc
WHERE total_new_vaccinations is not NULL
ORDER BY location, date;

--Using TEMP TABLE
DROP TABLE IF EXISTS #percentage_population_vaccinated
Create TABLE #percentage_population_vaccinated
(Continent NVARCHAR(255),
Location NVARCHAR(250),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
Total_new_vaccinations NUMERIC
)
Insert into #percentage_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    --adds the new vaccinations simultaneously as per the location
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,dea.date) as total_new_vaccinations
    FROM CovidDeaths dea INNER JOIN CovidVaccinations vac 
    ON dea.date = vac.date and dea.location = vac.location
    --WHERE dea.continent IS NOT NULL
SELECT 
    *,
    (CAST(total_new_vaccinations AS FLOAT) / population) * 100 AS percentage_population_vaccinated
FROM 
    #percentage_population_vaccinated;
--Create View for later visualization
--Create view does not work for temp tables using azure SQL database 
-- DESPITE THE RED THE CODE STILL WORKS
CREATE VIEW percentage_people_vaccinated
AS
WITH PopvsVAc AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    --adds the new vaccinations simultaneously as per the location
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location,dea.date) as total_new_vaccinations
    FROM CovidDeaths dea INNER JOIN CovidVaccinations vac 
    ON dea.date = vac.date and dea.location = vac.location
    WHERE dea.continent IS NOT NULL
)
SELECT *, CAST(total_new_vaccinations AS FLOAT) / population * 100 AS percentage_people_vaccinated
FROM PopvsVAc
WHERE total_new_vaccinations is not NULL
DROP VIEW percentage_people_vaccinated_view;
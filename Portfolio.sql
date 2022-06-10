--Below, I wanna verify that I have imported the correct data
SELECT *
FROM Portfolio..Deaths
ORDER BY 3,4

SELECT *
FROM Vaccinations
ORDER BY 3,4


--Below, I'm going to computer total deaths vs total cases 
--I'm curious to see the likelihood of death over time by location
--I chose my country, USA, because we had the craziest numbers 
SELECT location, date, total_cases, total_deaths,((total_deaths/total_cases)*100) as death_percentage
FROM Deaths
WHERE location = 'United States'
ORDER BY total_deaths ASC


--Below, I am just curious what percentage of the population has reported COVID-19 infections
--Again I chose the US for simplicity
--I also wanted to know when we had the first reported death, which was on February 29, 2020
SELECT location, date, total_cases, total_deaths, population,((total_cases/population)*100) as infection_rate
FROM Deaths
WHERE total_deaths > 0 AND location = 'United States'
ORDER BY 1,2


--Below, I want to see highest infections by location (country) and what percentage was infected 
--We can see that North Korea was bullshitting about their numbers but ok 
SELECT location, population, MAX(total_cases) as highest_infections_per_country, MAX((total_cases/population))*100 as percentage_infected
FROM Deaths
WHERE population IS NOT NULL AND continent IS NOT NULL 
GROUP BY location, population
ORDER BY highest_infections_per_country 


--Below, I want to show all the top 50 locations with the highest death per population to date
--I bet the US will be the leader here :( 
--I had to use the CAST statement because the total_death data was reported as varchar which would not allow using the MAX statement
--Ordering by DESC enables us to see highest to lowest
--This is when I realised I had to take out the continents since they're included in the same columns as countries
--I also learned that SQL Server doesn't use LIMIT. wtf.
SELECT location, MAX(CAST(total_deaths as INT)) as most_deaths_by_location
FROM Deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY most_deaths_by_location DESC
OFFSET 0 ROWS FETCH FIRST 50 ROWS ONLY;


--Below, I'm finding the number of reported deaths by continent
--Because of the way the data is recorded, North American numbers are only reflecting 'USA' and not including Canada
SELECT continent,MAX(CAST(total_deaths as INT)) as deaths_by_continent
FROM Deaths 
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY deaths_by_continent DESC


--Below, I'm looking at the death percentages for EACH day across all reported locations
SELECT date, SUM(new_cases) as all_new_cases, SUM(CAST (new_deaths as INT)) as all_new_deaths,SUM(CAST (new_deaths as INT))/SUM(new_cases)*100 as death_percentage 
FROM Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY death_percentage DESC

--Here, I can also remove the date and only focus on the total combine death percentage worldwide
--Sad numbers but 1.2% of the world population was lost to COVID-19
--And over 530 million people have reported having the virus to date
SELECT SUM(new_cases) as all_new_cases, SUM(CAST (new_deaths as INT)) as all_new_deaths,SUM(CAST (new_deaths as INT))/SUM(new_cases)*100 as death_percentage 
FROM Deaths
WHERE continent IS NOT NULL
--GROUP BY date

--------------------------------------------------------------

--Below,I'm aiming to join the two tables by date and location
--I wanna show off my joining skills but also look at when countries started reporting vaccinations 
--Choosing d and v saves tons and tons of typing 
SELECT d.date, d.continent, d.location, d.population, v.new_vaccinations
FROM Deaths as d
JOIN Vaccinations as v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3


--This is one of my most and least favourite queries
--I wanna see how many total reported vaccinations were done in each country as days went by
--Total vaccines are summed for the each new day in this query 
--I also want to see when the first vaccines were first administered
--The issue with this data is that most countries only reported vaccinations for one single and we are missing the rest of the data
--It is also wild to see that some countries like the UK and US started vaccinations in winter 2020 while others did not report anything until late summmer/fall 2021. 
--Again, I chose the US here because of the data availability but we can omit that line to focus on other countries 
SELECT d.date, d.continent, d.location, d.population, v.new_vaccinations, 
	SUM(CONVERT(bigint, v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) as daily_rolling_vaccinations
FROM Deaths as d
JOIN Vaccinations as v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location ='Uganda' 
ORDER BY 2,3


--Following up on the above query, I'm adding an option that shows us the daily rolling vaccination rate
--USing a CTE (common table expression) here helped me calculate without having to start a whole new query but just build onto what I already had 

WITH vaxxedpopulation(continent, location, date, population, new_vaccinations, daily_rolling_vaccinations)
AS
(
SELECT d.date, d.continent, d.location, d.population, v.new_vaccinations, 
	SUM(CONVERT(bigint, v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) as daily_rolling_vaccinations
FROM Deaths as d
JOIN Vaccinations as v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location ='United States' 
)
SELECT*, (ROUND(daily_rolling_vaccinations/population,3)*100) as daily_vaccinated_percentage
FROM vaxxedpopulation


--Creating a view for this query because I might need it later
--I'm a big fan of Views 
CREATE VIEW vax_rate as 
WITH vaxxedpopulation(continent, location, date, population, new_vaccinations, daily_rolling_vaccinations)
AS
(
SELECT d.date, d.continent, d.location, d.population, v.new_vaccinations, 
	SUM(CONVERT(bigint, v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location, d.date) as daily_rolling_vaccinations
FROM Deaths as d
JOIN Vaccinations as v
ON d.location = v.location
AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location ='United States' 
)
SELECT*, (ROUND(daily_rolling_vaccinations/population,3)*100) as daily_vaccinated_percentage
FROM vaxxedpopulation

SELECT* 
FROM vax_rate
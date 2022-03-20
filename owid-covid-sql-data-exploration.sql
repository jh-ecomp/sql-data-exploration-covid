
-- Basic querys just to check if everything is fine

select *
from death_covid dc;

select *
from vaccination_covid vc;

-- Verifying some columns

select distinct (continent)
from death_covid dc;

select distinct ("location")
from death_covid dc 
order by "location";

select distinct (population)
from death_covid dc
order by population desc;

update death_covid set continent = null where continent = '';
update vaccination_covid set continent = null where continent = '' ;
update vaccination_covid set new_vaccinations = null where new_vaccinations = '';
update vaccination_covid set total_vaccinations = null where total_vaccinations = '';
update vaccination_covid set people_vaccinated  = null where people_vaccinated = '';
update vaccination_covid set people_fully_vaccinated = null where people_fully_vaccinated = '';
-- Base query to death_covid table

select continent, "location", "date", total_cases, new_cases, total_deaths, population 
from death_covid dc
order by "location", "date";

-- Improving base query 

select "location", "date", total_cases, new_cases, total_deaths, population 
from death_covid dc
where continent is not null and population is not null and
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
order by "location", "date";

-- Percentage of deaths from Covid cases

select "location", "date", total_cases, total_deaths,
		(total_deaths / total_cases) * 100 as percentage_of_deaths 
from death_covid dc
where continent is not null and population is not null and 
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
order by "location", "date";

-- Percentage of the population infected by Covid 

select "location", "date", population, total_cases,
		(total_cases / population) * 100 as percentage_of_infected
from death_covid dc
where continent is not null and population is not null and 
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
order by "location", "date";

-- Countries with highest percentage of infected population 

select "location", population,
		max(total_cases) as total_cases,
		max((total_cases / population) * 100) as percentage_of_infected
from death_covid dc
where continent is not null and population is not null and total_cases is not null and 
	"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
group by "location", population 
order by percentage_of_infected desc;

-- Countries with highest count of deaths by Covid 

select "location", max(total_deaths) as total_deaths
from death_covid dc 
where continent is not null and total_deaths is not null and 
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
group by "location"
order by total_deaths desc;

-- Continents with highest count of deaths by Covid 

select "location", max(total_deaths) as total_deaths
from death_covid dc 
where continent is null and 
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
group by "location"
order by total_deaths desc;

-- You may be tempted to do this, but if you check the results you will see that something is wrong

select continent, max(total_deaths) as total_deaths
from death_covid dc 
where continent is not null and 
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
group by continent 
order by total_deaths desc;

-- Let's see some Global numbers

select sum(new_cases) as total_cases,
		sum(new_deaths) as total_deaths,
		sum(new_deaths) / sum(new_cases)*100 as percentage_of_deaths
from death_covid dc 
where continent is null and 
		"location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
order by total_cases, total_deaths;

-- Now its time to join death data with vaccination data
-- Looking at percentage of the fully vaccinated people

select dc.continent, dc."location", dc."date", dc.population, vc.new_vaccinations,
	sum(cast(vc.new_vaccinations as float)::int) over 
	(partition by dc."location" order by dc."location", dc."date") as cumulative_sum_new_vaccinations
from death_covid dc 
inner join vaccination_covid vc 
	on dc."location" = vc."location" and dc."date" = vc."date" 
where dc.continent is not null and 
		dc."location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
order by dc."location", dc."date" ;

-- With this query we're one step behind our goal, we just need to add a percentage column 
-- and we have some options like a CTE or a TEMP TABLE, a VIEW. Let's build a CTE

with DeathvsVaccination(continent, 
						"location", 
						"date", 
						population, 
						new_vaccinations, 
						cumulative_sum_new_vaccinations) as (
select dc.continent, dc."location", dc."date", dc.population, vc.new_vaccinations,
	sum(cast(vc.new_vaccinations as float)::int) over 
	(partition by dc."location" order by dc."location", dc."date") as cumulative_sum_new_vaccinations
from death_covid dc 
inner join vaccination_covid vc 
	on dc."location" = vc."location" and dc."date" = vc."date" 
where dc.continent is not null and 
		dc."location" not in ('Upper middle income', 'High income', 'Lower middle income', 'European Union', 'Low income', 'International')
order by dc."location", dc."date" )
select *, (cumulative_sum_new_vaccinations / population ) * 100 as percentage_of_vaccinated_population
from DeathvsVaccination;

-- This is all for now. We have a problem with this last query. Can you find it? A tip,
-- it has to do with people who received more the one dose.





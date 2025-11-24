-- 5. Analyze the data
-- I downloaded my mini-project file for Dec/2018, the file size is 268.7 MB.
-- Number of rows is 593,842.

-- Create and run SQL queries to answer the following questions:
-- 1) Find maximal departure delay in minutes for each airline. Sort results from smallest to largest maximum delay. Output airline names and values of the delay.
select al.Name AS AirlineName, max(p.DepDelayMinutes) as MaxDepDelayMinutes
from al_perf p
join L_AIRLINE_ID al
on p.DOT_ID_Reporting_Airline = al.ID
group by al.Name
order by MaxDepDelayMinutes asc;
-- returned 17 rows

-- 2) Find maximal early departures in minutes for each airline. Sort results from largest to smallest. Output airline names.
select al.name as Airlinename, max(abs(p.DepDelay)) as MaxEarlyDepartureMin
from al_perf p 
join L_AIRLINE_ID al
on p.DOT_ID_Reporting_Airline = al.ID
where p.DepDelay < 0
group by al.Name
order by MaxEarlyDepartureMin desc;
-- returned 17 rows

-- 3) Rank days of the week by the number of flights performed by all airlines on that day (1 is the busiest). Output the day of the week names, number of flights and ranks in the rank increasing order.
select 
	w.Day, 
	count(*) as NumFlights, 
    rank() over (order by count(*) desc) as BusiestDayRank
from al_perf as p
join L_WEEKDAYS as w
	 on p.DayOfWeek = w.Code
group by w.Day
order by BusiestDayRank asc;
-- returned 7 rows

-- 4) Find the airport that has the highest average departure delay among all airports. Consider 0 minutes delay for flights that departed early. Output one line of results: the airport name, code, and average delay.
select 
	a.Name as AirportName, 
	a.ID as AirportCode, 
	avg(p.DepDelayMinutes) as AvgDepartureDelay # according to the provided readme, early departures → already set to 0
from al_perf as p
join L_AIRPORT_ID as a
	on p.OriginAirportID = a.ID
group by a.ID, a.Name
order by AvgDepartureDelay desc
limit 1;
-- returned one row: 'Liberal, KS: Liberal Mid-America Regional','12902','63.82'

-- 5) For **each airline find an airport** where it has the highest average departure delay. Output an airline name, a name of the airport that has the highest average delay, and the value of that average delay. 
with avg_delays as (
    select 
        a.Name as airline_name,
        ap.Name as airport_name,
        avg(p.DepDelayMinutes) as avg_dep_delay,
        rank() over (
            partition by a.name
            order by avg(p.DepDelayMinutes) desc
        ) as rnk
    from al_perf as p
    join L_AIRLINE_ID as a
        on p.DOT_ID_Reporting_Airline = a.id
    join L_AIRPORT_ID as ap
        on p.OriginAirportID = ap.id
    group by a.Name, ap.Name
)
select airline_name, airport_name, avg_dep_delay
from avg_delays
where rnk = 1
order by airline_name;
-- returned 17 rows 


-- 6a) Check if your dataset has any canceled flights. 
select count(*) as num_canceled_flights
from al_perf
where cancelled = 1;
-- yes, returned one row indicating 6752 flights were canceled in my dataset 

-- 6b) If it does, what was the most frequent reason for each departure airport? Output airport name, the most frequent reason, and the number of cancelations for that reason.
with airport_delay_frequency as (
    select 
        ap.Name as airport_name,
        p.CancellationCode as cancel_reason,
        count(*) as num_cancellations,
        row_number() over (
            partition by ap.name
            order by count(*) desc
        ) as rn
    from al_perf as p
    join L_AIRPORT_ID as ap
        on p.OriginAirportID = ap.ID
    where p.Cancelled = 1
    group by ap.name, p.CancellationCode
)
select 
    ad.airport_name, 
    l.Reason,
    ad.num_cancellations
from airport_delay_frequency ad
join L_CANCELATION l
on ad.cancel_reason = l.Code
where rn = 1
order by num_cancellations desc, airport_name;
-- returned 280 rows

-- 7) Build a report that for each day output average number of flights over the preceding 3 days.
with daily_flights as (
	select FlightDate, count(*) as num_flights
	from al_perf
	group by FlightDate
)
select 
	Flightdate, 
	num_flights,
	avg(num_flights) over (
		order by flightdate
		rows between 2 preceding and current row 
	) as avg_num_flights_3day
from daily_flights
order by FlightDate;
-- returned 31 rows


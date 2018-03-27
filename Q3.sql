 
-- Participate

SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
        countryName varchar(50),
        year int,
        participationRatio real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)

DROP VIEW IF EXISTS part_ratio CASCADE;
DROP VIEW IF EXISTS ratio_list CASCADE;
DROP VIEW IF EXISTS decrease_country CASCADE;
DROP VIEW IF EXISTS mono_country CASCADE;
DROP VIEW IF EXISTS finalist CASCADE;
DROP VIEW IF EXISTS final CASCADE;


-- Define views for your intermediate steps here.
-- find the ratio of Participate of every election
CREATE VIEW part_ratio AS
SELECT id as election_id, country_id, EXTRACT(YEAR FROM e_date) AS year, votes_cast::decimal / electorate::decimal AS ratio
FROM election
WHERE EXTRACT(YEAR FROM e_date) >= 2001 AND EXTRACT(YEAR FROM e_date) <= 2016 ;

-- create a list of every year's ratio of every country
CREATE VIEW ratio_list AS
SELECT country_id, year, AVG(ratio) as ratio
FROM part_ratio
GROUP BY country_id, year;

-- find country that is not mono-non-decrease
CREATE VIEW decrease_country AS
SELECT distinct a.country_id
FROM ratio_list a, ratio_list b
WHERE a.country_id = b.country_id AND
      a.year > b.year AND
      a.ratio < b.ratio;

-- find all country that are  mono-non-decrease
CREATE VIEW mono_country AS
(SELECT id AS country_id FROM country)
EXCEPT 
(SELECT country_id FROM decrease_country);

--get the final list.
CREATE VIEW finalist AS
SELECT name AS countryName, country_id 
FROM mono_country, country
WHERE country_id = id;

--the final view, get all information that is need for the q3 table.
CREATE VIEW final AS
SELECT countryName, year, ratio AS participationRatio
FROM finalist, ratio_list
WHERE finalist.country_id = ratio_list.country_id;

-- the answer to the query 

insert into q3 (countryName, year, participationRatio)
                (SELECT countryName AS countryName,
                        year AS year,
                        participationRatio AS participationRatio
                 FROM final);

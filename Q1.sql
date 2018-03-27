-- VoteRange

SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
year INT,
countryName VARCHAR(50),
voteRange VARCHAR(20),
partyName VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)

DROP VIEW IF EXISTS this_and_previous CASCADE;
DROP VIEW IF EXISTS multiple_same_year CASCADE;
DROP VIEW IF EXISTS single_same_year CASCADE;
DROP VIEW IF EXISTS multiple_same_year_percentage_temp CASCADE;
DROP VIEW IF EXISTS multiple_same_year_percentage_temp2 CASCADE;
DROP VIEW IF EXISTS multiple_percentage CASCADE;
DROP VIEW IF EXISTS single_same_year_percentage_temp CASCADE;
DROP VIEW IF EXISTS single_percentage CASCADE;
DROP VIEW IF EXISTS compare_table CASCADE;
DROP VIEW IF EXISTS range_less_5 CASCADE;
DROP VIEW IF EXISTS range_5_to_10 CASCADE;
DROP VIEW IF EXISTS range_10_to_20 CASCADE;
DROP VIEW IF EXISTS range_20_to_30 CASCADE;
DROP VIEW IF EXISTS range_30_to_40 CASCADE;
DROP VIEW IF EXISTS range_more_40 CASCADE;
DROP VIEW IF EXISTS final CASCADE;

-- Define views for your intermediate steps here.

--AND e_type = 'Parliamentary election'

-- a temp table for all the elections.
CREATE VIEW this_and_previous AS
SELECT country_id AS country_id, 
       id AS election_id,
       EXTRACT(YEAR FROM e_date) AS election_date
FROM election
WHERE EXTRACT(YEAR FROM e_date) >= 1996 AND EXTRACT(YEAR FROM e_date) <= 2016
ORDER BY country_id;

-- a table of election that are in the same country same year
CREATE VIEW multiple_same_year AS
SELECT a.country_id, a.election_id, a.election_date AS election_year
FROM this_and_previous a, this_and_previous b                               
WHERE a.country_id = b.country_id
AND a.election_id != b.election_id
AND a.election_date = b.election_date;

-- a table of election that they are the only one in that country
CREATE VIEW single_same_year AS
SELECT country_id, election_id, election_date AS election_year 
FROM this_and_previous
WHERE election_id NOT IN (SELECT election_id FROM multiple_same_year);

-- start getting the information if there are multiple election in a year
CREATE VIEW multiple_same_year_percentage_temp AS
SELECT m.country_id, party_id, votes, votes_valid, election_year, m.election_id
FROM multiple_same_year m, election_result, election
WHERE m.election_id = election_result.election_id AND 
      election_result.election_id = election.id AND 
      m.election_id = election.id
ORDER BY m.country_id;

CREATE VIEW multiple_same_year_percentage_temp2 AS
SELECT country_id, party_id, election_year, SUM(votes) AS Sum1 , SUM(votes_valid) AS Sum2
FROM multiple_same_year_percentage_temp 
GROUP BY country_id, party_id, election_year;

CREATE VIEW multiple_percentage AS
SELECT country_id, party_id, election_year, Sum1::decimal/Sum2::decimal AS Percentage 
FROM multiple_same_year_percentage_temp2;

-- start getting the information if there is single election in a year
CREATE VIEW single_same_year_percentage_temp AS
SELECT m.country_id, party_id, votes, votes_valid, election_year, m.election_id
FROM single_same_year m, election_result, election
WHERE m.election_id = election_result.election_id AND 
      election_result.election_id = election.id AND 
      m.election_id = election.id
ORDER BY m.country_id;

CREATE VIEW single_percentage AS
SELECT country_id, party_id, election_year, votes::decimal/votes_valid::decimal AS Percentage
FROM single_same_year_percentage_temp
ORDER BY country_id;

--combine multiple and single view
--A view for all the electionm,party,country recorded
CREATE VIEW compare_table AS
(SELECT * FROM single_percentage WHERE Percentage IS NOT NULL)
UNION 
(SELECT * FROM multiple_percentage WHERE Percentage IS NOT NULL);

-- start comparison
CREATE VIEW range_less_5 AS
SELECT country_id, party_id, election_year, '(0-5]'::text AS range
FROM compare_table
WHERE Percentage <= 0.05
ORDER BY country_id;

CREATE VIEW range_5_to_10 AS
SELECT country_id, party_id, election_year, '(5-10]'::text AS range
FROM compare_table
WHERE Percentage > 0.05 AND Percentage <= 0.1
ORDER BY country_id;

CREATE VIEW range_10_to_20 AS
SELECT country_id, party_id, election_year, '(10-20]'::text AS range
FROM compare_table
WHERE Percentage > 0.1 AND Percentage <= 0.2
ORDER BY country_id;

CREATE VIEW range_20_to_30 AS
SELECT country_id, party_id, election_year, '(20-30]'::text AS range
FROM compare_table
WHERE Percentage > 0.2 AND Percentage <= 0.3
ORDER BY country_id;

CREATE VIEW range_30_to_40 AS
SELECT country_id, party_id, election_year, '(30-40]'::text AS range
FROM compare_table
WHERE Percentage > 0.3 AND Percentage <= 0.4
ORDER BY country_id;

CREATE VIEW range_more_40 AS
SELECT country_id, party_id, election_year, '(40-100]'::text AS range
FROM compare_table
WHERE Percentage > 0.4
ORDER BY country_id;

-- inser the final view.
-- same structure as the final q1 table
CREATE VIEW final AS
(SELECT * FROM range_less_5)
UNION
(SELECT * FROM range_5_to_10)
UNION
(SELECT * FROM range_10_to_20)
UNION
(SELECT * FROM range_20_to_30)
UNION 
(SELECT * FROM range_30_to_40)
UNION
(SELECT * FROM range_more_40);
-- the answer to the query 

INSERT INTO q1 (year,countryName,voteRange,partyName) 
                      (SELECT final.election_year AS year,
                              country.name AS countryName,
                              final.range AS voteRange,
                              party.name_short AS partyName
                       FROM final, country, party
                       WHERE final.country_id = country.id AND 
                             final.party_id = party.id);


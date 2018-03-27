 



-- Alliances

SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
        countryId INT, 
        alliedPartyId1 INT, 
        alliedPartyId2 INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)

DROP VIEW IF EXISTS count_election CASCADE;
DROP VIEW IF EXISTS possible_alliance CASCADE;
DROP VIEW IF EXISTS list1 CASCADE;
DROP VIEW IF EXISTS list2 CASCADE;
DROP VIEW IF EXISTS total_list CASCADE;
DROP VIEW IF EXISTS possible_pair CASCADE;
DROP VIEW IF EXISTS pair_count CASCADE;
DROP VIEW IF EXISTS pairs CASCADE;
DROP VIEW IF EXISTS enough CASCADE;

-- Define views for your intermediate steps here.
--count election of a country
CREATE VIEW count_election AS
SELECT country_id, count(id)
FROM election 
GROUP BY country_id;

-- get all the alliance
CREATE VIEW possible_alliance AS
SELECT distinct alliance_id
FROM election_result;

-- get all the boss's id pair with alliance id
CREATE VIEW list1 AS
SELECT id, party_id
FROM possible_alliance, election_result
WHERE possible_alliance.alliance_id = election_result.id;

-- get other member's id pair with alliance id
CREATE VIEW list2 AS
SELECT election_result.alliance_id, party_id
FROM possible_alliance, election_result
WHERE possible_alliance.alliance_id = election_result.alliance_id;

-- combine two list1, list2
CREATE VIEW total_list AS
(SELECT * FROM list1)
UNION 
(SELECT * FROM list2);

-- get all the possible pair of alliance
CREATE VIEW possible_pair AS
SELECT a.id, a.party_id AS p1, b.party_id AS p2
FROM total_list a, total_list b
WHERE a.id = b.id AND a.party_id < b.party_id;

-- count how many time these two party has been together.
CREATE VIEW pair_count AS
SELECT p1, p2 ,count(id) AS Num
FROM possible_pair
GROUP BY p1, p2;

-- get the pairs and their information
CREATE VIEW pairs AS
SELECT p1, p2, Num, country_id
FROM pair_count, party 
WHERE p1 = party.id;

-- final view, same structure as the final q7 table.
CREATE VIEW enough AS
SELECT p1, p2, pairs.country_id
FROM pairs, count_election
WHERE pairs.country_id = count_election.country_id AND
      pairs.Num >= (0.3*count_election.count::decimal);

-- the answer to the query 
insert into q7 (countryID, alliedPartyId1, alliedPartyId2)
               (SELECT country_id AS countryID,
                       p1 AS alliedPartyId1,
                       p2 AS alliedPartyId2
                FROM enough);

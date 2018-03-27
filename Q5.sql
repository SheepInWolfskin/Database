 



-- Committed

SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
        countryName VARCHAR(50),
        partyName VARCHAR(100),
        partyFamily VARCHAR(50),
        stateMarket REAL
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)

DROP VIEW IF EXISTS cabinet_count CASCADE;
DROP VIEW IF EXISTS party_cabinet_count CASCADE;
DROP VIEW IF EXISTS in_all_cabinet CASCADE;
DROP VIEW IF EXISTS get_country_name CASCADE;
DROP VIEW IF EXISTS get_party_name CASCADE;
DROP VIEW IF EXISTS no_family CASCADE;
DROP VIEW IF EXISTS with_family CASCADE;
DROP VIEW IF EXISTS almost_there CASCADE;
DROP VIEW IF EXISTS final CASCADE;

-- Define views for your intermediate steps here.
-- get the number of cabinet of all country
CREATE VIEW cabinet_count AS
SELECT country_id ,count(id) AS Num1
FROM cabinet 
GROUP BY country_id;

-- get the number of cabinet of a party.
CREATE VIEW party_cabinet_count AS
SELECT country_id, party_id, count(cabinet_id) Num2
FROM cabinet_party, party
WHERE party_id = party.id
GROUP BY country_id ,party_id;

--get the party id of parties that they are in all cabinet
CREATE VIEW in_all_cabinet AS
SELECT party_cabinet_count.country_id, party_cabinet_count.party_id
FROM party_cabinet_count, cabinet_count
WHERE party_cabinet_count.Num2 = cabinet_count.Num1 AND
      party_cabinet_count.country_id = cabinet_count.country_id;

-- getting the country name of that party belongs
CREATE VIEW get_country_name AS
SELECT country_id, party_id, name AS countryName
FROM country, in_all_cabinet
WHERE country_id = id;

-- getting the party name
CREATE VIEW get_party_name AS
SELECT get_country_name.country_id, party_id, countryName, name AS partyName
FROM party, get_country_name
WHERE party_id = id;

-- Two step below for party family
CREATE VIEW no_family AS
SELECT * FROM get_party_name
WHERE party_id NOT IN (SELECT party_id FROM party_family);

CREATE VIEW with_family AS
SELECT a.country_id, a.party_id, a.countryName, a.partyName, party_family.family
FROM get_party_name a, party_family
WHERE a.party_id = party_family.party_id;

-- combine the above two steps
CREATE VIEW almost_there AS
(SELECT country_id, party_id, countryName, partyName, family AS partyFamily FROM with_family)
UNION 
(SELECT country_id, party_id, countryName, partyName, CAST (NULL AS VARCHaR) AS partyFamily FROM no_family);

--the final view, has the same structure as the final q5 table.
CREATE VIEW final AS
SELECT countryName, partyName, partyFamily, state_market AS stateMarket
FROM almost_there, party_position
WHERE almost_there.party_id = party_position.party_id;

-- the answer to the query 
insert into q5 (countryName, partyName, partyFamily, stateMarket)
               (SELECT countryName AS countryName,
                       partyName AS partyName,
                       partyFamily AS partyFamily,
                       stateMarket AS stateMarket
                FROM final);

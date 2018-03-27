
-- Winners

SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
countryName VARCHaR(100),
partyName VARCHaR(100),
partyFamily VARCHaR(100),
wonElections INT,
mostRecentlyWonElectionId INT,
mostRecentlyWonElectionYear INT
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

DROP VIEW IF EXISTS  num_party_by_country CASCADE;
DROP VIEW IF EXISTS  most_vote_list CASCADE;
DROP VIEW IF EXISTS election_winner CASCADE;
DROP VIEW IF EXISTS election_winner_by_country CASCADE;
DROP VIEW IF EXISTS total_win_by_country CASCADE;
DROP VIEW IF EXISTS average_win_by_country CASCADE;
DROP VIEW IF EXISTS win_count_party CASCADE;
DROP VIEW IF EXISTS compare_table CASCADE;
DROP VIEW IF EXISTS finalist_t CASCADE;
DROP VIEW IF EXISTS finalist_c CASCADE;
DROP VIEW IF EXISTS finalist_c_wc CASCADE;
DROP VIEW IF EXISTS finalist_c_n_wc CASCADE;
DROP VIEW IF EXISTS win_year CASCADE;
DROP VIEW IF EXISTS finalist_c_n_wc_rw CASCADE;
DROP VIEW IF EXISTS finalist CASCADE;
DROP VIEW IF EXISTS no_family CASCADE;
DROP VIEW IF EXISTS with_family CASCADE;
DROP VIEW IF EXISTS final CASCADE;

-- Define views for your intermediate steps here.

-- get all the country's party number
CREATE VIEW num_party_by_country AS
SELECT country_id, count(id) AS partyNum
FROM party
GROUP BY country_id;

-- get the winner's vote number of every election
CREATE VIEW most_vote_list AS
SELECT election_id, MAX(votes) AS winner_vote
FROM election_result
GROUP BY election_id;

-- find the election winner
CREATE VIEW election_winner AS
SELECT most_vote_list.election_id, election_result.party_id,  winner_vote as votes
FROM election_result, most_vote_list
WHERE election_result.votes = most_vote_list.winner_vote AND
      election_result.election_id = most_vote_list.election_id;

-- group all winner by their country
CREATE VIEW election_winner_by_country AS
SELECT party.country_id, election_winner.election_id, election_winner.party_id, election_winner.votes
FROM election_winner, party
WHERE party.id = election_winner.party_id;

-- count how many party has won.
CREATE VIEW total_win_by_country AS
SELECT country_id, count(party_id) AS partyWin
FROM election_winner_by_country
GROUP BY country_id;

-- find average win times group by country
CREATE VIEW average_win_by_country AS
SELECT total_win_by_country.country_id, partyWin::decimal / partyNum::decimal AS ave_win
FROM total_win_by_country, num_party_by_country
WHERE total_win_by_country.country_id = num_party_by_country.country_id;

--find all the party's win count
CREATE VIEW win_count_party AS
SELECT country_id, party_id, count(election_id) AS win_count
FROM election_winner_by_country
GROUP BY country_id, party_id;

-- get a table compare total win of country and total win of a party
CREATE VIEW compare_table AS
SELECT average_win_by_country .country_id, party_id, win_count, ave_win
FROM win_count_party, average_win_by_country 
WHERE average_win_by_country.country_id =  win_count_party.country_id;

-- the below steps is for getting what the final table needs.
CREATE VIEW finalist_t AS
SELECT country_id, party_id
FROM compare_table
WHERE win_count > 3*ave_win;

CREATE VIEW finalist_c AS
SELECT name as countryName, finalist_t.country_id, party_id
FROM finalist_t, country
WHERE finalist_t.country_id = country.id;

CREATE VIEW finalist_c_wc AS
SELECT finalist_c.countryName,finalist_c.country_id, finalist_c.party_id, win_count_party.win_count
FROM finalist_c, win_count_party
WHERE finalist_c.party_id = win_count_party.party_id;

CREATE VIEW finalist_c_n_wc AS
SELECT a.countryName, party.name, a.country_id, a.party_id, a.win_count
FROM finalist_c_wc a, party
WHERE a.party_id = party.id;

CREATE VIEW win_year AS
SELECT election_winner.party_id, election_winner.election_id, EXTRACT(YEAR FROM e_date) as year
FROM election_winner, election
WHERE election_winner.election_id = election.id;

CREATE VIEW finalist_c_n_wc_rw AS
SELECT a.countryName, a.name, a.country_id, a.party_id, a.win_count, MAX(year)
FROM finalist_c_n_wc a, win_year
WHERE a.party_id = win_year.party_id
GROUP BY a.countryName, a.name, a.country_id, a.party_id, a.win_count;

CREATE VIEW finalist AS
SELECT a.countryName, a.name, a.country_id, a.party_id, a.win_count, win_year.election_id, max as latest
FROM finalist_c_n_wc_rw a, win_year
WHERE a.party_id = win_year.party_id AND win_year.year = a.max;

CREATE VIEW no_family AS
SELECT * FROM finalist
WHERE party_id NOT IN (SELECT party_id FROM party_family);

CREATE VIEW with_family AS
SELECT a.countryName, a.name, party_family.family, a.country_id, a.party_id, a.win_count, a.election_id, a.latest
FROM finalist a, party_family
WHERE a.party_id = party_family.party_id;

--the final view, same structure as the final q2 table.
CREATE VIEW final AS
(SELECT countryName, name AS partyName, family as partyFamily, win_count AS wonElections, election_id AS eID, latest AS year
 FROM with_family)
UNION 
(SELECT countryName, name AS partyName, CAST (NULL AS VARCHaR) as partyFamily, win_count AS wonElections, election_id AS eID, latest AS year
 FROM no_family);


-- the answer to the query 
insert into q2 (countryName, partyName, partyFamily, wonElections, mostRecentlyWonElectionId, mostRecentlyWonElectionYear)
            (SELECT countryName AS countryName,
                    partyName AS partyName,
                    partyFamily AS partyFamily,
                    wonElections AS wonElections,
                    eID AS mostRecentlyWonElectionId,
                    year AS mostRecentlyWonElectionYear
             FROM final);


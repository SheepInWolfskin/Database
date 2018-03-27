-- Sequences

SET SEARCH_PATH TO parlgov;
drop table if exists q6 cascade;

-- You must not change this table definition.

CREATE TABLE q6(
        countryName VARCHAR(50),
        cabinetId INT, 
        startDate DATE,
        endDate DATE,
        pmParty VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS intermediate_step CASCADE;


DROP VIEW IF EXISTS all_ids CASCADE;
DROP VIEW IF EXISTS previous_ids CASCADE;
DROP VIEW IF EXISTS Null_ids CASCADE;

DROP VIEW IF EXISTS PREVIOUS_ID CASCADE;
DROP VIEW IF EXISTS NULLEnd CASCADE;
DROP VIEW IF EXISTS CabinetTable CASCADE;
DROP VIEW IF EXISTS CabinetEnd CASCADE;
DROP VIEW IF EXISTS DURA CASCADE;
DROP VIEW IF EXISTS DURA2 CASCADE;
DROP VIEW IF EXISTS Cid CASCADE;
DROP VIEW IF EXISTS Cname CASCADE;
DROP VIEW IF EXISTS Pid CASCADE;
DROP VIEW IF EXISTS Pname CASCADE;
DROP VIEW IF EXISTS Pid2 CASCADE;
DROP VIEW IF EXISTS Pid_id CASCADE;
DROP VIEW IF EXISTS Pid2_id CASCADE;
DROP VIEW IF EXISTS Pid3_id CASCADE;
DROP VIEW IF EXISTS NoPM CASCADE;
DROP VIEW IF EXISTS Pidfinal CASCADE;
DROP VIEW IF EXISTS Final CASCADE;



-- find all ids
CREATE VIEW all_ids AS
SELECT id
FROM cabinet;


-- find all previous ids
CREATE VIEW previous_ids AS
SELECT previous_cabinet_id AS id
FROM cabinet;


-- find all recent id
CREATE VIEW Null_ids AS
(SELECT * FROM all_ids) EXCEPT (SELECT * FROM previous_ids);

-- combine previous ids with some information
CREATE VIEW PREVIOUS_ID AS
select Null_ids.id, cabinet.start_date AS startTime
FROM Null_ids, cabinet
WHERE Null_ids.id = cabinet.id;


CREATE VIEW NULLEnd AS
select PREVIOUS_ID.id AS cabinetId, startTime AS startDate, CAST(NULL AS DATE) AS endDate
FROM PREVIOUS_ID;

CREATE VIEW CabinetTable AS
SELECT id, start_date AS StartTime
FROM cabinet 
GROUP BY id;

CREATE VIEW CabinetEnd AS
SELECT cabinet.previous_cabinet_id AS id, start_date AS ending_time 
FROM cabinet
GROUP BY id;


-- find the time interval for id with endDate
CREATE VIEW DURA AS
SELECT CabinetTable.id AS cabinetId, CabinetTable.StartTime AS startDate, CabinetEnd.ending_time AS endDate
FROM CabinetTable, CabinetEnd
WHERE CabinetTable.id = CabinetEnd.id;

-- put all id together
CREATE VIEW DURA2 AS
(SELECT * from DURA)
UNION(SELECT * from NULLEND);

-- put the cid into table
CREATE VIEW Cid AS
SELECT cabinetId, startDate, endDate, country_id
FROM cabinet, DURA2
WHERE cabinet.id = DURA2.cabinetId;

-- put country name in table
CREATE VIEW Cname AS
SELECT cabinetId, startDate, endDate, country.name AS countryName
FROM Cid, country
WHERE Cid.country_id = country.id;


-- select all party who has pm as t


CREATE VIEW Pid AS
SELECT cabinetId, startDate, endDate, countryName, party_id
FROM Cname, cabinet_party
WHERE cabinetId = cabinet_id
GROUP BY Cname.startDate, cabinetId, endDate, countryName, party_id,  cabinet_party.pm
HAVING cabinet_party.pm = 't';



-- select all party who has pm f
CREATE VIEW Pid2 AS
SELECT cabinetId, startDate, endDate, countryName
FROM Cname, cabinet_party
WHERE cabinetId = cabinet_id
GROUP BY Cname.startDate, cabinetId, endDate, countryName, cabinet_party.pm
HAVING cabinet_party.pm = 'f';

-- select all cabinet 
CREATE VIEW Pid_id AS
SELECT distinct cabinetId
FROM Pid;

-- select all has no pm
CREATE VIEW Pid2_id AS
SELECT distinct cabinetId
FROM Pid2;

-- select all cabinet who has no pm
Create VIEW Pid3_id AS
(SELECT * FROM Pid2_id) EXCEPT (SELECT * FROM Pid_id);

-- select all information of the cabinet who has no pm
CREATE VIEW NoPM AS
SELECT Pid3_id.cabinetId, startDate, endDate, countryName, NULL AS pmParty
FROM Pid2, Pid3_id
WHERE pid2.cabinetId = Pid3_id.cabinetId;

CREATE VIEW Pidfinal AS
SELECT cabinetId, startDate, endDate, countryName, name
FROM Pid, party
WHERE Pid.party_id = party.id;

CREATE VIEW Final AS
(SELECT * from NoPM) UNION (SELECT * from Pidfinal);

INSERT INTO q6(countryName, cabinetId, startDate, endDate, pmParty)
              (SELECT countryName AS countryName,
                      cabinetId AS cabinetId,
                      startDate AS startDate,
                      endDate AS endDate,
                      pmParty AS pmParty
               FROM Final
              );


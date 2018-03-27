

-- Left-right



SET SEARCH_PATH TO parlgov;

drop table if exists q4 cascade;



-- You must not change this table definition.





CREATE TABLE q4(

        countryName VARCHAR(50),

        r0_2 INT,

        r2_4 INT,

        r4_6 INT,

        r6_8 INT,

        r8_10 INT

);



-- You may find it convenient to do this for each of the views

-- that define your intermediate steps.  (But give them better names!)

DROP VIEW IF EXISTS intermediate_step CASCADE;

DROP VIEW IF EXISTS zero_to_two CASCADE;
DROP VIEW IF EXISTS two_to_four CASCADE;
DROP VIEW IF EXISTS four_to_six CASCADE;
DROP VIEW IF EXISTS six_to_eight CASCADE;
DROP VIEW IF EXISTS eight_to_ten CASCADE;
DROP VIEW IF EXISTS zero_to_two_cid CASCADE;
DROP VIEW IF EXISTS two_to_four_cid CASCADE;
DROP VIEW IF EXISTS four_to_six_cid CASCADE;
DROP VIEW IF EXISTS six_to_eight_cid CASCADE;
DROP VIEW IF EXISTS eight_to_ten_cid CASCADE;
DROP VIEW IF EXISTS count_0_to_2 CASCADE;
DROP VIEW IF EXISTS count_2_to_4 CASCADE;
DROP VIEW IF EXISTS count_4_to_6 CASCADE;
DROP VIEW IF EXISTS count_6_to_8 CASCADE;
DROP VIEW IF EXISTS count_8_to_10 CASCADE;
DROP VIEW IF EXISTS step1 CASCADE;
DROP VIEW IF EXISTS step2 CASCADE;
DROP VIEW IF EXISTS step3 CASCADE;
DROP VIEW IF EXISTS step4 CASCADE;



-- Define views for your intermediate steps here.


-- put all id in different slots
CREATE VIEW zero_to_two AS 

SELECT party_id 

FROM party_position

WHERE left_right < 2 AND left_right >= 0;



CREATE VIEW two_to_four AS 

SELECT party_id 

FROM party_position

WHERE left_right < 4 AND left_right >= 2;



CREATE VIEW four_to_six AS 

SELECT party_id 

FROM party_position

WHERE left_right < 6 AND left_right >= 4;



CREATE VIEW six_to_eight AS 

SELECT party_id 

FROM party_position

WHERE left_right < 8 AND left_right >= 6;



CREATE VIEW eight_to_ten AS 

SELECT party_id 

FROM party_position

WHERE left_right < 10 AND left_right >= 8;

-- put cid into slots

CREATE VIEW zero_to_two_cid AS 

SELECT party_id, country_id

FROM zero_to_two, party

WHERE zero_to_two.party_id = party.id;



CREATE VIEW two_to_four_cid AS 

SELECT party_id, country_id

FROM two_to_four, party

WHERE two_to_four.party_id = party.id;





CREATE VIEW four_to_six_cid AS 

SELECT party_id, country_id

FROM four_to_six, party

WHERE four_to_six.party_id = party.id;





CREATE VIEW six_to_eight_cid AS 

SELECT party_id, country_id

FROM six_to_eight, party

WHERE six_to_eight.party_id = party.id;





CREATE VIEW eight_to_ten_cid AS 

SELECT party_id, country_id

FROM eight_to_ten, party

WHERE eight_to_ten.party_id = party.id;

-- count specific party_id in different slots

CREATE VIEW count_0_to_2 AS

SELECT country_id, country.name, count(party_id) AS PC

FROM zero_to_two_cid, country

WHERE zero_to_two_cid.country_id = country.id

GROUP BY country_id, country.name;



CREATE VIEW count_2_to_4 AS

SELECT country_id, country.name, count(party_id) AS PC

FROM two_to_four_cid, country

WHERE two_to_four_cid.country_id = country.id

GROUP BY country_id, country.name;



CREATE VIEW count_4_to_6 AS

SELECT country_id, country.name, count(party_id) AS PC

FROM four_to_six_cid, country

WHERE four_to_six_cid.country_id = country.id

GROUP BY country_id, country.name;



CREATE VIEW count_6_to_8 AS

SELECT country_id, country.name, count(party_id) AS PC

FROM six_to_eight_cid, country

WHERE six_to_eight_cid.country_id = country.id

GROUP BY country_id, country.name;



CREATE VIEW count_8_to_10 AS

SELECT country_id, country.name, count(party_id) AS PC

FROM eight_to_ten_cid, country

WHERE eight_to_ten_cid.country_id = country.id

GROUP BY country_id, country.name;


-- add first 2 slots together
CREATE VIEW step1 AS

SELECT count_0_to_2.country_id,

       count_0_to_2.name,

       count_0_to_2.PC AS r0_2,

       count_2_to_4.PC AS r2_4

FROM count_0_to_2, count_2_to_4

WHERE count_2_to_4.country_id = count_0_to_2.country_id;


-- add 3rd slot
CREATE VIEW step2 AS

SELECT step1.country_id,

       step1.name,

       step1.r0_2 AS r0_2,

       step1.r2_4 AS r2_4,

       count_4_to_6.PC AS r4_6

FROM step1, count_4_to_6

WHERE step1.country_id = count_4_to_6.country_id;


-- add 4th slot
CREATE VIEW step3 AS

SELECT step2.country_id,

       step2.name,

       step2.r0_2 AS r0_2,

       step2.r2_4 AS r2_4,

       step2.r4_6 AS r4_6,

       count_6_to_8.PC AS r6_8

FROM step2, count_6_to_8

WHERE step2.country_id = count_6_to_8.country_id;




-- add last slot into the final answer
CREATE VIEW step4 AS

SELECT step3.country_id,

       step3.name,

       step3.r0_2 AS r0_2,

       step3.r2_4 AS r2_4,

       step3.r4_6 AS r4_6,

       step3.r6_8 AS r6_8,

       count_8_to_10.PC AS r8_10

FROM step3, count_8_to_10

WHERE step3.country_id = count_8_to_10.country_id;





-- the answer to the query 

INSERT INTO q4 (countryName, r0_2, r2_4, r4_6, r6_8
 ,r8_10
)
                (SELECT name AS countryName,
                r0_2 AS r0_2,

                r2_4 AS r2_4,

                r4_6 AS r4_6,

                r6_8 AS r6_8,

                r8_10
 AS r8_10
                FROM step4);
                       

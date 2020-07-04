-- B. Join with position records
                           -- 1. Clean asterisks from names in position table
--Clear the deck to run code
DROP TABLE
	totals_2,
	bbref_totals,
	bbref_totals_2,
	joined_totals,
	joined_totals_2,
	joined_totals_3,
	joined_totals_4,
	multi_team_players,
	player_id_dict
;

--remove bbref's "header rows"
DELETE FROM	
	all_totals
	WHERE
		uniqueid = ''
;

--trim asterisks for Hall of Famers
UPDATE
	all_totals
SET
	Player = TRIM('*' FROM Player)
	WHERE
		Player LIKE '%*'
;
--Clean empty string fields
UPDATE
   NBA_historical.dbo.all_totals 
SET
   FG = '0.0' 
WHERE
   FG = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   FGA = '0.0' 
WHERE
   FGA = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   FT = '0.0' 
WHERE
   FT = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   FTA = '0.0' 
WHERE
   FTA = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   fgm_3 = '0.0' 
WHERE
   fgm_3 = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   fga_3 = '0.0' 
WHERE
   fga_3 = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   ORB = '0.0' 
WHERE
   ORB = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   DRB = '0.0' 
WHERE
   DRB = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   TRB = '0.0' 
WHERE
   TRB = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   AST = '0.0' 
WHERE
   AST = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   STL = '0.0' 
WHERE
   STL = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   BLK = '0.0' 
WHERE
   BLK = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   TOV = '0.0' 
WHERE
   TOV = '';
UPDATE
   NBA_historical.dbo.all_totals
SET
   PF = '0.0' 
WHERE
   PF = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   PTS = '0.0' 
WHERE
   PTS = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   fgm_2 = '0.0' 
WHERE
   fgm_2 = '';
UPDATE
   NBA_historical.dbo.all_totals 
SET
   fga_2 = '0.0' 
WHERE
   fga_2 = '';

--Clean names from all_totals
UPDATE all_totals SET Player = 'Alen Smailagic' WHERE Player = 'Alen Smailagić';
UPDATE all_totals SET Player = 'Boban Marjanovic' WHERE Player = 'Boban Marjanović';
UPDATE all_totals SET Player = 'Bogdan Bogdanovic' WHERE Player = 'Bogdan Bogdanović';
UPDATE all_totals SET Player = 'Davis Berta�ns' WHERE Player = 'Dāvis Bertāns';
UPDATE all_totals SET Player = 'Dzanan Musa' WHERE Player = 'Džanan Musa';
UPDATE all_totals SET Player = 'Dario Saric' WHERE Player = 'Dario Šarić';
UPDATE all_totals SET Player = 'Ersan Ilyasova' WHERE Player = 'Ersan İlyasova';
UPDATE all_totals SET Player = 'Juan Hernangomez' WHERE Player = 'Juan Hernangómez';
UPDATE all_totals SET Player = 'Luka Doncic' WHERE Player = 'Luka Dončić';
UPDATE all_totals SET Player = 'Marcus Morris Sr.' WHERE Player = 'Marcus Morris';
UPDATE all_totals SET Player = 'Timothe Luwawu-Cabarrot' WHERE Player = 'Timothé Luwawu-Cabarrot';
UPDATE all_totals SET Player = 'Vlatko Cancar' WHERE Player = 'Vlatko Čančar';
UPDATE all_totals SET Player = 'Willy Hernangomez' WHERE Player = 'Willy Hernangómez';
UPDATE all_totals SET Player = 'Zach Norvell Jr.' WHERE Player = 'Zach Norvell';
UPDATE all_totals SET Player = 'Alex Abrines' WHERE Player = 'Álex Abrines';
UPDATE all_totals SET Player = 'Angel Delgado' WHERE Player = 'Ángel Delgado';
UPDATE all_totals SET Player = 'Ante Zizic' WHERE Player = 'Ante Žižić';
UPDATE all_totals SET Player = 'Kiwane Garris' WHERE Player = 'Kiwane Lemorris Garris';

WITH bbref AS (
SELECT
	uniqueid,
	Player AS playername,
	SUBSTRING(Link,12,9) AS bbref_id,
	Season AS SeasonID,
	Tm,
	Pos AS position,
	Age,
	G,
	GS,
	MP,
	fgm_2,
	fgpercentage_2,
	fga_2,
	fgm_3,
	fgpercentage_3,
	fga_3,
	AST AS assists,
	BLK AS blocks,
	DRB AS drebounds,
	FG AS fieldgoalsmade,
	FGP AS fieldgoalpercentage,
	FGA AS fieldgoalattempts,
	FT AS freethrowsmade,
	FTA AS freethrowattempts,
	FTP AS freethrowpercentage,
	ORB AS orebounds,
	PF AS fouls,
	PTS AS points,
	STL AS steals,
	TOV AS turnovers,
	TRB AS totalrebounds,
	eFGP AS eFG
FROM
	all_totals
)
SELECT
	* INTO
		bbref_totals
	FROM 
		bbref
;
--Add blank column for later union
ALTER TABLE 
	bbref_totals
ADD
	nba_id varchar(50)
;
UPDATE
	bbref_totals
SET
	nba_id = ''
;

--Clean records with alternative names
UPDATE
	bbref_totals
SET 
	playername = 'Charles Vaughn'
WHERE
	playername = 'Chico Vaughn'
;
UPDATE
	bbref_totals
SET 
	playername = 'John Clemens'
WHERE
	playername = 'Barry Clemens'
;
UPDATE
	bbref_totals
SET 
	playername = 'Skal Labissiere'
WHERE
	playername = 'Skal Labissière'
;   --non-matching rebound totals prevent later join from functioning

--Clean empty string fields
UPDATE bbref_totals SET Age = '0.0' WHERE Age = '';
UPDATE bbref_totals SET G = '0.0' WHERE G = '';
UPDATE bbref_totals SET GS = '0.0' WHERE GS = '';
UPDATE bbref_totals SET MP = '0.0' WHERE MP = '';
UPDATE bbref_totals SET fgm_2 = '0.0' WHERE fgm_2 = '';
UPDATE bbref_totals SET fga_2 = '0.0' WHERE fga_2 = '';
UPDATE bbref_totals SET fgm_3 = '0.0' WHERE fgm_3 = '';
UPDATE bbref_totals SET fga_3 = '0.0' WHERE fga_3 = '';
UPDATE bbref_totals SET assists = '0.0' WHERE assists = '';
UPDATE bbref_totals SET blocks = '0.0' WHERE blocks = '';
UPDATE bbref_totals SET drebounds = '0.0' WHERE drebounds = '';
UPDATE bbref_totals SET fieldgoalsmade = '0.0' WHERE fieldgoalsmade = '';
UPDATE bbref_totals SET fieldgoalattempts = '0.0' WHERE fieldgoalattempts = '';
UPDATE bbref_totals SET freethrowsmade = '0.0' WHERE freethrowsmade = '';
UPDATE bbref_totals SET freethrowattempts = '0.0' WHERE freethrowattempts = '';
UPDATE bbref_totals SET orebounds = '0.0' WHERE orebounds = '';
UPDATE bbref_totals SET fouls = '0.0' WHERE fouls = '';
UPDATE bbref_totals SET points = '0.0' WHERE points = '';
UPDATE bbref_totals SET steals = '0.0' WHERE steals = '';
UPDATE bbref_totals SET turnovers = '0.0' WHERE turnovers = '';
UPDATE bbref_totals SET totalrebounds = '0.0' WHERE totalrebounds = '';

--CAST columns from bbref totals
WITH t2 AS (
SELECT
	uniqueid,
	playername,
	bbref_id,
	nba_id,
	SeasonID,
	Tm,
	position,
	CAST(Age AS dec(6,1)) AS Age,
	CAST(G AS dec(6,1)) AS G,
	CAST(GS AS dec(6,1)) AS GS,
	CAST(MP AS dec(6,1)) AS MP,
	CAST(fgm_2 AS dec(6,1)) AS fgm_2,
	CAST(fga_2 AS dec(6,1)) AS fga_2,
	CAST(fgm_3 AS dec(6,1)) AS fgm_3,
	CAST(fga_3 AS dec(6,1)) AS fga_3,
	CAST(assists AS dec(6,1)) AS assists,
	CAST(blocks AS dec(6,1)) AS blocks,
	CAST(drebounds AS dec(6,1)) AS drebounds,
	CAST(orebounds AS dec(6,1)) AS orebounds,
	CAST(totalrebounds AS dec(6,1)) AS totalrebounds,
	CAST(fieldgoalsmade AS dec(6,1)) AS fieldgoalsmade,
	CAST(fieldgoalattempts AS dec(6,1)) AS fieldgoalattempts,
	CAST(freethrowsmade AS dec(6,1)) AS freethrowsmade,
	CAST(freethrowattempts AS dec(6,1)) AS freethrowattempts,
	CAST(fouls AS dec(6,1)) AS fouls,
	CAST(points AS dec(6,1)) AS points,
	CAST(steals AS dec(6,1)) AS steals,
	CAST(turnovers AS dec(6,1)) AS turnovers
FROM
	bbref_totals
)
SELECT 
	* INTO
	bbref_totals_2
FROM
	t2
;

--Deduplicate nba dot com totals
WITH deduplicater AS (
SELECT 
	PLAYER_ID,
	PLAYER,
	TEAM,
	GP,
	MIN,
	FGM,
	FGA,
	FG_PCT,
	FG3M,
	FG3A,
	FG3_PCT,
	FTM,
	FTA,
	FT_PCT,
	OREB,
	DREB,
	REB,
	AST,
	STL,
	BLK,
	TOV,
	PF,
	PTS,
	EFF,
	AST_TOV,
	STL_TOV,
	Season,
	ROW_NUMBER () OVER (PARTITION BY PLAYER_ID, Season ORDER BY Season) AS record
FROM 
	totals
)
SELECT 
	* INTO
	totals_2
FROM
	deduplicater
WHERE
	record = 1
;

--Extract records for players with more than one team in a season, ommitted from totals,totals_2 (nba dot com) 
SELECT
	* INTO multi_team_players
FROM
	bbref_totals_2
	LEFT JOIN
		totals_2
	ON 
		SUBSTRING(SeasonID,3,2) = SUBSTRING(Season,6,2)
		AND CAST(points AS int) = CAST(PTS AS int)
		AND Tm = TEAM
		AND
		CASE 
		WHEN playername = PLAYER
		THEN 1
		WHEN playername != PLAYER
		AND SUBSTRING(playername,1,2) = SUBSTRING(bbref_id,6,2)
		AND CAST(G AS int) = CAST(GP AS int)
		AND CAST(points AS int) = CAST(PTS AS int)
		AND CAST(totalrebounds AS int) = CAST(REB AS int)
		AND CAST(assists AS int) = CAST(AST AS int)
		AND CAST(fouls AS int) = CAST(PF AS int)
		THEN 1
		ELSE 0 
		END = 1

WHERE 
	PLAYER IS NULL
;

--Cases where the join *did* work
SELECT
	* INTO joined_totals
FROM
	bbref_totals_2
	LEFT JOIN
		totals_2
	ON 
		SUBSTRING(SeasonID,3,2) = SUBSTRING(Season,6,2)
		AND CAST(points AS int) = CAST(PTS AS int)
		AND
		CASE 
		WHEN playername = PLAYER
		THEN 1
		WHEN playername != PLAYER
		AND SUBSTRING(Player,1,2) = SUBSTRING(bbref_id,6,2)
		AND CAST(G AS int) = CAST(GP AS int)
		AND CAST(points AS int) = CAST(PTS AS int)
		AND CAST(totalrebounds AS int) = CAST(REB AS int)
		AND CAST(assists AS int) = CAST(AST AS int)
		AND CAST(fouls AS int) = CAST(PF AS int)
		THEN 1
		ELSE 0 
		END = 1

WHERE 
	PLAYER IS NOT NULL
;

--Adding records for players ommitted from nba dot com due to playing for more than one team in a season
WITH omit AS (
SELECT
	playername,
	playername AS PLAYER,
	CAST(nba_id AS varchar(50)) AS PLAYER_ID,
	SeasonID AS Season,
	bbref_id,
	Tm AS TEAM,
	position,
	G AS GP,
	MP AS MIN,
	fieldgoalsmade AS FGM,
	fieldgoalattempts AS FGA,
	fgm_3 AS FG3M,
	fga_3 AS FG3A,
	freethrowsmade AS FTM,
	freethrowattempts AS FTA,
	orebounds AS OREB,
	drebounds AS DREB,
	totalrebounds AS REB,
	assists AS AST,
	steals AS STL,
	blocks AS BLK,
	turnovers AS TOV,
	fouls AS PF,
	points AS PTS,
	COUNT(Tm) OVER (PARTITION BY playername,SeasonID ORDER BY playername) AS numberofteams 
FROM 
	multi_team_players
)
SELECT 
	* INTO
	joined_totals_2
	FROM 
		omit
WHERE
	TEAM = 'TOT'

UNION ALL (
SELECT
	playername,
	Player,
	CAST(PLAYER_ID AS varchar(50)) AS PLAYER_ID,
	Season,
	bbref_id,
	TEAM,
	position,
	CAST(GP AS dec(6,1)) AS GP,
	CAST(MIN AS dec(6,1)) AS MIN,
	CAST(FGM AS dec(6,1)) AS FGM,
	CAST(FGA AS dec(6,1)) AS FGA,
	CAST(FG3M AS dec(6,1)) AS FG3M,
	CAST(FG3A AS dec(6,1)) AS FG3A,
	CAST(FTM AS dec(6,1)) AS FTM,
	CAST(FTA AS dec(6,1)) AS FTA,
	CAST(OREB AS dec(6,1)) AS OREB,
	CAST(DREB AS dec(6,1)) AS DREB,
	CAST(REB AS dec(6,1)) AS REB,
	CAST(AST AS dec(6,1)) AS AST,
	CAST(STL AS dec(6,1)) AS STL,
	CAST(BLK AS dec(6,1)) AS BLK,
	CAST(TOV AS dec(6,1)) AS TOV,
	CAST(PF AS dec(6,1)) AS PF,
	CAST(PTS AS dec(6,1)) AS PTS,
	COUNT(TEAM) OVER (PARTITION BY PLAYER,Season ORDER BY PLAYER) AS numberofteams
FROM 
	joined_totals 
)
;

--Add other records that were omitted despite playing for only one team during a season

WITH omit AS (
SELECT
	playername,
	playername AS PLAYER,
	CAST(nba_id AS varchar(50)) AS PLAYER_ID,
	SeasonID AS Season,
	Tm AS TEAM,
	bbref_id,
	position,
	G AS GP,
	MP AS MIN,
	fieldgoalsmade AS FGM,
	fieldgoalattempts AS FGA,
	fgm_3 AS FG3M,
	fga_3 AS FG3A,
	freethrowsmade AS FTM,
	freethrowattempts AS FTA,
	orebounds AS OREB,
	drebounds AS DREB,
	totalrebounds AS REB,
	assists AS AST,
	steals AS STL,
	blocks AS BLK,
	turnovers AS TOV,
	fouls AS PF,
	points AS PTS,
	COUNT(Tm) OVER (PARTITION BY playername,SeasonID ORDER BY playername) AS numberofteams 
FROM 
	multi_team_players
)
SELECT 
	* INTO
		joined_totals_3
	FROM 
		omit
WHERE
	numberofteams = 1

UNION ALL (
SELECT
	playername,
	Player,
	CAST(PLAYER_ID AS varchar(50)) AS PLAYER_ID,
	Season,
	TEAM,
	bbref_id,
	position,
	CAST(GP AS dec(6,1)) AS GP,
	CAST(MIN AS dec(6,1)) AS MIN,
	CAST(FGM AS dec(6,1)) AS FGM,
	CAST(FGA AS dec(6,1)) AS FGA,
	CAST(FG3M AS dec(6,1)) AS FG3M,
	CAST(FG3A AS dec(6,1)) AS FG3A,
	CAST(FTM AS dec(6,1)) AS FTM,
	CAST(FTA AS dec(6,1)) AS FTA,
	CAST(OREB AS dec(6,1)) AS OREB,
	CAST(DREB AS dec(6,1)) AS DREB,
	CAST(REB AS dec(6,1)) AS REB,
	CAST(AST AS dec(6,1)) AS AST,
	CAST(STL AS dec(6,1)) AS STL,
	CAST(BLK AS dec(6,1)) AS BLK,
	CAST(TOV AS dec(6,1)) AS TOV,
	CAST(PF AS dec(6,1)) AS PF,
	CAST(PTS AS dec(6,1)) AS PTS,
	numberofteams
FROM 
	joined_totals_2
)
;

UPDATE 
	joined_totals_3
SET 
	Season = '1999-00'
WHERE 
	Season = '2000'
;

UPDATE 
	joined_totals_3
SET 
	Season = '2009-10'
WHERE 
	Season = '2010'
;

UPDATE 
	joined_totals_3
SET 
	Season = '19'+ (CONVERT(varchar,((CONVERT(int,Season))-1901)) + '-' + SUBSTRING(Season,3,2))
WHERE 
	Season LIKE '19__'
;

UPDATE 
	joined_totals_3
SET 
	Season = '200'+ (CONVERT(varchar,((CONVERT(int,Season))-2001)) + '-' + SUBSTRING(Season,3,2))
WHERE 
	Season LIKE '200_'
;

UPDATE 
	joined_totals_3
SET 
	Season = '20'+ (CONVERT(varchar,((CONVERT(int,Season))-2001)) + '-' + SUBSTRING(Season,3,2))
WHERE 
	Season LIKE '201_'
;

UPDATE 
	joined_totals_3
SET 
	Season = '2019-20'
WHERE 
	Season = '2020'
;

WITH dict AS (
SELECT 
	playername,
	bbref_id,
	PLAYER,
	PLAYER_ID,
	ROW_NUMBER() OVER (PARTITION BY playername,bbref_id,PLAYER,PLAYER_ID ORDER BY playername) AS u_row
FROM
	joined_totals_3
WHERE 
	PLAYER_ID != ''
)
SELECT 
	* INTO player_id_dict
FROM 
	dict
WHERE 
	u_row = 1
;

WITH rename AS (
SELECT
	playername AS br_name,
	bbref_id AS br_id,
	PLAYER AS nbaname,
	PLAYER_ID AS nbaid
FROM
	player_id_dict
)
SELECT
	* INTO joined_totals_4
FROM
	joined_totals_3
LEFT JOIN
	rename
	ON bbref_id = br_id
	OR PLAYER_ID = nbaid
;

DROP TABLE
	totals_2,
	bbref_totals,
	bbref_totals_2,
	joined_totals,
	joined_totals_2,
	joined_totals_3,
	multi_team_players
;
                              -- 2. Clean position labels
-----------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE NBA_historical.dbo.joined_totals_4 ADD realposition AS 
(
   CASE
      WHEN
         position = 'F-C' 
      THEN
         'PF' 
      WHEN
         position = 'G-F' 
      THEN
         'SF' 
      WHEN
         position = 'F' 
      THEN
         'PF' 
      WHEN
         position = 'G' 
      THEN
         'SG' 
      WHEN
         position = 'C-F' 
      THEN
         'C' 
      WHEN
         position = 'C-PF' 
      THEN
         'C' 
      WHEN
         position = 'C-SF' 
      THEN
         'SF' 
      WHEN
         position = 'F-G' 
      THEN
         'SF' 
      WHEN
         position = 'PF-C' 
      THEN
         'PF' 
      WHEN
         position = 'PF-SF' 
      THEN
         'PF' 
      WHEN
         position = 'PG-SF' 
      THEN
         'SF' 
      WHEN
         position = 'PG-SG' 
      THEN
         'PG' 
      WHEN
         position = 'SF-PF' 
      THEN
         'SF' 
      WHEN
         position = 'SF-PG' 
      THEN
         'SF' 
      WHEN
         position = 'SF-SG' 
      THEN
         'SF' 
      WHEN
         position = 'SG-PF' 
      THEN
         'PF' 
      WHEN
         position = 'SG-PG' 
      THEN
         'SG' 
      WHEN
         position = 'SG-SF' 
      THEN
         'SG' 
      ELSE
         position 
   END
)
;
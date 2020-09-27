--I. Clean Original CSV Imports
   -- A. Clean Box Score Records
      --1. Clean empty strings
-------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE
   all_boxes 
SET
   FGM = NULL 
WHERE
   FGM = '';
UPDATE
   all_boxes 
SET
   FGA = NULL
WHERE
   FGA = '';
UPDATE
   all_boxes 
SET
   FTM = NULL
WHERE
   FTM = '';
UPDATE
   all_boxes 
SET
   FTA = NULL 
WHERE
   FTA = '';
UPDATE
   all_boxes 
SET
   FG3M = NULL
WHERE
   FG3M = '';
UPDATE
   all_boxes 
SET
   FG3A = NULL
WHERE
   FG3A = '';
UPDATE
   all_boxes 
SET
   OREB = NULL
WHERE
   OREB = '';
UPDATE
   all_boxes 
SET
   DREB = NULL
WHERE
   DREB = '';
UPDATE
   all_boxes 
SET
   REB = NULL 
WHERE
   REB = '';
UPDATE
   all_boxes 
SET
   AST = NULL
WHERE
   AST = '';
UPDATE
   all_boxes 
SET
   STL = NULL 
WHERE
   STL = '';
UPDATE
   all_boxes 
SET
   BLK = NULL
WHERE
   BLK = '';
UPDATE
   all_boxes 
SET
   TOV = NULL
WHERE
   TOV = '';
UPDATE
   all_boxes 
SET
   PF = NULL
WHERE
   PF = '';
UPDATE
   all_boxes 
SET
   PTS = NULL
WHERE
   PTS = '';
UPDATE
   all_boxes 
SET
   PLUS_MINUS = NULL 
WHERE
   PLUS_MINUS = '';
UPDATE
   all_boxes 
SET
   FGM = NULL 
WHERE
   FGM LIKE '%righ%';
UPDATE
	all_boxes
SET
	MIN = NULL
WHERE
	MIN LIKE '%"'
	OR PLUS_MINUS = ',,'
	OR PLUS_MINUS = ','
;
UPDATE
	all_boxes
SET
	PLUS_MINUS = NULL
WHERE
	PLUS_MINUS = ',,'
	OR PLUS_MINUS = ','
;
      -- 2. Cast values as decimals 
---------------------------------------------------------------------------------------------------------------------------------------------
SELECT
   "GAME_ID",
   TEAM_ID,
   TEAM_ABBREVIATION,
   TEAM_CITY,
   PLAYER_NAME,
   PLAYER_ID,
   START_POSITION,
   COMMENT,
   MIN,
   CAST(FGM AS dec(6, 1)) AS FGM,
   CAST(FGA AS dec(6, 1)) AS FGA,
   CAST(FG3M AS dec(6, 1)) AS FG3M,
   CAST(FG3A AS dec(6, 1)) AS FG3A,
   CAST(FTM AS dec(6, 1)) AS FTM,
   CAST(FTA AS dec(6, 1)) AS FTA,
   CAST(OREB AS dec(6, 1)) AS OREB,
   CAST(DREB AS dec(6, 1)) AS DREB,
   CAST(REB AS dec(6, 1)) AS REB,
   CAST(AST AS dec(6, 1)) AS AST,
   CAST(STL AS dec(6, 1)) AS STL,
   CAST(BLK AS dec(6, 1)) AS BLK,
   CAST(TOV AS dec(6, 1)) AS TOV,
   CAST(PF AS dec(6, 1)) AS PF,
   CAST(PTS AS dec(6, 1)) AS PTS,
   CAST((TRIM(',' FROM PLUS_MINUS)) AS dec(6,1)) AS PLUS_MINUS 
INTO 
   box_scores 
FROM
   all_boxes;

ALTER TABLE
   box_scores
ADD 
   MISSES
      AS (FGA - FGM),
   FT_MISSES
      AS (FTA - FTM),
   FG2M
      AS (
		CASE
		WHEN FG3M IS NOT NULL
		THEN
			(FGM - FG3M)
		ELSE
			FGM
		END),
   FG2A
      AS (
		CASE
		WHEN FG3A IS NOT NULL
		THEN
			(FGA - FG3A)
		ELSE
			FGA
		END),
   FG2PERCENT
      AS (CASE
         WHEN (FGA-FG3A) > 0
		 AND FG3A IS NOT NULL
         THEN ((FGM-FG3M)/(FGA-FG3A))
         ELSE (FGM/FGA)
         END),
   FG3PERCENT
      AS  (CASE
         WHEN FG3A > 0
         THEN (FG3M/FG3A)
         ELSE NULL
         END),
   FGPERCENT
      AS (CASE
         WHEN FGA > 0
         THEN (FGM/FGA)
         ELSE NULL
         END),
   EFG 
      AS (CASE
         WHEN FGA > 0
		 AND FG3M IS NOT NULL
         THEN ((FGM+FG3M)/FGA)
         ELSE (FGM/FGA)
         END),
   TS 
      AS (CASE
         WHEN FGA+(0.44*FTM) > 0
         THEN (PTS/(FGA+(0.44*FTM)))
         ELSE NULL
         END)
;
      -- 3. Name seasons according to YYYY-YY convention, parse minutes
--------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE box_scores 
   ADD SEASON_ID 
      AS (
   CASE
      WHEN 
         GAME_ID LIKE '21%' 
         OR GAME_ID LIKE '209%'
      THEN
         '20' + (SUBSTRING(GAME_ID, 2, 2)) + '-' + (CAST(CAST(SUBSTRING(GAME_ID, 2, 2) AS int) + 1 AS varchar(50)))
      WHEN
         GAME_ID LIKE '20%' AND GAME_ID NOT LIKE '209%'
      THEN 
         '20' + (SUBSTRING(GAME_ID, 2, 2)) + '-0' + (CAST(CAST(SUBSTRING(GAME_ID, 2, 2) AS int) + 1 AS varchar(50)))
      WHEN
         GAME_ID LIKE '299%'
      THEN
         '1999-00' 
      ELSE
         '19' + (SUBSTRING(GAME_ID, 2, 2)) + '-' + (CAST(CAST(SUBSTRING(GAME_ID, 2, 2) AS int) + 1 AS varchar(50)))
      END   
)
,
   MINUTES
      AS (
   CASE
   WHEN
      MIN LIKE '__:%' 
   THEN
      ((CAST(SUBSTRING(MIN, 1, 2) AS float)) + ((CAST(SUBSTRING(MIN, 4, 2)AS float))/60)) 
   WHEN
      MIN LIKE '_:%' 
   THEN
      ((CAST(SUBSTRING(MIN, 1, 1) AS float)) + ((CAST(SUBSTRING(MIN, 3, 2)AS float))/60))
   WHEN
     MIN LIKE '%"' 
     OR MIN LIKE '%"""'
     OR MIN LIKE ' %'
   THEN 
     NULL
   WHEN
      MIN = '' 
   THEN
      NULL
   WHEN
      MIN NOT LIKE '%:%'
   THEN
      CAST((MIN) AS int)   
   END
)
,   
   UNIQUE_TEAM 
      AS (TEAM_ABBREVIATION + '_' + (SUBSTRING(GAME_ID, 2, 2)))
;

GO
---------------------------------------------------------------------------------------------------------------------------------
                                                   --box_scores COMPLETED
---------------------------------------------------------------------------------------------------------------------------------
   -- B. Clean season totals records
      --1. Delete incorrectly delimited records
----------------------------------------------------------------------------------------------------------------------------------
DELETE
FROM
   totals 
WHERE
   GP LIKE 'B%';
DELETE
FROM
   totals 
WHERE
   GP LIKE 'P%';
DELETE
FROM
   totals 
WHERE
   GP LIKE 'D%';
      -- 2. Clean empty records
--------------------------------------------------------------------------------------------------------------------------------------
UPDATE
   totals 
SET
   FGM = NULL
WHERE
   FGM = '';
UPDATE
   totals 
SET
   FGA = NULL
WHERE
   FGA = '';
UPDATE
   totals 
SET
   FTM = NULL
WHERE
   FTM = '';
UPDATE
   totals 
SET
   FTA = NULL
WHERE
   FTA = '';
UPDATE
   totals 
SET
   FG3M = NULL
WHERE
   FG3M = '';
UPDATE
   totals 
SET
   FG3A = NULL
WHERE
   FG3A = '';
UPDATE
   totals 
SET
   OREB = NULL
WHERE
   OREB = '';
UPDATE
   totals 
SET
   DREB = NULL
WHERE
   DREB = '';
UPDATE
   totals 
SET
   REB = NULL
WHERE
   REB = '';
UPDATE
   totals 
SET
   AST = NULL
WHERE
   AST = '';
UPDATE
   totals 
SET
   STL = NULL
WHERE
   STL = '';
UPDATE
   totals 
SET
   BLK = NULL
WHERE
   BLK = '';
UPDATE
   totals 
SET
   TOV = NULL
WHERE
   TOV = '';
UPDATE
   totals 
SET
   PF = NULL
WHERE
   PF = '';
UPDATE
   totals 
SET
   PTS = NULL
WHERE
   PTS = '';
UPDATE
   totals 
SET
   AST_TOV = NULL
WHERE
   AST_TOV = '';
UPDATE
   totals 
SET
   STL_TOV = NULL
WHERE
   STL_TOV = '';

      -- 3. Cast totals as decimals
-----------------------------------------------------------------------------------------------------------------------------------------
WITH t1 AS (
SELECT
	PLAYER_ID,
	PLAYER_NAME AS PLAYER,
	SEASON_ID AS SEASON,
	TEAM_ID,
	TEAM_ABBREVIATION AS TEAM,
	COUNT(GAME_ID) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS GP,
	SUM(MINUTES) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS MP,
	(SUM(MINUTES) OVER (PARTITION BY TEAM_ID,SEASON_ID) / 5) AS TEAM_MINUTES,
	SUM(PTS) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS PTS,
	SUM(FGM) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS FGM,
	SUM(FGA) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS FGA,
	SUM(FG3M) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS FG3M,
	SUM(FG3A) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS FG3A,
	SUM(FTM) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS FTM,
	SUM(FTA) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS FTA,
	SUM(OREB) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS OREB,
	SUM(DREB) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS DREB,
	SUM(REB) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS REB,
	SUM(AST) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS AST,
	SUM(TOV) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS TOV,
	SUM(STL) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS STL,
	SUM(BLK) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS BLK,
	SUM(PF) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS PF,
	ROW_NUMBER() OVER (PARTITION BY PLAYER_ID,SEASON_ID ORDER BY SEASON_ID) AS player_row
FROM	
	box_scores
)
SELECT
	* INTO
		totals2
FROM
	t1
WHERE
	 PLAYER_ROW = 1
;
GO

	  -- 4. Verification for season totals
----------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [verifying_totals] AS
SELECT
	*
FROM
	totals2
		LEFT OUTER JOIN 
			(
SELECT
	PLAYER_ID AS ID,
	PLAYER AS NAME,
	TEAM AS TEAM_NAME,
	GP AS GAMES_PLAYED,
	MIN,
	FGM AS TOT_FGM,
	FGA AS TOT_FGA,
	FG_PCT,
	FG3M AS TOT_FG3M,
	FG3A AS TOT_FG3A,
	FG3_PCT,
	FTM AS TOT_FTM,
	FTA AS TOT_FTA,
	FT_PCT,
	OREB AS TOT_OREB,
	DREB AS TOT_DREB,
	REB AS TOT_REB,
	AST AS TOT_AST,
	STL AS TOT_STL,
	BLK AS TOT_BLK,
	TOV AS TOT_TOV,
	PF AS TOT_PF,
	PTS AS TOT_PTS,
	EFF,
	AST_TOV,
	STL_TOV,
	Season AS YEAR,
	ROW_NUMBER() OVER (PARTITION BY PLAYER_ID,Season ORDER BY PLAYER_ID) AS t_row
FROM
	totals
) t
		ON
			PLAYER_ID = ID
			AND SEASON = YEAR
;
GO

      -- 4. Calculate percentages, per game, per minute
--------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	PLAYER_ID,
	PLAYER,
	SEASON,
	TEAM_ID,
	TEAM,
	TEAM_MINUTES,
	PTS,
	(
	CASE
	WHEN MP < MIN
	THEN MIN
	ELSE MP
	END) AS MP,
	GP,
	(
	CASE
	WHEN FGM < TOT_FGM
	THEN TOT_FGM
	ELSE FGM
	END) AS FGM,
	(
	CASE
	WHEN FGA < TOT_FGA
	THEN TOT_FGA
	ELSE FGA 
	END) AS FGA,
	(
	CASE
	WHEN FG3M < TOT_FG3M
	THEN TOT_FG3M
	ELSE FG3M
	END) AS FG3M,
	(
	CASE
	WHEN FG3A < TOT_FG3A
	THEN TOT_FG3A
	ELSE FG3A
	END) FG3A,
	(
	CASE
	WHEN FTM < TOT_FTM
	THEN TOT_FTM
	ELSE FTM
	END) AS FTM,
	(
	CASE
	WHEN FTA < TOT_FTA
	THEN TOT_FTA
	ELSE FTA
	END) AS FTA,
	(
	CASE
	WHEN OREB < TOT_OREB
	THEN TOT_OREB
	ELSE OREB
	END) AS OREB,
	(
	CASE
	WHEN DREB < TOT_DREB
	THEN TOT_DREB
	ELSE DREB
	END) AS DREB,
	(
	CASE
	WHEN REB < TOT_REB
	THEN TOT_REB
	ELSE REB
	END) AS REB,
	(
	CASE
	WHEN AST < TOT_AST
	THEN TOT_AST
	ELSE AST
	END) AS AST,
	(
	CASE
	WHEN TOV < TOT_TOV
	THEN TOT_TOV
	ELSE TOV
	END) AS TOV,
	(
	CASE
	WHEN STL < TOT_STL
	THEN TOT_STL
	ELSE STL
	END) AS STL,
	(
	CASE
	WHEN BLK < TOT_BLK
	THEN TOT_BLK
	ELSE BLK
	END) AS BLK,
	(
	CASE
	WHEN PF < TOT_PF
	THEN TOT_PF
	ELSE PF
	END) AS PF
INTO
	totals2b
FROM
	verifying_totals
;

ALTER TABLE
   totals2b
ADD 
   MISSES
      AS (FGA - FGM),
   FT_MISSES
      AS (FTA - FTM),
   FG2M
      AS (
	  CASE 
	  WHEN FG3M IS NOT NULL
	  THEN
		(FGM - FG3M)
	  ELSE 
		FGM
	  END),
   FG2A
      AS (
	  CASE 
	  WHEN FG3A IS NOT NULL
	  THEN
		(FGA - FG3A)
	  ELSE 
		FGA
	  END),
   FG2PERCENT
      AS (CASE
         WHEN (FGA-FG3A) > 0
		 AND FG3A IS NOT NULL
         THEN ((FGM-FG3M)/(FGA-FG3A))
         ELSE (FGM/FGA)
         END),
   FG3PERCENT
      AS  (CASE
         WHEN FG3A > 0
         THEN (FG3M/FG3A)
         ELSE NULL
         END),
   FGPERCENT
      AS (CASE
         WHEN FGA > 0
         THEN (FGM/FGA)
         ELSE NULL
         END),
	FTPERCENT
      AS (CASE
         WHEN FTA > 0
         THEN (FTM/FTA)
         ELSE NULL
         END),
   EFG 
      AS (CASE
         WHEN FGA > 0
		 AND FG3M IS NOT NULL
         THEN ((FGM+FG3M)/FGA)
         ELSE (FGM/FGA)
         END),
   TS 
      AS (CASE
         WHEN FGA+(0.44*FTM) > 0
         THEN ((PTS/(FGA+(0.44*FTM)))/2)
         ELSE NULL
         END)
;
GO

SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;
SELECT
   PLAYER_ID,
   PLAYER,
   TEAM,
   TEAM_ID,
   SEASON,
   GP,
   MP,
   PTS,
   FGM,
   FGA,
   FG2M,
   FG2A,
   FG3M,
   FG3A,
   FTM,
   FTA,
   OREB,
   DREB,
   REB,
   AST,
   TOV,
   STL,
   BLK,
   PF,
   MISSES,
   FT_MISSES,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   FTPERCENT,
   EFG,
   TS,
   ('NBA') AS LEAGUE,
   (CASE	
		WHEN
			TEAM_MINUTES >= 3936
			AND TEAM_MINUTES < 5000
		THEN	
			TEAM_MINUTES
		WHEN 
			TEAM_MINUTES < 3936
		THEN 
			(MAX(GP) OVER (PARTITION BY TEAM,SEASON)*48)
		WHEN
			TEAM_MINUTES > 4000
		THEN
			4000
		ELSE	
			NULL
		END
	) AS TEAM_MINUTES
		INTO
			totals3
FROM
	totals2b
;
GO

--Per game values
ALTER TABLE
   totals3
ADD
   ppg AS 
(
   PTS / GP
)
,
rpg AS 
(
   REB / GP
)
,
apg AS 
(
   AST / GP
)
,
spg AS 
(
   STL / GP
)
,
bpg AS 
(
   BLK / GP
)
,
tpg AS 
(
   TOV / GP
)
,
pfpg AS 
(
   PF / GP
)
,
mpg AS 
(
   MP / GP
)
,
fgmpg AS 
(
   FGM / GP
)
,
fgapg AS 
(
   FGA / GP
)
,
fg3mpg AS 
(
   FG3M / GP
)
,
fg3apg AS 
(
   FG3A / GP
)
,
ftmpg AS 
(
   FTM / GP
)
,
ftapg AS 
(
   FTA / GP
)
,
orebpg AS 
(
   OREB / GP
)
,
drebpg AS 
(
   DREB / GP
),
missespg AS 
(
   (FGA - FGM) / GP
),
ftmissespg AS
(
   (FTA - FTM) / GP
),
fg2mpg AS
(
   FG2M/GP
),
fg2apg AS
(
   FG2A/GP
)
,
-- per-minute figures
ppm AS 
(
   PTS / MP
)
,
rpm AS 
(
   REB / MP
)
,
apm AS 
(
   AST / MP
)
,
spm AS 
(
   STL / MP
)
,
bpm AS 
(
   BLK / MP
)
,
tpm AS 
(
   TOV / MP
)
,
pfpm AS 
(
   PF / MP
)
,
mpm AS 
(
   MP / MP
)
,
fgmpm AS 
(
   FGM / MP
)
,
fgapm AS 
(
   FGA / MP
)
,
fg3mpm AS 
(
   FG3M / MP
)
,
fg3apm AS 
(
   FG3A / MP
)
,
ftmpm AS 
(
   FTM / MP
)
,
ftapm AS 
(
   FTA / MP
)
,
orebpm AS 
(
   OREB / MP
)
,
drebpm AS 
(
   DREB / MP
),
missespm AS 
(
   (FGA - FGM) / MP
),
ftmissespm AS
(
   (FTA - FTM) / MP
),
fg2mpm AS
(
   FG2M/MP
),
fg2apm AS
(
   FG2A/MP
)
;

UPDATE
	totals3
SET 
	TEAM_MINUTES = 4000
WHERE
	TEAM_MINUTES > 4000
;
GO

	  -- 5. Filling nulls in box scores with estimated values
--------------------------------------------------------------------------------------------------------------------------
GO
CREATE VIEW [boxes_with_estimates_replacing_nulls] AS
SELECT
	PLAYER_ID,
	PLAYER_NAME,
	TEAM_ABBREVIATION,
	TEAM_ID,
	SEASON_ID,
	GAME_ID,
	('NBA') AS LEAGUE,
	PTS,
	(CASE
	WHEN	
		MINUTES IS NULL AND PTS IS NOT NULL
	THEN mpg
	ELSE MINUTES
	END) AS MINUTES,
		(CASE
	WHEN	
		FGM IS NULL AND PTS IS NOT NULL AND PTS > 0 AND FTM IS NOT NULL AND FTM != PTS
	THEN fgmpg
	ELSE FGM
	END) AS FGM,
		(CASE
	WHEN	
		FGA IS NULL AND PTS IS NOT NULL
	THEN fgapg
	ELSE FGA
	END) AS FGA,
	FG3M,
	FG3A,
		(CASE
	WHEN	
		FTM IS NULL AND PTS IS NOT NULL AND (FGM*2) != PTS
	THEN ftmpg
	ELSE FTM
	END) AS FTM,
		(CASE
	WHEN	
		FTA IS NULL AND PTS IS NOT NULL AND (FGM*2) != PTS
	THEN ftapg
	ELSE FTA
	END) AS FTA,
		(CASE
	WHEN	
		OREB IS NULL AND REB IS NOT NULL AND orebpg IS NOT NULL
	THEN orebpg
	ELSE OREB
	END) AS OREB,
		(CASE
	WHEN	
		DREB IS NULL AND REB IS NOT NULL AND drebpg IS NOT NULL
	THEN drebpg
	ELSE DREB
	END) AS DREB,
		(CASE
	WHEN	
		REB IS NULL AND PTS IS NOT NULL
	THEN rpg
	ELSE REB
	END) AS REB,
		(CASE
	WHEN	
		AST IS NULL AND PTS IS NOT NULL
	THEN apg
	ELSE AST
	END) AS AST,
		(CASE
	WHEN	
		TOV IS NULL AND PTS IS NOT NULL
	THEN tpg
	ELSE TOV
	END) AS TOV,
		(CASE
	WHEN	
		STL IS NULL AND PTS IS NOT NULL
	THEN spg
	ELSE STL
	END) AS STL,
		(CASE
	WHEN	
		BLK IS NULL AND PTS IS NOT NULL
	THEN bpg
	ELSE BLK
	END) AS BLK,
		(CASE
	WHEN	
		PF IS NULL AND PTS IS NOT NULL
	THEN pfpg
	ELSE PF
	END) AS PF,
   PLUS_MINUS,
   FG2M,
   FG2A,
   MISSES,
   FT_MISSES,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   (FTM/FTA) AS FTPERCENT,
   EFG,
   TS
FROM 
	(
   SELECT
	   *
   FROM
	   box_scores
   )
   t2
		LEFT JOIN
			(
	      SELECT
            PLAYER_ID AS P_NUMBER,
            PLAYER AS P_NAME,
            TEAM AS T_NAME,
            TEAM_ID AS T_NUMBER,
            SEASON,
            GP,
            MP,
            ppg,
            rpg,
            apg,
            spg,
            bpg,
            tpg,
            pfpg,
            mpg,
            fgmpg,
            fgapg,
            fg3mpg,
            fg3apg,
            ftmpg,
            ftapg,
            orebpg,
            drebpg,
            missespg,
            ftmissespg,
            fg2mpg,
            fg2apg,
            ROW_NUMBER() OVER (PARTITION BY PLAYER_ID,SEASON ORDER BY SEASON) AS t1row
	      FROM
		      totals3
         )
         t1
				ON PLAYER_ID = P_NUMBER
				AND SEASON_ID = SEASON
WHERE t1row = 1
GO
;

      -- 5. Pace figures
--------------------------------------------------------------------------------------------------------------------------------------------
-- integrate CASE WHEN for seasons without OREB
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;
WITH t1 AS (
SELECT
	TEAM,
	SEASON,
	TEAM_MINUTES,
	ROW_NUMBER() OVER (PARTITION BY TEAM,SEASON ORDER BY TEAM) AS row_1
FROM
	totals3
),
t2 AS (
SELECT
   TEAM_ABBREVIATION AS t1team,
   TEAM_ID AS t1teamid,
   SEASON_ID AS t1season,
   LEAGUE AS t1league,
   PTS,
   FGA,
   FTA,
   OREB,
   REB,
   TOV,
   MINUTES
FROM
   boxes_with_estimates_replacing_nulls
),
	t3 AS (
SELECT
	TEAM,
	SEASON,
	TEAM_MINUTES,
	t1league AS LEAGUE,
   (CASE 
	WHEN 
		SUM(TOV) OVER (PARTITION BY TEAM,SEASON) > 50
		AND SUM(OREB) OVER (PARTITION BY TEAM,SEASON) > 50
		AND CAST(SUBSTRING(SEASON,1,4) AS int) > 1977
   THEN
		SUM(FGA + TOV + (FTA*0.4) - OREB) OVER (PARTITION BY TEAM,SEASON)
	WHEN 
		SUM(TOV) OVER (PARTITION BY TEAM,SEASON) IS NULL 
		AND SUM(FGA) OVER (PARTITION BY TEAM,SEASON) IS NOT NULL  -- next to cut 
		AND SUM(OREB) OVER (PARTITION BY TEAM,SEASON) > 50
		AND CAST(SUBSTRING(SEASON,1,4) AS int) > 1977
	THEN
		SUM(FGA + (0.159*(FGA+(0.44*FTA))) +(FTA*0.4) - OREB) OVER (PARTITION BY TEAM,SEASON)	
	WHEN  
		SUM(TOV) OVER (PARTITION BY TEAM,SEASON) IS NULL  --next to cut
		AND SUM(OREB) OVER (PARTITION BY TEAM,SEASON) IS NULL
		AND SUM(REB) OVER (PARTITION BY TEAM,SEASON) > 2400
		AND SUM(FTA) OVER (PARTITION BY TEAM,SEASON) IS NOT NULL
		AND SUM(FGA) OVER (PARTITION BY TEAM,SEASON) > 4800
	THEN
		SUM(FGA + (0.159*(FGA+(0.44*FTA))) +(FTA*0.4) - (0.3*REB)) OVER (PARTITION BY TEAM,SEASON)
	WHEN 
		SUM(FTA) OVER (PARTITION BY TEAM,SEASON) IS NULL
		AND SUM(REB) OVER (PARTITION BY TEAM,SEASON) IS NOT NULL
		AND SUM(FGA) OVER (PARTITION BY TEAM,SEASON) > 4800
	THEN
		SUM(FGA + (0.148*PTS) + (0.266*PTS) - (0.3*REB)) OVER (PARTITION BY TEAM,SEASON)
	WHEN
		SUM(FTA) OVER (PARTITION BY TEAM,SEASON) IS NULL
		AND SUM(REB) OVER (PARTITION BY TEAM,SEASON) IS NOT NULL
	THEN
		SUM((0.825*PTS) + (0.148*PTS) + (0.266*PTS) - (0.3*REB)) OVER (PARTITION BY TEAM,SEASON)
	ELSE
		SUM((0.825*PTS) + (0.148*PTS) + (0.266*PTS) - (0.122*PTS)) OVER (PARTITION BY TEAM,SEASON)		
	END
   )	AS OffPoss,
   SUM(MINUTES) OVER (PARTITION BY t1league) AS all_minutes,
   SUM(MINUTES) OVER (PARTITION BY TEAM,SEASON) AS TeamMin,
   ROW_NUMBER () OVER (PARTITION BY TEAM,SEASON ORDER BY SEASON) AS row_num
FROM
   t2
		LEFT JOIN	
			t1
				ON
					t1team = TEAM 
					AND t1season = SEASON
WHERE
	row_1 = 1
)
SELECT
	* INTO
		team_pace
FROM
	t3
WHERE
	row_num = 1
;

SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;
WITH
	t1 AS (
SELECT
   TEAM AS t1team,
   SEASON AS t1season,
   LEAGUE AS t1league,
   COUNT (TEAM) OVER (PARTITION BY SEASON) AS count_teams,
   COUNT (TEAM) OVER (PARTITION BY LEAGUE) AS count_all_teams,
   ROW_NUMBER() OVER (PARTITION BY SEASON ORDER BY SEASON) AS t1_row
FROM	
	totals3
GROUP BY
	LEAGUE,
	SEASON,
	TEAM
)
,
	t2 AS (
SELECT
   SEASON AS t2season,
   LEAGUE AS t2league,
   TEAM AS t2team,
   (SUM(OffPoss) OVER (PARTITION BY SEASON) / count_teams) AS LgOffPoss,
   (((SUM(OffPoss) OVER (PARTITION  BY SEASON)) / (SUM(TEAM_MINUTES) OVER (PARTITION BY SEASON)))*48) AS LgOffPace,
   ((SUM(OffPoss) OVER (PARTITION  BY SEASON)) / (SUM(TEAM_MINUTES) OVER (PARTITION BY SEASON))) AS LgOffPossPerMin,
   ROW_NUMBER() OVER (PARTITION BY SEASON ORDER BY SEASON) AS t2_row
FROM
	team_pace
		LEFT JOIN
			t1
				ON t1season = SEASON
WHERE
	t1_row = 1
)
,
	t3 AS (
SELECT
	LEAGUE AS t3league,
	SUM(OffPoss) OVER (PARTITION BY LEAGUE) AS AllTimeOffPoss,
	(SUM(OffPoss) OVER (PARTITION BY LEAGUE) / (all_minutes/5)) AS AllTimeOffPossPerMin,
	(SUM(OffPoss) OVER (PARTITION BY LEAGUE) / (all_minutes/5)*48) AS AllTimeOffPace,
	ROW_NUMBER () OVER (PARTITION BY LEAGUE ORDER BY LEAGUE) AS t3_row
FROM
	team_pace
),
	t4 AS (
SELECT
	TEAM AS t4team,
	SEASON AS t4season,
	all_minutes,
	TeamMin,
	OffPoss,
	(OffPoss/TEAM_MINUTES) AS OffPossPerMin,
	(OffPoss/TEAM_MINUTES*48) AS OffPace
FROM
	team_pace
		LEFT JOIN	
			t1
				ON TEAM = t1team
				AND SEASON = t1season
)
SELECT
	* INTO
		totals4
FROM
	totals3
		LEFT JOIN
			t1
				ON TEAM = t1team
				AND SEASON = t1season
					LEFT JOIN	
						t2
							ON t1season = t2season
							AND t1team = t2team
								LEFT JOIN	
									t3	
										ON totals3.LEAGUE = t3league
											LEFT JOIN	
												t4
													ON TEAM = t4team
													AND SEASON = t4season
WHERE
	t3_row = 1
;
GO

      -- 6. Calculate per possession figures
---------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE totals4 
   ADD 
ppp AS 
(
   PTS / (OffPossPerMin*MP)
)
,
rpp AS 
(
   REB / (OffPossPerMin*MP)
)
,
app AS 
(
   AST / (OffPossPerMin*MP)
)
,
spp AS 
(
   STL / (OffPossPerMin*MP)
)
,
bpp AS 
(
   BLK / (OffPossPerMin*MP)
)
,
tpp AS 
(
   TOV / (OffPossPerMin*MP)
)
,
pfpp AS 
(
   PF / (OffPossPerMin*MP)
)
,
fgmpp AS 
(
   FGM / (OffPossPerMin*MP)
)
,
fgapp AS 
(
   FGA / (OffPossPerMin*MP)
)
,
fg3mpp AS 
(
   FG3M / (OffPossPerMin*MP)
)
,
fg3app AS 
(
   FG3A / (OffPossPerMin*MP)
)
,
ftmpp AS 
(
   FTM / (OffPossPerMin*MP)
)
,
ftapp AS 
(
   FTA / (OffPossPerMin*MP)
)
,
orebpp AS 
(
   OREB / (OffPossPerMin*MP)
)
,
drebpp AS 
(
   DREB / (OffPossPerMin*MP)
),
missespp AS 
(
   MISSES / (OffPossPerMin*MP)
),
ftmissespp AS
(
   FT_MISSES / (OffPossPerMin*MP)
),
fg2mpp AS
(
   FG2M / (OffPossPerMin*MP)
),
fg2app AS
(
   FG2A / (OffPossPerMin*MP)
),
UNIQUE_TEAM_ID AS
(
   TEAM + '_' + (SUBSTRING(SEASON,3,2))
),
FT_PERCENT AS
(
	FTM/FTA
)
;

DROP TABLE
	totals2,
	totals2b
;
GO
      --7. Create views for per game, per minute, per possession
----------------------------------------------------------------------------------------------------------------------------------------
--per game view
CREATE VIEW [per_game] AS
SELECT
   PLAYER_ID,
   PLAYER,
   TEAM,
   SEASON,
   GP,
   MP,
   ppg,
   fgmpg,
   fgapg,
   fg2mpg,
   fg2apg,
   fg3mpg,
   fg3apg,
   ftmpg,
   ftapg,
   orebpg,
   drebpg,
   rpg,
   apg,
   tpg,
   spg,
   bpg,
   pfpg,
   missespg,
   ftmissespg,
   FGPERCENT AS FG_PERCENT,
   FG2PERCENT AS FG2_PERCENT,
   FG3PERCENT AS FG3_PERCENT,
   FT_PERCENT AS FT_PERCENT,
   EFG,
   TS
FROM
   totals4
;
GO

--per minute view
CREATE VIEW [per_minute] AS
SELECT
   PLAYER_ID,
   PLAYER,
   TEAM,
   SEASON,
   GP,
   MP,
   ppg,
   fgmpm,
   fgapm,
   fg2mpm,
   fg2apm,
   fg3mpm,
   fg3apm,
   ftmpm,
   ftapm,
   orebpm,
   drebpm,
   rpm,
   apm,
   tpm,
   spm,
   bpm,
   pfpm,
   missespm,
   ftmissespm,
   FGPERCENT AS FG_PERCENT,
   FG2PERCENT AS FG2_PERCENT,
   FG3PERCENT AS FG3_PERCENT,
   FT_PERCENT,
   EFG,
   TS
FROM
   totals4
;
GO

--per possession view
CREATE VIEW [per_possession] AS
SELECT
   PLAYER_ID,
   PLAYER,
   TEAM,
   SEASON,
   GP,
   MP,
   ppg,
   fgmpp,
   fgapp,
   fg2mpp,
   fg2app,
   fg3mpp,
   fg3app,
   ftmpp,
   ftapp,
   orebpp,
   drebpp,
   rpp,
   app,
   tpp,
   spp,
   bpp,
   pfpp,
   missespp,
   ftmissespp,
   FGPERCENT AS FG_PERCENT,
   FG2PERCENT AS FG2_PERCENT,
   FG3PERCENT AS FG3_PERCENT,
   (FTM/FTA) AS FT_PERCENT,
   EFG,
   TS
FROM
   totals4
;
GO

DROP TABLE
	team_pace;
----------------------------------------------------------------------------------------------------------------------------------------
                                                      --totals4 completed
---------------------------------------------------------------------------------------------------------------------------------------
   -- C. Collate position data from two sources
      -- 1. Clean bbref position table
--------------------------------------------------------------------------------------------------------------------------------------------
--Clear the deck to run code
DROP TABLE
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
   all_totals 
SET
   FG = NULL
WHERE
   FG = '';
UPDATE
   all_totals 
SET
   FGA = NULL
WHERE
   FGA = '';
UPDATE
   all_totals 
SET
   FT = NULL
WHERE
   FT = '';
UPDATE
   all_totals 
SET
   FTA = NULL
WHERE
   FTA = '';
UPDATE
   all_totals 
SET
   fgm_3 = NULL
WHERE
   fgm_3 = '';
UPDATE
   all_totals 
SET
   fga_3 = NULL
WHERE
   fga_3 = '';
UPDATE
   all_totals 
SET
   ORB = NULL
WHERE
   ORB = '';
UPDATE
   all_totals 
SET
   DRB = NULL
WHERE
   DRB = '';
UPDATE
   all_totals 
SET
   TRB = NULL
WHERE
   TRB = '';
UPDATE
   all_totals 
SET
   AST = NULL
WHERE
   AST = '';
UPDATE
   all_totals 
SET
   STL = NULL
WHERE
   STL = '';
UPDATE
   all_totals 
SET
   BLK = NULL
WHERE
   BLK = '';
UPDATE
   all_totals 
SET
   TOV = NULL
WHERE
   TOV = '';
UPDATE
   all_totals
SET
   PF = NULL
WHERE
   PF = '';
UPDATE
   all_totals 
SET
   PTS = NULL
WHERE
   PTS = '';
UPDATE
   all_totals 
SET
   fgm_2 = NULL 
WHERE
   fgm_2 = '';
UPDATE
   all_totals 
SET
   fga_2 = NULL
WHERE
   fga_2 = '';

--Clean names from all_totals which cannot be matched with stats
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

      --2. Clean master_player
-----------------------------------------------------------------------------------------------------------------------------------------------
--Handle players who have short names
--ALTER TABLE master_player 
   --ADD 
      --col varchar(50);
--GO

UPDATE master_player 
	SET col = SUBSTRING(bbref_player_link,12,8)
	WHERE LEN(bbref_player_link) = 24;
UPDATE master_player 
	SET col = SUBSTRING(bbref_player_link,12,7)
	WHERE LEN(bbref_player_link) = 23;
UPDATE master_player 
	SET col = SUBSTRING(bbref_player_link,12,6)
	WHERE LEN(bbref_player_link) = 22;
UPDATE master_player 
	SET col = SUBSTRING(bbref_player_link,12,5)
	WHERE LEN(bbref_player_link) = 21;

WITH subtable AS (
SELECT 
	SUBSTRING(bbref_player_link,12,9) as bbrefid,
	last_year AS height,
	player_id AS player_name,
	position AS nba_id_number,
	rookie_year AS simple_position,
	col,
	ROW_NUMBER () OVER (PARTITION BY bbref_player_link ORDER BY bbref_player_link) AS uniquerow
FROM master_player
)
SELECT 
	* INTO player_master_2
FROM subtable
;

UPDATE 
	player_master_2
	SET bbrefid = col 
	WHERE bbrefid != col
;

      --3. Clean totals from bbref
--------------------------------------------------------------------------------------------------------------------------------------------------
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
UPDATE bbref_totals SET Age = NULL WHERE Age = '';
UPDATE bbref_totals SET G = NULL WHERE G = '';
UPDATE bbref_totals SET GS = NULL WHERE GS = '';
UPDATE bbref_totals SET MP = NULL WHERE MP = '';
UPDATE bbref_totals SET fgm_2 = NULL WHERE fgm_2 = '';
UPDATE bbref_totals SET fga_2 = NULL WHERE fga_2 = '';
UPDATE bbref_totals SET fgm_3 = NULL WHERE fgm_3 = '';
UPDATE bbref_totals SET fga_3 = NULL WHERE fga_3 = '';
UPDATE bbref_totals SET assists = NULL WHERE assists = '';
UPDATE bbref_totals SET blocks = NULL WHERE blocks = '';
UPDATE bbref_totals SET drebounds = NULL WHERE drebounds = '';
UPDATE bbref_totals SET fieldgoalsmade = NULL WHERE fieldgoalsmade = '';
UPDATE bbref_totals SET fieldgoalattempts = NULL WHERE fieldgoalattempts = '';
UPDATE bbref_totals SET freethrowsmade = NULL WHERE freethrowsmade = '';
UPDATE bbref_totals SET freethrowattempts = NULL WHERE freethrowattempts = '';
UPDATE bbref_totals SET orebounds = NULL WHERE orebounds = '';
UPDATE bbref_totals SET fouls = NULL WHERE fouls = '';
UPDATE bbref_totals SET points = NULL WHERE points = '';
UPDATE bbref_totals SET steals = NULL WHERE steals = '';
UPDATE bbref_totals SET turnovers = NULL WHERE turnovers = '';
UPDATE bbref_totals SET totalrebounds = NULL WHERE totalrebounds = '';

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

WITH adjust AS (
SELECT 
	bbrefid,
	height,
	player_name,
	nba_id_number,
	simple_position,
	col,
	uniquerow
FROM player_master_2
)
SELECT 
	* INTO bbref_totals_3
FROM 
	bbref_totals_2 
LEFT JOIN 
	adjust 
	ON bbref_id = bbrefid
;

UPDATE bbref_totals_3 
SET 
   nba_id = nba_id_number 
WHERE 
   nba_id = '' 
   AND nba_id_number IS NOT NULL;

      -- 4. Clean nba dot com totals
-------------------------------------------------------------------------------------------------------------------------------------------
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

WITH adjust AS (
SELECT 
	bbrefid AS bbref_id_num,
	height AS ht,
	player_name AS name,
	nba_id_number AS nba_id_num,
	simple_position AS simpleposition,
	col AS col_,
	uniquerow AS ur
FROM player_master_2
)
SELECT 
	* INTO totals_3
FROM 
	totals_2 
LEFT JOIN 
	adjust 
	ON PLAYER_ID = nba_id_num
;

      -- 5. Join nba totals to bbref totals
-----------------------------------------------------------------------------------------------------------------------------------------------
--Extract records for players with more than one team in a season, ommitted from totals,totals_2 (nba dot com) 
SELECT 
	* INTO unjoined_players
FROM
	bbref_totals_3
	LEFT JOIN
		totals_3
	ON
		SUBSTRING(SeasonID,3,2) = SUBSTRING(Season,6,2)
		AND CASE
			WHEN nba_id = PLAYER_ID
			THEN 1
			WHEN nba_id != PLAYER_ID
			AND bbref_id = bbref_id_num
			THEN 1
			WHEN nba_id != PLAYER_ID
			AND bbref_id != bbref_id_num
			AND playername = PLAYER
			THEN 1
			WHEN nba_id != PLAYER_ID
			AND bbref_id != bbref_id_num
			AND playername != PLAYER
			AND playername = name
			AND CAST(points AS int) = CAST(PTS AS int)
			THEN 1
			ELSE 0 
			END = 1
WHERE Season IS NULL
;

--Cases where the join DID work
SELECT 
	* INTO joined_totals
FROM
	bbref_totals_3
	LEFT JOIN
		totals_3
	ON
		SUBSTRING(SeasonID,3,2) = SUBSTRING(Season,6,2)
		AND CASE
			WHEN nba_id = PLAYER_ID
			THEN 1
			WHEN nba_id != PLAYER_ID
			AND bbref_id = bbref_id_num
			THEN 1
			WHEN nba_id != PLAYER_ID
			AND bbref_id != bbref_id_num
			AND playername = PLAYER
			THEN 1
			WHEN nba_id != PLAYER_ID
			AND bbref_id != bbref_id_num
			AND playername != PLAYER
			AND playername = name
			AND CAST(points AS int) = CAST(PTS AS int)
			THEN 1
			ELSE 0 
			END = 1
WHERE Season IS NOT NULL
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
	unjoined_players
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
	unjoined_players
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
	Season = '20'+ (CONVERT(varchar,((CONVERT(int,Season))-2001)) + '-' + SUBSTRING(Season,3,2))
WHERE 
	Season LIKE '202_'
;

      -- 7. Clean position labels
-----------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE 
   joined_totals_3 
ADD 
   realposition AS 
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

WITH dict AS (
SELECT 
	playername,
	bbref_id,
	PLAYER,
	PLAYER_ID,
	realposition,
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
	PLAYER_ID AS nbaid,
	realposition AS real_position
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
	OR CASE
		WHEN bbref_id != br_id
			AND PLAYER_ID = nbaid
		THEN 1
		WHEN bbref_id != br_id
			AND PLAYER_ID = ''
			AND playername = br_name
				OR PLAYER = nbaname
		THEN 1
		ELSE 0
		END = 1
;
UPDATE 
	joined_totals_4 
SET PLAYER_ID = nbaid
WHERE PLAYER_ID = '' AND nbaid IS NOT NULL
;

GO
DROP TABLE
	totals_2,
	totals_3,
	bbref_totals,
	bbref_totals_2,
	bbref_totals_3,
	joined_totals,
	joined_totals_2,
	joined_totals_3,
	unjoined_players,
	player_master_2
;
GO
-- Total time - 3:21

      --8. Join positions to box_scores
-----------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [deduped_ids] AS
SELECT
   Name,
   ID,
   realposition,
   SeasonID,
   TEAM_NAME,
   rownum
FROM 
   (
SELECT
   PLAYER AS Name,
   PLAYER_ID AS ID,
   realposition,
   Season AS SeasonID,
   TEAM AS TEAM_NAME,
   ROW_NUMBER() OVER (PARTITION BY PLAYER_ID,Season,TEAM ORDER BY Season) AS rownum   
FROM
   joined_totals_4
)
	AS t1
WHERE
	rownum = 1
;
GO

CREATE VIEW [single_position] AS
SELECT
	Name,
	ID,
	realposition,
	uniques
FROM (
SELECT
	Name,
	ID,
	realposition,
	ROW_NUMBER() OVER (PARTITION BY Name,ID ORDER BY SeasonID) AS uniques
FROM
	deduped_ids
) AS t1
WHERE
	uniques = 1
;
GO

--adapted to use version of box_scores that has per-game values replacing NULLS
CREATE VIEW [box_scores_with_positions] AS
SELECT
   * 
FROM
    boxes_with_estimates_replacing_nulls  -- Here is where I made the change
	    LEFT JOIN    
            (
            SELECT
                Name,
                ID,
                realposition,
                SeasonID,
                TEAM_NAME
            FROM 
                deduped_ids
            )
            positions
                ON PLAYER_ID = ID
	            AND SEASON_ID = SeasonID
			        LEFT JOIN
				        (
                        SELECT
                            PLAYER_ID AS P,
                            SEASON AS S,
                            mpg
                        FROM
                            totals4
                        )
                        min_verify
					        ON PLAYER_ID = P
					        AND SEASON_ID = S
;
GO

   --D. Aggregates at different levels
      -- 1. Team season sums
------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [team_season_sums] AS
SELECT 
	*
FROM
(SELECT
      TEAM_ID,
	  TEAM_NAME,
      SEASONID,
      SUM(PTS) OVER(PARTITION BY TEAM_ID, seasonID) AS team_pts,
      SUM(FGM) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fgm,
      SUM(FGA) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fga,
      SUM(FG2M) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fg2m,
      SUM(FG2A) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fg2a,
      SUM(FG3M) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fg3m,
      SUM(FG3A) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fg3a,
      SUM(FTM) OVER(PARTITION BY TEAM_ID, seasonID) AS team_ftm,
      SUM(FTA) OVER(PARTITION BY TEAM_ID, seasonID) AS team_fta,
      SUM(OREB) OVER(PARTITION BY TEAM_ID, seasonID) AS team_oreb,
      SUM(DREB) OVER(PARTITION BY TEAM_ID, seasonID) AS team_dreb,
      SUM(REB) OVER(PARTITION BY TEAM_ID, seasonID) AS team_reb,
      SUM(AST) OVER(PARTITION BY TEAM_ID, seasonID) AS team_ast,
      SUM(TOV) OVER(PARTITION BY TEAM_ID, seasonID) AS team_tov,
      SUM(STL) OVER(PARTITION BY TEAM_ID, seasonID) AS team_stl,
      SUM(BLK) OVER(PARTITION BY TEAM_ID, seasonID) AS team_blk,
      SUM(PF) OVER(PARTITION BY TEAM_ID, seasonID) AS team_pf,
      SUM(MISSES) OVER(PARTITION BY TEAM_ID, seasonID) AS team_misses,
      SUM(FT_MISSES) OVER(PARTITION BY TEAM_ID, seasonID) AS team_ftmisses,
      SUM(MINUTES) OVER(PARTITION BY TEAM_ID, seasonID) AS team_minutes,
      SUM(PLUS_MINUS) OVER(PARTITION BY TEAM_ID, seasonID) AS team_plusminus,
      ROW_NUMBER () OVER (PARTITION BY TEAM_ID, seasonID ORDER BY seasonID) AS team_season_record
FROM
   box_scores_with_positions
) AS t1
WHERE
   team_season_record = 1
;
GO

		-- 2. team game sums
----------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [team_game_sums] AS
SELECT 
	*
FROM (
   SELECT   
      TEAM_ID,
      TEAM_ABBREVIATION,
      GAME_ID,
      SEASON_ID,
      SUM(PTS) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_pts,
      SUM(FGM) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fgm,
      SUM(FGA) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fga,
	  SUM(FG2M) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fg2m,
      SUM(FG2A) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fg2a,
      SUM(FG3M) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fg3m,
      SUM(FG3A) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fg3a,
      SUM(FTM) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_ftm,
      SUM(FTA) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_fta,
      SUM(OREB) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_oreb,
      SUM(DREB) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_dreb,
      SUM(REB) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_reb,
      SUM(AST) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_ast,
      SUM(TOV) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_tov,
      SUM(STL) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_stl,
      SUM(BLK) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_blk,
      SUM(PF) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_pf,
      SUM(MISSES) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_misses,
      SUM(FT_MISSES) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_ftmisses,
      SUM(MINUTES) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_minutes,
      SUM(PLUS_MINUS) OVER(PARTITION BY TEAM_ID, GAME_ID) AS team_game_plusminus,
      ROW_NUMBER () OVER (PARTITION BY TEAM_ID, GAME_ID ORDER BY GAME_ID) AS team_game_record
   FROM
      box_scores_with_positions
) AS t1
   WHERE
      team_game_record = 1
;
GO 
--Total time - 4:06

      -- 3. Opponent game sums
----------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
   t1.GAME_ID AS OWN_GAME_ID,
   t1.TEAM_ABBREVIATION AS OWN_TEAM,
   t1.TEAM_ID AS OWN_TEAM_ID,
   t2.GAME_ID AS OPPONENT_GAME_ID,
   t2.TEAM_ABBREVIATION AS OPPONENT,
   t2.TEAM_ID AS OPPONENT_ID,
   t2.SEASON_ID
INTO
   hinge
FROM
   box_scores t1,
   box_scores t2
WHERE
   t1.GAME_ID = t2.GAME_ID
   AND t1.TEAM_ID != t2.TEAM_ID
GROUP BY
   t1.GAME_ID,
   t2.GAME_ID,
   t1.TEAM_ABBREVIATION,
   t2.TEAM_ABBREVIATION,
   t1.TEAM_ID,
   t2.TEAM_ID,
   t2.SEASON_ID
;

GO
CREATE VIEW [both_teams_game_sums] AS
SELECT
   *
FROM
   team_game_sums
      LEFT JOIN
         (
         SELECT 
            OWN_GAME_ID,
            OWN_TEAM,
            OWN_TEAM_ID,
            OPPONENT_GAME_ID,
            OPPONENT,
            OPPONENT_ID
         FROM
	         hinge
         )
         t2
            ON GAME_ID = OWN_GAME_ID
            AND TEAM_ABBREVIATION = OWN_TEAM
               LEFT JOIN
                  (
                  SELECT
                     GAME_ID AS GAME_ID_NUMBER,
                     TEAM_ABBREVIATION AS TEAM,
                     TEAM_ID AS TEAM_ID_NUMBER,
                     SEASON_ID AS SEASON_ID_NUMBER,
                     team_game_pts AS opp_game_pts,
                     team_game_fgm AS opp_game_fgm,
                     team_game_fga AS opp_game_fga,
                     team_game_fg2m AS opp_game_fg2m,
                     team_game_fg2a AS opp_game_fg2a,
                     team_game_fg3m AS opp_game_fg3m,
                     team_game_fg3a AS opp_game_fg3a,
                     team_game_ftm AS opp_game_ftm,
                     team_game_fta AS opp_game_fta,
                     team_game_oreb AS opp_game_oreb,
                     team_game_dreb AS opp_game_dreb,
                     team_game_reb AS opp_game_reb,
                     team_game_ast AS opp_game_ast,
                     team_game_tov AS opp_game_tov,
                     team_game_stl AS opp_game_stl,
                     team_game_blk AS opp_game_blk,
                     team_game_pf AS opp_game_pf,
                     team_game_misses AS opp_game_misses,
                     team_game_ftmisses AS opp_game_ftmisses,
                     team_game_minutes AS opp_game_minutes,
                     team_game_plusminus AS opp_game_plusminus
                  FROM
                     team_game_sums
                  )
                  t1
                     ON OPPONENT_GAME_ID = GAME_ID_NUMBER
                     AND OPPONENT_ID = TEAM_ID_NUMBER
;
GO

      -- 4. Opponent season sums
------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [team_and_opp_season_sums] AS
SELECT
   *
FROM
   team_season_sums
      LEFT JOIN
         hinge
            ON TEAM_NAME = OWN_TEAM
            AND SeasonID = SEASON_ID
               LEFT JOIN
                    (
                    SELECT
                        TEAM_NAME AS OPPONENT_NAME,
                        TEAM_ID AS OPPONENT_ID_NUMBER,
                        SEASONID AS SEASON_ID_NUMBER,
                        team_pts AS opp_pts,
                        team_fgm AS opp_fgm,
                        team_fga AS opp_fga,
                        team_fg2m AS opp_fg2m,
                        team_fg2a AS opp_fg2a,
                        team_fg3m AS opp_fg3m,
                        team_fg3a AS opp_fg3a,
                        team_ftm AS opp_ftm,
                        team_fta AS opp_fta,
                        team_oreb AS opp_oreb,
                        team_dreb AS opp_dreb,
                        team_reb AS opp_reb,
                        team_ast AS opp_ast,
                        team_tov AS opp_tov,
                        team_stl AS opp_stl,
                        team_blk AS opp_blk,
                        team_pf AS opp_pf,
                        team_misses AS opp_misses,
                        team_ftmisses AS opp_ftmisses,
                        team_minutes AS opp_minutes,
                        team_plusminus AS opp_plusminus
                    FROM
                        team_season_sums
                    )
                    t1
                        ON OPPONENT_ID = OPPONENT_ID_NUMBER
                        AND SEASON_ID = SEASON_ID_NUMBER
;
GO
      -- 5. Box scores with both teams game sums
-----------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [box_scores_with_game_sums] AS 
SELECT
   box_scores_with_positions.*,
   both_teams_game_sums.GAME_ID_NUMBER,
   TEAM_ID_NUMBER,
   SEASON_ID_NUMBER,
   team_game_pts,
   team_game_fgm,
   team_game_fga,
   team_game_fg2m,
   team_game_fg2a,
   team_game_fg3m,
   team_game_fg3a,
   team_game_ftm,
   team_game_fta,
   team_game_oreb,
   team_game_dreb,
   team_game_reb,
   team_game_ast,
   team_game_tov,
   team_game_stl,
   team_game_blk,
   team_game_pf,
   team_game_misses,
   team_game_ftmisses,
   team_game_minutes,
   team_game_plusminus, 
   opp_game_pts,
   opp_game_fgm,
   opp_game_fga,
   opp_game_fg2m,
   opp_game_fg2a,
   opp_game_fg3m,
   opp_game_fg3a,
   opp_game_ftm,
   opp_game_fta,
   opp_game_oreb,
   opp_game_dreb,
   opp_game_reb,
   opp_game_ast,
   opp_game_tov,
   opp_game_stl,
   opp_game_blk,
   opp_game_pf,
   opp_game_misses,
   opp_game_ftmisses,
   opp_game_minutes,
   opp_game_plusminus      
FROM
   box_scores_with_positions
      LEFT JOIN 
         both_teams_game_sums
            ON
               box_scores_with_positions.GAME_ID = GAME_ID_NUMBER
               AND box_scores_with_positions.TEAM_ID = TEAM_ID_NUMBER
;
GO

      -- 6. Position game sums for both teams
----------------------------------------------------------------------------------------------------------------------------------------------
--Sections 6 and 7 need to be monitored. 
--They follow the same steps used for team game sums and opponent game sums, but need to be tested independently.

CREATE VIEW [position_game_sums] AS
SELECT * FROM (   
SELECT   
      TEAM_ID,
      TEAM_ABBREVIATION,
      GAME_ID,
      SEASON_ID AS SEASONID,
      realposition AS POSITION,
      SUM(PTS) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_pts,
      SUM(FGM) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fgm,
      SUM(FGA) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fga,
      SUM(FG2M) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fg2m,
      SUM(FG2A) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fg2a,
      SUM(FG3M) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fg3m,
      SUM(FG3A) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fg3a,
      SUM(FTM) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_ftm,
      SUM(FTA) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_fta,
      SUM(OREB) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_oreb,
      SUM(DREB) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_dreb,
      SUM(REB) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_reb,
      SUM(AST) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_ast,
      SUM(TOV) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_tov,
      SUM(STL) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_stl,
      SUM(BLK) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_blk,
      SUM(PF) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_pf,
      SUM(MISSES) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_misses,
      SUM(FT_MISSES) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_ftmisses,
      SUM(MINUTES) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_minutes,
      SUM(PLUS_MINUS) OVER(PARTITION BY TEAM_ABBREVIATION, GAME_ID, realposition) AS position_game_plusminus,
      ROW_NUMBER () OVER (PARTITION BY TEAM_ABBREVIATION, GAME_ID,realposition ORDER BY GAME_ID) AS position_game_record
   FROM
      box_scores_with_positions
) AS t1
   WHERE
      position_game_record = 1
;
GO
 
	-- 7. Opponent position game sums
----------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [both_teams_position_sums] AS
SELECT
   *
FROM
   position_game_sums
      LEFT JOIN
         hinge
            ON GAME_ID = OWN_GAME_ID
            AND TEAM_ABBREVIATION = OWN_TEAM
               LEFT JOIN
                  (
                  SELECT
                     GAME_ID AS GAME_ID_NUMBER,
                     TEAM_ABBREVIATION AS TEAM_NAME,
                     TEAM_ID AS TEAM_ID_NUMBER,
                     SEASONID AS SEASON_ID_NUMBER,
                     POSITION AS POSITION_NAME,
                     position_game_pts AS opp_game_pts,
                     position_game_fgm AS opp_game_fgm,
                     position_game_fga AS opp_game_fga,
                     position_game_fg2m AS opp_game_fg2m,
                     position_game_fg2a AS opp_game_fg2a,
                     position_game_fg3m AS opp_game_fg3m,
                     position_game_fg3a AS opp_game_fg3a,
                     position_game_ftm AS opp_game_ftm,
                     position_game_fta AS opp_game_fta,
                     position_game_oreb AS opp_game_oreb,
                     position_game_dreb AS opp_game_dreb,
                     position_game_reb AS opp_game_reb,
                     position_game_ast AS opp_game_ast,
                     position_game_tov AS opp_game_tov,
                     position_game_stl AS opp_game_stl,
                     position_game_blk AS opp_game_blk,
                     position_game_pf AS opp_game_pf,
                     position_game_misses AS opp_game_misses,
                     position_game_ftmisses AS opp_game_ftmisses,
                     position_game_minutes AS opp_game_minutes,
                     position_game_plusminus AS opp_game_plusminus
                  FROM
                     position_game_sums
                  )
                  t1
                     ON OPPONENT_GAME_ID = GAME_ID_NUMBER
                     AND OPPONENT_ID = TEAM_ID_NUMBER
                     AND POSITION = POSITION_NAME
;
GO

      -- 8. Game-level pace context
-----------------------------------------------------------------------------------------------------------------------------------------------
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;
WITH
	t1 AS (
SELECT 
   TEAM_ID AS team_num,
   OffPossPerMin AS own_pace,
   SEASON AS season_num,
   ROW_NUMBER() OVER (PARTITION BY TEAM_ID,SEASON ORDER BY SEASON) AS t1row
FROM
   totals4)
,
	t2 AS (
SELECT 
   TEAM_ID AS opp_num,
   OffPossPerMin AS opp_pace,
   SEASON AS opp_season_num,
   ROW_NUMBER() OVER (PARTITION BY TEAM_ID,SEASON ORDER BY SEASON) AS t2row
FROM
   totals4)
,
	t4 AS (
SELECT
   SEASON_ID,
   TEAM_ABBREVIATION AS TEAM,
   TEAM_ID,
   GAME_ID,
    (SUM(FGA + TOV + (FTA*0.4) - OREB) OVER (PARTITION BY GAME_ID ORDER BY GAME_ID) 
		 / 
			(
				SUM(MINUTES) OVER (PARTITION BY GAME_ID ORDER BY GAME_ID)
					/
						5)
	)
		AS pace,
	ROW_NUMBER () OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID) AS t4row
FROM
	box_scores
)
SELECT
   t4.SEASON_ID,
   TEAM,
   TEAM_ID,
   GAME_ID,
   (CASE
      WHEN pace < 1.5
	  THEN
		 ((own_pace + opp_pace)/2)
	  WHEN 
         (CAST(SUBSTRING(t4.SEASON_ID,1,4) AS int)) > 1977
		 AND pace IS NOT NULL
      THEN
         pace
      WHEN 
         (CAST(SUBSTRING(t4.SEASON_ID,1,4) AS int)) > 1977
		 AND pace IS NULL
	  THEN
		 ((own_pace + opp_pace)/2)
      ELSE
         ((own_pace + opp_pace)/2)
      END
   ) AS Game_Poss_Per_Min
INTO 
	game_pace
FROM
   t4
      LEFT JOIN
		t1
			ON TEAM_ID = team_num
			AND SEASON_ID = season_num
				LEFT JOIN
					hinge 
						ON TEAM_ID = OWN_TEAM_ID
						AND GAME_ID = OWN_GAME_ID
							LEFT JOIN 
								t2
									ON OPPONENT_ID = opp_num
									AND GAME_ID = OPPONENT_GAME_ID
									AND t4.SEASON_ID = opp_season_num
WHERE
	t1row = 1
	AND t2row = 1
	AND t4row = 1
;

   -- E. Points Created
      -- 1. Calculate inputs
-----------------------------------------------------------------------------------------------------------------------------------------------
GO
CREATE VIEW [points_created] AS
SELECT
    GAME_ID,
	TEAM_ID,
	TEAM_ABBREVIATION,
	PLAYER_NAME,
	PLAYER_ID,
	FGM,
	FGA,
	FG3M,
	FG3A,
	FTM,
	FTA,
	OREB,
	DREB,
	REB,
	AST,
	STL,
	BLK,
	TOV,
	PF,
	PTS,
	SEASON_ID,
	MINUTES,
	realposition,
	team_game_pts,
	team_game_fgm,
	team_game_fga,
	team_game_fg2m,
	team_game_fg2a,
	team_game_fg3m,
	team_game_fg3a,
	team_game_ftm,
	team_game_fta,
	team_game_oreb,
	team_game_dreb,
	team_game_reb,
	team_game_ast,
	team_game_tov,
	team_game_stl,
	team_game_blk,
	team_game_pf,
	team_game_minutes,
	avg_oreb_rate,
   (
   CASE
      WHEN
         team_game_oreb != 0
		 AND team_game_oreb IS NOT NULL
      THEN
         team_game_oreb*1.35
      WHEN
		 team_game_reb IS NOT NULL
	  THEN
         (
            team_game_reb*avg_oreb_rate*1.35
         )
	  WHEN 
		 team_game_reb IS NULL
		 AND team_game_misses IS NOT NULL 
		 AND team_game_ftmisses IS NOT NULL
	  THEN	
		 ((0.3*(team_game_misses + (team_game_ftmisses/2)))*1.35)
	  WHEN 
		 team_game_reb IS NULL
		 AND team_game_misses IS NULL 
		 AND team_game_fgm IS NOT NULL
		 AND team_game_ftmisses IS NOT NULL
	  THEN
		 ((0.3*(team_game_fgm + (team_game_ftmisses/2)))*1.35)
	  ELSE
		 0
      END
   ) AS team_second_chance, 
   (
	CASE
	WHEN 
		team_game_fgm < team_game_fga
		OR team_game_fga IS NULL
		THEN
			((team_game_pts - team_game_ftm) / team_game_fgm)
	ELSE
		2
	END) AS game_pts_per_fgm,
   (
   CASE
   WHEN 
      team_game_pts != 0
	  AND team_game_pts IS NOT NULL
	  AND (team_game_pts - team_game_ftm) IS NOT NULL
	  AND (team_game_pts - team_game_ftm) != 0
	  AND team_game_ftm IS NOT NULL
	THEN
		    (team_game_ast / (team_game_pts - team_game_ftm))
	ELSE
		0
	END
   ) AS assisted_percentage,
   (
   CASE
      WHEN
         FGM != 0
		 AND FGM IS NOT NULL
      THEN
         ((PTS - FTM) / FGM)
	  WHEN	
		PTS >= 0
		AND PTS IS NULL
		AND FGM IS NULL
	  THEN
		((PTS - FTM)/2)
      ELSE
         0 
   END
   ) AS pts_per_fgm,
   (
   CASE
      WHEN
         FGM != 0 
		 AND FGM IS NOT NULL
		 AND (.793*((FGM*(team_game_ast / (team_game_pts - team_game_ftm)))*((PTS - FTM) / FGM))) IS NOT NULL
      THEN
   (.793*((FGM*(team_game_ast / (team_game_pts - team_game_ftm)))*((PTS - FTM) / FGM))) 
	  ELSE
         0 
   END
   ) AS ASSISTED_PTS,
   (
   CASE
		WHEN
			AST IS NOT NULL
		THEN
			(0.207*AST)
		ELSE
			0
		END
   ) ASSIST_FGM_CREDIT,
   (
   CASE
	  WHEN 
        team_game_fgm != 0
		AND team_game_fgm IS NOT NULL
	  THEN
		  (team_game_ast / team_game_fgm)
	  WHEN
		(team_game_ast / team_game_fgm) IS NULL
	  THEN
	     ((team_game_pts/2)*
			(SELECT
				SUM(team_game_ast) / SUM(team_game_pts)
			FROM
				box_scores_with_game_sums
			WHERE team_game_ast > 0
			AND team_game_ast IS NOT NULL
			)
		)
	  ELSE
			0.22
	--check this
	END
   ) AS team_ast_fg,
   (
   CASE
	  WHEN 
        team_game_fgm != 0
		AND team_game_fgm IS NOT NULL
		AND team_game_ftm IS NOT NULL
	  THEN
	     ((team_game_pts - team_game_ftm) / team_game_fgm)
	  ELSE
		  2
	  END
   ) AS team_pts_per_fgm,
   (
   CASE 
	  WHEN 
         team_game_pts !=0
		 AND team_game_pts IS NOT NULL
		 AND  team_game_ftm IS NOT NULL
		 AND team_game_fgm IS NOT NULL 
		 AND team_game_fgm != 0
		 AND ((.793*(team_game_fgm*(team_game_ast / (team_game_pts - team_game_ftm))))*((team_game_pts - team_game_ftm) / team_game_fgm))
			IS NOT NULL
	  THEN
		   ((.793*(team_game_fgm*(team_game_ast / (team_game_pts - team_game_ftm))))*((team_game_pts - team_game_ftm) / team_game_fgm))
	  WHEN
		 team_game_ast IS NOT NULL
		 AND team_game_pts != 0
		 AND team_game_pts IS NOT NULL
	  THEN
         (team_game_ast / team_game_pts)
	  ELSE
	     17.125
	  END
   ) AS team_assisted_pts
FROM
   box_scores_with_game_sums   
		LEFT JOIN
			(
         SELECT
            GAME_ID_NUMBER AS GAME_NUMBER,
            TEAM_ID AS TEAM_NUMBER,
            (SELECT 
               (SUM(team_game_oreb) / SUM(team_game_reb)) 
            FROM
               box_scores_with_game_sums
            WHERE 
               team_game_oreb != 0
               AND team_game_oreb IS NOT NULL) AS avg_oreb_rate,
            ROW_NUMBER() OVER (PARTITION BY GAME_ID_NUMBER,TEAM_ID ORDER BY TEAM_ID) AS t2row
         FROM
	         box_scores_with_game_sums
         )
         t2
				ON GAME_ID_NUMBER = GAME_NUMBER
				AND TEAM_ID = TEAM_NUMBER
WHERE
	t2row = 1
;
GO

      -- 2. Calculate team unassisted, player second chance, player assisted, player Points Created
---------------------------------------------------------------------------------------------------------------------------------------------
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;

SELECT
   points_created.*,
   (
      team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance
   ) AS team_unassisted_pts,
   (
   CASE
	  WHEN 
        team_game_pts != 0
	  THEN
	     ((PTS / team_game_pts)*team_second_chance)
	  ELSE
		  0
	  END) AS second_chance_share, 
   (
   CASE
      WHEN
         (team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance) != 0 
		 AND team_game_pts != 0
		 AND (team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance) IS NOT NULL
		 AND team_game_pts IS NOT NULL
      THEN
         (
            (
            PTS - FTM - 
               ((team_ast_fg*FGM)*game_pts_per_fgm)
                   - 
                     ((PTS / team_game_pts)*team_second_chance)
            ) 
            / 	
            (team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)
         ) 
      ELSE
         0 
      END
   ) AS unassisted_percent_share,  
   (
   CASE
	  WHEN 
         team_game_pts != 0
	  THEN
		   ((PTS / team_game_pts)*team_assisted_pts)
	  ELSE 
		   0
	  END
   ) AS assisted_share,
   (
   CASE
	  WHEN 
         team_game_pts != 0
	  THEN
		   ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance))
	  ELSE 
         0
	  END
   ) AS unassisted_share,

   (
   CASE
      WHEN
         team_game_oreb > 0
		 AND OREB IS NOT NULL
		 AND PTS IS NOT NULL
		 AND FTM IS NOT NULL
		 --AND team_game_oreb IS NOT NULL
      THEN
         (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            ASSIST_FGM_CREDIT + 
            FTM + 
            (.256*(OREB / team_game_oreb)*team_second_chance) + 
            (.744*((PTS / team_game_pts)*team_second_chance))
         ) 
      WHEN
         team_game_oreb > 0
		 --AND team_game_oreb IS NOT NULL
		 AND OREB IS NOT NULL
		 AND PTS IS NOT NULL
		 AND ASSIST_FGM_CREDIT IS NOT NULL
		 AND FTM IS NULL
      THEN
         (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            ASSIST_FGM_CREDIT + 
            (.256*(OREB / team_game_oreb)*team_second_chance) + 
            (.744*((PTS / team_game_pts)*team_second_chance))
         ) 
      WHEN
         team_game_oreb > 0
		 --AND team_game_oreb IS NOT NULL
		 AND OREB IS NOT NULL
		 AND PTS IS NOT NULL
		 AND FTM IS NOT NULL
		 AND ASSIST_FGM_CREDIT IS NULL
      THEN
         (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            FTM + 
            (.256*(OREB / team_game_oreb)*team_second_chance) + 
            (.744*((PTS / team_game_pts)*team_second_chance))
         ) 
	 WHEN
		    team_game_oreb IS NULL 
			--AND team_game_reb IS NOT NULL
			AND REB IS NOT NULL
			AND FTM IS NOT NULL
			AND ASSIST_FGM_CREDIT IS NOT NULL
			AND team_assisted_pts IS NOT NULL
			AND team_second_chance IS NOT NULL
			AND (team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance) IS NOT NULL
			AND team_game_reb > 0
	  THEN 
          (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            ASSIST_FGM_CREDIT + 
            FTM +
            (.256*((REB*avg_oreb_rate) / ((team_game_reb*avg_oreb_rate)*team_second_chance))) + 
            (.744*((PTS / team_game_pts)*team_second_chance))
          ) 
      WHEN
		    team_game_oreb = 0 
			AND team_game_reb IS NOT NULL
			AND REB IS NOT NULL
			AND FTM IS NOT NULL
			AND ASSIST_FGM_CREDIT IS NOT NULL
	  THEN
          (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            ASSIST_FGM_CREDIT + 
            FTM +
            (.256*((REB*avg_oreb_rate) / ((team_game_reb*avg_oreb_rate)*team_second_chance))) + 
            (.744*((PTS / team_game_pts)*team_second_chance))
          ) 
      WHEN
		  ((team_game_reb*avg_oreb_rate)*team_second_chance) = 0
	  THEN
          (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            ASSIST_FGM_CREDIT + 
            FTM +
            (.744*((PTS / team_game_pts)*team_second_chance))
          ) 
	 WHEN
		    REB IS NULL
			AND FTM IS NOT NULL
			AND ASSIST_FGM_CREDIT IS NOT NULL
	  THEN
          (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            ASSIST_FGM_CREDIT + 
            FTM +
            (.744*((PTS / team_game_pts)*team_second_chance))
          ) 
     WHEN
			team_game_reb IS NOT NULL
			AND REB IS NOT NULL
			AND PTS IS NULL 
			AND ASSIST_FGM_CREDIT IS NOT NULL
	  THEN
          (
            ASSIST_FGM_CREDIT + 
            (.256*((REB*avg_oreb_rate) / ((team_game_reb*avg_oreb_rate)*team_second_chance))) 
		  )
	  WHEN
			PTS IS NULL
			AND MINUTES IS NULL
	  THEN
			0
	  ELSE
          (
            ((PTS / team_game_pts)*team_assisted_pts) + 
            ((PTS / team_game_pts)*(team_game_pts - team_assisted_pts - team_game_ftm - team_second_chance)) + 
            (.744*((PTS / team_game_pts)*team_second_chance))
          ) 
	  END
   ) AS game_points_created,
   (CASE
      WHEN
         realposition IS NULL
      THEN 'None'
      ELSE realposition
      END
   ) AS POSITION
INTO
	game_points_created
FROM
   points_created
;
GO

ALTER TABLE
	game_points_created
ADD 
   MISSES
      AS (FGA - FGM),
   FT_MISSES
      AS (FTA - FTM),
   FG2M
      AS (
		CASE
		WHEN FG3M IS NOT NULL
		THEN
			(FGM - FG3M)
		ELSE
			FGM
		END),
   FG2A
      AS (
		CASE
		WHEN FG3A IS NOT NULL
		THEN
			(FGA - FG3A)
		ELSE
			FGA
		END),
   FG2PERCENT
      AS (CASE
         WHEN (FGA-FG3A) > 0
		 AND FG3A IS NOT NULL
         THEN ((FGM-FG3M)/(FGA-FG3A))
         ELSE (FGM/FGA)
         END),
   FG3PERCENT
      AS  (CASE
         WHEN FG3A > 0
         THEN (FG3M/FG3A)
         ELSE NULL
         END),
   FGPERCENT
      AS (CASE
         WHEN FGA > 0
         THEN (FGM/FGA)
         ELSE NULL
         END),
   EFG 
      AS (CASE
         WHEN FGA > 0
		 AND FG3M IS NOT NULL
         THEN ((FGM+FG3M)/FGA)
         ELSE (FGM/FGA)
         END),
   TS 
      AS (CASE
         WHEN FGA+(0.44*FTM) > 0
         THEN (PTS/(FGA+(0.44*FTM)))
         ELSE NULL
         END)
;

--check execution for pre-oreb seasons on team_second_chance and game_points_created

      -- 3. Adding season-level points created stats
-------------------------------------------------------------------------------------------------------------------------------------------------
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;

WITH 
   t1 AS (
SELECT
   TEAM AS teamname,
   TEAM_ID AS teamnumber,
   SEASON AS seasonnumber,
   OffPossPerMin,
   LgOffPossPerMin,
   AllTimeOffPossPerMin,
   (OffPossPerMin/LgOffPossPerMin) AS season_pace_factor,
   (OffPossPerMin/AllTimeOffPossPerMin) AS historical_pace_factor,
   ROW_NUMBER() OVER (PARTITION BY TEAM_ID,SEASON ORDER BY TEAM_ID) AS pace_record
FROM
   totals4
),
   t2 AS (
SELECT
   PLAYER_ID AS pid,
   SEASON_ID AS sid,
   TEAM_ID AS tid,
   SUM(game_points_created) OVER (PARTITION BY PLAYER_ID, SEASON_ID ORDER BY SEASON_ID) AS season_points_created,
   ROW_NUMBER () OVER (PARTITION BY PLAYER_ID, SEASON_ID ORDER BY SEASON_ID) AS sum_record
FROM
   game_points_created
),
	t3 AS (
SELECT
   PLAYER_ID AS player_number,
   PLAYER AS name,
   SEASON AS season_number,
   GP,
   MP
FROM
   totals4
)
SELECT
   game_points_created.*,
   (season_points_created/GP) AS pointscreatedpg,
   (season_points_created/MP) AS pointscreatedpm,
   (season_points_created/(MP*OffPossPerMin)) AS pointscreatedpp, 
   (season_points_created/season_pace_factor) AS season_points_created,
   (season_points_created/historical_pace_factor) AS era_adjusted_points_created,
   ((season_points_created/GP)/season_pace_factor) AS season_pointscreatedpg,
   ((season_points_created/GP)/historical_pace_factor) AS era_adjusted_pointscreatedpg,
   ((season_points_created/(MP*OffPossPerMin))/season_pace_factor) AS season_pointscreatedpp,
   ((season_points_created/(MP*OffPossPerMin))/historical_pace_factor) AS era_adjusted_pointscreatedpp 
INTO
	points_created_master
FROM
   game_points_created
      LEFT JOIN
         t1
            ON SEASON_ID = seasonnumber
            AND TEAM_ID = teamnumber
               LEFT JOIN
                  t2 
                     ON PLAYER_ID = pid
                     AND SEASON_ID = sid
                     --AND TEAM_ID = tid -- joining on team_id here caused problems for multi-team players
						LEFT JOIN 
							t3
								ON PLAYER_ID = player_number
								AND SEASON_ID = season_number
WHERE
   sum_record = 1
   AND pace_record = 1
;

      -- 4. Incorporating points created into game sums for both teams
----------------------------------------------------------------------------------------------------------------------------------------------
GO
CREATE VIEW [game_sums_by_position] AS   
SELECT
   * 
FROM
   both_teams_position_sums
      LEFT JOIN
         (
         SELECT 
            TEAM_ABBREVIATION AS teamname,
            TEAM_ID AS teamnumber,
            GAME_ID AS gamenumber,
            SEASON_ID AS seasonnumber,
            POSITION AS positionname,
            SUM(game_points_created) OVER (PARTITION BY POSITION,TEAM_ID,GAME_ID) AS position_points_created,
            ROW_NUMBER () OVER (PARTITION BY POSITION,TEAM_ID,GAME_ID ORDER BY GAME_ID) AS position_record
         FROM
	         game_points_created
         )
         t1
            ON GAME_ID = gamenumber
            AND TEAM_ID = teamnumber
            AND POSITION = positionname
				LEFT JOIN
					(
               SELECT
                  TEAM_ABBREVIATION AS opponent_team_name,
                  TEAM_ID AS opponent_team_number,
                  GAME_ID AS game_number,
                  SEASON_ID AS season_number,
                  POSITION AS opponent_position,
                  SUM(game_points_created) OVER (PARTITION BY POSITION,TEAM_ID,GAME_ID) AS opponent_position_points_created,
                  ROW_NUMBER () OVER (PARTITION BY POSITION,TEAM_ID,GAME_ID ORDER BY GAME_ID) AS opponent_position_record   
               FROM
                  game_points_created
               )
               t2
						ON OPPONENT_GAME_ID = game_number
						AND OPPONENT_ID = opponent_team_number
						AND POSITION = opponent_position
WHERE
   position_record = 1
   AND opponent_position_record = 1
;
GO

   --F. Expected stats and differentials
      -- 1. Expected player stats
----------------------------------------------------------------------------------------------------------------------------------------------
WITH 
   t1 AS (
SELECT
   TEAM_ID AS teamid,
   GAME_ID AS gameid,
   Game_Poss_Per_Min,
   ROW_NUMBER () OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID) AS pace_record
FROM
   game_pace
),
   t2 as (
SELECT
   PLAYER_ID AS playerid,
   TEAM_ID AS teamidnumber,
   SEASON AS seasonid,
   ppp,
   fgmpp,
   fgapp,
   fg2mpp,
   fg2app,
   fg3mpp,
   fg3app,
   ftmpp,
   ftapp,
   orebpp,
   drebpp,
   rpp,
   app,
   tpp,
   spp,
   bpp,
   pfpp,
   missespp,
   ftmissespp,
   ppg,
   fgmpg,
   fgapg,
   fg2mpg,
   fg2apg,
   fg3mpg,
   fg3apg,
   ftmpg,
   ftapg,
   orebpg,
   drebpg,
   rpg,
   apg,
   tpg,
   spg,
   bpg,
   mpg,
   pfpg,
   missespg,
   ftmissespg,
   FGPERCENT AS FG_PERCENT,
   FG2PERCENT AS FG2_PERCENT,
   FG3PERCENT AS FG3_PERCENT,
   FT_PERCENT
FROM
   totals4
)
SELECT
   points_created_master.*,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      ppg
   ELSE
      ppp*Minutes*Game_Poss_Per_Min
   END) AS expected_pts,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      fgmpg
   ELSE
      fgmpp*Minutes*Game_Poss_Per_Min
   END) AS expected_fgm,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      fgapg
   ELSE
      fgapp*Minutes*Game_Poss_Per_Min
   END) AS expected_fga,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      fg2mpg
   ELSE
      fg2mpp*Minutes*Game_Poss_Per_Min
   END) AS expected_fg2m,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      fg2apg
   ELSE
      fg2app*Minutes*Game_Poss_Per_Min
   END) AS expected_fg2a,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      fg3mpg
   ELSE
      fg3mpp*Minutes*Game_Poss_Per_Min
   END) AS expected_fg3m,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      fg3apg
   ELSE
      fg3app*Minutes*Game_Poss_Per_Min
   END) AS expected_fg3a,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      ftmpg
   ELSE
      ftmpp*Minutes*Game_Poss_Per_Min
   END) AS expected_ftm,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      ftapg
   ELSE
      ftapp*Minutes*Game_Poss_Per_Min
   END) AS expected_fta,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      orebpg
   ELSE
      orebpp*Minutes*Game_Poss_Per_Min
   END) AS expected_oreb,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      drebpg
   ELSE
      drebpp*Minutes*Game_Poss_Per_Min
   END) AS expected_dreb,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      rpg
   ELSE
      rpp*Minutes*Game_Poss_Per_Min
   END) AS expected_reb,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      apg
   ELSE
      app*Minutes*Game_Poss_Per_Min
   END) AS expected_ast,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      tpg
   ELSE
      tpp*Minutes*Game_Poss_Per_Min
   END) AS expected_tov,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      spg
   ELSE
      spp*Minutes*Game_Poss_Per_Min
   END) AS expected_stl,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      bpg
   ELSE
      bpp*Minutes*Game_Poss_Per_Min
   END) AS expected_blk,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      pfpg
   ELSE
      pfpp*Minutes*Game_Poss_Per_Min
   END) AS expected_pf,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      missespg
   ELSE
      missespp*Minutes*Game_Poss_Per_Min
   END) AS expected_misses,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      ftmissespg
   ELSE
      ftmissespp*Minutes*Game_Poss_Per_Min
   END) AS expected_ftmisses,
   (CASE
   WHEN
      Minutes IS NULL
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
      pointscreatedpg
	  --pointscreatedpg, mpg*Game_Poss_Per_Min*pointscreatedpp
    WHEN
	  Minutes = 0
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) > 20
      AND CAST(SUBSTRING(GAME_ID,2,2) AS int) < 74
   THEN
	  pointscreatedpg
   ELSE
      pointscreatedpp*Minutes*Game_Poss_Per_Min
   END) AS expected_pointscreated,
   (CASE
   WHEN
      MINUTES > 0
      OR PTS > 0
      OR FGM > 0
      OR FGA > 0
      OR FG3M > 0
      OR FG3A > 0
      OR FTM > 0
      OR FTA > 0
      OR OREB > 0
      OR DREB > 0
      OR REB > 0
      OR AST > 0
      OR TOV > 0
      OR STL > 0
      OR BLK > 0
      OR PF > 0
   THEN 
      1
   ELSE
      0
   END
   ) AS PLAYED,
   FG_PERCENT AS expected_fgpercent,
   FG2_PERCENT AS expected_fg2percent,
   FG3_PERCENT AS expected_fg3percent,
   FT_PERCENT AS expected_ftpercent,
   EFG AS expected_efg,
   TS AS expected_ts,
   ppp,
   fgmpp,
   fgapp,
   fg2mpp,
   fg2app,
   fg3mpp,
   fg3app,
   ftmpp,
   ftapp,
   orebpp,
   drebpp,
   rpp,
   app,
   tpp,
   spp,
   bpp,
   pfpp,
   missespp,
   ftmissespp,
   ppg,
   fgmpg,
   fgapg,
   fg2mpg,
   fg2apg,
   fg3mpg,
   fg3apg,
   ftmpg,
   ftapg,
   orebpg,
   drebpg,
   rpg,
   apg,
   tpg,
   spg,
   bpg,
   pfpg,
   missespg,
   ftmissespg,
   mpg
INTO
   expected_player_stats
FROM
   points_created_master
      LEFT JOIN
         t1
            ON GAME_ID = gameid
            AND TEAM_ID = teamid 
               LEFT JOIN
                  t2
                     ON PLAYER_ID = playerid
                     AND TEAM_ID = teamidnumber
                     AND SEASON_ID = seasonid
WHERE
   pace_record = 1
;
GO

-- Filling expected values for "zero minute" lines
UPDATE
	expected_player_stats	
	SET 
		expected_pts = ppg,
		expected_fgm = fgmpg,
		expected_fga = fgapg,
		expected_fg2m = fg2mpg,
		expected_fg2a = fg2apg,
		expected_fg3m = fg3mpg,
		expected_fg3a = fg3apg,
		expected_ftm = ftmpg,
		expected_fta = ftapg,
		expected_oreb = orebpg,
		expected_dreb = drebpg,
		expected_reb = rpg,
		expected_ast = apg,
		expected_tov = tpg,
		expected_stl = spg,
		expected_blk = bpg,
		expected_pf = pfpg,
		expected_misses = missespg,
		expected_ftmisses = ftmissespg,
		expected_pointscreated = pointscreatedpg
	WHERE 
		MINUTES = 0 
        AND PLAYED = 1
;

-- Filling expected values for null minute records
UPDATE
	expected_player_stats	
	SET 
		expected_pts = ppg,
		expected_fgm = fgmpg,
		expected_fga = fgapg,
		expected_fg2m = fg2mpg,
		expected_fg2a = fg2apg,
		expected_fg3m = fg3mpg,
		expected_fg3a = fg3apg,
		expected_ftm = ftmpg,
		expected_fta = ftapg,
		expected_oreb = orebpg,
		expected_dreb = drebpg,
		expected_reb = rpg,
		expected_ast = apg,
		expected_tov = tpg,
		expected_stl = spg,
		expected_blk = bpg,
		expected_pf = pfpg,
		expected_misses = missespg,
		expected_ftmisses = ftmissespg,
		expected_pointscreated = pointscreatedpg
	WHERE 
		MINUTES IS NULL
        AND PLAYED = 1
;

-- Filling minutes for games that a player played
UPDATE
	expected_player_stats
SET 
	MINUTES = mpg
WHERE
	MINUTES IS NULL 
	AND PLAYED = 1
;

-- Filling minutes for games that a player played
UPDATE
	expected_player_stats
SET 
	MINUTES = mpg
WHERE
	MINUTES = 0
	AND PLAYED = 1
;
GO
      --2. Differentials at player-game level
----------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [player_differential] AS
SELECT
   PLAYER_ID,
   PLAYER_NAME AS PLAYER,
   GAME_ID,
   TEAM_ID,
   (PTS - expected_pts) AS pts_differential,
   (FGM - expected_fgm) AS fgm_differential,
   (FGA - expected_fga) AS fga_differential,
   ((FGM - FG3M) - expected_fg2m) AS fg2m_differential,
   ((FGA - FG3A) - expected_fg2a) AS fg2a_differential,
   (FG3M - expected_fg3m) AS fg3m_differential,
   (FG3A - expected_fg3a) AS fg3a_differential,
   (FTM - expected_ftm) AS ftm_differential,
   (FTA - expected_fta) AS fta_differential,
   (OREB - expected_oreb) AS oreb_differential,
   (DREB - expected_dreb) AS dreb_differential,
   (REB - expected_reb) AS reb_differential,
   (AST - expected_ast) AS ast_differential,
   (TOV - expected_tov) AS tov_differential,
   (STL - expected_stl) AS stl_differential,
   (BLK - expected_blk) AS blk_differential,
   (PF - expected_pf) AS pf_differential,
   (game_points_created - expected_pointscreated) AS pointscreated_differential,
   ((FGA-FGM) - expected_misses) AS misses_differential,
   ((FTA-FTM) - expected_ftmisses) AS ftmisses_differential,
   ((FGM/FGA) - expected_fgpercent) AS fgpercent_differential,
   (((FGM - FG3M)/(FGA - FG3A)) - expected_fg2percent) AS fg2percent_differential,
   ((FG3M/FG3A) - expected_fg3percent) AS fg3percent_differential,
   (((FGM + FG3M)/FGA) - expected_efg) AS efg_differential,
   ((PTS/(FGA * (0.44*FTA))) - expected_ts) AS ts_differential
FROM
   expected_player_stats
;
GO

      -- 3. Differentials at position-game level
------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [position_differential] AS
SELECT 
	*
FROM (
SELECT
   GAME_ID,
   TEAM_ID,
   POSITION,
   SUM(PTS - expected_pts) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_pts_differential,
   SUM(FGM - expected_fgm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fgm_differential,
   SUM(FGA - expected_fga) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fga_differential,
   SUM(FG2M - expected_fg2m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fg2m_differential,
   SUM(FG2A - expected_fg2a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fg2a_differential,
   SUM(FG3M - expected_fg3m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fg3m_differential,
   SUM(FG3A - expected_fg3a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fg3a_differential,
   SUM(FTM - expected_ftm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_ftm_differential,
   SUM(FTA - expected_fta) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_fta_differential,
   SUM(OREB - expected_oreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_oreb_differential,
   SUM(DREB - expected_dreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_dreb_differential,
   SUM(REB - expected_reb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_reb_differential,
   SUM(AST - expected_ast) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_ast_differential,
   SUM(TOV - expected_tov) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_tov_differential,
   SUM(STL - expected_stl) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_stl_differential,
   SUM(BLK - expected_blk) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_blk_differential,
   SUM(PF - expected_pf) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_pf_differential,
   SUM(game_points_created - expected_pointscreated) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS postion_pointscreated_differential,
   SUM(misses - expected_misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_misses_differential,
   SUM(ft_misses - expected_ftmisses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_ftmisses_differential,
   ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS position_record
FROM
   expected_player_stats
) AS t1
WHERE
   position_record = 1
;
GO

      --4. Opponent position differentials
---------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [opponent_position_differential] AS
SELECT
   PLAYER_ID AS defender_id,
   PLAYER_NAME AS defender,
   TEAM_ID,
   GAME_ID,
   POSITION,
   Minutes,
   expected_player_stats.SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   t1.*
FROM
   expected_player_stats
      LEFT JOIN 
         hinge
            ON TEAM_ID = OWN_TEAM_ID
            AND GAME_ID = OWN_GAME_ID
               LEFT JOIN
 (
SELECT
   GAME_ID AS game,
   TEAM_ID AS opponent,
   POSITION AS opponent_position,
   SUM(PTS - expected_pts) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_pts_differential,
   SUM(FGM - expected_fgm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fgm_differential,
   SUM(FGA - expected_fga) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fga_differential,
   SUM(FG2M - expected_fg2m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg2m_differential,
   SUM(FG2A - expected_fg2a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg2a_differential,
   SUM(FG3M - expected_fg3m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg3m_differential,
   SUM(FG3A - expected_fg3a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg3a_differential,
   SUM(FTM - expected_ftm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ftm_differential,
   SUM(FTA - expected_fta) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fta_differential,
   SUM(OREB - expected_oreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_oreb_differential,
   SUM(DREB - expected_dreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_dreb_differential,
   SUM(REB - expected_reb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_reb_differential,
   SUM(AST - expected_ast) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ast_differential,
   SUM(TOV - expected_tov) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_tov_differential,
   SUM(STL - expected_stl) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_stl_differential,
   SUM(BLK - expected_blk) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_blk_differential,
   SUM(PF - expected_pf) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_pf_differential,
   SUM(game_points_created - expected_pointscreated) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_postion_pointscreated_differential,
   SUM(misses - expected_misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_misses_differential,
   SUM(ft_misses - expected_ftmisses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ftmisses_differential,
   ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_record
FROM
   expected_player_stats
) t1
                     ON OPPONENT_ID = t1.opponent
                     AND GAME_ID = game
                     AND POSITION = opponent_position
WHERE
   opponent_position_record = 1
;
GO

      -- 5. Pace-adjusted game-level opponent position differentials
--------------------------------------------------------------------------------------------------------------------------------------------
WITH 
   t1 AS (
SELECT
   GAME_ID AS game,
   TEAM_ID AS opponent,
   POSITION AS opponent_position,
   SUM(PTS - expected_pts) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_pts_differential,
   SUM(FGM - expected_fgm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fgm_differential,
   SUM(FGA - expected_fga) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fga_differential,
   SUM(FG2M - expected_fg2m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg2m_differential,
   SUM(FG2A - expected_fg2a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg2a_differential,
   SUM(FG3M - expected_fg3m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg3m_differential,
   SUM(FG3A - expected_fg3a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg3a_differential,
   SUM(FTM - expected_ftm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ftm_differential,
   SUM(FTA - expected_fta) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fta_differential,
   SUM(OREB - expected_oreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_oreb_differential,
   SUM(DREB - expected_dreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_dreb_differential,
   SUM(REB - expected_reb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_reb_differential,
   SUM(AST - expected_ast) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ast_differential,
   SUM(TOV - expected_tov) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_tov_differential,
   SUM(STL - expected_stl) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_stl_differential,
   SUM(BLK - expected_blk) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_blk_differential,
   SUM(PF - expected_pf) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_pf_differential,
   SUM(game_points_created - expected_pointscreated) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_postion_pointscreated_differential,
   SUM(misses - expected_misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_misses_differential,
   SUM(ft_misses - expected_ftmisses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ftmisses_differential,
   ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_record
FROM
   expected_player_stats
),
   t2 AS (
SELECT
   GAME_ID AS game_number,
   Game_Poss_Per_Min,
   ROW_NUMBER () OVER (PARTITION BY GAME_ID ORDER BY GAME_ID) AS game_record
FROM
   game_pace
), 
   t3 AS (
SELECT
   SEASON AS season_number,
   LgOffPossPerMin,
   ROW_NUMBER () OVER (PARTITION BY SEASON ORDER BY SEASON) AS pace_record
FROM
   totals4
)
SELECT
   PLAYER_ID AS defender_id,
   PLAYER_NAME AS defender,
   TEAM_ID,
   GAME_ID,
   POSITION,
   Minutes,
   expected_player_stats.SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   t1.opponent,
   opponent_position,
   (opponent_position_pts_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_pts_differential,
   (opponent_position_fgm_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fgm_differential,
   (opponent_position_fga_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fga_differential,
   (opponent_position_fg2m_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fg2m_differential,
   (opponent_position_fg2a_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fg2a_differential,
   (opponent_position_fg3m_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fg3m_differential,
   (opponent_position_fg3a_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fg3a_differential,
   (opponent_position_ftm_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_ftm_differential,
   (opponent_position_fta_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_fta_differential,
   (opponent_position_oreb_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_oreb_differential,
   (opponent_position_dreb_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_dreb_differential,
   (opponent_position_reb_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_reb_differential,
   (opponent_position_ast_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_ast_differential,
   (opponent_position_tov_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_tov_differential,
   (opponent_position_stl_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_stl_differential,
   (opponent_position_blk_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_blk_differential,
   (opponent_position_pf_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_pf_differential,
   (opponent_postion_pointscreated_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_pointscreated_differential,
   (opponent_position_misses_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_misses_differential,
   (opponent_position_ftmisses_differential/(Game_Poss_Per_Min/LgOffPossPerMin)) AS opponent_position_ftmisses_differential
INTO
	pace_adjusted_opponent_position_differential
FROM
   expected_player_stats
      LEFT JOIN 
         hinge
            ON TEAM_ID = OWN_TEAM_ID
            AND GAME_ID = OWN_GAME_ID
               LEFT JOIN
                  t1
                     ON OPPONENT_ID = t1.opponent
                     AND GAME_ID = game
                     AND POSITION = opponent_position
                        LEFT JOIN 
                           t2
                              ON GAME_ID = game_number
                                 LEFT JOIN
                                    t3 
                                       ON expected_player_stats.SEASON_ID = season_number
WHERE
   opponent_position_record = 1
   AND game_record = 1
   AND pace_record = 1
;
GO

--Season summation process seems to be skewing results

      -- 6. Season-level opponent position differentials
--------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [season_opponent_position_differential] AS
SELECT
   PLAYER_ID AS defender_id,
   PLAYER_NAME AS defender,
   TEAM_ID,
   GAME_ID,
   POSITION,
   hinge.SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   t1.game,
   t1.opponent,
   opponent_position,
   SUM(opponent_position_pts_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_pts_differential,
      SUM(opponent_position_fgm_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fgm_differential,
   SUM(opponent_position_fga_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fga_differential,
   SUM(opponent_position_fg2m_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fg2m_differential,
   SUM(opponent_position_fg2a_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fg2a_differential,
   SUM(opponent_position_fg3m_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fg3m_differential,
   SUM(opponent_position_fg3a_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fg3a_differential,
   SUM(opponent_position_ftm_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_ftm_differential,
   SUM(opponent_position_fta_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_fta_differential,
   SUM(opponent_position_oreb_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_oreb_differential,
   SUM(opponent_position_dreb_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_dreb_differential,
   SUM(opponent_position_reb_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_reb_differential,
   SUM(opponent_position_ast_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_ast_differential,
   SUM(opponent_position_tov_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_tov_differential,
   SUM(opponent_position_stl_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_stl_differential,
   SUM(opponent_position_blk_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_blk_differential,
   SUM(opponent_position_pf_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_pf_differential,
   SUM(opponent_postion_pointscreated_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_postion_pointscreated_differential,
   SUM(opponent_position_misses_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_misses_differential,
   SUM(opponent_position_ftmisses_differential) OVER (PARTITION BY TEAM_ID,POSITION,hinge.SEASON_ID ORDER BY hinge.SEASON_ID) 
      AS season_opponent_position_ftmisses_differential
FROM
   expected_player_stats
      LEFT JOIN 
         hinge
            ON TEAM_ID = OWN_TEAM_ID
            AND GAME_ID = OWN_GAME_ID
               LEFT JOIN
(
SELECT
   GAME_ID AS game,
   TEAM_ID AS opponent,
   POSITION AS opponent_position,
   SUM(PTS - expected_pts) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_pts_differential,
   SUM(FGM - expected_fgm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fgm_differential,
   SUM(FGA - expected_fga) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fga_differential,
   SUM(FG2M - expected_fg2m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg2m_differential,
   SUM(FG2A - expected_fg2a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg2a_differential,
   SUM(FG3M - expected_fg3m) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg3m_differential,
   SUM(FG3A - expected_fg3a) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fg3a_differential,
   SUM(FTM - expected_ftm) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ftm_differential,
   SUM(FTA - expected_fta) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_fta_differential,
   SUM(OREB - expected_oreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_oreb_differential,
   SUM(DREB - expected_dreb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_dreb_differential,
   SUM(REB - expected_reb) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_reb_differential,
   SUM(AST - expected_ast) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ast_differential,
   SUM(TOV - expected_tov) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_tov_differential,
   SUM(STL - expected_stl) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_stl_differential,
   SUM(BLK - expected_blk) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_blk_differential,
   SUM(PF - expected_pf) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_pf_differential,
   SUM(game_points_created - expected_pointscreated) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) 
      AS opponent_postion_pointscreated_differential,
   SUM(misses - expected_misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_misses_differential,
   SUM(ft_misses - expected_ftmisses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_ftmisses_differential,
   ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_record
FROM
   expected_player_stats
) t1
                     ON OPPONENT_ID = t1.opponent
                     AND GAME_ID = game
                     AND POSITION = opponent_position
WHERE
   opponent_position_record = 1
;
GO

      -- 7. Pace-adjusted season-level opponent differentials
-----------------------------------------------------------------------------------------------------------------------------------------------
WITH t1 AS (
SELECT
   PLAYER_ID,
   TEAM_ID,
   SEASON,
   OffPossPerMin,
   LgOffPossPerMin,
   MP,
   ROW_NUMBER() OVER (PARTITION BY PLAYER_ID,TEAM_ID,SEASON ORDER BY SEASON) AS pace_record
FROM
   totals4
),
	t2 AS (
SELECT
   defender_id,
   defender,
   --PLAYER_ID,
   t1.TEAM_ID AS tid,
   POSITION,
   MP AS minutesplayed,
   SEASON_ID,
   OWN_TEAM_ID,
   (season_opponent_position_pts_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_pts_differential,
   (season_opponent_position_fgm_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fgm_differential,
   (season_opponent_position_fga_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fga_differential,
   (season_opponent_position_fg2m_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fg2m_differential,
   (season_opponent_position_fg2a_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fg2a_differential,
   (season_opponent_position_fg3m_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fg3m_differential,
   (season_opponent_position_fg3a_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fg3a_differential,
   (season_opponent_position_ftm_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_ftm_differential,
   (season_opponent_position_fta_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_fta_differential,
   (season_opponent_position_oreb_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_oreb_differential,
   (season_opponent_position_dreb_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_dreb_differential,
   (season_opponent_position_reb_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_reb_differential,
   (season_opponent_position_ast_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_ast_differential,
   (season_opponent_position_tov_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_tov_differential,
   (season_opponent_position_stl_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_stl_differential,
   (season_opponent_position_blk_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_blk_differential,
   (season_opponent_position_pf_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_pf_differential,
   (season_opponent_postion_pointscreated_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_pointscreated_differential,
   (season_opponent_position_misses_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_misses_differential,
   (season_opponent_position_ftmisses_differential/(OffPossPerMin/LgOffPossPerMin)) AS season_opponent_position_ftmisses_differential,
   ROW_NUMBER() OVER (PARTITION BY defender_id,season_opponent_position_differential.TEAM_ID,SEASON_ID ORDER BY defender_id) AS deduplicator
FROM
   season_opponent_position_differential
      LEFT JOIN
         t1 
            ON season_opponent_position_differential.TEAM_ID = t1.TEAM_ID
            AND SEASON_ID = SEASON
			AND defender_id = PLAYER_ID
)
SELECT
	* INTO
		pace_adjusted_season_opponent_position_differential
FROM
	t1
		LEFT JOIN
			t2
				ON t1.PLAYER_ID = defender_id
				AND SEASON = SEASON_ID
WHERE 
    pace_record = 1
	AND deduplicator = 1
;
GO

      -- 8. Individual share of game-level opponent position differentials
--------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [opponent_impact] AS
SELECT
   DEFENDER_ID,
   DEFENDER,
   TEAM_ID,
   GAME_ID,
   POSITION,
   Minutes,
   SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   (opponent_position_pts_differential*(Minutes/(game_minutes/5))) AS opponent_pts_impact,
   (opponent_position_fgm_differential*(Minutes/(game_minutes/5))) AS opponent_fgm_impact,
   (opponent_position_fga_differential*(Minutes/(game_minutes/5))) AS opponent_fga_impact,
   (opponent_position_fg2m_differential*(Minutes/(game_minutes/5))) AS opponent_fg2m_impact,
   (opponent_position_fg2a_differential*(Minutes/(game_minutes/5))) AS opponent_fg2a_impact,
   (opponent_position_fg3m_differential*(Minutes/(game_minutes/5))) AS opponent_fg3m_impact,
   (opponent_position_fg3a_differential*(Minutes/(game_minutes/5))) AS opponent_fg3a_impact,
   (opponent_position_ftm_differential*(Minutes/(game_minutes/5))) AS opponent_ftm_impact,
   (opponent_position_fta_differential*(Minutes/(game_minutes/5))) AS opponent_fta_impact,
   (opponent_position_oreb_differential*(Minutes/(game_minutes/5))) AS opponent_oreb_impact,
   (opponent_position_dreb_differential*(Minutes/(game_minutes/5))) AS opponent_dreb_impact,
   (opponent_position_reb_differential*(Minutes/(game_minutes/5))) AS opponent_reb_impact,
   (opponent_position_ast_differential*(Minutes/(game_minutes/5))) AS opponent_ast_impact,
   (opponent_position_tov_differential*(Minutes/(game_minutes/5))) AS opponent_tov_impact,
   (opponent_position_stl_differential*(Minutes/(game_minutes/5))) AS opponent_stl_impact,
   (opponent_position_blk_differential*(Minutes/(game_minutes/5))) AS opponent_blk_impact,
   (opponent_position_pf_differential*(Minutes/(game_minutes/5))) AS opponent_pf_impact,
   (opponent_position_misses_differential*(Minutes/(game_minutes/5))) AS opponent_misses_impact,
   (opponent_position_ftmisses_differential*(Minutes/(game_minutes/5))) AS opponent_ftmisses_impact,
   (opponent_postion_pointscreated_differential*(Minutes/(game_minutes/5))) AS opponent_pointscreated_impact
FROM
   opponent_position_differential
      LEFT JOIN
            (
            SELECT
                GAME_ID AS gamenum,
                TEAM_ID AS teamnum,
                (CASE
                    WHEN 
                        SUM(Minutes) OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID) < 240
                    THEN
                        240
                    ELSE   
                        SUM(Minutes) OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID)
                    END
                ) AS game_minutes,
                ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID) AS row
            FROM 
                opponent_position_differential
            )
            t1
                ON GAME_ID = gamenum
                AND TEAM_ID = teamnum
WHERE
   row = 1
;
GO

      -- 9. Pace-adjusted individual share of game-level opponent position differentials
-------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [pace_adjusted_opponent_impact] AS
WITH t1 AS (
SELECT
   GAME_ID AS gamenum,
   TEAM_ID AS teamnum,
   (CASE
      WHEN 
         SUM(Minutes) OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID) < 240
      THEN
         240
      ELSE   
         SUM(Minutes) OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY GAME_ID)
      END
   ) AS game_minutes,
   ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID ORDER BY TEAM_ID) AS row
FROM 
   pace_adjusted_opponent_position_differential
)
SELECT
   DEFENDER_ID,
   DEFENDER,
   TEAM_ID,
   GAME_ID,
   POSITION,
   Minutes,
   SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   (opponent_position_pts_differential*(Minutes/(game_minutes/5))) AS opponent_pts_impact,
   (opponent_position_fgm_differential*(Minutes/(game_minutes/5))) AS opponent_fgm_impact,
   (opponent_position_fga_differential*(Minutes/(game_minutes/5))) AS opponent_fga_impact,
   (opponent_position_fg2m_differential*(Minutes/(game_minutes/5))) AS opponent_fg2m_impact,
   (opponent_position_fg2a_differential*(Minutes/(game_minutes/5))) AS opponent_fg2a_impact,
   (opponent_position_fg3m_differential*(Minutes/(game_minutes/5))) AS opponent_fg3m_impact,
   (opponent_position_fg3a_differential*(Minutes/(game_minutes/5))) AS opponent_fg3a_impact,
   (opponent_position_ftm_differential*(Minutes/(game_minutes/5))) AS opponent_ftm_impact,
   (opponent_position_fta_differential*(Minutes/(game_minutes/5))) AS opponent_fta_impact,
   (opponent_position_oreb_differential*(Minutes/(game_minutes/5))) AS opponent_oreb_impact,
   (opponent_position_dreb_differential*(Minutes/(game_minutes/5))) AS opponent_dreb_impact,
   (opponent_position_reb_differential*(Minutes/(game_minutes/5))) AS opponent_reb_impact,
   (opponent_position_ast_differential*(Minutes/(game_minutes/5))) AS opponent_ast_impact,
   (opponent_position_tov_differential*(Minutes/(game_minutes/5))) AS opponent_tov_impact,
   (opponent_position_stl_differential*(Minutes/(game_minutes/5))) AS opponent_stl_impact,
   (opponent_position_blk_differential*(Minutes/(game_minutes/5))) AS opponent_blk_impact,
   (opponent_position_pf_differential*(Minutes/(game_minutes/5))) AS opponent_pf_impact,
   (opponent_position_misses_differential*(Minutes/(game_minutes/5))) AS opponent_misses_impact,
   (opponent_position_ftmisses_differential*(Minutes/(game_minutes/5))) AS opponent_ftmisses_impact,
   (opponent_position_pointscreated_differential*(Minutes/(game_minutes/5))) AS opponent_pointscreated_impact
FROM
   pace_adjusted_opponent_position_differential
      LEFT JOIN
         t1
            ON GAME_ID = gamenum
            AND TEAM_ID = teamnum
WHERE
   row = 1
;
GO

      -- 10. Season-level opponent impact
--------------------------------------------------------------------------------------------------------------------------------------------
--This has been changed. It originally summed from (raw) opponent_impact. It now sums from pace_adjusted_opponent_impact
--Check carefully

CREATE VIEW [season_opponent_impact] AS
SELECT 
	*
FROM (
SELECT
   DEFENDER_ID,
   DEFENDER,
   TEAM_ID,
   GAME_ID,
   POSITION,
   SUM(Minutes) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS MP,
   SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   SUM(opponent_pts_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_pts_impact,
   SUM(opponent_fgm_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fgm_impact,
   SUM(opponent_fga_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fga_impact,
   SUM(opponent_fg2m_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fg2m_impact,
   SUM(opponent_fg2a_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fg2a_impact,
   SUM(opponent_fg3m_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fg3m_impact,
   SUM(opponent_fg3a_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fg3a_impact,
   SUM(opponent_ftm_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_ftm_impact,
   SUM(opponent_fta_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_fta_impact,
   SUM(opponent_oreb_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_oreb_impact,
   SUM(opponent_dreb_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_dreb_impact,
   SUM(opponent_reb_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_reb_impact,
   SUM(opponent_ast_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_ast_impact,
   SUM(opponent_tov_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_tov_impact,
   SUM(opponent_stl_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_stl_impact,
   SUM(opponent_blk_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_blk_impact,
   SUM(opponent_pf_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_pf_impact,
   SUM(opponent_misses_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_misses_impact,
   SUM(opponent_ftmisses_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_ftmisses_impact,
   SUM(opponent_pointscreated_impact) OVER (PARTITION BY SEASON_ID,DEFENDER_ID ORDER BY SEASON_ID) AS total_opponent_pointscreated_impact,
   ROW_NUMBER() OVER (PARTITION BY SEASON_ID, DEFENDER_ID ORDER BY SEASON_ID) AS season_row
FROM
   pace_adjusted_opponent_impact
) t1
WHERE
   season_row = 1
;
GO

      -- 11. Pace-adjusted season-level opponent impact
--------------------------------------------------------------------------------------------------------------------------------------------
WITH t1 AS (
SELECT 
   TEAM_ID AS tid,
   SEASON,
   (OffPossPerMin/LgOffPossPerMin) AS pace_factor,
   ROW_NUMBER () OVER (PARTITION BY TEAM_ID,SEASON ORDER BY TEAM_ID) AS pace_record
FROM
   totals4
),
	t2 AS (
SELECT
   DEFENDER_ID,
   DEFENDER,
   TEAM_ID,
   POSITION,
   SUM(MINUTES) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON) AS MP,
   SEASON_ID,
   OWN_TEAM_ID,
   OWN_GAME_ID,
   OPPONENT_ID,
   OPPONENT_GAME_ID,
   ((SUM(opponent_pts_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_pts_impact,
   ((SUM(opponent_fgm_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fgm_impact,
   ((SUM(opponent_fga_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fga_impact,
   ((SUM(opponent_fg2m_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fg2m_impact,
   ((SUM(opponent_fg2a_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fg2a_impact,
   ((SUM(opponent_fg3m_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fg3m_impact,
   ((SUM(opponent_fg3a_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fg3a_impact,
   ((SUM(opponent_ftm_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_ftm_impact,
   ((SUM(opponent_fta_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_fta_impact,
   ((SUM(opponent_oreb_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_oreb_impact,
   ((SUM(opponent_dreb_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_dreb_impact,
   ((SUM(opponent_reb_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_reb_impact,
   ((SUM(opponent_ast_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_ast_impact,
   ((SUM(opponent_tov_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_tov_impact,
   ((SUM(opponent_stl_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_stl_impact,
   ((SUM(opponent_blk_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_blk_impact,
   ((SUM(opponent_pf_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_pf_impact,
   ((SUM(opponent_misses_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_misses_impact,
   ((SUM(opponent_ftmisses_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_ftmisses_impact,
   ((SUM(opponent_pointscreated_impact) OVER (PARTITION BY SEASON,DEFENDER_ID ORDER BY SEASON))/pace_factor) AS total_opponent_pointscreated_impact,
   ROW_NUMBER() OVER (PARTITION BY SEASON, DEFENDER_ID ORDER BY SEASON) AS season_row
FROM
   opponent_impact
		LEFT JOIN
			t1
				ON TEAM_ID = tid
				AND SEASON = SEASON_ID
WHERE
   pace_record = 1
)
SELECT
	* INTO
		pace_adjustment_season_opponent_impact
FROM
	t2
		LEFT JOIN 
			t1
				ON tid = TEAM_ID
				AND SEASON = SEASON_ID
WHERE
   season_row = 1
   AND pace_record = 1
;
GO

			-- 12. Reducing in-place load
DROP TABLE
	pace_adjusted_season_opponent_position_differential,
	player_id_dict,
	both_teams_position_sums
;
GO

--End of defensive section
------------------------------------------------------------------------------------------------------------------------------------------------

-- II. Offensive analysis               
   -- A. Evaluate offense relative to expectation
      --1. Determining strength of defense faced
-------------------------------------------------------------------------------------------------------------------------------------------------
WITH 
   t1 AS (
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   TEAM_ID,
   TEAM_NAME,
   GAME_ID AS GAME,
   realposition AS POSITION,
   Minutes
FROM
   box_scores_with_positions
),
   t2 AS (
SELECT
   GAME_ID,
   TEAM_ABBREVIATION AS opponent_name,
   TEAM_ID AS opponent_number,
   SEASON_ID,
   POSITION AS opponent_position,
   SUM(opp_game_pts) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_pts,
   SUM(opp_game_fgm) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fgm,
   SUM(opp_game_fga) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fga,
   SUM(opp_game_fg2m) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fg2m,
   SUM(opp_game_fg2a) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fg2a,
   SUM(opp_game_fg3m) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fg3m,
   SUM(opp_game_fg3a) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fg3a,
   SUM(opp_game_ftm) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_ftm,
   SUM(opp_game_fta) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_fta,
   SUM(opp_game_oreb) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_oreb,
   SUM(opp_game_dreb) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_dreb,
   SUM(opp_game_reb) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_reb,
   SUM(opp_game_ast) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_ast,
   SUM(opp_game_tov) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_tov,
   SUM(opp_game_stl) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_stl,
   SUM(opp_game_blk) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_blk,
   SUM(opp_game_pf) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_pf,
   SUM(opp_game_misses) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_misses,
   SUM(opp_game_ftmisses) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_ftmisses,
   SUM(opp_game_minutes) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_minutes,
   SUM(opp_game_plusminus) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_plusminus,
   SUM(opponent_position_points_created) OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS defense_position_pointscreated,
   ROW_NUMBER () OVER (PARTITION BY TEAM_ID,SEASON_ID,POSITION ORDER BY SEASON_ID) AS opponent_position_record
FROM
   game_sums_by_position
WHERE 
   opponent_position_record = 1
),
   t3 AS (
SELECT
   TEAM_NAME AS defense,
   TEAM_ID AS defense_id,
   SEASON_ID AS year_id,
   (opp_fga + (0.4*opp_fta) + opp_tov - opp_oreb) AS defense_possessions,
   ROW_NUMBER () OVER (PARTITION BY TEAM_ID, SEASON_ID ORDER BY SEASON_ID) AS opponent_record
FROM
   team_and_opp_season_sums
)
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   TEAM_ID,
   TEAM_NAME,
   POSITION,
   GAME_ID,
   opponent,
   opponent_id,
   MINUTES,
   t2.SEASON_ID,
   opponent_position,
   (defense_position_pts/defense_possessions) AS defense_ptspp,
   (defense_position_fgm/defense_possessions) AS defense_fgmpp,
   (defense_position_fga/defense_possessions) AS defense_fgapp,
   (defense_position_fg2m/defense_possessions) AS defense_fg2mpp,
   (defense_position_fg2a/defense_possessions) AS defense_fg2app,
   (defense_position_fg3m/defense_possessions) AS defense_fg3mpp,
   (defense_position_fg3a/defense_possessions) AS defense_fg3app,
   (defense_position_ftm/defense_possessions) AS defense_ftmpp,
   (defense_position_fta/defense_possessions) AS defense_ftapp,
   (defense_position_oreb/defense_possessions) AS defense_orebpp,
   (defense_position_dreb/defense_possessions) AS defense_drebpp,
   (defense_position_reb/defense_possessions) AS defense_rebpp,
   (defense_position_ast/defense_possessions) AS defense_astpp,
   (defense_position_tov/defense_possessions) AS defense_tovpp,
   (defense_position_stl/defense_possessions) AS defense_stlpp,
   (defense_position_blk/defense_possessions) AS defense_blkpp,
   (defense_position_pf/defense_possessions) AS defense_pfpp,
   (defense_position_plusminus/defense_possessions) AS defense_plusminuspp,
   (defense_position_misses/defense_possessions) AS defense_missespp,
   (defense_position_ftmisses/defense_possessions) AS defense_ftmissespp,
   (defense_position_pointscreated/defense_possessions) AS defense_pointscreatedpp,
   defense_possessions
INTO
   quality_of_opponent_defense   
FROM
   t1
      LEFT JOIN
         hinge
            ON GAME = OWN_GAME_ID
            AND TEAM_ID = OWN_TEAM_ID
               LEFT JOIN
                  t2
                     ON GAME = GAME_ID
                     AND OPPONENT_ID = opponent_number
                     AND POSITION = opponent_position
                        LEFT JOIN
                           t3
                              ON opponent_number = defense_id
                              AND t2.SEASON_ID = year_id

WHERE
   opponent_record = 1
;
GO

      -- 2. Expected offensive stats
-------------------------------------------------------------------------------------------------------------------------------------------
WITH 
   t1 AS (
SELECT
   GAME_ID AS game,
   Game_Poss_Per_Min,
   ROW_NUMBER () OVER (PARTITION BY GAME_ID ORDER BY GAME_ID) AS game_num
FROM
   game_pace
),
   t2 AS (
SELECT
   SEASON AS year,
   (((SUM(pts) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5)  AS avg_ptspp,
   (((SUM(fgm) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_fgmpp,
   (((SUM(fga) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_fgapp,
   (((SUM(fg2m) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_fg2mpp,
   (((SUM(fg2a) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_fg2app,
   (((SUM(fg3m) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_fg3mpp,
   (((SUM(fg3a) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_fg3app,
   (((SUM(ftm) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_ftmpp,
   (((SUM(fta) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_ftapp,
   (((SUM(oreb) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_orebpp,
   (((SUM(dreb) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_drebpp,
   (((SUM(reb) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_rebpp,
   (((SUM(ast) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_astpp,
   (((SUM(tov) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_tovpp,
   (((SUM(stl) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_stlpp,
   (((SUM(blk) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_blkpp,
   (((SUM(pf) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_pfpp,
   (((SUM(misses) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_missespp,
   (((SUM(FT_MISSES) OVER (PARTITION BY SEASON))/(LgOffPoss*count_teams))/5) AS avg_ftmissespp,
   ROW_NUMBER () OVER (PARTITION BY SEASON ORDER BY SEASON) AS season_record
FROM
   totals4
),

	t3 AS (
SELECT
	SEASON_ID AS SEASON_ID_NUMBER,
	((total_pc/total_poss)/5) AS avg_pointscreatedpp,
	ROW_NUMBER() OVER (PARTITION BY SEASON_ID ORDER BY SEASON_ID) AS pc_row
FROM	
	(
SELECT
	SEASON_ID,
	SUM(game_points_created) OVER (PARTITION BY SEASON_ID) as total_pc,
	ROW_NUMBER () OVER (PARTITION BY SEASON_ID ORDER BY SEASON_ID) AS sub_row_1 
FROM
	game_points_created
) subtable1
		LEFT JOIN
			(
SELECT
	SEASON,
	LgOffPoss*count_teams AS total_poss,
	ROW_NUMBER () OVER (PARTITION BY SEASON ORDER BY SEASON) AS sub_row_2
FROM
	totals4
) subtable2
				ON SEASON_ID = SEASON
WHERE
	sub_row_1 = 1
	AND sub_row_2 = 1
)
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   GAME_ID,
   TEAM_NAME,
   TEAM_ID,
   POSITION,
   SEASON_ID,
   OPPONENT,
   OPPONENT_ID,
   Minutes,
   Game_Poss_Per_Min,
   (defense_ptspp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_pts,
   (defense_fgmpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fgm,
   (defense_fgapp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fga,
   (defense_fg2mpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fg2m,
   (defense_fg2app*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fg2a,
   (defense_fg3mpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fg3m,
   (defense_fg3app*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fg3a,
   (defense_ftmpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_ftm,
   (defense_ftapp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_fta,
   (defense_orebpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_oreb,
   (defense_drebpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_dreb,
   (defense_rebpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_reb,
   (defense_astpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_ast,
   (defense_tovpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_tov,
   (defense_stlpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_stl,
   (defense_blkpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_blk,
   (defense_pfpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_pf,
   (defense_missespp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_misses,
   (defense_ftmissespp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_ftmisses,
   (defense_pointscreatedpp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_pointscreated,
   (defense_plusminuspp*Minutes*Game_Poss_Per_Min) AS opponent_based_expected_plusminus,
   (avg_ptspp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_pts,
   (avg_fgmpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fgm,
   (avg_fgapp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fga,
   (avg_fg2mpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fg2m,
   (avg_fg2app*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fg2a,
   (avg_fg3mpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fg3m,
   (avg_fg3app*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fg3a,
   (avg_ftmpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_ftm,
   (avg_ftapp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_fta,
   (avg_orebpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_oreb,
   (avg_drebpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_dreb,
   (avg_rebpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_reb,
   (avg_astpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_ast,
   (avg_tovpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_tov,
   (avg_stlpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_stl,
   (avg_blkpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_blk,
   (avg_pfpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_pf,
   (avg_missespp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_misses,
   (avg_ftmissespp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_ftmisses,
   (avg_pointscreatedpp*Minutes*Game_Poss_Per_Min) AS avg_based_expected_pointscreated
INTO
	expected_offense
FROM
   quality_of_opponent_defense
      LEFT JOIN 
         t1 
            ON GAME_ID = game
               LEFT JOIN 
                  t2
                     ON SEASON_ID = year
						LEFT JOIN
							t3
								ON SEASON_ID = SEASON_ID_NUMBER
WHERE
   game_num = 1
   AND season_record = 1
   AND pc_row = 1
;
GO

      -- 3. Offensive differentials at game level
-----------------------------------------------------------------------------------------------------------------------------------------------
WITH t1 AS (
SELECT
   PLAYER_ID AS playerid,
   PLAYER_NAME AS name,
   GAME_ID AS gameid,
   TEAM_ABBREVIATION,
   TEAM_ID AS teamid,
   SEASON_ID AS seasonid,
   PTS,
   FGM,
   FGA,
   (FGM - FG3M) AS FG2M,
   (FGA - FG3A) AS FG2A,
   FG3M,
   FG3A,
   FTM,
   FTA,
   OREB,
   DREB,
   REB,
   AST,
   TOV,
   STL,
   BLK,
   PF,
   (FGA - FGM) AS MISSES,
   (FTA - FTM) AS FT_MISSES,
   --PLUS_MINUS,
   game_points_created,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   (FTM/FTA) AS FTPERCENT,
   EFG,
   TS,
   ROW_NUMBER () OVER (PARTITION BY PLAYER_ID,GAME_ID ORDER BY GAME_ID) AS line
FROM
   points_created_master
)
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   GAME_ID,
   TEAM_ABBREVIATION,
   TEAM_ID,
   POSITION,
   SEASON_ID,
   OPPONENT,
   OPPONENT_ID,
   Minutes,
   Game_Poss_Per_Min,
   (PTS - opponent_based_expected_pts) AS opponent_based_pts_differential,
   (FGM - opponent_based_expected_fgm) AS opponent_based_fgm_differential,
   (FGA - opponent_based_expected_fga) AS opponent_based_fga_differential,
   (FG2M - opponent_based_expected_fg2m) AS opponent_based_fg2m_differential,
   (FG2A - opponent_based_expected_fg2a) AS opponent_based_fg2a_differential,
   (FG3M - opponent_based_expected_fg3m) AS opponent_based_fg3m_differential,
   (FG3A - opponent_based_expected_fg3a) AS opponent_based_fg3a_differential,
   (FTM - opponent_based_expected_ftm) AS opponent_based_ftm_differential,
   (FTA - opponent_based_expected_fta) AS opponent_based_fta_differential,
   (OREB - opponent_based_expected_oreb) AS opponent_based_oreb_differential,
   (DREB - opponent_based_expected_dreb) AS opponent_based_dreb_differential,
   (REB - opponent_based_expected_reb) AS opponent_based_reb_differential,
   (AST - opponent_based_expected_ast) AS opponent_based_ast_differential,
   (TOV - opponent_based_expected_tov) AS opponent_based_tov_differential,
   (STL - opponent_based_expected_stl) AS opponent_based_stl_differential,
   (BLK - opponent_based_expected_blk) AS opponent_based_blk_differential,
   (PF - opponent_based_expected_pf) AS opponent_based_pf_differential,
   (MISSES - opponent_based_expected_misses) AS opponent_based_misses_differential,
   (FT_MISSES - opponent_based_expected_ftmisses) AS opponent_based_ftmisses_differential,
   --(PLUS_MINUS - opponent_based_expected_plusminus) AS opponent_based_plusminus_differential,
   (game_points_created - opponent_based_expected_pointscreated) AS opponent_based_pointscreated_differential,
   (PTS - avg_based_expected_pts) AS avg_based_pts_differential,
   (FGM - avg_based_expected_fgm) AS avg_based_fgm_differential,
   (FGA - avg_based_expected_fga) AS avg_based_fga_differential,
   (FG2M - avg_based_expected_fg2m) AS avg_based_fg2m_differential,
   (FG2A - avg_based_expected_fg2a) AS avg_based_fg2a_differential,
   (FG3M - avg_based_expected_fg3m) AS avg_based_fg3m_differential,
   (FG3A - avg_based_expected_fg3a) AS avg_based_fg3a_differential,
   (FTM - avg_based_expected_ftm) AS avg_based_ftm_differential,
   (FTA - avg_based_expected_fta) AS avg_based_fta_differential,
   (OREB - avg_based_expected_oreb) AS avg_based_oreb_differential,
   (DREB - avg_based_expected_dreb) AS avg_based_dreb_differential,
   (REB - avg_based_expected_reb) AS avg_based_reb_differential,
   (AST - avg_based_expected_ast) AS avg_based_ast_differential,
   (TOV - avg_based_expected_tov) AS avg_based_tov_differential,
   (STL - avg_based_expected_stl) AS avg_based_stl_differential,
   (BLK - avg_based_expected_blk) AS avg_based_blk_differential,
   (PF - avg_based_expected_pf) AS avg_based_pf_differential,
   (MISSES - avg_based_expected_misses) AS avg_based_misses_differential,
   (FT_MISSES - avg_based_expected_ftmisses) AS avg_based_ftmisses_differential,
   --(PLUS_MINUS - avg_based_expected_plusminus) AS avg_based_plusminus_differential,
   (game_points_created - avg_based_expected_pointscreated) AS avg_based_pointscreated_differential,
   game_points_created,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   FTPERCENT,
   EFG,
   TS
INTO
   offensive_differentials
FROM
   expected_offense
      LEFT JOIN
         t1
            ON GAME_ID = gameid
            AND PLAYER_ID = playerid
WHERE
   line = 1;
GO

      -- 4. Pace-adjusted game-level offensive differentials
------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [pace_adjusted_offensive_differentials] AS
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   GAME_ID,
   TEAM_ABBREVIATION,
   TEAM_ID,
   POSITION,
   SEASON_ID,
   OPPONENT,
   OPPONENT_ID,
   Minutes,
   Game_Poss_Per_Min,
   (opponent_based_pts_differential/pace_factor) AS pace_adjusted_opponent_based_pts_differential,
   (opponent_based_fgm_differential/pace_factor) AS pace_adjusted_opponent_based_fgm_differential,
   (opponent_based_fga_differential/pace_factor) AS pace_adjusted_opponent_based_fga_differential,
   (opponent_based_fg2m_differential/pace_factor) AS pace_adjusted_opponent_based_fg2m_differential,
   (opponent_based_fg2a_differential/pace_factor) AS pace_adjusted_opponent_based_fg2a_differential,
   (opponent_based_fg3m_differential/pace_factor) AS pace_adjusted_opponent_based_fg3m_differential,
   (opponent_based_fg3a_differential/pace_factor) AS pace_adjusted_opponent_based_fg3a_differential,
   (opponent_based_ftm_differential/pace_factor) AS pace_adjusted_opponent_based_ftm_differential,
   (opponent_based_fta_differential/pace_factor) AS pace_adjusted_opponent_based_fta_differential,
   (opponent_based_oreb_differential/pace_factor) AS pace_adjusted_opponent_based_oreb_differential,
   (opponent_based_dreb_differential/pace_factor) AS pace_adjusted_opponent_based_dreb_differential,
   (opponent_based_reb_differential/pace_factor) AS pace_adjusted_opponent_based_reb_differential,
   (opponent_based_ast_differential/pace_factor) AS pace_adjusted_opponent_based_ast_differential,
   (opponent_based_tov_differential/pace_factor) AS pace_adjusted_opponent_based_tov_differential,
   (opponent_based_stl_differential/pace_factor) AS pace_adjusted_opponent_based_stl_differential,
   (opponent_based_blk_differential/pace_factor) AS pace_adjusted_opponent_based_blk_differential,
   (opponent_based_pf_differential/pace_factor) AS pace_adjusted_opponent_based_pf_differential,
   (opponent_based_misses_differential/pace_factor) AS pace_adjusted_opponent_based_misses_differential,
   (opponent_based_ftmisses_differential/pace_factor) AS pace_adjusted_opponent_based_ftmisses_differential,
   --(opponent_based_plusminus_differential/pace_factor) AS pace_adjusted_opponent_based_plusminus_differential,
   (opponent_based_pointscreated_differential/pace_factor) AS pace_adjusted_opponent_based_pointscreated_differential,
   (avg_based_pts_differential/pace_factor) AS pace_adjusted_avg_based_pts_differential,
   (avg_based_fgm_differential/pace_factor) AS pace_adjusted_avg_based_fgm_differential,
   (avg_based_fga_differential/pace_factor) AS pace_adjusted_avg_based_fga_differential,
   (avg_based_fg2m_differential/pace_factor) AS pace_adjusted_avg_based_fg2m_differential,
   (avg_based_fg2a_differential/pace_factor) AS pace_adjusted_avg_based_fg2a_differential,
   (avg_based_fg3m_differential/pace_factor) AS pace_adjusted_avg_based_fg3m_differential,
   (avg_based_fg3a_differential/pace_factor) AS pace_adjusted_avg_based_fg3a_differential,
   (avg_based_ftm_differential/pace_factor) AS pace_adjusted_avg_based_ftm_differential,
   (avg_based_fta_differential/pace_factor) AS pace_adjusted_avg_based_fta_differential,
   (avg_based_oreb_differential/pace_factor) AS pace_adjusted_avg_based_oreb_differential,
   (avg_based_dreb_differential/pace_factor) AS pace_adjusted_avg_based_dreb_differential,
   (avg_based_reb_differential/pace_factor) AS pace_adjusted_avg_based_reb_differential,
   (avg_based_ast_differential/pace_factor) AS pace_adjusted_avg_based_ast_differential,
   (avg_based_tov_differential/pace_factor) AS pace_adjusted_avg_based_tov_differential,
   (avg_based_stl_differential/pace_factor) AS pace_adjusted_avg_based_stl_differential,
   (avg_based_blk_differential/pace_factor) AS pace_adjusted_avg_based_blk_differential,
   (avg_based_pf_differential/pace_factor) AS pace_adjusted_avg_based_pf_differential,
   (avg_based_misses_differential/pace_factor) AS pace_adjusted_avg_based_misses_differential,
   (avg_based_ftmisses_differential/pace_factor) AS pace_adjusted_avg_based_ftmisses_differential,
   --(avg_based_plusminus_differential/pace_factor) AS pace_adjusted_avg_based_plusminus_differential,
   (avg_based_pointscreated_differential/pace_factor) AS pace_adjusted_avg_based_pointscreated_differential,
   --(PLUS_MINUS/pace_factor) AS pace_adjusted_plus_minus,
   (game_points_created/pace_factor) AS pace_adjusted_game_points_created,
   FGPERCENT AS FG_PERCENT,
   FG2PERCENT AS FG2_PERCENT,
   FG3PERCENT AS FG3_PERCENT,
   FTPERCENT AS FT_PERCENT,
   EFG,
   TS
FROM
   offensive_differentials
		LEFT JOIN
			(
SELECT
	TEAM_ID AS tid,
	SEASON AS sid,
	(OffPossPerMin/LgOffPossPerMin) AS pace_factor,
	ROW_NUMBER () OVER (PARTITION BY TEAM_ID,SEASON ORDER BY TEAM_ID) AS pace_row
FROM
	totals4
) t1
				ON TEAM_ID = tid
				AND SEASON_ID = sid
WHERE
	pace_row = 1
;
GO

      -- 6. offensive differentials at season level
--------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [season_offensive_impact] AS
SELECT 
	*
FROM
(SELECT
   PLAYER_ID,
   PLAYER_NAME,
   GAME_ID,
   TEAM_ABBREVIATION,
   TEAM_ID,
   POSITION,
   SEASON_ID,
   SUM(opponent_based_pts_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_pts_differential,
   SUM(opponent_based_fgm_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fgm_differential,
   SUM(opponent_based_fga_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fga_differential,
   SUM(opponent_based_fg2m_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fg2m_differential,
   SUM(opponent_based_fg2a_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fg2a_differential,
   SUM(opponent_based_fg3m_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fg3m_differential,
   SUM(opponent_based_fg3a_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fg3a_differential,
   SUM(opponent_based_ftm_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_ftm_differential,
   SUM(opponent_based_fta_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_fta_differential,
   SUM(opponent_based_oreb_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_oreb_differential,
   SUM(opponent_based_dreb_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_dreb_differential,
   SUM(opponent_based_reb_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_reb_differential,
   SUM(opponent_based_ast_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_ast_differential,
   SUM(opponent_based_tov_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_tov_differential,
   SUM(opponent_based_stl_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_stl_differential,
   SUM(opponent_based_blk_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_blk_differential,
   SUM(opponent_based_pf_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_pf_differential,
   SUM(opponent_based_misses_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_misses_differential,
   SUM(opponent_based_ftmisses_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_ftmisses_differential,
   --SUM(opponent_based_plusminus_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_plusminus_differential,
   SUM(opponent_based_pointscreated_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_opponent_based_pointscreated_differential,
   SUM(avg_based_pts_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_pts_differential,
   SUM(avg_based_fgm_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fgm_differential,
   SUM(avg_based_fga_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fga_differential,
   SUM(avg_based_fg2m_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fg2m_differential,
   SUM(avg_based_fg2a_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fg2a_differential,
   SUM(avg_based_fg3m_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fg3m_differential,
   SUM(avg_based_fg3a_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fg3a_differential,
   SUM(avg_based_ftm_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_ftm_differential,
   SUM(avg_based_fta_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_fta_differential,
   SUM(avg_based_oreb_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_oreb_differential,
   SUM(avg_based_dreb_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_dreb_differential,
   SUM(avg_based_reb_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_reb_differential,
   SUM(avg_based_ast_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_ast_differential,
   SUM(avg_based_tov_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_tov_differential,
   SUM(avg_based_stl_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_stl_differential,
   SUM(avg_based_blk_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_blk_differential,
   SUM(avg_based_pf_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_pf_differential,
   SUM(avg_based_misses_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_misses_differential,
   SUM(avg_based_ftmisses_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_ftmisses_differential,
   --SUM(avg_based_plusminus_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_plusminus_differential,
   SUM(avg_based_pointscreated_differential) OVER (PARTITION BY PLAYER_ID,SEASON_ID) AS total_position_based_pointscreated_differential,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   FTPERCENT,
   EFG,
   TS,
   ROW_NUMBER () OVER (PARTITION BY PLAYER_ID,SEASON_ID ORDER BY PLAYER_ID) AS player_record
FROM
   offensive_differentials
) t1
WHERE
   player_record = 1
;
GO

      -- 7. Pace-adjusted season-level offensive differentials
------------------------------------------------------------------------------------------------------------------------------------
WITH t1 AS (
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   GAME_ID,
   TEAM_ABBREVIATION,
   TEAM_ID,
   POSITION,
   SEASON_ID,
   OPPONENT,
   OPPONENT_ID,
   SUM(Minutes) OVER (PARTITION BY SEASON_ID,PLAYER_ID) AS MP, 
-- opponent-based

   SUM(pace_adjusted_opponent_based_pts_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_pts_differential,
   SUM(pace_adjusted_opponent_based_fgm_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fgm_differential,
   SUM(pace_adjusted_opponent_based_fga_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fga_differential,
   SUM(pace_adjusted_opponent_based_fg2m_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fg2m_differential,
   SUM(pace_adjusted_opponent_based_fg2a_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fg2a_differential,
   SUM(pace_adjusted_opponent_based_fg3m_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fg3m_differential,
   SUM(pace_adjusted_opponent_based_fg3a_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fg3a_differential,
   SUM(pace_adjusted_opponent_based_ftm_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_ftm_differential,
   SUM(pace_adjusted_opponent_based_fta_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_fta_differential,
   SUM(pace_adjusted_opponent_based_oreb_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_oreb_differential,
   SUM(pace_adjusted_opponent_based_dreb_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_dreb_differential,
   SUM(pace_adjusted_opponent_based_reb_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_reb_differential,
   SUM(pace_adjusted_opponent_based_ast_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_ast_differential,
   SUM(pace_adjusted_opponent_based_tov_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_tov_differential,
   SUM(pace_adjusted_opponent_based_stl_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_stl_differential,
   SUM(pace_adjusted_opponent_based_blk_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_blk_differential,
   SUM(pace_adjusted_opponent_based_pf_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_pf_differential,
   SUM(pace_adjusted_opponent_based_misses_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_misses_differential,
   SUM(pace_adjusted_opponent_based_ftmisses_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_ftmisses_differential,
   --SUM(pace_adjusted_opponent_based_plusminus_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      --AS total_opponent_based_plusminus_differential,
   SUM(pace_adjusted_opponent_based_pointscreated_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_opponent_based_pointscreated_differential,
-- avg-based

   SUM(pace_adjusted_avg_based_pts_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_pts_differential,
   SUM(pace_adjusted_avg_based_fgm_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fgm_differential,
   SUM(pace_adjusted_avg_based_fga_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fga_differential,
   SUM(pace_adjusted_avg_based_fg2m_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fg2m_differential,
   SUM(pace_adjusted_avg_based_fg2a_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fg2a_differential,
   SUM(pace_adjusted_avg_based_fg3m_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fg3m_differential,
   SUM(pace_adjusted_avg_based_fg3a_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fg3a_differential,
   SUM(pace_adjusted_avg_based_ftm_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_ftm_differential,
   SUM(pace_adjusted_avg_based_fta_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_fta_differential,
   SUM(pace_adjusted_avg_based_oreb_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_oreb_differential,
   SUM(pace_adjusted_avg_based_dreb_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_dreb_differential,
   SUM(pace_adjusted_avg_based_reb_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_reb_differential,
   SUM(pace_adjusted_avg_based_ast_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_ast_differential,
   SUM(pace_adjusted_avg_based_tov_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_tov_differential,
   SUM(pace_adjusted_avg_based_stl_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_stl_differential,
   SUM(pace_adjusted_avg_based_blk_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_blk_differential,
   SUM(pace_adjusted_avg_based_pf_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_pf_differential,
   SUM(pace_adjusted_avg_based_misses_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_misses_differential,
   SUM(pace_adjusted_avg_based_ftmisses_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_ftmisses_differential,
   --SUM(pace_adjusted_avg_based_plusminus_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      --AS total_avg_based_plusminus_differential,
   SUM(pace_adjusted_avg_based_pointscreated_differential) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_avg_based_pointscreated_differential,
   --SUM(pace_adjusted_plus_minus) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      --AS total_plusminus,
   SUM(pace_adjusted_game_points_created) OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) 
      AS total_pointscreated,
   ROW_NUMBER () OVER (PARTITION BY SEASON_ID,PLAYER_ID ORDER BY PLAYER_ID) AS t1_row
FROM
   pace_adjusted_offensive_differentials
)
SELECT
	* INTO
		pace_adjusted_season_offensive_impact
FROM 
	t1
WHERE
	t1_row = 1
;
GO

      -- 8. Season-level standard deviations
--------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [season_offensive_stdevs] AS
SELECT
	*
FROM (
SELECT
   PLAYER_ID,
   PLAYER_NAME,
   TEAM_ABBREVIATION,
   TEAM_ID,
   POSITION,
   SEASON_ID,
   inner_table.MP,
   STDEV(total_opponent_based_pts_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_pts_differential,
   STDEV(total_opponent_based_fgm_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fgm_differential,
   STDEV(total_opponent_based_fga_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fga_differential,
   STDEV(total_opponent_based_fg2m_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fg2m_differential,
   STDEV(total_opponent_based_fg2a_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fg2a_differential,
   STDEV(total_opponent_based_fg3m_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fg3m_differential,
   STDEV(total_opponent_based_fg3a_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fg3a_differential,
   STDEV(total_opponent_based_ftm_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_ftm_differential,
   STDEV(total_opponent_based_fta_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_fta_differential,
   STDEV(total_opponent_based_oreb_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_oreb_differential,
   STDEV(total_opponent_based_dreb_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_dreb_differential,
   STDEV(total_opponent_based_reb_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_reb_differential,
   STDEV(total_opponent_based_ast_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_ast_differential,
   STDEV(total_opponent_based_tov_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_tov_differential,
   STDEV(total_opponent_based_stl_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_stl_differential,
   STDEV(total_opponent_based_blk_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_blk_differential,
   STDEV(total_opponent_based_pf_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_pf_differential,
   STDEV(total_opponent_based_misses_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_misses_differential,
   STDEV(total_opponent_based_ftmisses_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_ftmisses_differential,
   STDEV(total_opponent_based_pointscreated_differential) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_based_pointscreated_differential,
   STDEV(total_avg_based_pts_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_pts_differential,
   STDEV(total_avg_based_fgm_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fgm_differential,
   STDEV(total_avg_based_fga_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fga_differential,
   STDEV(total_avg_based_fg2m_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fg2m_differential,
   STDEV(total_avg_based_fg2a_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fg2a_differential,
   STDEV(total_avg_based_fg3m_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fg3m_differential,
   STDEV(total_avg_based_fg3a_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fg3a_differential,
   STDEV(total_avg_based_ftm_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_ftm_differential,
   STDEV(total_avg_based_fta_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_fta_differential,
   STDEV(total_avg_based_oreb_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_oreb_differential,
   STDEV(total_avg_based_dreb_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_dreb_differential,
   STDEV(total_avg_based_reb_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_reb_differential,
   STDEV(total_avg_based_ast_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_ast_differential,
   STDEV(total_avg_based_tov_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_tov_differential,
   STDEV(total_avg_based_stl_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_stl_differential,
   STDEV(total_avg_based_blk_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_blk_differential,
   STDEV(total_avg_based_pf_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_pf_differential,
   STDEV(total_avg_based_misses_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_misses_differential,
   STDEV(total_avg_based_ftmisses_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_ftmisses_differential,
   STDEV(total_avg_based_pointscreated_differential) OVER (PARTITION BY SEASON_ID) AS stdev_avg_based_pointscreated_differential,
   STDEV(FGPERCENT) OVER (PARTITION BY SEASON_ID) AS stdev_fg_percent,
   STDEV(FG2PERCENT) OVER (PARTITION BY SEASON_ID) AS stdev_fg2_percent,
   STDEV(FG3PERCENT) OVER (PARTITION BY SEASON_ID) AS stdev_fg3_percent,
   STDEV(FTPERCENT) OVER (PARTITION BY SEASON_ID) AS stdev_ft_percent,
   STDEV(EFG) OVER (PARTITION BY SEASON_ID) AS stdev_efg,
   STDEV(TS) OVER (PARTITION BY SEASON_ID) AS stdev_ts,
   ROW_NUMBER () OVER (PARTITION BY PLAYER_ID,SEASON_ID ORDER BY SEASON_ID) AS season_record
FROM
   pace_adjusted_season_offensive_impact
        LEFT JOIN
            (SELECT
                PLAYER_ID AS pid,
                SEASON AS s,
                MP,
				FGPERCENT,
				FG2PERCENT,
				FG3PERCENT,
				FTPERCENT,
				EFG,
				TS,
                ROW_NUMBER () OVER (PARTITION BY PLAYER_ID,SEASON ORDER BY SEASON) AS r
            FROM
                totals4
            ) inner_table
                ON PLAYER_ID = pid 
                AND SEASON_ID = s
WHERE
    r = 1
) t1
WHERE
   season_record = 1
;

-- III. Combine offense and defense
   -- A. Calculate z-scores and combine offense with defense	
      -- 1. Game-level offensive and defensive z-scores						
-------------------------------------------------------------------------------------------------------------------------------------
GO
WITH 
	t1 AS (
SELECT
   DEFENDER_ID AS defenderid,
   DEFENDER AS defendername,
   TEAM_ID AS tid,
   SEASON_ID,
   SUM(opponent_pts_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_pts_impact,
   SUM(opponent_fgm_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fgm_impact,
   SUM(opponent_fga_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fga_impact,
   SUM(opponent_fg2m_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fg2m_impact,
   SUM(opponent_fg2a_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fg2a_impact,
   SUM(opponent_fg3m_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fg3m_impact,
   SUM(opponent_fg3a_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fg3a_impact,
   SUM(opponent_ftm_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_ftm_impact,
   SUM(opponent_fta_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_fta_impact,
   SUM(opponent_oreb_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_oreb_impact,
   SUM(opponent_dreb_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_dreb_impact,
   SUM(opponent_reb_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_reb_impact,
   SUM(opponent_ast_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_ast_impact,
   SUM(opponent_tov_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_tov_impact,
   SUM(opponent_stl_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_stl_impact,
   SUM(opponent_blk_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_blk_impact,
   SUM(opponent_pf_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_pf_impact,
   SUM(opponent_misses_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_misses_impact,
   SUM(opponent_ftmisses_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_ftmisses_impact,
   SUM(opponent_pointscreated_impact) OVER (PARTITION BY DEFENDER_ID,SEASON_ID) AS opponent_pointscreated_impact,
   ROW_NUMBER () OVER (PARTITION BY DEFENDER_ID,SEASON_ID ORDER BY DEFENDER_ID) AS t1_record
FROM
   pace_adjusted_opponent_impact
) 
SELECT
	* INTO
		defensive_stdevs
FROM
	t1
		LEFT JOIN
			(
SELECT
   SEASON_ID AS yearnum,
   STDEV(opponent_pts_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_pts_impact,
   STDEV(opponent_fgm_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fgm_impact,
   STDEV(opponent_fga_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fga_impact,
   STDEV(opponent_fg2m_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fg2m_impact,
   STDEV(opponent_fg2a_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fg2a_impact,
   STDEV(opponent_fg3m_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fg3m_impact,
   STDEV(opponent_fg3a_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fg3a_impact,
   STDEV(opponent_ftm_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_ftm_impact,
   STDEV(opponent_fta_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_fta_impact,
   STDEV(opponent_oreb_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_oreb_impact,
   STDEV(opponent_dreb_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_dreb_impact,
   STDEV(opponent_reb_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_reb_impact,
   STDEV(opponent_ast_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_ast_impact,
   STDEV(opponent_tov_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_tov_impact,
   STDEV(opponent_stl_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_stl_impact,
   STDEV(opponent_blk_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_blk_impact,
   STDEV(opponent_pf_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_pf_impact,
   STDEV(opponent_misses_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_misses_impact,
   STDEV(opponent_ftmisses_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_ftmisses_impact,
   STDEV(opponent_pointscreated_impact) OVER (PARTITION BY SEASON_ID) AS stdev_opponent_pointscreated_impact,
   ROW_NUMBER () OVER (PARTITION BY SEASON_ID ORDER BY SEASON_ID) AS t2_record
FROM
   t1
WHERE
	t1_record = 1
) t2
	ON SEASON_ID = yearnum
WHERE
	t1_record = 1
	AND t2_record = 1
;
GO

--This has the season values for defense, but only game-level values for offense
--Compare outputs for pace_adjusted_offensive_differentials and season_adjusted_offensive_impact
CREATE VIEW [combined_impact] AS
SELECT
   pace_adjusted_season_offensive_impact.PLAYER_ID,
   pace_adjusted_season_offensive_impact.PLAYER_NAME,
   pace_adjusted_season_offensive_impact.TEAM_ABBREVIATION,
   pace_adjusted_season_offensive_impact.TEAM_ID,
   pace_adjusted_season_offensive_impact.SEASON_ID,
   (total_opponent_based_pts_differential/stdev_opponent_based_pts_differential) AS opponent_based_pts_z,
   (total_opponent_based_fgm_differential/stdev_opponent_based_fgm_differential) AS opponent_based_fgm_z,
   (total_opponent_based_fga_differential/stdev_opponent_based_fga_differential) AS opponent_based_fga_z,
   (total_opponent_based_fg2m_differential/stdev_opponent_based_fg2m_differential) AS opponent_based_fg2m_z,
   (total_opponent_based_fg2a_differential/stdev_opponent_based_fg2a_differential) AS opponent_based_fg2a_z,
   (total_opponent_based_fg3m_differential/stdev_opponent_based_fg3m_differential) AS opponent_based_fg3m_z,
   (total_opponent_based_fg3a_differential/stdev_opponent_based_fg3a_differential) AS opponent_based_fg3a_z,
   (total_opponent_based_ftm_differential/stdev_opponent_based_ftm_differential) AS opponent_based_ftm_z,
   (total_opponent_based_fta_differential/stdev_opponent_based_fta_differential) AS opponent_based_fta_z,
   (total_opponent_based_oreb_differential/stdev_opponent_based_oreb_differential) AS opponent_based_oreb_z,
   (total_opponent_based_dreb_differential/stdev_opponent_based_dreb_differential) AS opponent_based_dreb_z,
   (total_opponent_based_reb_differential/stdev_opponent_based_reb_differential) AS opponent_based_reb_z,
   (total_opponent_based_ast_differential/stdev_opponent_based_ast_differential) AS opponent_based_ast_z,
   (total_opponent_based_tov_differential/stdev_opponent_based_tov_differential) AS opponent_based_tov_z,
   (total_opponent_based_stl_differential/stdev_opponent_based_stl_differential) AS opponent_based_stl_z,
   (total_opponent_based_blk_differential/stdev_opponent_based_blk_differential) AS opponent_based_blk_z,
   (total_opponent_based_pf_differential/stdev_opponent_based_pf_differential) AS opponent_based_pf_z,
   (total_opponent_based_misses_differential/stdev_opponent_based_misses_differential) AS opponent_based_misses_z,
   (total_opponent_based_ftmisses_differential/stdev_opponent_based_ftmisses_differential) AS opponent_based_ftmisses_z,
   (total_opponent_based_pointscreated_differential/stdev_opponent_based_pointscreated_differential) AS opponent_based_pointscreated_z,
   (total_avg_based_pts_differential/stdev_avg_based_pts_differential) AS avg_based_pts_z,
   (total_avg_based_fgm_differential/stdev_avg_based_fgm_differential) AS avg_based_fgm_z,
   (total_avg_based_fga_differential/stdev_avg_based_fga_differential) AS avg_based_fga_z,
   (total_avg_based_fg2m_differential/stdev_avg_based_fg2m_differential) AS avg_based_fg2m_z,
   (total_avg_based_fg2a_differential/stdev_avg_based_fg2a_differential) AS avg_based_fg2a_z,
   (total_avg_based_fg3m_differential/stdev_avg_based_fg3m_differential) AS avg_based_fg3m_z,
   (total_avg_based_fg3a_differential/stdev_avg_based_fg3a_differential) AS avg_based_fg3a_z,
   (total_avg_based_ftm_differential/stdev_avg_based_ftm_differential) AS avg_based_ftm_z,
   (total_avg_based_fta_differential/stdev_avg_based_fta_differential) AS avg_based_fta_z,
   (total_avg_based_oreb_differential/stdev_avg_based_oreb_differential) AS avg_based_oreb_z,
   (total_avg_based_dreb_differential/stdev_avg_based_dreb_differential) AS avg_based_dreb_z,
   (total_avg_based_reb_differential/stdev_avg_based_reb_differential) AS avg_based_reb_z,
   (total_avg_based_ast_differential/stdev_avg_based_ast_differential) AS avg_based_ast_z,
   (total_avg_based_tov_differential/stdev_avg_based_tov_differential) AS avg_based_tov_z,
   (total_avg_based_stl_differential/stdev_avg_based_stl_differential) AS avg_based_stl_z,
   (total_avg_based_blk_differential/stdev_avg_based_blk_differential) AS avg_based_blk_z,
   (total_avg_based_pf_differential/stdev_avg_based_pf_differential) AS avg_based_pf_z,
   (total_avg_based_misses_differential/stdev_avg_based_misses_differential) AS avg_based_misses_z,
   (total_avg_based_ftmisses_differential/stdev_avg_based_ftmisses_differential) AS avg_based_ftmisses_z,
   (total_avg_based_pointscreated_differential/stdev_avg_based_pointscreated_differential) AS avg_based_pointscreated_z,
   (opponent_pts_impact/stdev_opponent_pts_impact) AS opponent_pts_z,
   (opponent_fgm_impact/stdev_opponent_fgm_impact) AS opponent_fgm_z,
   (opponent_fga_impact/stdev_opponent_fga_impact) AS opponent_fga_z,
   (opponent_fg2m_impact/stdev_opponent_fg2m_impact) AS opponent_fg2m_z,
   (opponent_fg2a_impact/stdev_opponent_fg2a_impact) AS opponent_fg2a_z,
   (opponent_fg3m_impact/stdev_opponent_fg3m_impact) AS opponent_fg3m_z,
   (opponent_fg3a_impact/stdev_opponent_fg3a_impact) AS opponent_fg3a_z,
   (opponent_ftm_impact/stdev_opponent_ftm_impact) AS opponent_ftm_z,
   (opponent_fta_impact/stdev_opponent_fta_impact) AS opponent_fta_z,
   (opponent_oreb_impact/stdev_opponent_oreb_impact) AS opponent_oreb_z,
   (opponent_dreb_impact/stdev_opponent_dreb_impact) AS opponent_dreb_z,
   (opponent_reb_impact/stdev_opponent_reb_impact) AS opponent_reb_z,
   (opponent_ast_impact/stdev_opponent_ast_impact) AS opponent_ast_z,
   (opponent_tov_impact/stdev_opponent_tov_impact) AS opponent_tov_z,
   (opponent_stl_impact/stdev_opponent_stl_impact) AS opponent_stl_z,
   (opponent_blk_impact/stdev_opponent_blk_impact) AS opponent_blk_z,
   (opponent_pf_impact/stdev_opponent_pf_impact) AS opponent_pf_z,
   (opponent_misses_impact/stdev_opponent_misses_impact) AS opponent_misses_z,
   (opponent_ftmisses_impact/stdev_opponent_ftmisses_impact) AS opponent_ftmisses_z,
   (opponent_pointscreated_impact/stdev_opponent_pointscreated_impact) AS opponent_pointscreated_z   
FROM
   pace_adjusted_season_offensive_impact
      LEFT JOIN
         season_offensive_stdevs
            ON pace_adjusted_season_offensive_impact.SEASON_ID = season_offensive_stdevs.SEASON_ID
			AND pace_adjusted_season_offensive_impact.PLAYER_ID = season_offensive_stdevs.PLAYER_ID
               LEFT JOIN      
                  defensive_stdevs
                    ON pace_adjusted_season_offensive_impact.SEASON_ID = defensive_stdevs.SEASON_ID
                    AND pace_adjusted_season_offensive_impact.PLAYER_ID = defenderid
;
GO

      -- 2. Combining differentials and z-scores
--------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [differentials_and_z_scores] AS
SELECT 
	* FROM 
(
SELECT
   DEFENDER_ID,
   DEFENDER,
   combined_impact.TEAM_ABBREVIATION,
   season_opponent_impact.TEAM_ID,
   season_opponent_impact.MP,
   season_opponent_impact.SEASON_ID,

--defense value totals

   total_opponent_pts_impact,
   total_opponent_fgm_impact,
   total_opponent_fga_impact,
   total_opponent_fg2m_impact,
   total_opponent_fg2a_impact,
   total_opponent_fg3m_impact,
   total_opponent_fg3a_impact,
   total_opponent_ftm_impact,
   total_opponent_fta_impact,
   total_opponent_oreb_impact,
   total_opponent_dreb_impact,
   total_opponent_reb_impact,
   total_opponent_ast_impact,
   total_opponent_tov_impact,
   total_opponent_stl_impact,
   total_opponent_blk_impact,
   total_opponent_pf_impact,
   total_opponent_misses_impact,
   total_opponent_ftmisses_impact,
   total_opponent_pointscreated_impact,

-- offense value totals
   total_opponent_based_pts_differential,
   total_opponent_based_fgm_differential,
   total_opponent_based_fga_differential,
   total_opponent_based_fg2m_differential,
   total_opponent_based_fg2a_differential,
   total_opponent_based_fg3m_differential,
   total_opponent_based_fg3a_differential,
   total_opponent_based_ftm_differential,
   total_opponent_based_fta_differential,
   total_opponent_based_oreb_differential,
   total_opponent_based_dreb_differential,
   total_opponent_based_reb_differential,
   total_opponent_based_ast_differential,
   total_opponent_based_tov_differential,
   total_opponent_based_stl_differential,
   total_opponent_based_blk_differential,
   total_opponent_based_pf_differential,
   total_opponent_based_misses_differential,
   total_opponent_based_ftmisses_differential,
   total_opponent_based_pointscreated_differential,
         -- avg-based
   total_avg_based_pts_differential,
   total_avg_based_fgm_differential,
   total_avg_based_fga_differential,
   total_avg_based_fg2m_differential,
   total_avg_based_fg2a_differential,
   total_avg_based_fg3m_differential,
   total_avg_based_fg3a_differential,
   total_avg_based_ftm_differential,
   total_avg_based_fta_differential,
   total_avg_based_oreb_differential,
   total_avg_based_dreb_differential,
   total_avg_based_reb_differential,
   total_avg_based_ast_differential,
   total_avg_based_tov_differential,
   total_avg_based_stl_differential,
   total_avg_based_blk_differential
   total_avg_based_pf_differential,
   total_avg_based_misses_differential,
   total_avg_based_ftmisses_differential,
   total_avg_based_pointscreated_differential,
   total_pointscreated,

-- z scores
-- opponent-based offensive z-scores


--These values are now only season-level volume z-scores
   opponent_based_pts_z,
   opponent_based_fgm_z,
   opponent_based_fga_z,
   opponent_based_fg2m_z,
   opponent_based_fg2a_z,
   opponent_based_fg3m_z,
   opponent_based_fg3a_z,
   opponent_based_ftm_z,
   opponent_based_fta_z,
   opponent_based_oreb_z,
   opponent_based_dreb_z,
   opponent_based_reb_z,
   opponent_based_ast_z,
   opponent_based_tov_z,
   opponent_based_stl_z,
   opponent_based_blk_z,
   opponent_based_pf_z,
   opponent_based_misses_z,
   opponent_based_ftmisses_z,
   opponent_based_pointscreated_z,

-- avg-based offensive z-scores

   avg_based_pts_z,
   avg_based_fgm_z,
   avg_based_fga_z,
   avg_based_fg2m_z,
   avg_based_fg2a_z,
   avg_based_fg3m_z,
   avg_based_fg3a_z,
   avg_based_ftm_z,
   avg_based_fta_z,
   avg_based_oreb_z,
   avg_based_dreb_z,
   avg_based_reb_z,
   avg_based_ast_z,
   avg_based_tov_z,
   avg_based_stl_z,
   avg_based_blk_z,
   avg_based_pf_z,
   avg_based_misses_z,
   avg_based_ftmisses_z,
   avg_based_pointscreated_z,

-- defensive z-scores

   opponent_pts_z,
   opponent_fgm_z,
   opponent_fga_z,
   opponent_fg2m_z,
   opponent_fg2a_z,
   opponent_fg3m_z,
   opponent_fg3a_z,
   opponent_ftm_z,
   opponent_fta_z,
   opponent_oreb_z,
   opponent_dreb_z,
   opponent_reb_z,
   opponent_ast_z,
   opponent_tov_z,
   opponent_stl_z,
   opponent_blk_z,
   opponent_pf_z,
   opponent_misses_z,
   opponent_ftmisses_z,
   opponent_pointscreated_z,
   ROW_NUMBER () OVER (PARTITION BY B.PLAYER_ID,B.SEASON_ID ORDER BY B.PlAYER_ID) AS rn
FROM
   season_opponent_impact
      LEFT JOIN
		pace_adjusted_season_offensive_impact B
            ON DEFENDER_ID = PLAYER_ID
            AND season_opponent_impact.SEASON_ID = B.SEASON_ID
               LEFT JOIN
					   combined_impact
						   ON season_opponent_impact.SEASON_ID = combined_impact.SEASON_ID
						   AND season_opponent_impact.DEFENDER_ID = combined_impact.PLAYER_ID
) t
WHERE
	rn = 1
;
GO

			-- 3. Determining z-scores for season totals (not per-possession cast onto season level)
----------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [season_totals_offense_z_scores] AS
SELECT
	SEASON,
	PLAYER_ID,
	PLAYER,
	TEAM_ID,
	TEAM,
	((season_points_created - avg_pointscreated)/stdev_pointscreated) AS season_total_pointscreated_z,
	((PTS - avg_pts)/stdev_pts) AS season_total_pts_z,
	((FGM - avg_fgm)/stdev_fgm) AS season_total_fgm_z,
	((FGA - avg_fga)/stdev_fga) AS season_total_fga_z,
	((FG3M - avg_fg3m)/stdev_fg3m) AS season_total_fg3m_z,
	((FG3A - avg_fg3a)/stdev_fg3a) AS season_total_fg3a_z,
	((FTM - avg_ftm)/stdev_ftm) AS season_total_ftm_z,
	((FTA - avg_fta)/stdev_fta) AS season_total_fta_z,
	((OREB - avg_oreb)/stdev_oreb) AS season_total_oreb_z,
	((DREB - avg_dreb)/stdev_dreb) AS season_total_dreb_z,
	((REB - avg_reb)/stdev_reb) AS season_total_reb_z,
	((AST - avg_ast)/stdev_ast) AS season_total_ast_z,
	((TOV - avg_tov)/stdev_tov) AS season_total_tov_z,
	((STL - avg_stl)/stdev_stl) AS season_total_stl_z,
	((BLK - avg_blk)/stdev_blk) AS season_total_blk_z,
	((PF - avg_pf)/stdev_pf) AS season_total_pf_z,
	((MISSES - avg_misses)/stdev_misses) AS season_total_misses_z,
	((FT_MISSES - avg_ftmisses)/stdev_ftmisses) AS season_total_ftmisses_z
FROM
	(
	SELECT
		totals4.SEASON,
		totals4.PLAYER_ID,
		totals4.PLAYER,
		totals4.TEAM,
		totals4.TEAM_ID,
		season_points_created,
		totals4.PTS,
		totals4.FGM,
		totals4.FGA,
		totals4.FG3M,
		totals4.FG3A,
		totals4.FTM,
		totals4.FTA,
		totals4.OREB,
		totals4.DREB,
		totals4.REB,
		totals4.AST,
		totals4.TOV,
		totals4.STL,
		totals4.BLK,
		totals4.PF,
		totals4.MISSES,
		totals4.FT_MISSES,
		AVG(season_points_created) OVER (PARTITION BY SEASON_ID) AS avg_pointscreated,
		AVG(totals4.PTS) OVER (PARTITION BY SEASON_ID) AS avg_pts,
		AVG(totals4.FGM) OVER (PARTITION BY SEASON_ID) AS avg_fgm,
		AVG(totals4.FGA) OVER (PARTITION BY SEASON_ID) AS avg_fga,
		AVG(totals4.FG3M) OVER (PARTITION BY SEASON_ID) AS avg_fg3m,
		AVG(totals4.FG3A) OVER (PARTITION BY SEASON_ID) AS avg_fg3a,
		AVG(totals4.FTM) OVER (PARTITION BY SEASON_ID) AS avg_ftm,
		AVG(totals4.FTA) OVER (PARTITION BY SEASON_ID) AS avg_fta,
		AVG(totals4.OREB) OVER (PARTITION BY SEASON_ID) AS avg_oreb,
		AVG(totals4.DREB) OVER (PARTITION BY SEASON_ID) AS avg_dreb,
		AVG(totals4.REB) OVER (PARTITION BY SEASON_ID) AS avg_reb,
		AVG(totals4.AST) OVER (PARTITION BY SEASON_ID) AS avg_ast,
		AVG(totals4.TOV) OVER (PARTITION BY SEASON_ID) AS avg_tov,
		AVG(totals4.STL) OVER (PARTITION BY SEASON_ID) AS avg_stl,
		AVG(totals4.BLK) OVER (PARTITION BY SEASON_ID) AS avg_blk,
		AVG(totals4.PF) OVER (PARTITION BY SEASON_ID) AS avg_pf,
		AVG(totals4.MISSES) OVER (PARTITION BY SEASON_ID) AS avg_misses,
		AVG(totals4.FT_MISSES) OVER (PARTITION BY SEASON_ID) AS avg_ftmisses,
		STDEV(season_points_created) OVER (PARTITION BY SEASON_ID) AS STDEV_pointscreated,
		STDEV(totals4.PTS) OVER (PARTITION BY SEASON_ID) AS STDEV_pts,
		STDEV(totals4.FGM) OVER (PARTITION BY SEASON_ID) AS STDEV_fgm,
		STDEV(totals4.FGA) OVER (PARTITION BY SEASON_ID) AS STDEV_fga,
		STDEV(totals4.FG3M) OVER (PARTITION BY SEASON_ID) AS STDEV_fg3m,
		STDEV(totals4.FG3A) OVER (PARTITION BY SEASON_ID) AS STDEV_fg3a,
		STDEV(totals4.FTM) OVER (PARTITION BY SEASON_ID) AS STDEV_ftm,
		STDEV(totals4.FTA) OVER (PARTITION BY SEASON_ID) AS STDEV_fta,
		STDEV(totals4.OREB) OVER (PARTITION BY SEASON_ID) AS STDEV_oreb,
		STDEV(totals4.DREB) OVER (PARTITION BY SEASON_ID) AS STDEV_dreb,
		STDEV(totals4.REB) OVER (PARTITION BY SEASON_ID) AS STDEV_reb,
		STDEV(totals4.AST) OVER (PARTITION BY SEASON_ID) AS STDEV_ast,
		STDEV(totals4.TOV) OVER (PARTITION BY SEASON_ID) AS STDEV_tov,
		STDEV(totals4.STL) OVER (PARTITION BY SEASON_ID) AS STDEV_stl,
		STDEV(totals4.BLK) OVER (PARTITION BY SEASON_ID) AS STDEV_blk,
		STDEV(totals4.PF) OVER (PARTITION BY SEASON_ID) AS STDEV_pf,
		STDEV(totals4.MISSES) OVER (PARTITION BY SEASON_ID) AS STDEV_misses,
		STDEV(totals4.FT_MISSES) OVER (PARTITION BY SEASON_ID) AS STDEV_ftmisses,
		ROW_NUMBER () OVER (PARTITION BY totals4.PLAYER_ID,SEASON ORDER BY SEASON) AS t1_record
	FROM
		totals4
			LEFT JOIN
				points_created_master
					ON SEASON = SEASON_ID
					AND totals4.PLAYER_ID = points_created_master.PLAYER_ID
	) t1
WHERE
	t1_record = 1
;

--Not part of the script, just a top-level view
GO
CREATE VIEW [top_view] AS
SELECT DISTINCT
	totals4.PLAYER,
	totals4.PLAYER_ID,
	totals4.SEASON,
	totals4.TEAM,
	totals4.TEAM_ID,
	totals4.MP,
	ROUND(season_total_pointscreated_z,2) AS O_SCORE_SEASON,
	avg_based_pointscreated_z as O_SCORE_PP,
	opponent_pointscreated_z as D_SCORE, 
	(avg_based_pointscreated_z - opponent_pointscreated_z) AS TOTAL_SCORE_PP,
	(season_total_pointscreated_z - opponent_pointscreated_z) AS TOTAL_SCORE_SEASON,
	era_adjusted_points_created AS TRUE_POINTS_CREATED,
	era_adjusted_pointscreatedpg AS TRUE_POINTS_CREATED_PG,
	opponent_pts_z AS OPP_SCORING_SCORE,
	opponent_fgm_z AS OPP_FGM_SCORE,
	opponent_misses_z AS OPP_MISSES_SCORE,
	opponent_tov_z AS OPP_TOV_SCORE,
	opponent_reb_z AS OPP_REB_SCORE,
	opponent_fta_z AS OPP_FTA_SCORE,
	avg_based_blk_z AS BLK_SCORE,
	opponent_based_stl_z AS STL_SCORE,
	avg_based_oreb_z AS OREB_SCORE,
	avg_based_ast_z AS AST_SCORE,
	((avg_based_tov_z + opponent_based_tov_z)/2) AS TOV_SCORE,
	((avg_based_dreb_z + opponent_oreb_z)/2) AS DREB_SCORE,
	totals4.EFG,
	totals4.TS
FROM
	season_totals_offense_z_scores a
		LEFT JOIN
			totals4
				ON a.PLAYER_ID = totals4.PLAYER_ID
				AND a.SEASON = totals4.SEASON
					LEFT JOIN
						points_created_master c
							ON a.PLAYER_ID = c.PLAYER_ID
							AND a.SEASON = c.SEASON_ID
								LEFT JOIN
									combined_impact d
										ON a.PLAYER_ID = d.PLAYER_ID
										AND a.SEASON = d.SEASON_ID
;

GO
-- Career-level view
CREATE VIEW [career_view] AS
SELECT
	(W_O_SCORE_SEASON / CAREER_MP) AS WEIGHTED_O_SCORE_SEASON,
	(W_O_SCORE_PP / CAREER_MP) AS WEIGHTED_O_SCORE_PP,
	(W_D_SCORE / CAREER_MP) AS WEIGHTED_D_SCORE,
	(W_TOTAL_SCORE_SEASON / CAREER_MP) AS WEIGHTED_TOTAL_SCORE_SEASON,
	(W_TOTAL_SCORE_PP / CAREER_MP) AS WEIGHTED_TOTAL_SCORE_PP,
	(TOTAL_POINTS_CREATED/NUMBER_OF_SEASONS) AS PC_PER_SEASON,
	(career_opponent_pointscreated_impact/NUMBER_OF_SEASONS) AS OPP_PC_IMPACT_PER_SEASON,
	(career_opponent_pts_impact/NUMBER_OF_SEASONS) AS OPP_PTS_IMPACT_PER_SEASON,
	(career_opponent_misses_impact/NUMBER_OF_SEASONS) AS OPP_MISSES_IMPACT_PER_SEASON,
	(career_opponent_fgm_impact/NUMBER_OF_SEASONS) AS OPP_FGM_IMPACT_PER_SEASON,
	(career_opponent_fga_impact/NUMBER_OF_SEASONS) AS OPP_FGA_IMPACT_PER_SEASON,
	(career_opponent_tov_impact/NUMBER_OF_SEASONS) AS OPP_TOV_IMPACT_PER_SEASON,
	(career_opponent_fta_impact/NUMBER_OF_SEASONS) AS OPP_FTA_IMPACT_PER_SEASON,
	(career_opponent_oreb_impact/NUMBER_OF_SEASONS) AS OPP_OREB_IMPACT_PER_SEASON,
	(career_opponent_dreb_impact/NUMBER_OF_SEASONS) AS OPP_DREB_IMPACT_PER_SEASON,
	(career_opponent_reb_impact/NUMBER_OF_SEASONS) AS OPP_REB_IMPACT_PER_SEASON,
	(career_avg_based_pointscreated_impact/NUMBER_OF_SEASONS) AS PC_IMPACT_PER_SEASON,
	(career_avg_based_pts_impact/NUMBER_OF_SEASONS) AS PTS_IMPACT_PER_SEASON,
	(career_avg_based_fgm_impact/NUMBER_OF_SEASONS) AS FGM_IMPACT_PER_SEASON,
	(career_avg_based_fga_impact/NUMBER_OF_SEASONS) AS FGA_IMPACT_PER_SEASON,
	(career_avg_based_ftm_impact/NUMBER_OF_SEASONS) AS FTM_IMPACT_PER_SEASON,
	(career_avg_based_fta_impact/NUMBER_OF_SEASONS) AS FTA_IMPACT_PER_SEASON,
	(career_avg_based_oreb_impact/NUMBER_OF_SEASONS) AS OREB_IMPACT_PER_SEASON,
	(career_avg_based_dreb_impact/NUMBER_OF_SEASONS) AS DREB_IMPACT_PER_SEASON,
	(career_avg_based_reb_impact/NUMBER_OF_SEASONS) AS REB_IMPACT_PER_SEASON,
	(career_avg_based_ast_impact/NUMBER_OF_SEASONS) AS AST_IMPACT_PER_SEASON,
	(career_avg_based_tov_impact/NUMBER_OF_SEASONS) AS TOV_IMPACT_PER_SEASON,
	(career_avg_based_stl_impact/NUMBER_OF_SEASONS) AS STL_IMPACT_PER_SEASON,
	(career_avg_based_blk_impact/NUMBER_OF_SEASONS) AS BLK_IMPACT_PER_SEASON,
	(career_avg_based_misses_impact/NUMBER_OF_SEASONS) AS MISSES_IMPACT_PER_SEASON,
	t1.*
FROM (
SELECT
	a.PLAYER_ID,
	PLAYER,
	SUM(TRUE_POINTS_CREATED) OVER (PARTITION BY a.PLAYER_ID) AS TOTAL_POINTS_CREATED,
	SUM(O_SCORE_SEASON*a.MP) OVER (PARTITION BY a.PLAYER_ID) 
		AS W_O_SCORE_SEASON,
	SUM(O_SCORE_PP*a.MP) OVER (PARTITION BY a.PLAYER_ID) 
		AS W_O_SCORE_PP,
	SUM(D_SCORE*a.MP) OVER (PARTITION BY a.PLAYER_ID) 
		AS W_D_SCORE,
	SUM(TOTAL_SCORE_SEASON*a.MP) OVER (PARTITION BY a.PLAYER_ID) 
		AS W_TOTAL_SCORE_SEASON,
	SUM(TOTAL_SCORE_PP*a.MP) OVER (PARTITION BY a.PLAYER_ID) 
		AS W_TOTAL_SCORE_PP,
	SUM(a.MP) OVER (PARTITION BY a.PLAYER_ID) AS CAREER_MP,
	COUNT(a.SEASON) OVER (PARTITION BY a.PLAYER_ID) AS NUMBER_OF_SEASONS,
	SUM(total_opponent_pointscreated_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_pointscreated_impact,
	SUM(total_opponent_pts_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_pts_impact,
	SUM(total_opponent_fgm_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fgm_impact,
	SUM(total_opponent_fga_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fga_impact,
	SUM(total_opponent_fg2m_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fg2m_impact,
	SUM(total_opponent_fg2a_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fg2a_impact,
	SUM(total_opponent_fg3m_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fg3m_impact,
	SUM(total_opponent_fg3a_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fg3a_impact,
	SUM(total_opponent_ftm_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_ftm_impact,
	SUM(total_opponent_fta_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_fta_impact,
	SUM(total_opponent_oreb_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_oreb_impact,
	SUM(total_opponent_dreb_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_dreb_impact,
	SUM(total_opponent_reb_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_reb_impact,
	SUM(total_opponent_ast_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_ast_impact,
	SUM(total_opponent_tov_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_tov_impact,
	SUM(total_opponent_stl_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_stl_impact,
	SUM(total_opponent_blk_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_blk_impact,
	SUM(total_opponent_pf_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_pf_impact,
	SUM(total_opponent_misses_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_misses_impact,
	SUM(total_opponent_ftmisses_impact) OVER (PARTITION BY a.PLAYER_ID) AS career_opponent_ftmisses_impact,
	SUM(total_avg_based_pointscreated_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_pointscreated_impact,
	SUM(total_avg_based_pts_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_pts_impact,
	SUM(total_avg_based_fgm_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fgm_impact,
	SUM(total_avg_based_fga_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fga_impact,
	SUM(total_avg_based_fg2m_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fg2m_impact,
	SUM(total_avg_based_fg2a_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fg2a_impact,
	SUM(total_avg_based_fg3m_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fg3m_impact,
	SUM(total_avg_based_fg3a_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fg3a_impact,
	SUM(total_avg_based_ftm_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_ftm_impact,
	SUM(total_avg_based_fta_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_fta_impact,
	SUM(total_avg_based_oreb_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_oreb_impact,
	SUM(total_avg_based_dreb_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_dreb_impact,
	SUM(total_avg_based_reb_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_reb_impact,
	SUM(total_avg_based_ast_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_ast_impact,
	SUM(total_avg_based_tov_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_tov_impact,
	SUM(total_avg_based_stl_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_stl_impact,
	SUM(total_avg_based_blk_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_blk_impact,
	SUM(total_avg_based_pf_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_pf_impact,
	SUM(total_avg_based_misses_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_misses_impact,
	SUM(total_avg_based_ftmisses_differential) OVER (PARTITION BY a.PLAYER_ID) AS career_avg_based_ftmisses_impact,
	ROW_NUMBER () OVER (PARTITION BY a.PLAYER_ID ORDER  BY a.PLAYER_ID) AS player_record
FROM
	top_view a
		LEFT JOIN
			pace_adjustment_season_opponent_impact b
				ON a.PLAYER_ID = b.DEFENDER_ID
				AND a.SEASON = b.SEASON_ID
					LEFT JOIN 
						pace_adjusted_season_offensive_impact c
							ON a.PLAYER_ID = c.PLAYER_ID
							AND a.SEASON = c.SEASON_ID
) t1
WHERE
	player_record = 1
;

GO
-- game differntials view
CREATE VIEW [game_differentials] AS
SELECT 
   PLAYER_ID,
   PLAYER_NAME,
   GAME_ID,
   TEAM_ABBREVIATION,
   TEAM_ID,
   POSITION,
   a.SEASON_ID,
   a.OPPONENT,
   a.OPPONENT_ID,
   Minutes,
   Game_Poss_Per_Min,
   PTS,
   FGM,
   FGA,
   FG2M,
   FG2A,
   FG3M,
   FG3A,
   FTM,
   FTA,
   OREB,
   DREB,
   REB,
   AST,
   TOV,
   STL,
   BLK,
   PF,
   MISSES,
   FT_MISSES,
   game_points_created,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   FTPERCENT,
   EFG,
   TS,
   avg_based_expected_pts,
   avg_based_expected_fgm,
   avg_based_expected_fga,
   avg_based_expected_fg2m,
   avg_based_expected_fg2a,
   avg_based_expected_fg3m,
   avg_based_expected_fg3a,
   avg_based_expected_ftm,
   avg_based_expected_fta,
   avg_based_expected_oreb,
   avg_based_expected_dreb,
   avg_based_expected_reb,
   avg_based_expected_ast,
   avg_based_expected_tov,
   avg_based_expected_stl,
   avg_based_expected_blk,
   avg_based_expected_pf,
   avg_based_expected_misses,
   avg_based_expected_ftmisses,
   avg_based_expected_pointscreated,
   d.*
FROM
	expected_offense a
		LEFT JOIN
	(
SELECT
   PLAYER_ID AS playerid,
   PLAYER_NAME AS name,
   GAME_ID AS gameid,
   TEAM_ABBREVIATION,
   TEAM_ID AS teamid,
   SEASON_ID AS seasonid,
   PTS,
   FGM,
   FGA,
   (FGM - FG3M) AS FG2M,
   (FGA - FG3A) AS FG2A,
   FG3M,
   FG3A,
   FTM,
   FTA,
   OREB,
   DREB,
   REB,
   AST,
   TOV,
   STL,
   BLK,
   PF,
   (FGA - FGM) AS MISSES,
   (FTA - FTM) AS FT_MISSES,
   game_points_created,
   FGPERCENT,
   FG2PERCENT,
   FG3PERCENT,
   (FTM/FTA) AS FTPERCENT,
   EFG,
   TS,
   ROW_NUMBER () OVER (PARTITION BY PLAYER_ID,GAME_ID ORDER BY GAME_ID) AS line
FROM
   points_created_master
) b
		    ON GAME_ID = gameid
            AND PLAYER_ID = playerid
				LEFT JOIN
					hinge
						ON GAME_ID = OWN_GAME_ID
						AND TEAM_ID = OWN_TEAM_ID
							LEFT JOIN
								(
SELECT
   GAME_ID AS GAME,
   TEAM_ID AS OPPONENT_TEAM,
   POSITION AS opponent_position,
   SUM(PTS) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_pts,
   SUM(FGM) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fgm,
   SUM(FGA) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fga,
   SUM(FG2M) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fg2m,
   SUM(FG2A) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fg2a,
   SUM(FG3M) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fg3m,
   SUM(FG3A) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fg3a,
   SUM(FTM) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_ftm,
   SUM(FTA) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_fta,
   SUM(OREB) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_oreb,
   SUM(DREB) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_dreb,
   SUM(REB) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_reb,
   SUM(AST) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_ast,
   SUM(TOV) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_tov,
   SUM(STL) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_stl,
   SUM(BLK) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_blk,
   SUM(PF) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_pf,
   SUM(game_points_created) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_pointscreated,
   SUM(misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_misses,
   SUM(ft_misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_ftmisses,
   SUM(expected_PTS) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_pts,
   SUM(expected_FGM) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fgm,
   SUM(expected_FGA) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fga,
   SUM(expected_FG2M) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fg2m,
   SUM(expected_FG2A) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fg2a,
   SUM(expected_FG3M) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fg3m,
   SUM(expected_FG3A) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fg3a,
   SUM(expected_FTM) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_ftm,
   SUM(expected_FTA) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_fta,
   SUM(expected_OREB) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_oreb,
   SUM(expected_DREB) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_dreb,
   SUM(expected_REB) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_reb,
   SUM(expected_AST) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_ast,
   SUM(expected_TOV) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_tov,
   SUM(expected_STL) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_stl,
   SUM(expected_BLK) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_blk,
   SUM(expected_PF) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_pf,
   SUM(expected_pointscreated) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_pointscreated,
   SUM(expected_misses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_misses,
   SUM(expected_ftmisses) OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS expected_opponent_ftmisses,
   ROW_NUMBER() OVER (PARTITION BY GAME_ID,TEAM_ID,POSITION ORDER BY GAME_ID) AS opponent_position_record
FROM
	expected_player_stats
) d
								ON OPPONENT_GAME_ID = GAME
								AND hinge.OPPONENT_ID = OPPONENT_TEAM
								AND POSITION = opponent_position
WHERE 
	line = 1
	AND opponent_position_record = 1
;

-- Offensive efficiency
GO
CREATE VIEW [offensive_efficiency] AS
SELECT 
    PLAYER_ID,
    PLAYER,
    SEASON,
    season_points_created,
    season_points_lost,
    opportunities,
    (season_points_created
        /
    (season_points_created + season_points_lost)
    ) AS offensive_efficiency,
    (season_points_created / opportunities) AS points_created_rate,
    (season_points_lost / opportunities) AS points_lost_rate
FROM 
    (
SELECT  
    PLAYER_ID,
    PLAYER,
    SEASON,
    SUM(game_points_lost) OVER (PARTITION BY PLAYER_ID,SEASON) AS season_points_lost,
    season_points_created,
    (CASE
		WHEN (FGA + TOV + AST + (FTA*0.44))  IS NOT NULL
			THEN (FGA + TOV + AST + (FTA*0.44)) 
		WHEN TOV IS NULL 
			AND (FGA + AST + (FTA*0.44)) IS NOT NULL
			THEN (FGA + AST + (FTA*0.44)) 
		WHEN (FGA + AST) IS NOT NULL
			THEN (FGA + AST)
		WHEN FGA IS NOT NULL
			THEN FGA
		ELSE PTS
		END
	) AS opportunities,
    ROW_NUMBER() OVER (PARTITION BY PLAYER_ID,SEASON ORDER BY PLAYER_ID) AS rnum
FROM
    totals4 a
        LEFT JOIN
            (
            SELECT
                PLAYER_ID AS pid,
                SEASON_ID,
                season_points_created,
                ROW_NUMBER () OVER (PARTITION BY PLAYER_ID,SEASON_ID ORDER BY PLAYER_ID) AS rn
            FROM
                points_created_master
            ) b  
                ON PLAYER_ID = pid
                AND SEASON = SEASON_ID
                    LEFT JOIN
                        (
                        SELECT  
                        PLAYER_ID AS id,
                        GAME_ID,
                        SEASON_ID AS s,
                        (
						CASE
						WHEN TOV IS NOT NULL 
						AND FT_MISSES IS NOT NULL
						AND MISSES IS NOT NULL
						AND ((team_pts_per_fgm * MISSES) + (0.75* FT_MISSES) + TOV) IS NOT NULL
						AND team_pts_per_fgm >= 2
						THEN
                            ((team_pts_per_fgm * MISSES)
                            + (0.75* FT_MISSES)
                            + TOV)
						WHEN TOV IS NULL 
						AND FT_MISSES IS NOT NULL
						AND MISSES IS NOT NULL
						AND ((team_pts_per_fgm * MISSES) + (0.75* FT_MISSES)) IS NOT NULL
						AND team_pts_per_fgm >= 2
						THEN
						    ((team_pts_per_fgm * MISSES)
                            + (0.75* FT_MISSES))
						WHEN FT_MISSES IS NULL
						AND MISSES IS NOT NULL
						AND team_pts_per_fgm >= 2
						THEN
							(team_pts_per_fgm * MISSES)
						WHEN team_pts_per_fgm < 2
						AND ((2 * MISSES) + (0.75* FT_MISSES) + TOV) IS NOT NULL
						THEN
                            ((2 * MISSES)
                            + (0.75* FT_MISSES)
                            + TOV)							
						ELSE
							game_points_created
						END
						) AS game_points_lost
                        FROM 
                            points_created_master
                        ) c  
                            ON pid = id  
                            AND SEASON_ID = s
WHERE   
    rn = 1
    ) subquery
WHERE
    rnum = 1
;
GO

-- Career ranks
SET ARITHABORT OFF SET ANSI_WARNINGS OFF;
SELECT
	PLAYER_ID,
	PLAYER,
	Career_Total_Score_Season,
	Career_Total_Score_Per_Poss,
	Career_PC_Per_Season,
	Career_Opp_PC_Impact_Per_Season,
	Career_Points_Created,
	Career_W_D_Score,
	Career_W_Total_Score_Season,
	Career_Opp_PC_Impact,
	Career_W_O_Score_Per_Poss,
	Career_Avg_Based_PC_Impact,
	Career_D_Score,
	RANK () OVER (ORDER BY Prime_PC DESC) AS Prime_PC,
	RANK () OVER (ORDER BY Prime_O_Score_Season DESC) AS Prime_O_Score_Season,
	RANK () OVER (ORDER BY Prime_O_Score_Per_Poss DESC) AS Prime_O_Score_Per_Poss,
	RANK () OVER (ORDER BY Prime_D_Score) AS Prime_D_Score,
	RANK () OVER (ORDER BY Prime_Total_Score_Season DESC) AS Prime_Total_Score_Season,
	RANK () OVER (ORDER BY Prime_Total_Score_Per_Poss DESC) AS Prime_Total_Score_Per_Poss,
	Career_Offensive_Efficiency
INTO
	career_ranks
FROM
(
SELECT
	PLAYER_ID,
	PLAYER,
	Career_Total_Score_Season,
	Career_Total_Score_Per_Poss,
	Career_PC_Per_Season,
	Career_Opp_PC_Impact_Per_Season,
	Career_Points_Created,
	Career_W_D_Score,
	Career_W_Total_Score_Season,
	Career_Opp_PC_Impact,
	Career_W_O_Score_Per_Poss,
	Career_Avg_Based_PC_Impact,
	Career_D_Score,
	SUM(TRUE_POINTS_CREATED) OVER (PARTITION BY PLAYER_ID) AS Prime_PC,
	SUM(O_SCORE_SEASON) OVER (PARTITION BY PLAYER_ID) AS Prime_O_Score_Season,
	SUM(O_SCORE_PP)  OVER (PARTITION BY PLAYER_ID) AS Prime_O_Score_Per_Poss,
	SUM(D_SCORE)  OVER (PARTITION BY PLAYER_ID) AS Prime_D_Score,
	SUM(TOTAL_SCORE_SEASON)  OVER (PARTITION BY PLAYER_ID) AS Prime_Total_Score_Season,
	SUM(TOTAL_SCORE_PP) OVER (PARTITION BY PLAYER_ID) AS Prime_Total_Score_Per_Poss,
	Career_Offensive_Efficiency,
	ROW_NUMBER() OVER (PARTITION BY PLAYER_ID ORDER BY PLAYER_ID) AS record
FROM
	(
SELECT
	PLAYER_ID,
	PLAYER,
	RANK() OVER (ORDER BY WEIGHTED_TOTAL_SCORE_SEASON DESC) AS Career_Total_Score_Season,
	RANK() OVER (ORDER BY WEIGHTED_TOTAL_SCORE_PP DESC) AS Career_Total_Score_Per_Poss,
	RANK() OVER (ORDER BY PC_PER_SEASON DESC) AS Career_PC_Per_Season,
	RANK() OVER (ORDER BY OPP_PC_IMPACT_PER_SEASON) AS Career_Opp_PC_Impact_Per_Season,
	RANK() OVER (ORDER BY TOTAL_POINTS_CREATED DESC) AS Career_Points_Created,
	RANK() OVER (ORDER BY W_D_SCORE) AS Career_W_D_Score,
	RANK() OVER (ORDER BY W_TOTAL_SCORE_SEASON DESC) AS Career_W_Total_Score_Season,
	RANK() OVER (ORDER BY career_opponent_pointscreated_impact) AS Career_Opp_PC_Impact,
	RANK() OVER (ORDER BY W_O_SCORE_PP DESC) AS Career_W_O_Score_Per_Poss,
	RANK() OVER (ORDER BY career_avg_based_pointscreated_impact DESC) AS Career_Avg_Based_PC_Impact,
	RANK() OVER (ORDER BY WEIGHTED_D_SCORE) AS Career_D_Score
FROM
	career_view
WHERE
	WEIGHTED_TOTAL_SCORE_SEASON IS NOT NULL
	AND WEIGHTED_TOTAL_SCORE_PP IS NOT NULL
	AND PC_PER_SEASON IS NOT NULL
	AND OPP_PC_IMPACT_PER_SEASON IS NOT NULL
	AND TOTAL_POINTS_CREATED IS NOT NULL
	AND W_D_SCORE IS NOT NULL
	AND W_TOTAL_SCORE_SEASON IS NOT NULL
	AND career_opponent_pointscreated_impact IS NOT NULL
	AND W_O_SCORE_PP IS NOT NULL
	AND career_avg_based_pointscreated_impact IS NOT NULL
	AND WEIGHTED_D_SCORE IS NOT NULL
) t1
	LEFT JOIN
		(
		SELECT
			PLAYER_ID AS id,
			PLAYER_NAME AS n,
			SEASON_ID AS s,
			season_points_created,
			RANK () OVER (PARTITION BY PLAYER_ID ORDER BY season_points_created DESC) AS season_rank
		FROM
			points_created_master
		) t2
			ON PLAYER_ID = id
				LEFT JOIN
					(
					SELECT
						PLAYER_ID AS pid,
						TRUE_POINTS_CREATED,
						O_SCORE_SEASON,
						O_SCORE_PP,
						D_SCORE,
						TOTAL_SCORE_SEASON,
						TOTAL_SCORE_PP,
						RANK () OVER (PARTITION BY PLAYER_ID ORDER BY TOTAL_SCORE_SEASON DESC) AS top_season_rank
					FROM
						top_view a
							LEFT JOIN
								pace_adjustment_season_opponent_impact b
									ON a.PLAYER_ID = b.DEFENDER_ID
									AND a.SEASON = b.SEASON_ID
					) t3
						ON id = pid
							LEFT JOIN
								(
								SELECT
									PLAYER_ID AS id_number,
									offensive_efficiency,
									(offensive_efficiency*opportunities) AS WEIGHTED_OFFENSIVE_EFFICIENCY,
									(SUM(offensive_efficiency*opportunities) OVER (PARTITION BY PLAYER_ID)
										/
											SUM(opportunities) OVER (PARTITION BY PLAYER_ID)
									) AS Career_Offensive_Efficiency, --migrated here from outer query
									SUM(opportunities) OVER (PARTITION BY PLAYER_ID) AS Career_Opportunities,
									ROW_NUMBER () OVER (PARTITION BY PLAYER_ID ORDER BY PLAYER_ID) AS efficiency_record
								FROM
									offensive_efficiency
								) t4
									ON 
										id = id_number
WHERE
	season_rank <= 6
	AND top_season_rank <= 6
	AND efficiency_record = 1
) subquery
WHERE 
	record = 1
;

--ON_GOD
GO
CREATE VIEW [ON_GOD] AS
SELECT
	PLAYER_ID,
	PLAYER_NAME,
	GAME_ID,
	team_abbreviation as TEAM,
	TEAM_ID,
	OPPONENT,
	OPPONENT_ID,
	SEASON_ID,
	(game_points_created - avg_based_expected_pointscreated) 
				AS OFFENSE,
	(
		((opponent_pointscreated - expected_opponent_pointscreated)*(-1))
		* (MINUTES/48)) 
				AS DEFENSE,
	(
		(game_points_created - avg_based_expected_pointscreated)
			+
		(((opponent_pointscreated - expected_opponent_pointscreated)*(-1)) * (MINUTES/48))
	) 
				AS ON_GOD
FROM
	game_differentials
;
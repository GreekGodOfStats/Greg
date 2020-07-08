--hustle cleaning
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
Age decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
G decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
CONTESTED_SHOTS decimal(8,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
CONTESTED_SHOTS_2PT decimal(8,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
CONTESTED_SHOTS_3PT decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
DEFLECTIONS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
CHARGES_DRAWN decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
SCREEN_ASSISTS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
SCREEN_AST_PTS decimal(8,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
OFF_LOOSE_BALLS_RECOVERED decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
DEF_LOOSE_BALLS_RECOVERED decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
LOOSE_BALLS_RECOVERED decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
PCT_LOOSE_BALLS_RECOVERED_OFF decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
PCT_LOOSE_BALLS_RECOVERED_DEF decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
OFF_BOXOUTS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
DEF_BOXOUTS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
BOX_OUTS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
BOX_OUT_PLAYER_TEAM_REBS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
BOX_OUT_PLAYER_REBS decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
PCT_BOX_OUTS_OFF decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
PCT_BOX_OUTS_DEF decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
PCT_BOX_OUTS_TEAM_REB decimal(6,3);
ALTER TABLE Matchups.dbo.hustle_2019_20
ALTER COLUMN
PCT_BOX_OUTS_REB decimal(6,3);

--pergame cleaning
ALTER TABLE Matchups.dbo.per_game_2019_20
ALTER COLUMN 
FGM decimal (6,3);
ALTER TABLE Matchups.dbo.per_game_2019_20
ALTER COLUMN
FTM decimal (6,3);
ALTER TABLE Matchups.dbo.per_game_2019_20
ALTER COLUMN
OREB decimal (6,3);
ALTER TABLE Matchups.dbo.per_game_2019_20
ALTER COLUMN
TOV decimal (6,3);
ALTER TABLE Matchups.dbo.per_game_2019_20
ALTER COLUMN
PTS decimal (6,3);

--per100 cleaning
ALTER TABLE Matchups.dbo.per_100_2019_20
ALTER COLUMN GP decimal (6,3);
ALTER TABLE Matchups.dbo.per_100_2019_20
ALTER COLUMN FGM decimal (6,3);
ALTER TABLE Matchups.dbo.per_100_2019_20
ALTER COLUMN FGA decimal (6,3);
ALTER TABLE Matchups.dbo.per_100_2019_20
ALTER COLUMN OREB decimal (6,3);
ALTER TABLE Matchups.dbo.per_100_2019_20
ALTER COLUMN TOV decimal (6,3);
ALTER TABLE Matchups.dbo.per_100_2019_20
ALTER COLUMN PTS decimal (6,3);

--DROP TABLE Matchups.dbo.thisyear;

SELECT * 
INTO Matchups.dbo.thisyear
FROM Matchups.dbo.teammatchupdata

LEFT JOIN (SELECT per_100_2019_20.PLAYER_ID,
per_100_2019_20.PLAYER_NAME,
per_100_2019_20.TEAM_ID,
per_100_2019_20.TEAM_ABBREVIATION,
per_100_2019_20.GP AS GamesPlayed,
per_100_2019_20.FGM AS FGMade,
per_100_2019_20.FGA AS FTMade,
per_100_2019_20.OREB AS OREBs,
per_100_2019_20.TOV AS TOVs,
per_100_2019_20.PTS
FROM Matchups.dbo.per_100_2019_20) AS per100 
ON per100.PLAYER_NAME = teammatchupdata.OFF_PLAYER_NAME

LEFT JOIN (SELECT per_game_2019_20.PLAYER_ID AS PLAYERID,
      per_game_2019_20.PLAYER_NAME AS PLAYERNAME,
      per_game_2019_20.TEAM_ID AS TEAMID,
      per_game_2019_20.TEAM_ABBREVIATION AS TEAMABBREVIATION,
      per_game_2019_20.FGM AS FGMgm,
      per_game_2019_20.FTM AS FTMgm,
      per_game_2019_20.OREB AS OREBgm,
      per_game_2019_20.TOV AS TOVgm,
      per_game_2019_20.PTS AS PTSgm
FROM Matchups.dbo.per_game_2019_20) AS pergame 
ON pergame.PLAYERID = teammatchupdata.OFF_PLAYER_ID

LEFT JOIN (SELECT hustle_2019_20.PLAYER_ID AS player_ID_
      ,hustle_2019_20.PLAYER_NAME AS playersname
      ,hustle_2019_20.TEAM_ID AS TEAM_ID_
      ,hustle_2019_20.G
      ,hustle_2019_20.DEFLECTIONS
      ,hustle_2019_20.CHARGES_DRAWN
      ,hustle_2019_20.DEF_LOOSE_BALLS_RECOVERED
      ,hustle_2019_20.LOOSE_BALLS_RECOVERED
      ,hustle_2019_20.PCT_LOOSE_BALLS_RECOVERED_DEF
FROM Matchups.dbo.hustle_2019_20) AS hustle 
ON hustle.player_ID_ = teammatchupdata.DEF_PLAYER_ID;

--initial transformation
SELECT Matchups.dbo.thisyear.*, Matchups.dbo.per_game_2019_20.PLAYER_ID AS defender_id,BLK,STL
INTO Matchups.dbo.mbd19_20
FROM Matchups.dbo.thisyear
LEFT OUTER JOIN Matchups.dbo.per_game_2019_20
ON thisyear.DEF_PLAYER_ID = per_game_2019_20.PLAYER_ID;
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF;
WITH A AS (
SELECT ((SELECT SUM(PTSgm*PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)/
(SELECT SUM(PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)) AS DefensiveLoad,
(SELECT SUM(PLAYER_PTS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID) AS pts_allowed,
(SELECT SUM(PTS/100*PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID) AS exp_pts_all_,
((SELECT SUM(PTS/100*PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)/
(SELECT SUM(PLAYER_PTS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)) AS defensive_effectiveness,
(SELECT SUM(PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID) AS Possessions,
((SELECT SUM(((PTSgm-FTMgm)/FGMgm)*PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)
/(SELECT SUM(PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)) AS TERM_D,
((SELECT SUM(MATCHUP_FGA) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)-
(SELECT SUM(MATCHUP_FGM) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)-
(SELECT SUM(DISTINCT BLK*G) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)) AS ind_def_unblocked_misses,
((STL*G)-DEF_LOOSE_BALLS_RECOVERED) AS SoloSteals,
((SELECT SUM(MATCHUP_TOV) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)-((STL*G)-DEF_LOOSE_BALLS_RECOVERED)-CHARGES_DRAWN) AS OOTO,
(SELECT SUM(TOVs/100*PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID) AS Expected_OOTO,
(((SELECT SUM(MATCHUP_TOV) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)-((STL*G)-DEF_LOOSE_BALLS_RECOVERED)-CHARGES_DRAWN)
/(SELECT SUM(TOVs/100*PARTIAL_POSS) WHERE DEF_PLAYER_ID = DEF_PLAYER_ID)) AS realtoexp_OOTO,
DEF_PLAYER_ID AS PLYRID
FROM Matchups.dbo.mbd19_20
GROUP BY DEF_PLAYER_ID, TEAM_ID_,STL,G,DEF_LOOSE_BALLS_RECOVERED,CHARGES_DRAWN,BLK
HAVING DEF_PLAYER_ID = DEF_PLAYER_ID)
SELECT Matchups.dbo.mbd19_20.*,A.*
INTO Matchups.dbo.currentseason
FROM Matchups.dbo.mbd19_20
LEFT JOIN A
ON Matchups.dbo.mbd19_20.DEF_PLAYER_ID = A.PLYRID;

--FIXING TEAM LOAD
WITH team_load AS(
SELECT
(SELECT SUM(DISTINCT PTSgm*PARTIAL_POSS) WHERE TEAM_ID_ = TEAM_ID_) AS teamsum_ppgtimesposs,
(SELECT SUM(DISTINCT Possessions)) AS teamsumposs,
TEAM_ID_ AS _team
FROM [dbo].[currentseason]
GROUP BY TEAM_ID_
HAVING TEAM_ID_ = TEAM_ID_)
SELECT Matchups.dbo.currentseason.*,team_load.* 
INTO Matchups.dbo.teamloading
FROM Matchups.dbo.currentseason
JOIN team_load
ON TEAM_ID_ = _team;

ALTER TABLE Matchups.dbo.teamloading
ADD TeamLoad AS (teamsum_ppgtimesposs/teamsumposs),
RelativeLoad AS (DefensiveLoad/(teamsum_ppgtimesposs/teamsumposs)),
loadadjeff AS ((DefensiveLoad/(teamsum_ppgtimesposs/teamsumposs))*defensive_effectiveness),
ind_opp_ppfgm AS (
CASE 
WHEN FGMgm>0 THEN (PTSgm-FTMgm)/FGMgm
ELSE 2
END),
totalblocks AS (BLK*G),
ind_opp_ppfgm_weighted AS (
CASE
WHEN FGMgm>0 THEN (((PTSgm-FTMgm)/FGMgm)*PARTIAL_POSS)
ELSE 0
END);

--beta table, team sums

--SET ARITHABORT OFF
--SET ANSI_WARNINGS OFF;
WITH B AS (
SELECT SUM(DISTINCT OOTO) AS TeamSumOOTO, 
SUM(MATCHUP_FGA) AS oppfga, 
SUM(MATCHUP_FGM) AS oppfgm,
(SELECT SUM(DISTINCT totalblocks)) AS teamsumblocks,
(SELECT SUM(DISTINCT loadadjeff)) AS teamsum_loadadjeff,
TEAM_ID_ AS tm
FROM Matchups.dbo.teamloading
GROUP BY TEAM_ID_
HAVING TEAM_ID_ = TEAM_ID_)
SELECT Matchups.dbo.teamloading.*,B.* 
INTO Matchups.dbo.beta
FROM Matchups.dbo.teamloading
JOIN B
ON TEAM_ID_ = tm;

--add computed columns to beta table
ALTER TABLE Matchups.dbo.beta
ADD TERM_A AS (loadadjeff/teamsum_loadadjeff),
TERM_B AS (Possessions/(teamsumposs/5)),
TERM_C AS (oppfga-oppfgm-teamsumblocks),
percentoftmOOTO AS (OOTO/TeamSumOOTO);
SELECT *
INTO Matchups.dbo.gamma
FROM Matchups.dbo.beta;
--DROP TABLE thisyear;
--DROP TABLE currentseason;
--DROP TABLE beta
--DROP TABLE mbd19_20;

--alter gamma table
ALTER TABLE Matchups.dbo.gamma
ADD ShootingDefense AS (TERM_A*TERM_B*TERM_C*TERM_D),
AtimesB AS (realtoexp_OOTO*percentoftmOOTO);
--into delta table
WITH C AS (
SELECT (SUM(DISTINCT AtimesB)) AS teamsum_AtimesB,
TEAM_ID_ AS squad
FROM Matchups.dbo.gamma
GROUP BY TEAM_ID_
HAVING TEAM_ID_ = TEAM_ID_)
SELECT Matchups.dbo.gamma.*,C.* 
INTO Matchups.dbo.delta
FROM Matchups.dbo.gamma
JOIN C
ON TEAM_ID_ = squad;
ALTER TABLE Matchups.dbo.delta
ADD OOTO_component AS ((AtimesB/teamsum_AtimesB)*TeamSumOOTO),
NonShootingDefense AS (((AtimesB/teamsum_AtimesB)*TeamSumOOTO)+CHARGES_DRAWN+SoloSteals),
TotalDefense AS ((((AtimesB/teamsum_AtimesB)*TeamSumOOTO)+CHARGES_DRAWN+SoloSteals)+ShootingDefense),
ShootingD_per_100 AS (ShootingDefense/Possessions*100),
NonShootingD_per_100 AS ((((AtimesB/teamsum_AtimesB)*TeamSumOOTO)+CHARGES_DRAWN+SoloSteals)/Possessions*100),
TotalD_per_100 AS (((((AtimesB/teamsum_AtimesB)*TeamSumOOTO)+CHARGES_DRAWN+SoloSteals)+ShootingDefense)/Possessions*100);

DROP TABLE Matchups.dbo.thisyear;
DROP TABLE Matchups.dbo.mbd19_20;
DROP TABLE Matchups.dbo.currentseason;
DROP TABLE Matchups.dbo.gamma;
DROP TABLE beta;
DROP TABLE teamloading;
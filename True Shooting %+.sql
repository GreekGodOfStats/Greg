DROP TABLE NBA_historical.dbo.tsplus;
DROP TABLE NBA_historical.dbo.trueshootingplus;

WITH A AS (
SELECT
(SELECT SUM(PTS) WHERE Season=Season) AS seasonPTS,
(SELECT SUM(FGA) WHERE Season=Season) AS seasonFGA,
(SELECT SUM(FTA) WHERE Season=Season) AS seasonFTA,
Season AS szn
FROM NBA_historical.dbo.totals
GROUP BY Season
HAVING Season = Season)
SELECT NBA_historical.dbo.totals.*, A.*
INTO NBA_historical.dbo.tsplus
FROM NBA_historical.dbo.totals
LEFT JOIN A 
ON Season = szn
;

ALTER TABLE NBA_historical.dbo.tsplus
ADD seasonTS AS ((seasonPTS/(seasonFGA+(.44*seasonFTA)))/2);

ALTER TABLE NBA_historical.dbo.tsplus
DROP COLUMN szn;

WITH B AS (
SELECT
(SELECT CASE WHEN FGA=0 THEN 0
WHEN FTA=0 THEN 0
ELSE ((PTS/(FGA+(.44*FTA)))/2) 
END) AS TrueShootingPercentage,
Season AS szn,
PLAYER AS playername
FROM NBA_historical.dbo.tsplus
GROUP BY Season,PLAYER,FGA,FTA,PTS,FGA,FTA
HAVING Season = Season
AND PLAYER = PLAYER)
SELECT NBA_historical.dbo.tsplus.*, B.*
INTO NBA_historical.dbo.trueshootingplus
FROM NBA_historical.dbo.tsplus
LEFT JOIN B 
ON Season = B.szn
AND PLAYER = playername
;
----------------------------------------------------------------
ALTER TABLE NBA_historical.dbo.trueshootingplus
DROP COLUMN szn, playername;

--next CTE
WITH C AS (
SELECT
(SELECT (STDEV (ALL TrueShootingPercentage) OVER (PARTITION BY Season ORDER BY TrueShootingPercentage))) AS tsp_stdev,
Season AS szn,
Player AS playername
FROM NBA_historical.dbo.trueshootingplus
GROUP BY Season,PLAYER
HAVING Season=Season
AND PLAYER=PLAYER)
SELECT NBA_historical.dbo.trueshootingplus.*, C.*
INTO NBA_historical.dbo.tspercentage
FROM NBA_historical.dbo.trueshootingplus
LEFT JOIN C 
ON Season = szn
AND PLAYER = playername
;
WITH D AS (
SELECT (SELECT STDEV(TrueShootingPercentage)) AS Season_TS_StDev, Season AS what_season
FROM NBA_historical.dbo.trueshootingplus
WHERE Season=Season
GROUP BY Season)
SELECT NBA_historical.dbo.trueshootingplus.*, D.Season_TS_StDev
INTO NBA_historical.dbo.true_shooting_plus
FROM NBA_historical.dbo.trueshootingplus
LEFT JOIN D
ON Season=what_season
;
--------------------------------------------------------------------------------
ALTER TABLE NBA_historical.dbo.true_shooting_plus
ADD unique_key AS (PLAYER_ID+PLAYER);

ALTER TABLE NBA_historical.dbo.true_shooting_plus
ADD League AS ('NBA');
-------------------------------------------------------------------------------------
DROP TABLE NBA_historical.dbo.tsplus;

WITH E AS (SELECT (SELECT STDEVP(ALL TrueShootingPercentage)) AS hist_stdev,
League AS league_id
FROM NBA_historical.dbo.true_shooting_plus
GROUP BY League
)
SELECT NBA_historical.dbo.true_shooting_plus.*, E.hist_stdev
INTO NBA_historical.dbo.tsplus
FROM NBA_historical.dbo.true_shooting_plus
LEFT JOIN E
ON League = league_id;
ALTER TABLE NBA_historical.dbo.tsplus
ADD TS_PLUS AS ((((TrueShootingPercentage-seasonTS)/Season_TS_StDev)*hist_stdev)+.5);

--This is for conditions to unlock Asecntion quests every character has one
SELECT DISTINCT HTMLCONTENT
FROM(TIL_PORTFOLIO_PROJECTS.CHARALAMBOS_PERSONAL_PROJECT.MYHTMLDATAASCENTION);

CREATE OR REPLACE TABLE ASCENTION_QUEST_CONDITIONS AS (

WITH HTML_REPLACE AS (
SELECT URL, REGEXP_REPLACE(HTMLCONTENT,'\\n','') AS HTML,
RTRIM(REGEXP_SUBSTR(HTML,'\\w+&#39'),'&#39') AS HERO,SPLIT_PART(REGEXP_SUBSTR(HTML,'Ascension Quest:.*?Walkthrough'),'|',1) AS ASCENTION_QUEST
FROM TIL_PORTFOLIO_PROJECTS.CHARALAMBOS_PERSONAL_PROJECT.MYHTMLDATAASCENTION)

,

ALLQUESTSFILTER AS (

SELECT *,'1' AS ONE
FROM XC3_TEST_QUESTS AS A

INNER JOIN 

(SELECT *,'1' AS ONE
FROM MYHTMLDATAASCENTION) AS B

ON ONE = ONE
)
,

HTML_SPLIT1 AS (

SELECT HTML,VALUE AS SPLIT1,URL,ASCENTION_QUEST,HERO
FROM HTML_REPLACE,
LATERAL SPLIT_TO_TABLE(HTML,'<\/h3')
)
,
HTML_SPLIT2 AS (

SELECT SPLIT1,URL,HTML,VALUE AS SPLIT2,REGEXP_SUBSTR(SPLIT2,'Standard') AS QUESTFILTER,REGEXP_SUBSTR(SPLIT2,'Unlock Conditions') AS QUESTFILTER1,
REGEXP_SUBSTR(SPLIT2,'Required Quests') AS QUESTFILTER2,HERO,REGEXP_SUBSTR(SPLIT2,'Quest Giver') AS TABLE_HEADER
FROM HTML_SPLIT1,
LATERAL SPLIT_TO_TABLE(SPLIT1,'<\/h4>')
//centre
)

,

HTML_SPLIT_3 AS (

SELECT URL,HERO,SPLIT_PART(REGEXP_SUBSTR(HTML,'Ascension Quest:.*?Walkthrough'),'|',1) AS ASCENTION_QUEST,VALUE AS SPLIT3,TABLE_HEADER
FROM HTML_SPLIT2,
LATERAL SPLIT_TO_TABLE(SPLIT2,'</td>')
)

,

HTML_SPLIT_4 AS (

SELECT VALUE AS SPLIT4,HERO,TABLE_HEADER,ASCENTION_QUEST
FROM HTML_SPLIT_3,
LATERAL SPLIT_TO_TABLE(SPLIT3,REGEXP_SUBSTR(SPLIT3,'>'))
)


,

HTML_TABLE AS (
SELECT *,
  CASE MOD(ROW_NUMBER() OVER (ORDER BY ORDER1,HERO), 2)
    WHEN 0 THEN 2
    ELSE 1
  END AS ID
FROM(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(SPLIT4,'</th',''),'</a',''),'</span',''),' '),'<tr',''),'<th',''),'<td class="center"',''),'<th width="40%"',''),'<th width="40%"',''),'<td width="60%" class="center"',''),'</tr',''),' width="40%"','') AS MAIN_TABLE,HERO,SPLIT4,ASCENTION_QUEST,SPLIT4,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ORDER1,
TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(SPLIT4,'</th',''),'</a',''),'</span',''),' ')
FROM HTML_SPLIT_4
WHERE TABLE_HEADER IS NOT NULL AND MAIN_TABLE != SPLIT4 AND MAIN_TABLE != '' AND MAIN_TABLE != 'Reward' AND MAIN_TABLE != 'Required Discussion Topic and Locatio'
ORDER BY ORDER1))

,
//RTRIM(RTRIM(RTRIM(RTRIM(SPLIT4,'</th'),'</a'),'</span'),' ')
HTML_TABLE_DISS AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY HERO ORDER BY (ORDER1)) AS ORDISS
FROM(
SELECT REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(SPLIT4,'</th',''),'</a',''),'</span',''),' '),'<tr',''),'<th',''),'<td class="center"',''),'<th width="40%"',''),'<th width="40%"',''),'<td width="60%" class="center"',''),'</tr',''),' width="40%"','') AS MAIN_TABLE,HERO,SPLIT4,ASCENTION_QUEST,SPLIT4,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ORDER1
FROM HTML_SPLIT_4
WHERE TABLE_HEADER IS NOT NULL AND MAIN_TABLE != '' AND MAIN_TABLE != 'Reward'
ORDER BY ORDER1
))


,
HTML_DISS AS (
SELECT *,
CASE 
WHEN MAIN_TABLE = 'Required Discussion Topic and Location' THEN 1
WHEN MAIN_TABLE = 'City' OR MAIN_TABLE = 'Curious About Training <hr class="a-table__line"' 
OR MAIN_TABLE =  'Great Sword''s Base' OR MAIN_TABLE = 'The Sea <hr class="a-table__line"' 
OR MAIN_TABLE = 'Agnus Castle' OR MAIN_TABLE = 'Ghondor''s Grumblings <hr class="a-table__line"' THEN 2
ELSE NULL END AS DISCUSSION_FILTER
FROM HTML_TABLE_DISS
WHERE DISCUSSION_FILTER IS NOT NULL
)

,

HTML_DISS_1 AS (
SELECT A.MAIN_TABLE,LTRIM(REGEXP_REPLACE(B.MAIN_TABLE,' <hr class="a-table__line"',''),' ') AS VALUE,A.HERO,A.ASCENTION_QUEST
FROM
(SELECT MAIN_TABLE,HERO,ASCENTION_QUEST
FROM HTML_DISS
WHERE DISCUSSION_FILTER = 1) AS A
INNER JOIN 
(SELECT MAIN_TABLE,HERO,ASCENTION_QUEST
FROM HTML_DISS AS B
WHERE DISCUSSION_FILTER = 2) AS B

ON A.HERO = B.HERO
)


--MAIN_TABLE = 'Required Discussion Topic and Locatio'

,

HTML_ORDER_1 AS (
SELECT *,ROW_NUMBER() OVER ( ORDER BY (SELECT NULL)) AS RN
FROM HTML_TABLE
WHERE ID =1)

-- SELECT *
-- FROM HTML_ORDER_1;

,

HTML_ORDER_2 AS (
SELECT *,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RN
FROM HTML_TABLE
WHERE ID =2)

SELECT MAIN_TABLE,VALUE,CAST(HEROS AS VARCHAR(255)) AS HEROS,ASCENTION_QUEST_NAME
FROM (
SELECT A.MAIN_TABLE,B.MAIN_TABLE AS VALUE,
CASE WHEN A.HERO = 'Miyabi' AND REGEXP_REPLACE(A.ASCENTION_QUEST,'&#39;','') NOT LIKE '%Walkthrough%' THEN 'Mio'
ELSE A.HERO END AS HEROS,
CASE WHEN HEROS = 'Mio' THEN 'Ascension Quest: Side Story: Mio Walkthrough '
ELSE REGEXP_REPLACE(A.ASCENTION_QUEST,'&#39;','') END AS ASCENTION_QUEST_NAME
FROM HTML_ORDER_1 AS A 
INNER JOIN HTML_ORDER_2 AS B 
ON A.RN = B.RN

UNION 

SELECT *
FROM HTML_DISS_1

UNION

SELECT NULL AS MAIN_TABLE, NULL AS VALUE, 'Ethel' AS HEROS, NULL AS ASCENTION_QUEST_NAME
)
)
;
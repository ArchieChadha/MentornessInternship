use game_analysis;

ALTER TABLE level_details2 RENAME TO ld;
-- Drop the column 'myunknowncolumn' from the ld table
ALTER TABLE ld DROP COLUMN myunknowncolumn;
-- Change the data type of 'timestamp' column to datetime and rename it to 'start_datetime'
ALTER TABLE ld CHANGE COLUMN timestamp start_datetime DATETIME;
-- Modify the data type of 'Dev_Id' column to varchar(10)
ALTER TABLE ld MODIFY COLUMN Dev_Id VARCHAR(10);
-- Modify the data type of 'Difficulty' column to varchar(15)
ALTER TABLE ld MODIFY COLUMN Difficulty VARCHAR(15);


ALTER TABLE level_details2 RENAME TO ld;
-- Drop the column 'myunknowncolumn' from the ld table
ALTER TABLE ld DROP COLUMN myunknowncolumn;
-- Change the data type of 'timestamp' column to datetime and rename it to 'start_datetime'
ALTER TABLE ld CHANGE COLUMN timestamp start_datetime DATETIME;
-- Modify the data type of 'Dev_Id' column to varchar(10)
ALTER TABLE ld MODIFY COLUMN Dev_Id VARCHAR(10);
-- Modify the data type of 'Difficulty' column to varchar(15)
ALTER TABLE ld MODIFY COLUMN Difficulty VARCHAR(15);
-- Add a composite primary key consisting of P_ID, Dev_id, and start_datetime columns to the ld table
ALTER TABLE ld ADD PRIMARY KEY(P_ID, Dev_id, start_datetime);
-- Add a composite primary key consisting of P_ID, Dev_id, and start_datetime columns to the ld table
ALTER TABLE ld ADD PRIMARY KEY(P_ID, Dev_id, start_datetime);

-- pd (P_ID,PName,L1_status,L2_Status,L1_code,L2_Code)
-- ld (P_ID,Dev_ID,start_time,stages_crossed,level,difficulty,kill_count,
-- headshots_count,score,lives_earned)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all player at level 0

SELECT
ld.P_ID, ld.Dev_ID, 
pd. PName, ld.difficulty
FROM
ld
JOIN pd ON ld.P_ID = pd.P_ID
WHERE
ld.Level = 0;


-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and at least 3 stages are crossed

SELECT 
    pd.L1_Code, 
    ROUND(AVG(ld.kill_count), 2) AS Avg_Kill
FROM 
    ld
JOIN pd
  ON ld.P_ID = pd.P_ID
WHERE 
    ld.lives_earned = 2
    AND ld.stages_crossed >= 3
GROUP BY 
    pd.L1_Code;
    
    

-- Q3) Find the total number of stages crossed at each difficulty level where for Level2 with players use zm_series devices. Arrange the result in decreasing order of the total number of stages crossed.

SELECT 
    ld.difficulty,
    COUNT(ld.stages_crossed) AS total_stages_crossed
FROM 
    ld
JOIN pd 
  ON ld.P_ID = pd.P_ID
WHERE 
    ld.level = 2 
    AND ld.Dev_ID LIKE 'zm_%'
GROUP BY 
    ld.difficulty
ORDER BY 
    total_stages_crossed DESC;
    
    
-- Q4) Extract P_ID and the total number of unique dates for those players who have played games on multiple days.

SELECT 
    P_ID,
    COUNT(DISTINCT start_datetime) AS total_unique_dates
FROM 
    ld
GROUP BY 
    P_ID
HAVING 
    total_unique_dates > 1;
        

-- Q5) Find P_ID and level-wise sum of kill_counts where kill_count is greater than the average kill count for the Medium difficulty.

SELECT 
    P_ID, 
    level, 
    SUM(kill_Count) AS total_kill_count
FROM 
    ld
WHERE 
    kill_Count > (
        SELECT AVG(kill_Count)
        FROM ld
        WHERE difficulty = 'Medium')
GROUP BY 
    P_ID, level;
    
    
-- Q6) Find Level and its corresponding Level code wise sum of lives earned excluding level 0. Arrange in ascending order of the level.

SELECT 
    ld.level,
    CASE
        WHEN ld.level = 1 THEN pd.l1_code
        WHEN ld.level = 2 THEN pd.l2_code
        ELSE NULL
    END AS Level_Code,
    SUM(ld.lives_earned) AS Total_Lives_Earned
FROM 
    ld
JOIN pd 
  ON ld.P_ID = pd.P_ID
WHERE 
    ld.Level > 0
GROUP BY 
    ld.Level, Level_Code
ORDER BY 
    ld.Level;



-- Q7) Find Top 3 scores based on each dev_id and rank them in increasing order using Row_Number. Display difficulty as well.

SELECT 
    Dev_id, 
    score, 
    difficulty, 
    rank
FROM (
    SELECT 
        Dev_ID, 
        score, 
        difficulty, 
        ROW_NUMBER() OVER (PARTITION BY Dev_id ORDER BY score DESC) AS rank
    FROM 
        ld
)
WHERE 
    rank <= 3;


-- Q8) Find the first_login datetime for each device id

SELECT 
    Dev_ID, 
    MIN(start_datetime) AS first_Login
FROM 
    ld
GROUP BY 
    Dev_ID
ORDER BY 
    first_Login;



-- Q9) Find the Top 5 scores based on each difficulty level and rank them in increasing order using Rank. Display dev_id as well.

SELECT 
    Difficulty, 
    score, 
    dev_id, 
    rank
FROM (
    SELECT 
        difficulty, 
        score, 
        Dev_ID, 
        RANK() OVER (PARTITION BY difficulty ORDER BY score DESC) AS rank
    FROM 
        ld
)
WHERE 
    rank <= 5
ORDER BY 
    difficulty, rank;



-- Q10) Find the device ID that is first logged in (based on start_datetime) for each player(p_id). 
-- Output should contain player id, device id, and first login datetime.

SELECT 
    P_ID, 
    Dev_ID, 
    MIN(start_datetime) AS First_Login
FROM 
    ld
GROUP BY 
    P_ID, Dev_ID;
    
    

-- Q11) For each player and date, determine how many `kill_counts` were played by the player so far.

-- a) Using window functions

SELECT 
    P_ID, 
    start_datetime, 
    SUM(kill_count) OVER (PARTITION BY P_id ORDER BY start_datetime) AS total_kill_count
FROM 
    ld;
    
      
-- b) Without window functions

SELECT 
    ld1.P_ID,
    ld1.start_datetime,
    SUM(ld1.Kill_Count) AS total_kills_so_far
FROM
    ld ld1
        JOIN
    ld ld2 ON ld1.P_ID = ld2.P_ID
        AND ld1.start_datetime >= ld2.start_datetime
GROUP BY ld1.P_ID , ld1.start_datetime

  
-- Q12) Find the cumulative sum of stages crossed over a start_datetime 

  SELECT 
  start_time, 
  SUM(stages_crossed) OVER(ORDER BY start_time) AS Cumulative_Stages_Crossed
FROM 
  ld;


-- Q13) Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

SELECT
    P_ID,
    start_datetime,
    stages_crossed,
    SUM(stages_crossed) OVER (PARTITION BY P_ID
        ORDER BY start_datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS cumulative_sum
FROM
    ld;
    
    
-- Q14) Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

SELECT 
  Dev_ID, P_ID, SUM(score) AS Total_Score
FROM 
  ld
GROUP BY Dev_ID, P_ID
ORDER BY Total_Score DESC
LIMIT 3;

    
-- Q15) Find players who scored more than 50% of the average score scored by the sum of scores for each player_id

    SELECT
      P_ID
FROM (
    SELECT 
      P_ID, SUM(score) AS Total_Score
    FROM 
    ld
    GROUP BY P_ID ) AS player_scores
WHERE 
      Total_Score > (SELECT 0.5 * AVG(Total_Score) 
      FROM 
      (SELECT SUM(score) AS Total_Score FROM ld GROUP BY P_ID) AS avg_scores);
    

-- 16) Create a stored procedure to find top n headshots_count based on each dev_id and rank them in increasing order using Row_Number. Display difficulty as well.

DELIMITER \\
CREATE PROCEDURE Top_NHeadshots(
    IN n INT)
BEGIN
    SELECT 
        Dev_id, 
        headshots_count, 
        difficulty, 
        ranking
    FROM (
        SELECT 
            dev_id, 
            headshots_count, 
            difficulty, 
            ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY headshots_count DESC) AS ranking
        FROM 
            ld
    ) AS ranked
    WHERE 
        ranking <= n;
END \\
DELIMITER ;

-- Call the stored procedure Top_N_Headshots
-- The parameter '4' sHOWS that the top 4 headshots count will be returned for each dev_id

CALL Top_NHeadshots(4);



-- Q17) Create a function to return the sum of Score for a given player_id.

DELIMITER \\
CREATE FUNCTION Total_Score(
    player_Id INT
)
RETURNS INT
BEGIN
    DECLARE total_Score INT;
    
    SELECT 
        SUM(score) INTO total_Score
    FROM 
        ld
    WHERE 
        P_ID = player_Id;
    
    RETURN total_Score;
END \\
DELIMITER ;


-- Call the Total_Score function to calculate the total score for the player with ID 683

SELECT Total_Score(683);


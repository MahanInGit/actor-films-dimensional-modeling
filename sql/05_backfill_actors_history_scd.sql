-- ============================================
-- Initial Load for Actors SCD Table
-- ============================================

-- Builds the historical SCD records for actors up to 2021.
-- Consecutive years with the same quality_class and is_active
-- values are grouped into one historical period.

INSERT INTO actors_history_scd (
    actor,
    actorid,
    quality_class,
    is_active,
    start_date,
    end_date,
    current_year
)

-- Adds the previous year's values for each actor so changes
-- can be detected year by year.
WITH with_previous AS (
    SELECT
        actor,
        actorid,
        quality_class,
        is_active,
        current_year,

        -- Previous quality_class for the same actor
        LAG(quality_class) OVER (
            PARTITION BY actorid
            ORDER BY current_year
        ) AS previous_quality_class,

        -- Previous is_active value for the same actor
        LAG(is_active) OVER (
            PARTITION BY actorid
            ORDER BY current_year
        ) AS previous_is_active
    FROM actors
    WHERE current_year <= 2021
),

-- Flags the first record or any year where the actor's
-- tracked attributes changed.
with_change_flag AS (
    SELECT
        *,
        CASE
            WHEN previous_quality_class IS NULL THEN 1
            WHEN quality_class <> previous_quality_class THEN 1
            WHEN is_active <> previous_is_active THEN 1
            ELSE 0
        END AS change_flag
    FROM with_previous
),

-- Creates a streak identifier for each continuous period
-- where quality_class and is_active stayed the same.
with_streak AS (
    SELECT
        *,
        SUM(change_flag) OVER (
            PARTITION BY actorid
            ORDER BY current_year
        ) AS streak_identifier
    FROM with_change_flag
)

-- Converts each streak into one SCD history record.
SELECT
    actor,
    actorid,
    quality_class,
    is_active,
    MIN(current_year) AS start_date,
    MAX(current_year) AS end_date,
    2021 AS current_year
FROM with_streak
GROUP BY
    actor,
    actorid,
    quality_class,
    is_active,
    streak_identifier;
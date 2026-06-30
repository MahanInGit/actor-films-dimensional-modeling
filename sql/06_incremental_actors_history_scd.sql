-- ============================================
-- Incremental Load for Actors SCD Table
-- ============================================

-- Updates the actors SCD table from the 2020 snapshot to the 2021 snapshot.
-- It keeps old historical records, extends unchanged active records,
-- closes changed records, and creates new records where needed.

INSERT INTO actors_history_scd (
    actor,
    actorid,
    quality_class,
    is_active,
    start_date,
    end_date,
    current_year
)

-- Gets the previous SCD snapshot.
WITH last_year_scd AS (
    SELECT *
    FROM actors_history_scd
    WHERE current_year = 2020
),

-- Keeps historical records that were already closed before 2020.
historical_scd AS (
    SELECT
        actor,
        actorid,
        quality_class,
        is_active,
        start_date,
        end_date
    FROM last_year_scd
    WHERE end_date < 2020
),

-- Gets records that were active in the previous snapshot year.
last_year_active_scd AS (
    SELECT *
    FROM last_year_scd
    WHERE end_date = 2020
),

-- Gets the current year actor data.
this_year_data AS (
    SELECT *
    FROM actors
    WHERE current_year = 2021
),

-- Extends records where quality_class and is_active did not change.
unchanged_records AS (
    SELECT
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        ly.start_date,
        2021 AS end_date
    FROM this_year_data ty
    JOIN last_year_active_scd ly
        ON ty.actorid = ly.actorid
    WHERE ty.quality_class = ly.quality_class
      AND ty.is_active = ly.is_active
),

-- Creates two records when a change happens:
-- 1. the previous version remains closed at 2020
-- 2. the new version starts in 2021
changed_records AS (
    SELECT
        ty.actor,
        ty.actorid,
        UNNEST(ARRAY[
            ROW(
                ly.quality_class,
                ly.is_active,
                ly.start_date,
                ly.end_date
            )::actors_scd_type,

            ROW(
                ty.quality_class,
                ty.is_active,
                2021,
                2021
            )::actors_scd_type
        ]) AS records
    FROM this_year_data ty
    JOIN last_year_active_scd ly
        ON ty.actorid = ly.actorid
    WHERE ty.quality_class <> ly.quality_class
       OR ty.is_active <> ly.is_active
),

-- Expands the changed records back into normal table columns.
unnested_changed_records AS (
    SELECT
        actor,
        actorid,
        (records::actors_scd_type).quality_class,
        (records::actors_scd_type).is_active,
        (records::actors_scd_type).start_date,
        (records::actors_scd_type).end_date
    FROM changed_records
),

-- Adds actors that did not exist in last year's active SCD records.
new_records AS (
    SELECT
        ty.actor,
        ty.actorid,
        ty.quality_class,
        ty.is_active,
        2021 AS start_date,
        2021 AS end_date
    FROM this_year_data ty
    LEFT JOIN last_year_active_scd ly
        ON ty.actorid = ly.actorid
    WHERE ly.actorid IS NULL
)

-- Combines all SCD record types into the new 2021 snapshot.
SELECT *, 2021 AS current_year
FROM historical_scd

UNION ALL

SELECT *, 2021 AS current_year
FROM unchanged_records

UNION ALL

SELECT *, 2021 AS current_year
FROM unnested_changed_records

UNION ALL

SELECT *, 2021 AS current_year
FROM new_records;
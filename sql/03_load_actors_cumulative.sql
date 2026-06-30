-- ============================================
-- Populate Actors Cumulative Table
-- ============================================

-- Inserts one row per actor per year, starting from the
-- actor's first film year up to the latest year in the source data.
-- Each row stores the actor's cumulative film history and yearly status.

INSERT INTO actors (
    actor,
    actorid,
    films,
    quality_class,
    is_active,
    current_year
)

-- Creates a complete list of years available in the actor_films dataset.
WITH years AS (
    SELECT *
    FROM GENERATE_SERIES(
        (SELECT MIN(year) FROM actor_films),
        (SELECT MAX(year) FROM actor_films)
    ) AS year
),

-- Finds the first year each actor appeared in the dataset.
actor_first_year AS (
    SELECT
        actorid,
        actor,
        MIN(year) AS first_year
    FROM actor_films
    GROUP BY actorid, actor
),

-- Creates one row for every actor and every year from
-- their first active year onward.
actors_and_years AS (
    SELECT
        afy.actorid,
        afy.actor,
        y.year
    FROM actor_first_year afy
    JOIN years y
        ON afy.first_year <= y.year
),

-- Builds the final yearly actor snapshot.
final AS (
    SELECT
        ay.actor,
        ay.actorid,

        -- Stores all films for the actor up to the current year
        -- as an array of film_info records.
        COALESCE(
            ARRAY(
                SELECT ROW(
                    af.film,
                    af.votes,
                    af.rating,
                    af.filmid
                )::film_info
                FROM actor_films af
                WHERE af.actorid = ay.actorid
                  AND af.year <= ay.year
                ORDER BY af.year, af.filmid
            ),
            ARRAY[]::film_info[]
        ) AS films,

        -- Assigns a quality class based on the actor's average
        -- rating in their most recent active year up to this snapshot.
        CASE
            WHEN latest_year.avg_rating > 8 THEN 'star'
            WHEN latest_year.avg_rating > 7 THEN 'good'
            WHEN latest_year.avg_rating > 6 THEN 'average'
            ELSE 'bad'
        END::quality_class AS quality_class,

        -- Marks whether the actor released at least one film
        -- in the current snapshot year.
        EXISTS (
            SELECT 1
            FROM actor_films af
            WHERE af.actorid = ay.actorid
              AND af.year = ay.year
        ) AS is_active,

        -- The year represented by this actor snapshot.
        ay.year AS current_year

    FROM actors_and_years ay

    -- Finds the actor's latest active year up to the current snapshot
    -- and calculates the average film rating for that year.
    LEFT JOIN LATERAL (
        SELECT AVG(af.rating) AS avg_rating
        FROM actor_films af
        WHERE af.actorid = ay.actorid
          AND af.year = (
              SELECT MAX(af2.year)
              FROM actor_films af2
              WHERE af2.actorid = ay.actorid
                AND af2.year <= ay.year
          )
    ) latest_year ON TRUE
)

-- Inserts the prepared yearly snapshots into the actors table.
SELECT *
FROM final;
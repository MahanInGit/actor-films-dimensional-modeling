-- ============================================
-- Custom Types
-- ============================================

-- Defines the quality category assigned to an actor
-- based on the average rating of their most recent films.

CREATE TYPE quality_class AS ENUM (
    'star',
    'good',
    'average',
    'bad'
);


-- Composite type used to store film information inside
-- an array. Each actor can have multiple films, allowing
-- the table to maintain a nested film history.

CREATE TYPE film_info AS (
    film TEXT,
    votes INTEGER,
    rating DOUBLE PRECISION,
    filmid TEXT
);

-- Composite type used for Slowly Changing Dimension (SCD)
-- processing. It represents one historical version of an
-- actor's attributes, including the period during which
-- those values were valid.

CREATE TYPE actors_scd_type AS (
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER
);
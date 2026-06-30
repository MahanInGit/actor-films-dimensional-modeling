-- ============================================
-- Actors Table
-- ============================================

-- Stores one record per actor for each year, following
-- a cumulative table design. Each row represents the
-- actor's state in a specific year, including their
-- complete film history up to that point.

CREATE TABLE actors (
    -- Actor's full name
    actor TEXT NOT NULL,

    -- Unique IMDb actor identifier
    actorid TEXT NOT NULL,

    -- Cumulative array of all films the actor has appeared
    -- in up to the current year
    films film_info[],

    -- Classification based on the latest film rating
    quality_class quality_class,

    -- Indicates whether the actor released a film
    -- during the current year
    is_active BOOLEAN NOT NULL,

    -- Snapshot year represented by this record
    current_year INTEGER NOT NULL,

    -- Ensures one record per actor per year
    PRIMARY KEY (actorid, current_year),

    -- Prevents invalid years from being inserted
    CHECK (current_year > 1800)
);
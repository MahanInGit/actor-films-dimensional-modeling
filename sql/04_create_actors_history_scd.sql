-- ============================================
-- Actors History (SCD Type 2)
-- ============================================

-- Stores the historical versions of each actor's attributes
-- using a Slowly Changing Dimension (Type 2) design.
-- A new record is created whenever an actor's quality_class
-- or active status changes, preserving the full history.

CREATE TABLE actors_history_scd (
    -- Actor's full name
    actor TEXT,

    -- Unique IMDb actor identifier
    actorid TEXT,

    -- Actor's quality classification during this period
    quality_class quality_class,

    -- Indicates whether the actor was active during this period
    is_active BOOLEAN,

    -- First year this version became valid
    start_date INTEGER,

    -- Last year this version remained valid
    end_date INTEGER,

    -- Snapshot year when the SCD table was generated
    current_year INTEGER,

    -- Ensures each historical version is unique
    PRIMARY KEY (actorid, start_date, current_year)
);
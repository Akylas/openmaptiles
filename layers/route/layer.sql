CREATE OR REPLACE FUNCTION network_level (
    network text
)
    RETURNS integer
    AS $$
    SELECT
        coalesce(array_position(ARRAY['icn', 'ncn', 'rcn', 'lcn'], network::text), array_position(ARRAY['iwn', 'nwn', 'rwn', 'lwn'], network::text));

$$
LANGUAGE SQL
IMMUTABLE STRICT;

-- etldoc: osm_route_linestring -> osm_route_max_network
CREATE TEMP TABLE osm_route_max_network AS SELECT DISTINCT ON (member_id, route)
    osm_id,
    member_id,
    geometry,
    route,
    network_level (network) AS network,
    name,
    ref,
    colour,
    ascent,
    descent,
    distance,
    website
FROM
    osm_route_linestring
WHERE
    "type" = 1
    AND network != ''
    AND network_level (network) IS NOT NULL
    AND ROLE IN ('', 'forward', 'backward', 'reverse')
ORDER BY
    member_id,
    route,
    network_level (network);

-- etldoc: osm_route_max_network -> osm_route_network
CREATE TEMP TABLE osm_route_network AS
SELECT
    osm_id,
    member_id,
    geometry,
    'bicycle' AS class,
    network,
    nullif (name, '') AS name,
    nullif (ref, '') AS ref,
    nullif (colour, '') AS colour,
    ascent::int,
    descent::int,
    distance::int,
    nullif (website, '') AS website
FROM
    osm_route_max_network
WHERE
    route = 'bicycle'
UNION ALL
SELECT
    osm_id,
    member_id,
    geometry,
    'hiking' AS class,
    network,
    nullif (name, '') AS name,
    nullif (ref, '') AS ref,
    nullif (colour, '') AS colour,
    ascent::int,
    descent::int,
    distance::int,
    nullif (website, '') AS website
FROM
    osm_route_max_network
WHERE
    route = 'hiking';

-- etldoc: osm_route_network -> osm_route_network_merge
DROP TABLE IF EXISTS osm_route_network_merge CASCADE;

CREATE TABLE IF NOT EXISTS osm_route_network_merge AS
SELECT
    osm_id,
    member_id,
    (ST_Dump (ST_LineMerge (ST_Collect (geometry)))).geom AS geometry,
    class,
    network,
    name,
    ref,
    colour,
    ascent,
    descent,
    distance,
    website
FROM
    osm_route_network
GROUP BY
    osm_id,
    member_id,
    class,
    network,
    name,
    ref,
    colour,
    ascent,
    descent,
    distance,
    website,
    -- Cluster by windows to lower time and memory required
    (ST_XMin (geometry) / 10000)::int,
    (ST_YMin (geometry) / 10000)::int;

-- etldoc: osm_route_network_merge -> osm_route_network_merge_z12
CREATE MATERIALIZED VIEW osm_route_network_merge_z12 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 30) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge
    WHERE
        ST_Length (geometry) > 20);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z12_geometry_idx ON osm_route_network_merge_z12 USING gist (geometry);

-- etldoc: osm_route_network_merge_z12 -> osm_route_network_merge_z11
CREATE MATERIALIZED VIEW osm_route_network_merge_z11 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 60) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z12
    WHERE
        ST_Length (geometry) > 75);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z11_geometry_idx ON osm_route_network_merge_z11 USING gist (geometry);

-- etldoc: osm_route_network_merge_z11 -> osm_route_network_merge_z10
CREATE MATERIALIZED VIEW osm_route_network_merge_z10 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 110) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z11
    WHERE
        ST_Length (geometry) > 125);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z10_geometry_idx ON osm_route_network_merge_z10 USING gist (geometry);

-- etldoc: osm_route_network_merge_z10 -> osm_route_network_merge_z9
CREATE MATERIALIZED VIEW osm_route_network_merge_z9 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 200) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z10
    WHERE
        ST_Length (geometry) > 250 AND
        network <= 4);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z9_geometry_idx ON osm_route_network_merge_z9 USING gist (geometry);

-- etldoc: osm_route_network_merge_z9 -> osm_route_network_merge_z8
CREATE MATERIALIZED VIEW osm_route_network_merge_z8 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 400) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z9
    WHERE
        ST_Length (geometry) > 500);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z8_geometry_idx ON osm_route_network_merge_z8 USING gist (geometry);

-- etldoc: osm_route_network_merge_z8 -> osm_route_network_merge_z7
CREATE MATERIALIZED VIEW osm_route_network_merge_z7 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 800) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z8
    WHERE
        ST_Length (geometry) > 1000
        AND network <= 3);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z7_geometry_idx ON osm_route_network_merge_z7 USING gist (geometry);

-- etldoc: osm_route_network_merge_z7 -> osm_route_network_merge_z6
CREATE MATERIALIZED VIEW osm_route_network_merge_z6 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 1600) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z7
    WHERE
        ST_Length (geometry) > 2000);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z6_geometry_idx ON osm_route_network_merge_z6 USING gist (geometry);

-- etldoc: osm_route_network_merge_z6 -> osm_route_network_merge_z5
CREATE MATERIALIZED VIEW osm_route_network_merge_z5 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 1600) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z6
    WHERE
        ST_Length (geometry) > 2000
        AND network <= 2);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z5_geometry_idx ON osm_route_network_merge_z5 USING gist (geometry);

-- etldoc: osm_route_network_merge_z5 -> osm_route_network_merge_z4
CREATE MATERIALIZED VIEW osm_route_network_merge_z4 AS (
    SELECT
        osm_id,
        member_id,
        ST_Simplify (geometry, 1600) AS geometry,
        class,
        network,
        name,
        ref,
        colour,
        ascent,
        descent,
        distance,
        website
    FROM
        osm_route_network_merge_z5
    WHERE
        ST_Length (geometry) > 2000
        AND network <= 1);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z4_geometry_idx ON osm_route_network_merge_z4 USING gist (geometry);

-- etldoc: layer_route[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_route |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_route(geometry, integer) CASCADE;

CREATE OR REPLACE FUNCTION layer_route (
    bbox geometry,
    zoom_level integer
)
    RETURNS TABLE (
            osm_id bigint,
            member_id bigint,
            geometry geometry,
            class text,
            network integer,
            name text,
            ref text,
            colour text,
            ascent integer,
            descent integer,
            distance integer,
            website text
        )
        AS $$
    SELECT
        *
    FROM
        osm_route_network_merge_z4
    WHERE
        zoom_level = 4
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z5
    WHERE
        zoom_level = 5
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z6
    WHERE
        zoom_level = 6
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z7
    WHERE
        zoom_level = 7
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z8
    WHERE
        zoom_level = 8
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z9
    WHERE
        zoom_level = 9
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z10
    WHERE
        zoom_level = 10
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z11
    WHERE
        zoom_level = 11
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge_z12
    WHERE
        zoom_level = 12
        AND geometry && bbox
    UNION ALL
    SELECT
        *
    FROM
        osm_route_network_merge
    WHERE
        zoom_level >= 13
        AND geometry && bbox;

$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;


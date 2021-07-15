CREATE OR REPLACE FUNCTION network_level (
    network text
)
    RETURNS integer
    AS $$
    SELECT
        nullif(coalesce(array_position(ARRAY['icn', 'ncn', 'rcn', 'lcn'], network::text), array_position(ARRAY['iwn', 'nwn', 'rwn', 'lwn'], network::text)), -1);

$$
LANGUAGE SQL
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION route_ref (
    ref text,
    name text
)
    RETURNS text
    AS $$
    SELECT
        nullif(coalesce(nullif (ref,''), TRIM(BOTH '-–' from REGEXP_REPLACE(SPLIT_PART(SPLIT_PART(name, ':', 1), ',', 1), '([^A-Z0-9\:\,\-–]+)|(\M-\m)', '', 'g'))), '');

$$
LANGUAGE SQL
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION coord_str (
    coord double precision
)
    RETURNS text
    AS $$
    SELECT (coord::numeric(11,8))::text;

$$
LANGUAGE SQL
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION bbox_str (
    bbox box2d
)
    RETURNS text
    AS $$
    SELECT
        coord_str(ST_XMin(bbox)) || ',' || coord_str(ST_YMin(bbox)) || ',' || coord_str(ST_XMax(bbox)) || ',' || coord_str(ST_YMax(bbox));

$$
LANGUAGE SQL
IMMUTABLE STRICT;

-- etldoc: osm_route_linestring -> osm_route_max_network
-- CREATE TEMP TABLE osm_route_max_network AS SELECT DISTINCT ON (member_id, route)
--     osm_id,
--     relation_id,
--     member_id,
--     geometry,
--     route as class,
--     network_level (network) AS network,
--     nullif (name, '') as name,
--     route_ref (ref, name) AS ref,
--     nullif (symbol, '') as symbol,
--     nullif (coalesce(nullif(color, ''), SPLIT_PART(symbol, ':', 1)), '') AS color,
--     ascent,
--     descent,
--     distance,
--     nullif (description, '') as description,
--     nullif (website, '') as website
-- FROM
--     osm_route_linestring
-- ORDER BY
--     member_id,
--     route,
--     network_level (network);

-- etldoc: osm_route_max_network -> osm_route_network
-- CREATE TEMP TABLE osm_route_network AS
-- SELECT
--     coalesce(bicycle.osm_id, hiking.osm_id) AS osm_id,
--     coalesce(bicycle.relation_id, hiking.relation_id) AS relation_id,
--     coalesce(bicycle.member_id, hiking.member_id) AS member_id,
--     coalesce(bicycle.geometry, hiking.geometry) AS geometry,
--     coalesce(bicycle.route, hiking.route) AS class,
--     coalesce(bicycle.network, hiking.network) AS network,
--     nullif (coalesce(bicycle.name, hiking.name), '') AS name,
--     nullif (coalesce(bicycle.symbol, hiking.symbol), '') AS symbol,
--     nullif (coalesce(bicycle.ref, hiking.ref), '') AS ref,
--     nullif (coalesce(bicycle.color, hiking.color), '') AS color,
--     coalesce(bicycle.ascent, hiking.ascent)::int AS ascent,
--     coalesce(bicycle.descent, hiking.descent)::int AS descent,
--     coalesce(bicycle.distance, hiking.distance)::int AS distance,
--     nullif (coalesce(bicycle.description, hiking.description), '') AS description,
--     nullif (coalesce(bicycle.website, hiking.website), '') AS website
-- FROM
--     (SELECT * FROM osm_route_max_network WHERE route = 'bicycle') AS bicycle
--     FULL OUTER JOIN (SELECT * FROM osm_route_max_network WHERE route IN ('hiking', 'foot')) AS hiking ON
--         bicycle.member_id = hiking.member_id
-- ;

-- etldoc: osm_route_network -> osm_route_network_merge
DROP MATERIALIZED VIEW IF EXISTS osm_route_network_merge CASCADE;
CREATE MATERIALIZED VIEW IF NOT EXISTS osm_route_network_merge AS
(
SELECT osm_id,
       (ST_Dump(geometry)).geom as geometry,
       route AS class,
       network_level (network) AS network,
       nullif (name, '') AS name,
       route_ref (ref, name) AS ref,
       nullif (symbol, '') AS symbol,
       NULL::text AS textcolor,
       nullif (coalesce(SPLIT_PART(SPLIT_PART(symbol, ':', 1), '_', 1), color), '') AS color,
       case when ascent <@ int4range(0,100000) then ascent else null END as ascent,
       case when descent <@ int4range(0,100000) then descent else null END as descent,
       coalesce(nullif (distance, 0), ST_Length(geometry)::int) AS distance,
       nullif (description, '') AS description,
       nullif (website, '') AS website,
       extent
    FROM (
        SELECT osm_id,
            ST_LineMerge (ST_Collect (geometry)) AS geometry,
            (array_agg(route))[1] AS route,
            (array_agg(network))[1] AS network,
            (array_agg(name))[1] AS name,
            (array_agg(ref))[1] AS ref,
            (array_agg(symbol))[1] AS symbol,
            (array_agg(color))[1] AS color,
            (array_agg(ascent))[1] AS ascent,
            (array_agg(descent))[1] AS descent,
            coalesce(nullif ((array_agg(distance))[1],0), (sum(ST_Length(geometry))/1000)::int) AS distance,
            (array_agg(description))[1] AS description,
            (array_agg(website))[1] AS website,
            bbox_str ((ST_Extent(ST_Transform(geometry, 4326)))) AS extent
        FROM osm_route_linestring
        GROUP BY osm_id
     ) union_route
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS oosm_route_network_merge_geometry_idx
    ON osm_route_network_merge USING gist (geometry);

-- DROP MATERIALIZED VIEW IF EXISTS osm_route_network_merge CASCADE;
-- CREATE MATERIALIZED VIEW IF NOT EXISTS osm_route_network_merge AS
-- (
-- SELECT osm_id,
--        geometry,
--        route AS class,
--        network_level (network) AS network,
--        nullif (name, '') AS name,
--        route_ref (ref, name) AS ref,
--        nullif (symbol, '') AS symbol,
--        nullif (coalesce(nullif(color, ''), SPLIT_PART(symbol, ':', 1)), '') AS color,
--        ascent,
--        descent,
--        coalesce(nullif (distance, 0), ST_Length(geometry)::int) AS distance,
--        nullif (description, '') AS description,
--        nullif (website, '') AS website,
--        bbox
--     FROM (
--         SELECT osm_id,
--             (ST_Dump(ST_LineMerge (ST_Collect (geometry)))).geom AS geometry,
--             route,
--             network,
--             name,
--             ref,
--             symbol,
--             color,
--             sum(ascent)::int AS ascent,
--             sum(descent)::int AS descent,
--             coalesce(nullif ((array_agg(distance))[1],0), (sum(ST_Length(geometry))/1000)::int) AS distance,
--             description,
--             website,
--             bbox_str ((ST_Extent(ST_Transform(geometry, 4326)))) AS bbox
--         FROM osm_route_linestring
--         GROUP BY osm_id,
--             route,
--             network,
--             name,
--             ref,
--             symbol,
--             color,
--             ascent,
--             descent,
--             distance,
--             description,
--             website
--      ) union_route
--     ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
-- CREATE INDEX IF NOT EXISTS oosm_route_network_merge_geometry_idx
--     ON osm_route_network_merge USING gist (geometry);

-- etldoc: osm_route_network_merge -> osm_route_network_merge_z12
CREATE MATERIALIZED VIEW osm_route_network_merge_z12 AS (
    SELECT *
    FROM
        osm_route_network_merge);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z12_geometry_idx ON osm_route_network_merge_z12 USING gist (geometry);

-- etldoc: osm_route_network_merge_z12 -> osm_route_network_merge_z11
CREATE MATERIALIZED VIEW osm_route_network_merge_z11 AS (
    SELECT *
    FROM
        osm_route_network_merge_z12);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z11_geometry_idx ON osm_route_network_merge_z11 USING gist (geometry);

-- etldoc: osm_route_network_merge_z11 -> osm_route_network_merge_z10
CREATE MATERIALIZED VIEW osm_route_network_merge_z10 AS (
    SELECT *
    FROM
        osm_route_network_merge_z11
    );

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z10_geometry_idx ON osm_route_network_merge_z10 USING gist (geometry);

-- etldoc: osm_route_network_merge_z10 -> osm_route_network_merge_z9
CREATE MATERIALIZED VIEW osm_route_network_merge_z9 AS (
    SELECT *
    FROM
        osm_route_network_merge_z10
    WHERE
        network <= 4);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z9_geometry_idx ON osm_route_network_merge_z9 USING gist (geometry);

-- etldoc: osm_route_network_merge_z9 -> osm_route_network_merge_z8
CREATE MATERIALIZED VIEW osm_route_network_merge_z8 AS (
    SELECT
        osm_id,
        ST_Simplify(geometry, ZRes(10)) AS geometry,
        class,
        network,
        name,
        ref,
        symbol,
        textcolor,
        color,
        ascent,
        descent,
        distance,
        description,
        website,
        extent
    FROM
        osm_route_network_merge_z9);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z8_geometry_idx ON osm_route_network_merge_z8 USING gist (geometry);

-- etldoc: osm_route_network_merge_z8 -> osm_route_network_merge_z7
CREATE MATERIALIZED VIEW osm_route_network_merge_z7 AS (
    SELECT
        osm_id,
        ST_Simplify(geometry, ZRes(9)) AS geometry,
        class,
        network,
        name,
        ref,
        symbol,
        textcolor,
        color,
        ascent,
        descent,
        distance,
        description,
        website,
        extent
    FROM
        osm_route_network_merge_z8
    WHERE network <= 3 AND name IS NOT NULL);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z7_geometry_idx ON osm_route_network_merge_z7 USING gist (geometry);

-- etldoc: osm_route_network_merge_z7 -> osm_route_network_merge_z6
CREATE MATERIALIZED VIEW osm_route_network_merge_z6 AS (
    SELECT
        osm_id,
        ST_Simplify(geometry, ZRes(8)) AS geometry,
        class,
        network,
        name,
        ref,
        symbol,
        textcolor,
        color,
        ascent,
        descent,
        distance,
        description,
        website,
        extent
    FROM
        osm_route_network_merge_z7
    WHERE network <= 2);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z6_geometry_idx ON osm_route_network_merge_z6 USING gist (geometry);

-- etldoc: osm_route_network_merge_z6 -> osm_route_network_merge_z5
CREATE MATERIALIZED VIEW osm_route_network_merge_z5 AS (
    SELECT
        osm_id,
        ST_Simplify(geometry, ZRes(7)) AS geometry,
        class,
        network,
        name,
        ref,
        symbol,
        textcolor,
        color,
        ascent,
        descent,
        distance,
        description,
        website,
        extent
    FROM
        osm_route_network_merge_z6
    WHERE
        network <= 2 AND name IS NOT NULL);

CREATE INDEX IF NOT EXISTS osm_route_network_merge_z5_geometry_idx ON osm_route_network_merge_z5 USING gist (geometry);

-- etldoc: osm_route_network_merge_z5 -> osm_route_network_merge_z4
CREATE MATERIALIZED VIEW osm_route_network_merge_z4 AS (
    SELECT
        osm_id,
        ST_Simplify(geometry, ZRes(6)) AS geometry,
        class,
        network,
        name,
        ref,
        symbol,
        textcolor,
        color,
        ascent,
        descent,
        distance,
        description,
        website,
        extent
    FROM
        osm_route_network_merge_z5
    WHERE
        network <= 1);

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
            geometry geometry,
            class text,
            network integer,
            name text,
            ref text,
            symbol text,
            textcolor text,
            color text,
            ascent integer,
            descent integer,
            distance integer,
            description text,
            website text,
            extent text
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


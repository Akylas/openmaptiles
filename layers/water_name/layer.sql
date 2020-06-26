-- etldoc: layer_water_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water_name | <z0_8> z0_8 | <z9_13> z9_13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_water_name(bbox geometry, zoom_level integer, pixel_width real, pixel_height real)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, tags hstore, class text, intermittent int, ele int, way_pixels bigint) AS $$
    -- etldoc: osm_water_lakeline ->  layer_water_name:z9_13
    -- etldoc: osm_water_lakeline ->  layer_water_name:z14_
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END                                      AS osm_id_hash,
    geometry, name,
    tags,
    'lake'::text                                 AS class,
    NULLIF(is_intermittent, FALSE)::int AS intermittent,
    substring(ele from E'^(-?\\d+)(\\D|$)')::int AS ele,
    (area/NULLIF(zoom_level::real*pixel_width::real*pixel_height::real,0))::bigint AS way_pixels
FROM osm_water_lakeline
WHERE geometry && bbox
      AND ((zoom_level BETWEEN 8 AND 11 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
        OR (zoom_level >= 12))
    -- etldoc: osm_water_point ->  layer_water_name:z9_13
    -- etldoc: osm_water_point ->  layer_water_name:z14_
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END                                      AS osm_id_hash,
    geometry, name,
    tags,
    'lake'::text                                 AS class,
    NULLIF(is_intermittent, FALSE)::int AS intermittent,
    substring(ele from E'^(-?\\d+)(\\D|$)')::int AS ele,
    (area/NULLIF(zoom_level::real*pixel_width::real*pixel_height::real,0))::bigint AS way_pixels
FROM osm_water_point
    WHERE geometry && bbox AND (
        (zoom_level BETWEEN 8 AND 11 AND area > 10000*2^(20-zoom_level))
        OR (zoom_level BETWEEN 11 AND 12 AND area > 500*2^(20-zoom_level))
        OR (zoom_level >= 13)
    )
UNION ALL
SELECT
    -- etldoc: osm_marine_point ->  layer_water_name:z0_8
    -- etldoc: osm_marine_point ->  layer_water_name:z9_13
    -- etldoc: osm_marine_point ->  layer_water_name:z14_
    UNION ALL
    SELECT osm_id*10, geometry, name,
    tags,
    place::text                                  AS class,
    NULLIF(is_intermittent, FALSE)::int AS intermittent,
    NULL::int AS ele,
    NULL::bigint AS way_pixels
FROM osm_marine_point
WHERE geometry && bbox
  AND (
        place = 'ocean'
        OR (zoom_level >= "rank" AND "rank" IS NOT NULL)
        OR (zoom_level >= 8)
    );
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

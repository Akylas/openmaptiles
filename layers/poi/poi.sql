-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z12> z12 | <z13> z13 | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_poi(geometry, integer, numeric) CASCADE;

CREATE OR REPLACE FUNCTION layer_poi (
    bbox geometry,
    zoom_level integer,
    pixel_width numeric
)
    RETURNS TABLE (
                osm_id   bigint,
                geometry geometry,
                name     text,
                tags     hstore,
                class    text,
                subclass text,
            historic text,
                agg_stop integer,
                layer    integer,
                level    integer,
            capacity integer,
                indoor   integer,
            ele int,
                "rank"   int
            )
        AS $$
    SELECT
        osm_id_hash AS osm_id,
       geometry,
       NULLIF(name, '') AS name,
       tags,
       poi_class(subclass, mapping_key) AS class,
        CASE WHEN subclass = 'information' THEN
            NULLIF (information, '')
        WHEN subclass = 'place_of_worship' THEN
            NULLIF (religion, '')
        WHEN subclass = 'pitch' THEN
            NULLIF (sport, '')
        WHEN poi_class (subclass, mapping_key) = subclass THEN
            NULL
        ELSE
            subclass
           END AS subclass,
        NULL::text AS historic,
       CASE WHEN agg_stop > 1 THEN
            agg_stop ELSE NULL
        END AS agg_stop,
       NULLIF(layer, 0) AS layer,
       "level",
        capacity,
        CASE WHEN indoor = TRUE THEN
            1 ELSE NULL
        END AS indoor,
        substring(ele FROM E'^(-?\\d+)(\\D|$)')::int AS ele,
        row_number() OVER (PARTITION BY LabelGrid (geometry, 100 * pixel_width) ORDER BY CASE WHEN name IS NULL THEN
                2000
            ELSE
                poi_class_rank (poi_class (subclass, mapping_key))
            END ASC)::int AS "rank"
FROM (
        -- etldoc: osm_poi_point ->  layer_poi:z11
        -- etldoc: osm_poi_point ->  layer_poi:z12
        SELECT
            *,
            osm_id * 10 AS osm_id_hash
        FROM
            osm_poi_point
        WHERE
            geometry && bbox
            AND zoom_level BETWEEN 11 AND 12
            AND (subclass IN ('alpine_hut', 'wilderness_hut', 'camp_site')
                OR poi_class (subclass, mapping_key) IN ('spring'))
        UNION ALL
         -- etldoc: osm_poi_point ->  layer_poi:z12
         -- etldoc: osm_poi_point ->  layer_poi:z13
        SELECT
            *,
                osm_id * 10 AS osm_id_hash
        FROM
            osm_poi_point
        WHERE
            geometry && bbox
           AND zoom_level BETWEEN 12 AND 13
            AND ((subclass = 'station'
                    AND mapping_key = 'railway')
                OR subclass IN ('halt', 'ferry_terminal', 'alpine_hut', 'wilderness_hut', 'camp_site')
                OR poi_class (subclass, mapping_key) IN ('spring'))
         UNION ALL
         -- etldoc: osm_poi_point ->  layer_poi:z14_
        SELECT
            *,
                osm_id * 10 AS osm_id_hash
        FROM
            osm_poi_point
        WHERE
            geometry && bbox
           AND zoom_level >= 14
            AND (subclass != 'information'
                OR (information IN ('office', 'visitor_centre')
                    AND NULLIF (name, '') IS NOT NULL))
            AND (subclass != 'viewpoint'
                OR (NULLIF (name, '') IS NOT NULL))
         UNION ALL
         -- etldoc: osm_poi_polygon ->  layer_poi:z12
         -- etldoc: osm_poi_polygon ->  layer_poi:z13
        SELECT
            *,
                NULL::integer AS agg_stop,
            CASE WHEN osm_id < 0 THEN
                - osm_id * 10 + 4
            ELSE
                osm_id * 10 + 1
                    END AS osm_id_hash
        FROM
            osm_poi_polygon
        WHERE
            geometry && bbox
           AND zoom_level BETWEEN 12 AND 13
            AND ((subclass = 'station'
                    AND mapping_key = 'railway')
                OR subclass IN ('halt', 'ferry_terminal', 'alpine_hut', 'wilderness_hut', 'camp_site')
                OR poi_class (subclass, mapping_key) IN ('spring'))
         UNION ALL
         -- etldoc: osm_poi_polygon ->  layer_poi:z14_
    SELECT
        *,
                NULL::integer AS agg_stop,
        CASE WHEN osm_id < 0 THEN
            - osm_id * 10 + 4
        ELSE
            osm_id * 10 + 1
                    END AS osm_id_hash
    FROM
        osm_poi_polygon
    WHERE
        geometry && bbox
        AND zoom_level >= 14) AS poi_union
ORDER BY
    "rank"
$$
LANGUAGE SQL
STABLE PARALLEL SAFE;

-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL

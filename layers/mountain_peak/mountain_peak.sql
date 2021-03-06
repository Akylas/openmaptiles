-- etldoc: layer_mountain_peak[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_mountain_peak | <z7_> z7+" ] ;

CREATE OR REPLACE FUNCTION layer_mountain_peak (bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE (
                osm_id   bigint,
                geometry geometry,
                osmid bigint,
                name     text,
                wikidata text,
                wikipedia text,
                class    text,
                tags     hstore,
                ele      int,
                summitcross integer,
                "rank"   int
            )
    AS $$
SELECT
    -- etldoc: osm_peak_point -> layer_mountain_peak:z7_
    osm_id,
    geometry,
        osm_id AS osmid,
        NULLIF (name, '') AS name,
        NULLIF (wikidata, '') AS wikidata,
        NULLIF (wikipedia, '') AS wikipedia,
    tags->'natural' AS class,
    tags,
    ele::int,
        CASE WHEN summitcross = TRUE THEN
            1 ELSE NULL
        END AS summitcross,
    rank::int
FROM (
        SELECT
            osm_id,
            geometry,
            name,
            wikidata,
            wikipedia,
            tags,
            substring(ele FROM E'^(-?\\d+)(\\D|$)')::int AS ele,
            summitcross,
            row_number() OVER (
                PARTITION BY LabelGrid (geometry, 100 * pixel_width) 
                ORDER BY (
                    (CASE WHEN ele IS NOT NULL
                    AND ele ~ E'^-?\\d{1,4}(\\D|$)' THEN
                    substring(ele FROM E'^(-?\\d+)(\\D|$)')::int ELSE 0 END) +
                    (CASE WHEN tags->'natural' != 'saddle' THEN 10000 ELSE 0 END) +
                    (CASE WHEN NULLIF (name, '') IS NOT NULL THEN 10000 ELSE 0 END)
            ) DESC
            )::int AS "rank"
        FROM
            osm_peak_point
        WHERE
            geometry && bbox
     ) AS ranked_peaks
WHERE zoom_level >= 7
  AND (rank <= 5 OR zoom_level >= 14)
ORDER BY "rank" ASC;

$$
LANGUAGE SQL
STABLE PARALLEL SAFE;

-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL

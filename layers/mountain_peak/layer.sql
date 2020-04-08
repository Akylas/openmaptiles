
-- etldoc: layer_mountain_peak[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_mountain_peak | <z7_> z7+" ] ;

CREATE OR REPLACE FUNCTION layer_mountain_peak(
    bbox geometry,
    zoom_level integer,
    pixel_width numeric)
  RETURNS TABLE(
    osm_id bigint,
    geometry geometry,
    osmId bigint,
    name text,
    wikidata text,
    wikipedia text,
    class text,
    tags hstore,
    ele int,
    summitcross integer,
    "rank" int) AS
$$
   -- etldoc: osm_peak_point -> layer_mountain_peak:z7_
  SELECT
    osm_id,
    geometry,
    osm_id as osmId,
    name,
    NULLIF(wikidata, '') AS wikidata,
    NULLIF(wikipedia, '') AS wikipedia,
    tags -> 'natural' AS class,
    tags,
    ele::int,
    CASE WHEN summitcross=TRUE THEN 1 END as summitcross,
    rank::int FROM (
      SELECT osm_id, geometry, name, wikidata, wikipedia, tags,
      substring(ele from E'^(-?\\d+)(\\D|$)')::int AS ele,
      summitcross,
      row_number() OVER (
          PARTITION BY LabelGrid(geometry, 100 * pixel_width)
          ORDER BY (
            (CASE WHEN ele is not null  THEN substring(ele from E'^(-?\\d+)(\\D|$)')::int ELSE 0 END) +
            (CASE WHEN NULLIF(wikipedia, '') is not null THEN 10000 ELSE 0 END) +
            (CASE WHEN NULLIF(name, '') is not null THEN 10000 ELSE 0 END)
          ) DESC
      )::int AS "rank"
      FROM osm_peak_point
      WHERE geometry && bbox
    ) AS ranked_peaks
  WHERE
    (zoom_level >= 7 AND rank <= 1 AND ele is not null) OR
    (zoom_level >= 9 AND rank <= 3 AND ele is not null) OR
    (zoom_level >= 11 AND rank <= 5 AND ele is not null) OR
    (zoom_level >= 14)
  ORDER BY "rank" ASC;

$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;

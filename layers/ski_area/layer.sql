-- etldoc: layer_ski_area[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_ski_area | <z10_> z10+" ] ;

DROP FUNCTION IF EXISTS layer_ski_area(geometry, integer);
CREATE OR REPLACE FUNCTION layer_ski_area(bbox geometry, zoom_level integer)
RETURNS TABLE(
		osm_id bigint,
		geometry geometry,
		type text,
		difficulty text,
		name text
	) AS $$
    SELECT
        osm_id,
        geometry,
        type,
        difficulty,
        name
    FROM (
        -- etldoc: osm_skiarea_linestring -> layer_ski_area:z10_
        SELECT
            osm_id,
	        geometry,
	        type,
	        difficulty,
	        name
	    FROM osm_skiarea_linestring
           WHERE zoom_level >= 10
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

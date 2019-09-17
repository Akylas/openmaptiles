-- etldoc: layer_ski_lift[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_ski_lift | <z12_> z12+" ] ;

DROP FUNCTION IF EXISTS layer_ski_lift(geometry, integer);
CREATE OR REPLACE FUNCTION layer_ski_lift(bbox geometry, zoom_level integer)
RETURNS TABLE(
		osm_id bigint,
		geometry geometry,
		name text
	) AS $$
    SELECT
        osm_id,
        geometry,
        name
    FROM (
        -- etldoc: osm_skilift_linestring -> layer_ski_lift:z12_
        SELECT
            osm_id,
	        geometry,
	        name
	    FROM osm_skilift_linestring
           WHERE zoom_level >= 12
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

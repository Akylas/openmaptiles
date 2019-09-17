CREATE OR REPLACE FUNCTION convert_type(type smallint) RETURNS text AS $$
    SELECT CASE
        WHEN type = 0 THEN 'point'
        WHEN type = 1 THEN 'path'
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION convert_symbol_to_colour(symbol text) RETURNS text AS $$
    SELECT CASE
        WHEN symbol LIKE 'green:white:green_%' THEN 'green'
        WHEN symbol LIKE 'blue:white:blue_%' THEN 'blue'
        WHEN symbol LIKE 'yellow:white:yellow_%' THEN 'yellow'
        WHEN symbol LIKE 'red:white:red_%' THEN 'red'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- etldoc: layer_hiking[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_hiking | <z10_> z10+" ] ;

CREATE OR REPLACE FUNCTION layer_hiking(bbox geometry, zoom_level integer)
RETURNS TABLE(
		osm_id bigint,
		geometry geometry,
		type text,
		member_name text,
		relation_name text,
		colour text
	) AS $$
    SELECT
        osm_id,
        geometry,
        type,
        member_name,
        relation_name,
        colour
    FROM (
        -- etldoc: osm_route_member -> layer_hiking:z10_
        SELECT
            osm_id,
	        geometry,
	        convert_type(type) as type,
	        member_name,
	        name as relation_name,
	        convert_symbol_to_colour(symbol) as colour
	    FROM osm_route_member
           WHERE zoom_level >= 10
			AND route = 'hiking'
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

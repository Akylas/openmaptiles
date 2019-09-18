CREATE OR REPLACE FUNCTION convert_hiking_type(type smallint) RETURNS text AS $$
    SELECT CASE
        WHEN type = 0 THEN 'point'
        WHEN type = 1 THEN 'path'
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION convert_hiking_symbol_to_colour(symbol text) RETURNS text AS $$
    SELECT CASE
        WHEN symbol LIKE 'green:white:green_%' THEN 'green'
        WHEN symbol LIKE 'blue:white:blue_%' THEN 'blue'
        WHEN symbol LIKE 'yellow:white:yellow_%' THEN 'yellow'
        WHEN symbol LIKE 'red:white:red_%' THEN 'red'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- etldoc: layer_hiking[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_hiking | <z10_11> z10-11| <z12_13> z12-13 | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_hiking(geometry, integer);
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
        -- etldoc: osm_route_member -> layer_hiking:z10_11
        SELECT
            osm_id,
	        geometry,
	        convert_hiking_type(type) as type,
	        member_name,
	        name as relation_name,
	        convert_hiking_symbol_to_colour(symbol) as colour
	    FROM osm_route_member_gen2
           WHERE zoom_level >= 10 AND zoom_level <= 11
			AND route = 'hiking'
			AND type = 1

		UNION ALL

        -- etldoc: osm_route_member -> layer_hiking:z12_13
        SELECT
            osm_id,
	        geometry,
	        convert_hiking_type(type) as type,
	        member_name,
	        name as relation_name,
	        convert_hiking_symbol_to_colour(symbol) as colour
	    FROM osm_route_member_gen1
           WHERE zoom_level >= 12 AND zoom_level <= 13
			AND route = 'hiking'

		UNION ALL

        -- etldoc: osm_route_member -> layer_hiking:z14_
        SELECT
            osm_id,
	        geometry,
	        convert_hiking_type(type) as type,
	        member_name,
	        name as relation_name,
	        convert_hiking_symbol_to_colour(symbol) as colour
	    FROM osm_route_member
           WHERE zoom_level >= 14
			AND route = 'hiking'
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

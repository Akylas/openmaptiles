CREATE OR REPLACE FUNCTION convert_type(type smallint) RETURNS text AS $$
    SELECT CASE
        WHEN type = 0 THEN 'point'
        WHEN type = 1 THEN 'path'
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION convert_ref(ref text, name text) RETURNS text AS $$
    SELECT CASE
        WHEN name = ref THEN ''
        WHEN STRPOS(name, CONCAT(ref, ' ')) = 1 THEN ''
        WHEN STRPOS(name, CONCAT('[', ref, ']')) = 1 THEN ''
        ELSE ref
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- etldoc: layer_cycle_route[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_cycle_route | <z10_11> z10-11| <z12_13> z12-13 | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_cycle_route(geometry, integer);
CREATE OR REPLACE FUNCTION layer_cycle_route(bbox geometry, zoom_level integer)
RETURNS TABLE(
		osm_id bigint,
		geometry geometry,
		type text,
		network text,
		ref text,
		relation_name text
	) AS $$
    SELECT
        osm_id,
        geometry,
        type,
        network,
        ref,
        relation_name
    FROM (
        -- etldoc: osm_route_member -> layer_cycle_route:z10_11
        SELECT
            osm_id,
	        geometry,
	        convert_type(type) AS type,
	        network,
	        convert_ref(ref, name) AS ref,
	        name AS relation_name
	    FROM osm_route_member_gen2
           WHERE zoom_level >= 10 AND zoom_level <= 11
			AND route = 'bicycle'
			AND type = 1

		UNION ALL

        -- etldoc: osm_route_member -> layer_cycle_route:z12_13
        SELECT
            osm_id,
	        geometry,
	        convert_type(type) AS type,
	        network,
	        convert_ref(ref, name) AS ref,
	        name AS relation_name
	    FROM osm_route_member_gen1
           WHERE zoom_level >= 12 AND zoom_level <= 13
			AND route = 'bicycle'

		UNION ALL

        -- etldoc: osm_route_member -> layer_cycle_route:z14_
        SELECT
            osm_id,
	        geometry,
	        convert_type(type) AS type,
	        network,
	        convert_ref(ref, name) AS ref,
	        name AS relation_name
	    FROM osm_route_member
           WHERE zoom_level >= 14
			AND route = 'bicycle'
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

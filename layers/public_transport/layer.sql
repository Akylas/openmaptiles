CREATE OR REPLACE FUNCTION convert_type(type smallint) RETURNS text AS $$
    SELECT CASE
        WHEN type = 0 THEN 'station'
        WHEN type = 1 THEN 'path'
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION convert_route(route text) RETURNS text AS $$
    SELECT CASE
        WHEN route IN ('tracks', 'train') THEN 'railway'
        ELSE route
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- etldoc: layer_public_transport[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_public_transport | <z12_> z12+" ] ;

CREATE OR REPLACE FUNCTION layer_public_transport(bbox geometry, zoom_level integer)
RETURNS TABLE(
		osm_id bigint,
		geometry geometry,
		route text,
		type text,
		ref text,
		member_name text,
		relation_name text,
		colour text
	) AS $$
    SELECT
        osm_id,
        geometry,
        route,
        type,
        ref,
        member_name,
        relation_name,
        colour
    FROM (
        -- etldoc: osm_route_member -> layer_public_transport:z12_
        SELECT
            osm_id,
	        geometry,
	        convert_route(route) as route,
	        convert_type(type) as type,
	        ref,
	        member_name,
	        name as relation_name,
	        colour
	    FROM osm_route_member
           WHERE zoom_level >= 12
			AND route IN ('tracks', 'bus', 'railway', 'subway', 'tram', 'train')
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

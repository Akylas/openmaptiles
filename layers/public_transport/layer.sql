CREATE OR REPLACE FUNCTION convert_public_transport_type(type smallint) RETURNS text AS $$
    SELECT CASE
        WHEN type = 0 THEN 'station'
        WHEN type = 1 THEN 'line'
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION convert_public_transport_route(route text) RETURNS text AS $$
    SELECT CASE
        WHEN route IN ('tracks', 'train') THEN 'railway'
        ELSE route
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- etldoc: layer_public_transport[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_public_transport | <z10> z10 |<z11> z11 | <z12_13> z12-13 | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_public_transport(geometry, integer);
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
        -- etldoc: osm_route_member -> layer_public_transport:z10
        SELECT
            MIN(osm_id) AS osm_id,
            geometry,
            'railway'::text AS route,
            'path'::text AS type,
            NULL::text AS ref,
            NULL::text AS member_name,
            NULL::text AS relation_name,
            NULL::text AS colour
        FROM osm_route_member_gen2
           WHERE zoom_level = 10
            AND route IN ('railway', 'tracks', 'train')
            AND type = 1
            GROUP BY member, geometry

        UNION ALL

        -- etldoc: osm_route_member -> layer_public_transport:z11
        SELECT
            MIN(osm_id) AS osm_id,
            geometry,
            convert_public_transport_route(route) as route,
            'path'::text AS type,
            NULL::text AS ref,
            NULL::text AS member_name,
            NULL::text AS relation_name,
            colour
        FROM osm_route_member_gen2
           WHERE zoom_level = 11
            AND route IN ('railway', 'tracks', 'train', 'subway')
            AND type = 1
            GROUP BY member, geometry, route, colour

        UNION ALL

        -- etldoc: osm_route_member -> layer_public_transport:z12_13
        SELECT
            MIN(osm_id) AS osm_id,
            geometry,
            convert_public_transport_route(route) as route,
            'path'::text AS type,
            NULL::text AS ref,
            NULL::text AS member_name,
            NULL::text AS relation_name,
            colour
        FROM osm_route_member_gen1
           WHERE zoom_level >= 12 AND zoom_level <= 13
            AND route IN ('railway', 'tracks', 'train', 'subway', 'tram', 'bus')
            AND type = 1
            GROUP BY member, geometry, route, colour

        UNION ALL

        SELECT
            osm_id,
            geometry,
            convert_public_transport_route(route) as route,
            convert_public_transport_type(type) as type,
            ref,
            member_name,
            name as relation_name,
            colour
        FROM osm_route_member_gen1
           WHERE zoom_level >= 12 AND zoom_level <= 13
            AND route IN ('railway', 'tracks', 'train', 'subway', 'tram', 'bus')

        UNION ALL

        -- etldoc: osm_route_member -> layer_public_transport:z14_
        SELECT
            MIN(osm_id) AS osm_id,
            geometry,
            convert_public_transport_route(route) as route,
            'path'::text AS type,
            NULL::text AS ref,
            NULL::text AS member_name,
            NULL::text AS relation_name,
            colour
        FROM osm_route_member
           WHERE zoom_level >= 14
            AND route IN ('railway', 'tracks', 'train', 'subway', 'tram', 'bus')
            AND type = 1
            GROUP BY member, geometry, route, colour

        UNION ALL

        SELECT
            osm_id,
            geometry,
            convert_public_transport_route(route) as route,
            convert_public_transport_type(type) as type,
            ref,
            member_name,
            name as relation_name,
            colour
        FROM osm_route_member
           WHERE zoom_level >= 14
            AND route IN ('railway', 'tracks', 'train', 'subway', 'tram', 'bus')
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

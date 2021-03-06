CREATE OR REPLACE FUNCTION highway_is_link(highway text) RETURNS boolean AS
$$
SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;


-- etldoc: layer_transportation[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_transportation |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;
CREATE OR REPLACE FUNCTION layer_transportation(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text,
ramp int, oneway int, brunnel TEXT, service TEXT, tracktype TEXT, layer INT, level INT,
indoor INT, bicycle TEXT, foot TEXT, horse TEXT, mtb_scale TEXT, sac_scale TEXT, mtb_scale_uphill TEXT, mtb_type TEXT, mtb_name TEXT, surface TEXT, type TEXT, difficulty TEXT) AS $$
    SELECT
        osm_id, geometry,
       CASE
           WHEN NULLIF(highway, '') IS NOT NULL OR NULLIF(public_transport, '') IS NOT NULL
               THEN highway_class(highway, public_transport, construction)
           WHEN NULLIF(railway, '') IS NOT NULL THEN railway_class(railway)
           WHEN NULLIF(aerialway, '') IS NOT NULL THEN 'aerialway'
           WHEN NULLIF(shipway, '') IS NOT NULL THEN shipway
           WHEN NULLIF(man_made, '') IS NOT NULL THEN man_made
           END AS class,
       CASE
           WHEN railway IS NOT NULL THEN railway
           WHEN (highway IS NOT NULL OR public_transport IS NOT NULL)
               AND highway_class(highway, public_transport, construction) = 'path'
               THEN COALESCE(NULLIF(public_transport, ''), highway)
           WHEN aerialway IS NOT NULL THEN aerialway
           END AS subclass,
       -- All links are considered as ramps as well
        CASE WHEN highway_is_link(highway) OR highway = 'steps'
             THEN 1 ELSE NULLIF(is_ramp, FALSE)::int END AS ramp,
        NULLIF(is_oneway, 0)::int AS oneway,
       brunnel(is_bridge, is_tunnel, is_ford) AS brunnel,
       NULLIF(service, '') AS service,
        NULLIF(tracktype, '') AS tracktype,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor,
       NULLIF(bicycle, '') AS bicycle,
       NULLIF(foot, '') AS foot,
       NULLIF(horse, '') AS horse,
       NULLIF(mtb_scale, '') AS mtb_scale,
        NULLIF(sac_scale, '') AS sac_scale,
        NULLIF(mtb_scale_uphill, '') AS mtb_scale_uphill,
        NULLIF(mtb_type, '') AS mtb_type,
        NULLIF(mtb_name, '') AS mtb_name,
        NULLIF(surface, '') AS surface,
        NULLIF(type, '') AS type,
        NULLIF(difficulty, '') AS difficulty
FROM (
         -- etldoc: osm_transportation_merge_linestring_gen_z4 -> layer_transportation:z4
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                NULL::int AS layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale,
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type,
                NULL as difficulty,
                NULL AS surface, z_order
         FROM osm_transportation_merge_linestring_gen_z4
         WHERE zoom_level = 4
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z5 -> layer_transportation:z5
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                NULL::int AS layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale,
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
         FROM osm_transportation_merge_linestring_gen_z5
         WHERE zoom_level = 5
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z6 -> layer_transportation:z6
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                NULL::int AS layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale,
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
         FROM osm_transportation_merge_linestring_gen_z6
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z7  ->  layer_transportation:z7
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                NULL::int AS layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale,
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
         FROM osm_transportation_merge_linestring_gen_z7
         WHERE zoom_level = 7
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                NULL::int AS layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale,
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
         FROM osm_transportation_merge_linestring_gen_z8
         WHERE zoom_level = 8
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale, 
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
FROM osm_transportation_merge_linestring_gen_z9
         WHERE zoom_level = 9
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS is_ramp, 
                NULL::int AS is_oneway, 
                NULL as man_made,
                layer, NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale, 
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
FROM osm_transportation_merge_linestring_gen_z10
         WHERE zoom_level = 10
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL as sac_scale,
                NULL as mtb_scale_uphill,
                NULL as mtb_type,
                NULL as mtb_name,
                NULL as type,
                NULL as difficulty,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z11
         WHERE zoom_level = 11
         UNION ALL

         -- etldoc: osm_highway_linestring  ->  layer_transportation:z12
         -- etldoc: osm_highway_linestring  ->  layer_transportation:z13
         -- etldoc: osm_highway_linestring  ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                highway,
                construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                public_transport,
                service_value(service) AS service,
                is_bridge,
                is_tunnel,
                is_ford,
                is_ramp,
                is_oneway,
                man_made,
                layer,
                CASE WHEN highway IN ('footway', 'steps') THEN "level" END AS "level",
            CASE WHEN highway = 'track' THEN "tracktype" END AS "tracktype",
                CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
            bicycle, foot, horse, mtb_scale, sac_scale, mtb_scale_uphill, mtb_type, mtb_name,
            NULL AS type, NULL as difficulty,
                surface_value(surface) AS "surface",
                z_order
         FROM osm_highway_linestring
        WHERE NOT is_area AND (
            zoom_level = 12
           AND (
                             highway_class(highway, public_transport, construction) NOT IN ('minor')
                         OR highway IN ('unclassified', 'residential')
                     ) AND man_made <> 'pier'
                OR zoom_level >= 13
                         AND (
                                    man_made <> 'pier'
                            OR
                                    man_made = 'pier' AND NOT ST_IsClosed(geometry)
                        )
                 OR zoom_level >= 14
                         AND (
                            man_made <> 'pier'
                            OR
                            NOT ST_IsClosed(geometry)
                        )
             )
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::int AS is_oneway, NULL as man_made,
            NULL::int AS layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL as surface, z_order
         FROM osm_railway_linestring_gen_z8
         WHERE zoom_level = 8
           AND railway = 'rail'
           AND service = ''
           AND usage = 'main'
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::int AS is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_railway_linestring_gen_z9
         WHERE zoom_level = 9
           AND railway = 'rail'
           AND service = ''
           AND usage = 'main'
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z10  ->  layer_transportation:z10
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, railway, NULL AS aerialway, NULL AS shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_railway_linestring_gen_z10
         WHERE zoom_level = 10
           AND railway IN ('rail', 'narrow_gauge')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z11  ->  layer_transportation:z11
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, railway, NULL AS aerialway, NULL AS shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL as surface, z_order
         FROM osm_railway_linestring_gen_z11
         WHERE zoom_level = 11
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z12  ->  layer_transportation:z12
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, railway, NULL AS aerialway, NULL AS shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL as surface, z_order
         FROM osm_railway_linestring_gen_z12
         WHERE zoom_level = 12
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring ->  layer_transportation:z13
         -- etldoc: osm_railway_linestring ->  layer_transportation:z14_
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, railway, NULL AS aerialway, NULL AS shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL as surface, z_order
         FROM osm_railway_linestring
         WHERE zoom_level = 13
             AND railway IN ('rail', 'narrow_gauge', 'light_rail') AND service = ''
           OR zoom_level >= 14
         UNION ALL

         -- etldoc: osm_aerialway_linestring_gen_z12  ->  layer_transportation:z12
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, NULL as railway, aerialway, NULL AS shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_aerialway_linestring_gen_z12
         WHERE zoom_level = 12
         UNION ALL

         -- etldoc: osm_aerialway_linestring ->  layer_transportation:z13
         -- etldoc: osm_aerialway_linestring ->  layer_transportation:z14_
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, NULL as railway, aerialway, NULL AS shipway,
            NULL AS public_transport, NULL AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_aerialway_linestring
         WHERE zoom_level >= 13
         UNION ALL

        -- etldoc: osm_skilift_linestring_gen1  ->  layer_transportation:z12
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, NULL as railway, aerialway, NULL AS shipway,
            NULL AS public_transport, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel, NULL::boolean AS is_ford, NULL::boolean AS is_ramp, NULL::int AS is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
        FROM osm_skilift_linestring_gen1
        WHERE zoom_level = 13
        UNION ALL

        -- etldoc: osm_skilift_linestring       ->  layer_transportation:z13
        -- etldoc: osm_skilift_linestring       ->  layer_transportation:z14_
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, NULL as railway, aerialway, NULL AS shipway,
            NULL AS public_transport, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel, NULL::boolean AS is_ford, NULL::boolean AS is_ramp, NULL::int AS is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
        FROM osm_skilift_linestring
        WHERE zoom_level >= 14
        UNION ALL

        -- etldoc: osm_skipiste_linestring       ->  layer_transportation:z14_
        SELECT
            osm_id, geometry,
            'piste'::text AS highway, NULL AS construction, NULL as railway, NULL AS aerialway, NULL AS shipway,
            NULL AS public_transport, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel, NULL::boolean AS is_ford, NULL::boolean AS is_ramp, NULL::int AS is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            type, difficulty,
            NULL AS surface, z_order
        FROM osm_skipiste_linestring
        WHERE zoom_level >= 14
        UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z11  ->  layer_transportation:z11
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, NULL AS railway, NULL AS aerialway, shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_shipway_linestring_gen_z11
         WHERE zoom_level = 11
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z12  ->  layer_transportation:z12
        SELECT
            osm_id, geometry,
            NULL AS highway, NULL AS construction, NULL AS railway, NULL AS aerialway, shipway,
            NULL AS public_transport, service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, NULL as man_made,
            layer, NULL::int AS level, NULL::text AS tracktype, NULL::boolean AS indoor,
            NULL as bicycle, NULL as foot, NULL as horse, NULL as mtb_scale, NULL as sac_scale,
            NULL as mtb_scale_uphill, NULL as mtb_type, NULL as mtb_name,
            NULL AS type, NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_shipway_linestring_gen_z12
         WHERE zoom_level = 12
         UNION ALL

         -- etldoc: osm_shipway_linestring ->  layer_transportation:z13
         -- etldoc: osm_shipway_linestring ->  layer_transportation:z14_
        SELECT
            osm_id, 
            geometry,
            NULL AS highway, 
            NULL AS construction, 
            NULL AS railway, 
            NULL AS aerialway, 
            shipway,
            NULL AS public_transport, 
            service_value(service) AS service,
            is_bridge, 
            is_tunnel, 
            is_ford, 
            is_ramp, 
            is_oneway, 
            NULL as man_made,
            layer, 
            NULL::int AS level, 
            NULL::text AS tracktype, 
            NULL::boolean AS indoor,
            NULL as bicycle, 
            NULL as foot, 
            NULL as horse, 
            NULL as mtb_scale, 
            NULL as sac_scale,
            NULL as mtb_scale_uphill, 
            NULL as mtb_type, 
            NULL as mtb_name,
            NULL AS type, 
            NULL as difficulty,
            NULL AS surface, z_order
         FROM osm_shipway_linestring
         WHERE zoom_level >= 13
         UNION ALL

         -- NOTE: We limit the selection of polys because we need to be
         -- careful to net get false positives here because
         -- it is possible that closed linestrings appear both as
         -- highway linestrings and as polygon
         -- etldoc: osm_highway_polygon ->  layer_transportation:z13
         -- etldoc: osm_highway_polygon ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                highway,
                NULL AS construction,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                public_transport,
                NULL AS service,
                CASE
                    WHEN man_made IN ('bridge') THEN TRUE
                    ELSE FALSE
                    END AS is_bridge,
                FALSE AS is_tunnel, 
                FALSE AS is_ford,
                FALSE AS is_ramp, 
                FALSE::int AS is_oneway, 
                man_made,
                layer, 
                NULL::int AS level, 
                NULL::text AS tracktype, 
                NULL::boolean AS indoor,
                NULL as bicycle, 
                NULL as foot, 
                NULL as horse, 
                NULL as mtb_scale, 
                NULL as sac_scale,
                NULL as mtb_scale_uphill, 
                NULL as mtb_type, 
                NULL as mtb_name,
                NULL AS type, 
                NULL as difficulty,
                NULL AS surface, z_order
         FROM osm_highway_polygon
              -- We do not want underground pedestrian areas for now
         WHERE zoom_level >= 13
           AND (
                 man_made IN ('bridge', 'pier')
                 OR (is_area AND COALESCE(layer, 0) >= 0)
             )
     ) AS zoom_levels
WHERE geometry && bbox
ORDER BY z_order ASC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;

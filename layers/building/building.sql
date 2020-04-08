-- etldoc: layer_building[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_building | <z13> z13 | <z14_> z14+ " ] ;

CREATE OR REPLACE FUNCTION as_numeric(text) RETURNS NUMERIC AS $$
 -- Inspired by http://stackoverflow.com/questions/16195986/isnumeric-with-postgresql/16206123#16206123
DECLARE test NUMERIC;
BEGIN
     test = $1::NUMERIC;
     RETURN test;
EXCEPTION WHEN others THEN
     RETURN -1;
END;
$$ STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE INDEX IF NOT EXISTS osm_building_relation_building_idx ON osm_building_relation(building) WHERE ST_GeometryType(geometry) = 'ST_Polygon';
CREATE INDEX IF NOT EXISTS osm_building_relation_member_idx ON osm_building_relation(member);
--CREATE INDEX IF NOT EXISTS osm_building_associatedstreet_role_idx ON osm_building_associatedstreet(role) WHERE ST_GeometryType(geometry) = 'ST_Polygon';
--CREATE INDEX IF NOT EXISTS osm_building_street_role_idx ON osm_building_street(role) WHERE ST_GeometryType(geometry) = 'ST_Polygon';

CREATE OR REPLACE VIEW osm_all_buildings AS (
         -- etldoc: osm_building_relation -> layer_building:z14_
         -- Buildings built from relations
         SELECT member AS osm_id,geometry,NULL::text AS name, building::text AS class,amenity,shop,tourism,leisure,
                  COALESCE(nullif(as_numeric(height),-1),nullif(as_numeric(buildingheight),-1)) as height,
                  COALESCE(nullif(as_numeric(min_height),-1),nullif(as_numeric(buildingmin_height),-1)) as min_height,
                  COALESCE(nullif(as_numeric(levels),-1),nullif(as_numeric(buildinglevels),-1)) as levels,
                  COALESCE(nullif(as_numeric(min_level),-1),nullif(as_numeric(buildingmin_level),-1)) as min_level,
                  FALSE as hide_3d
         FROM
         osm_building_relation WHERE building = '' AND ST_GeometryType(geometry) = 'ST_Polygon'
         UNION ALL

         -- etldoc: osm_building_associatedstreet -> layer_building:z14_
         -- Buildings in associatedstreet relations
         SELECT member AS osm_id,geometry,NULL::text AS name, building::text AS class,amenity,shop,tourism,leisure,
                  COALESCE(nullif(as_numeric(height),-1),nullif(as_numeric(buildingheight),-1)) as height,
                  COALESCE(nullif(as_numeric(min_height),-1),nullif(as_numeric(buildingmin_height),-1)) as min_height,
                  COALESCE(nullif(as_numeric(levels),-1),nullif(as_numeric(buildinglevels),-1)) as levels,
                  COALESCE(nullif(as_numeric(min_level),-1),nullif(as_numeric(buildingmin_level),-1)) as min_level,
                  FALSE as hide_3d
         FROM
         osm_building_associatedstreet WHERE role = 'house' AND ST_GeometryType(geometry) = 'ST_Polygon'
         UNION ALL
         -- etldoc: osm_building_street -> layer_building:z14_
         -- Buildings in street relations
         SELECT member AS osm_id,geometry,NULL::text AS name, building::text AS class,amenity,shop,tourism,leisure,
                  COALESCE(nullif(as_numeric(height),-1),nullif(as_numeric(buildingheight),-1)) as height,
                  COALESCE(nullif(as_numeric(min_height),-1),nullif(as_numeric(buildingmin_height),-1)) as min_height,
                  COALESCE(nullif(as_numeric(levels),-1),nullif(as_numeric(buildinglevels),-1)) as levels,
                  COALESCE(nullif(as_numeric(min_level),-1),nullif(as_numeric(buildingmin_level),-1)) as min_level,
                  FALSE as hide_3d
         FROM
         osm_building_street WHERE role = 'house' AND ST_GeometryType(geometry) = 'ST_Polygon'
         UNION ALL

         -- etldoc: osm_building_polygon -> layer_building:z14_
         -- Buildings that are from multipolygons
         SELECT osm_id, geometry, name, building::text AS class,amenity,shop,tourism,leisure,
                  COALESCE(nullif(as_numeric(height),-1),nullif(as_numeric(buildingheight),-1)) as height,
                  COALESCE(nullif(as_numeric(min_height),-1),nullif(as_numeric(buildingmin_height),-1)) as min_height,
                  COALESCE(nullif(as_numeric(levels),-1),nullif(as_numeric(buildinglevels),-1)) as levels,
                  COALESCE(nullif(as_numeric(min_level),-1),nullif(as_numeric(buildingmin_level),-1)) as min_level,
                  FALSE as hide_3d
         FROM
         osm_building_polygon obp
         WHERE osm_id < 0

         UNION ALL
         -- etldoc: osm_building_polygon -> layer_building:z14_
         -- Standalone buildings
         SELECT obp.osm_id,obp.geometry,obp.name, obp.building::text as class,obp.amenity,obp.shop,obp.tourism,obp.leisure,
                  COALESCE(nullif(as_numeric(obp.height),-1),nullif(as_numeric(obp.buildingheight),-1)) as height,
                  COALESCE(nullif(as_numeric(obp.min_height),-1),nullif(as_numeric(obp.buildingmin_height),-1)) as min_height,
                  COALESCE(nullif(as_numeric(obp.levels),-1),nullif(as_numeric(obp.buildinglevels),-1)) as levels,
                  COALESCE(nullif(as_numeric(obp.min_level),-1),nullif(as_numeric(obp.buildingmin_level),-1)) as min_level,
                  CASE WHEN obr.role='outline' THEN TRUE ELSE FALSE END as hide_3d
         FROM
         osm_building_polygon obp
           LEFT JOIN osm_building_relation obr ON (obr.member = obp.osm_id)
         WHERE obp.osm_id >= 0
);

CREATE OR REPLACE FUNCTION layer_building(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, osm_id bigint, name text, class text, render_height int, render_min_height int, hide_3d boolean) AS $$
    SELECT geometry, osm_id, case when 
        (class in ('yes') and (nullif(amenity,'') is null and nullif(shop,'') is null and nullif(tourism,'') is null and nullif(leisure,'') is null)) then nullif(name,'') end as name, 
        nullif(class,'yes') as class, render_height, 
        nullif(render_min_height,0) as render_min_height,
        CASE WHEN hide_3d THEN TRUE END AS hide_3d
    FROM (
        -- etldoc: osm_building_polygon_gen1 -> layer_building:z13
        SELECT
            osm_id, geometry, name, building::text AS class,amenity,shop,tourism,leisure,
            NULL::int AS render_height, NULL::int AS render_min_height,
            FALSE AS hide_3d
        FROM osm_building_polygon_gen1
        WHERE zoom_level = 13 AND geometry && bbox
        UNION ALL
        -- etldoc: osm_building_polygon -> layer_building:z14_
        SELECT DISTINCT ON (osm_id)
           osm_id, geometry, name, class,amenity,shop,tourism,leisure,
           ceil( COALESCE(height, levels*3.66,5))::int AS render_height,
           floor(COALESCE(min_height, min_level*3.66,0))::int AS render_min_height,
           hide_3d
        FROM osm_all_buildings
        WHERE
            (levels IS NULL OR levels < 1000) AND
            (min_level IS NULL OR min_level < 1000) AND
            (height IS NULL OR height < 3000) AND
            (min_height IS NULL OR min_height < 3000) AND
            zoom_level >= 14 AND geometry && bbox
    ) AS zoom_levels
    ORDER BY render_height ASC, ST_YMin(geometry) DESC;
$$
LANGUAGE SQL IMMUTABLE
PARALLEL SAFE;

-- not handled: where a building outline covers building parts

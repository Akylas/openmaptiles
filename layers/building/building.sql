-- etldoc: layer_building[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_building | <z13> z13 | <z14_> z14+ " ] ;

CREATE INDEX IF NOT EXISTS osm_building_relation_building_idx ON osm_building_relation (building) WHERE building = '' AND ST_GeometryType(geometry) = 'ST_Polygon';
CREATE INDEX IF NOT EXISTS osm_building_relation_member_idx ON osm_building_relation (member) WHERE role = 'outline';

CREATE OR REPLACE VIEW osm_all_buildings AS
(
SELECT
    -- etldoc: osm_building_relation -> layer_building:z14_
    -- Buildings built from relations
    member AS osm_id,
    geometry,
    NULL::text AS name,
    building::text AS class,
    amenity,
    shop,
    tourism,
    leisure,
    aerialway,
    COALESCE(CleanNumeric(height), CleanNumeric(buildingheight)) AS height,
    COALESCE(CleanNumeric(min_height), CleanNumeric(buildingmin_height)) AS min_height,
    COALESCE(CleanNumeric(levels), CleanNumeric(buildinglevels)) AS levels,
    COALESCE(CleanNumeric(min_level), CleanNumeric(buildingmin_level)) AS min_level,
    FALSE AS hide_3d
FROM  osm_building_relation 
WHERE building = '' 
  AND ST_GeometryType(geometry) = 'ST_Polygon'
UNION ALL

SELECT
    -- etldoc: osm_building_polygon -> layer_building:z14_
    -- Standalone buildings
    obp.osm_id,
    obp.geometry,
    obp.name, 
    obp.building::text as class,
    obp.amenity,
    obp.shop,
    obp.tourism,
    obp.leisure,
    obp.aerialway,
    COALESCE(CleanNumeric(obp.height), CleanNumeric(obp.buildingheight)) AS height,
    COALESCE(CleanNumeric(obp.min_height), CleanNumeric(obp.buildingmin_height)) AS min_height,
    COALESCE(CleanNumeric(obp.levels), CleanNumeric(obp.buildinglevels)) AS levels,
    COALESCE(CleanNumeric(obp.min_level), CleanNumeric(obp.buildingmin_level)) AS min_level,
    obr.role IS NOT NULL AS hide_3d
FROM osm_building_polygon obp
         LEFT JOIN osm_building_relation obr ON
        obp.osm_id >= 0 AND
        obr.member = obp.osm_id AND
        obr.role = 'outline'
WHERE ST_GeometryType(obp.geometry) IN ('ST_Polygon', 'ST_MultiPolygon')
    );

CREATE OR REPLACE FUNCTION layer_building(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, class text, render_height int, render_min_height int, hide_3d boolean) AS $$
    SELECT osm_id, geometry, case when 
        (class in ('yes') and (nullif(amenity,'') is null and nullif(shop,'') is null and nullif(tourism,'') is null and nullif(leisure,'') is null and nullif(aerialway,'') is null)) then nullif(name,'') end as name, 
        nullif(class,'yes') as class, render_height, 
        nullif(render_min_height,0) as render_min_height,
       CASE WHEN hide_3d THEN TRUE END AS hide_3d
FROM (
         SELECT
             -- etldoc: osm_building_block_gen_z13 -> layer_building:z13
             osm_id,
             geometry,
             NULL::text AS name,
             NULL::text AS class,
             NULL::text AS amenity,
             NULL::text AS shop,
             NULL::text AS tourism,
             NULL::text AS leisure,
             NULL::text AS aerialway,
             NULL::int AS render_height,
             NULL::int AS render_min_height,
             FALSE AS hide_3d
         FROM osm_building_block_gen_z13
         WHERE zoom_level = 13
           AND geometry && bbox
         UNION ALL
         SELECT
                                  -- etldoc: osm_building_polygon -> layer_building:z14_
            DISTINCT ON (osm_id) osm_id, 
                                    geometry, 
                                    name, 
                                    class,
                                    amenity,
                                    shop,
                                    tourism,
                                    leisure,
                                    aerialway,
                                    ceil(COALESCE(height, levels * 3.66, 5))::int AS render_height,
                                    floor(COALESCE(min_height, min_level * 3.66, 0))::int AS render_min_height,
                                    hide_3d
         FROM osm_all_buildings
         WHERE (levels IS NULL OR levels < 1000)
           AND (min_level IS NULL OR min_level < 1000)
           AND (height IS NULL OR height < 3000)
           AND (min_height IS NULL OR min_height < 3000)
           AND zoom_level >= 14
           AND geometry && bbox
     ) AS zoom_levels
ORDER BY render_height ASC, ST_YMin(geometry) DESC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE
                ;

-- not handled: where a building outline covers building parts

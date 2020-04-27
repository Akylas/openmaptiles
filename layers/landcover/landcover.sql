--TODO: Find a way to nicely generalize landcover
--CREATE TABLE IF NOT EXISTS landcover_grouped_gen2 AS (
--	SELECT osm_id, ST_Simplify((ST_Dump(geometry)).geom, 600) AS geometry, landuse, "natural", wetland
--	FROM (
--	  SELECT max(osm_id) AS osm_id, ST_Union(ST_Buffer(geometry, 600)) AS geometry, landuse, "natural", wetland
--	  FROM osm_landcover_polygon_gen1
--	  GROUP BY LabelGrid(geometry, 15000000), landuse, "natural", wetland
--	) AS grouped_measurements
--);
--CREATE INDEX IF NOT EXISTS landcover_grouped_gen2_geometry_idx ON landcover_grouped_gen2 USING gist(geometry);



CREATE OR REPLACE FUNCTION filter_rings(geometry, DOUBLE PRECISION)
    RETURNS geometry AS
$BODY$
SELECT ST_BuildArea(ST_Collect(b.final_geom)) AS filtered_geom
    FROM (SELECT ST_MakePolygon((/* Get outer ring of polygon */
    SELECT ST_ExteriorRing(a.the_geom) AS outer_ring /* ie the outer ring */
    ),  ARRAY(/* Get all inner rings > a particular area */
        SELECT ST_ExteriorRing(b.geom) AS inner_ring
        FROM (SELECT (ST_DumpRings(a.the_geom)).*) b
        WHERE b.path[1] > 0 /* ie not the outer ring */
        AND ST_Area(b.geom) > $2 
    ) ) AS final_geom
            FROM (SELECT ST_GeometryN(ST_Multi($1),/*ST_Multi converts any Single Polygons to MultiPolygons */
                                    generate_series(1,ST_NumGeometries(ST_Multi($1)))
                                    ) AS the_geom
                ) a
        ) b
$BODY$
    LANGUAGE 'sql' IMMUTABLE;


CREATE OR REPLACE FUNCTION landcover_class(subclass VARCHAR) RETURNS TEXT AS $$
    SELECT CASE
        %%FIELD_MAPPING: class %%
    END;
$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;



-- This statement can be deleted after the water importer image stops creating this object as a table
-- DO $$ BEGIN DROP TABLE IF EXISTS landcover_grouped CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- -- etldoc: osm_landcover_polygon -> landcover_grouped
-- DROP MATERIALIZED VIEW IF EXISTS landcover_grouped CASCADE;
-- CREATE MATERIALIZED VIEW landcover_grouped AS (
-- 	SELECT osm_id, geometry, subclass, name FROM osm_landcover_polygon
-- );
-- CREATE INDEX IF NOT EXISTS landcover_grouped_geometry_idx ON landcover_grouped USING gist(geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS landcover_grouped_gen1 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_landcover_polygon_gen1 -> landcover_grouped_gen1
DROP MATERIALIZED VIEW IF EXISTS landcover_grouped_gen1 CASCADE;
CREATE MATERIALIZED VIEW landcover_grouped_gen1 AS (
	SELECT osm_id, ST_Simplify((ST_DUMP(geometry)).geom , 20.0) AS geometry, subclass, name
	FROM (
	  SELECT max(osm_id) AS osm_id, (ST_UNION(ST_SNAPTOGRID(filter_rings(geometry, 100000),0.0001))) AS geometry, subclass, name
	  FROM osm_landcover_polygon_gen1
	  GROUP BY LabelGrid(geometry, 150000), landcover_class(subclass), subclass, name
	) AS grouped_measurements
);
CREATE INDEX IF NOT EXISTS landcover_grouped_gen1_geometry_idx ON landcover_grouped_gen1 USING gist(geometry);

-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS landcover_grouped_gen2 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';

-- etldoc: osm_landcover_polygon_gen2 -> landcover_grouped_gen2
DROP MATERIALIZED VIEW IF EXISTS landcover_grouped_gen2 CASCADE;
CREATE MATERIALIZED VIEW landcover_grouped_gen2 AS (
	SELECT osm_id, ST_Simplify((ST_DUMP(geometry)).geom , 40.0) AS geometry, subclass, name
	FROM (
	  SELECT max(osm_id) AS osm_id, (ST_UNION(ST_SNAPTOGRID(filter_rings(geometry, 400000),0.0001))) AS geometry, subclass, name
	  FROM osm_landcover_polygon_gen2
	  GROUP BY LabelGrid(geometry, 150000), landcover_class(subclass), subclass, name
	) AS grouped_measurements
);
CREATE INDEX IF NOT EXISTS landcover_grouped_gen2_geometry_idx ON landcover_grouped_gen2 USING gist(geometry);

-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS landcover_grouped_gen3 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';

-- etldoc: osm_landcover_polygon_gen3 -> landcover_grouped_gen3
DROP MATERIALIZED VIEW IF EXISTS landcover_grouped_gen3 CASCADE;
CREATE MATERIALIZED VIEW landcover_grouped_gen3 AS (
	SELECT osm_id, ST_Simplify((ST_DUMP(geometry)).geom , 80.0) AS geometry, subclass, name
	FROM (
	  SELECT max(osm_id) AS osm_id, (ST_UNION(ST_SNAPTOGRID(filter_rings(geometry, 1000000),0.0001))) AS geometry, subclass, name
	  FROM osm_landcover_polygon_gen3
	  GROUP BY LabelGrid(geometry, 150000), landcover_class(subclass), subclass, name
	) AS grouped_measurements
);
CREATE INDEX IF NOT EXISTS landcover_grouped_gen3_geometry_idx ON landcover_grouped_gen3 USING gist(geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS landcover_grouped_gen4 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_landcover_polygon_gen4 -> landcover_grouped_gen4
DROP MATERIALIZED VIEW IF EXISTS landcover_grouped_gen4 CASCADE;
CREATE MATERIALIZED VIEW landcover_grouped_gen4 AS (
	SELECT osm_id, ST_Simplify((ST_DUMP(geometry)).geom , 160.0) AS geometry, subclass, name
	FROM (
	  SELECT max(osm_id) AS osm_id, (ST_UNION(ST_SNAPTOGRID(filter_rings(geometry, 2000000),0.0001))) AS geometry, subclass, name
	  FROM osm_landcover_polygon_gen4
	  GROUP BY LabelGrid(geometry, 150000), landcover_class(subclass), subclass, name
	) AS grouped_measurements
);
CREATE INDEX IF NOT EXISTS landcover_grouped_gen4_geometry_idx ON landcover_grouped_gen4 USING gist(geometry);

-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS landcover_grouped_gen5 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_landcover_polygon_gen5 -> landcover_grouped_gen5
DROP MATERIALIZED VIEW IF EXISTS landcover_grouped_gen5 CASCADE;
CREATE MATERIALIZED VIEW landcover_grouped_gen5 AS (
	SELECT osm_id, ST_Simplify((ST_DUMP(geometry)).geom , 320.0) AS geometry, subclass, name
	FROM (
	  SELECT max(osm_id) AS osm_id, (ST_UNION(ST_SNAPTOGRID(filter_rings(geometry, 5000000),0.0001))) AS geometry, subclass, name
	  FROM osm_landcover_polygon_gen5
	  GROUP BY LabelGrid(geometry, 150000), landcover_class(subclass), subclass, name
	) AS grouped_measurements
);
CREATE INDEX IF NOT EXISTS landcover_grouped_gen5_geometry_idx ON landcover_grouped_gen4 USING gist(geometry);



-- etldoc: ne_110m_glaciated_areas ->  landcover_z0
CREATE OR REPLACE VIEW landcover_z0 AS (
    SELECT NULL::bigint AS osm_id, geometry, 'glacier'::text AS subclass, NULL::text AS name FROM ne_110m_glaciated_areas
);

CREATE OR REPLACE VIEW landcover_z2 AS (
    -- etldoc: ne_50m_glaciated_areas ->  landcover_z2
    SELECT NULL::bigint AS osm_id, geometry, 'glacier'::text AS subclass, NULL::text AS name FROM ne_50m_glaciated_areas
    UNION ALL
    -- etldoc: ne_50m_antarctic_ice_shelves_polys ->  landcover_z2
    SELECT NULL::bigint AS osm_id, geometry, 'ice_shelf'::text AS subclass, NULL::text AS name FROM ne_50m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE VIEW landcover_z5 AS (
    -- etldoc: ne_10m_glaciated_areas ->  landcover_z5
    SELECT NULL::bigint AS osm_id, geometry, 'glacier'::text AS subclass, NULL::text AS name FROM ne_10m_glaciated_areas
    UNION ALL
    -- etldoc: ne_10m_antarctic_ice_shelves_polys ->  landcover_z5
    SELECT NULL::bigint AS osm_id, geometry, 'ice_shelf'::text AS subclass, NULL::text AS name FROM ne_10m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE VIEW landcover_z6 AS (
    -- etldoc: osm_landcover_polygon_gen7 ->  landcover_z6
    SELECT osm_id, geometry, subclass, name FROM osm_landcover_polygon_gen7
);

CREATE OR REPLACE VIEW landcover_z8 AS (
    -- etldoc: osm_landcover_polygon_gen6 ->  landcover_z8
    SELECT osm_id, geometry, subclass, name FROM osm_landcover_polygon_gen6
);

CREATE OR REPLACE VIEW landcover_z9 AS (
    -- etldoc: landcover_grouped_gen5 ->  landcover_z9
    SELECT osm_id, geometry, subclass, name FROM landcover_grouped_gen5
);

CREATE OR REPLACE VIEW landcover_z10 AS (
    -- etldoc: landcover_grouped_gen4 ->  landcover_z10
    SELECT osm_id, geometry, subclass, name FROM landcover_grouped_gen4
);

CREATE OR REPLACE VIEW landcover_z11 AS (
    -- etldoc: landcover_grouped_gen3 ->  landcover_z11
    SELECT osm_id, geometry, subclass, name FROM landcover_grouped_gen3
);

CREATE OR REPLACE VIEW landcover_z12 AS (
    -- etldoc: landcover_grouped_gen2 ->  landcover_z12
    SELECT osm_id, geometry, subclass, name FROM landcover_grouped_gen2
);


-- UPDATE my_spatial_table t
-- SET geom = a.geom
-- FROM (
--     SELECT osm_id, ST_Collect(ST_MakePolygon(geom)) AS geom
--     FROM (
--         SELECT osm_id, ST_NRings(geom) AS nrings, 
--             ST_ExteriorRing((ST_Dump(geom)).geom) AS geom
--         FROM my_spatial_table
--         WHERE ST_NRings(geom) > 1
--         ) s
--     GROUP BY osm_id, nrings
--     HAVING nrings > COUNT(osm_id)
--     ) a
-- WHERE t.gid = a.gid;

CREATE OR REPLACE VIEW landcover_z13 AS (
    -- etldoc: osm_landcover_polygon_gen1 ->  landcover_z13

    -- SELECT osm_id, ST_Collect(ST_MakePolygon(geometry)) AS geometry, subclass, name
	-- FROM (
    --     SELECT osm_id, 
    --         ST_ExteriorRing((ST_Dump(geometry)).geom) AS geometry, subclass, name
    --     FROM landcover_grouped_gen1
    --     WHERE ST_NumInteriorRings(geometry) >= 1 AND ST_GeometryType(geometry) = 'ST_Polygon'
    --     ) as s
    -- GROUP BY osm_id, subclass, name
    -- UNION ALL
    -- SELECT * FROM landcover_grouped_gen1
    --     WHERE ST_NumInteriorRings(geometry)  = 0 OR ST_GeometryType(geometry) = 'ST_MultiPolygon'

    SELECT osm_id, geometry, subclass, name FROM landcover_grouped_gen1
);

CREATE OR REPLACE VIEW landcover_z14 AS (
    -- etldoc: osm_landcover_polygon ->  landcover_z14
    SELECT osm_id, geometry, subclass, name FROM osm_landcover_polygon
);
CREATE OR REPLACE VIEW landcover_linestring AS (
    -- etldoc: osm_landcover_linestring ->  landcover_cliffs
    SELECT osm_id, geometry, subclass, NULL::text as name FROM osm_landcover_linestring
);

-- etldoc: layer_landcover[shape=record fillcolor=lightpink, style="rounded, filled", label="layer_landcover | <z0_1> z0-z1 | <z2_4> z2-z4 | <z5_6> z5-z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_landcover(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text, name text) AS $$
    SELECT osm_id, geometry,
        landcover_class(subclass) AS class,
        subclass,
        case when (subclass not in ('park')) then nullif(name,'') end as name
    FROM (
        -- etldoc:  landcover_z0 -> layer_landcover:z0_1
        SELECT * FROM landcover_z0
        WHERE zoom_level BETWEEN 0 AND 1
        UNION ALL
        -- etldoc:  landcover_z2 -> layer_landcover:z2_4
        SELECT * FROM landcover_z2
        WHERE zoom_level BETWEEN 2 AND 4
        UNION ALL
        -- etldoc:  landcover_z5 -> layer_landcover:z5
        SELECT * FROM landcover_z5
        WHERE zoom_level = 5
        UNION ALL
        -- etldoc:  landcover_z6 -> layer_landcover:z6_7
        SELECT *
        FROM landcover_z6 WHERE zoom_level BETWEEN 6 AND 7
        UNION ALL
        -- etldoc:  landcover_z8 -> layer_landcover:z8
        SELECT *
        FROM landcover_z8 WHERE zoom_level = 8
        UNION ALL
        -- etldoc:  landcover_z9 -> layer_landcover:z9
        SELECT *
        FROM landcover_z9 WHERE zoom_level = 9
        UNION ALL
        -- etldoc:  landcover_z10 -> layer_landcover:z10
        SELECT *
        FROM landcover_z10 WHERE zoom_level = 10
        UNION ALL
        -- etldoc:  landcover_z11 -> layer_landcover:z11
        SELECT *
        FROM landcover_z11 WHERE zoom_level = 11
        UNION ALL
        -- etldoc:  landcover_z12 -> layer_landcover:z12
        SELECT *
        FROM landcover_z12 WHERE zoom_level = 12
        UNION ALL
        -- etldoc:  landcover_z13 -> layer_landcover:z13
        SELECT *
        FROM landcover_z13 WHERE zoom_level = 13
        UNION ALL
        -- etldoc:  landcover_z14 -> layer_landcover:z14_
        SELECT *
        FROM landcover_z14 WHERE zoom_level >= 14
        UNION ALL
        -- etldoc:  landcover_linestring -> layer_landcover:z12_
        SELECT * FROM landcover_linestring WHERE  zoom_level >= 12
            AND (subclass in ('cliff'))
        UNION ALL
        -- etldoc:  landcover_linestring -> layer_landcover:z14_
        SELECT * FROM landcover_linestring WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;

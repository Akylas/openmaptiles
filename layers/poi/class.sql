CREATE OR REPLACE FUNCTION poi_class_rank (
   class text
)
   RETURNS int
   AS $$
   SELECT
      CASE class
      WHEN 'hospital' THEN
         20
      WHEN 'railway' THEN
         40
      WHEN 'harbor' THEN
         75
      WHEN 'college' THEN
         80
      WHEN 'school' THEN
         85
      WHEN 'stadium' THEN
         90
      WHEN 'zoo' THEN
         95
      WHEN 'town_hall' THEN
         100
      WHEN 'campsite' THEN
         110
      WHEN 'lodging' THEN
         113
      WHEN 'national_park' THEN
         114
      WHEN 'cemetery' THEN
         115
      WHEN 'park' THEN
         120
      WHEN 'drinking_water' THEN
         125
      WHEN 'watering_place' THEN
         126
      WHEN 'bakery' THEN
         127
      WHEN 'bus' THEN
         128
      WHEN 'tram' THEN
         128
      WHEN 'subway' THEN
         128
      WHEN 'police' THEN
         130
      WHEN 'library' THEN
         135
      WHEN 'post' THEN
         140
      WHEN 'golf' THEN
         150
      WHEN 'grocery' THEN
         500
      WHEN 'restaurant' THEN
         600
      WHEN 'bar' THEN
         800
      ELSE
         1000
      END;

$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION poi_class (
   subclass text,
   mapping_key text
)
   RETURNS text
   AS $$
   SELECT
      CASE %%FIELD_MAPPING: class %%
   ELSE
      subclass
      END;

$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;


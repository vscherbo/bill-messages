-- View: "vw_ЕАдрес_Счета"

DROP VIEW "vwЕАдресСчета";

CREATE OR REPLACE VIEW "vwЕАдресСчета" AS 
 SELECT b."№ счета", e."ЕАдрес"
   FROM "Счета" b, "Работники" e
  WHERE b."КодРаботника" = e."КодРаботника" AND e."ЕАдрес" IS NOT NULL;

ALTER TABLE "vwЕАдресСчета"
  OWNER TO arc_energo;

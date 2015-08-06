-- Trigger: tr_Счет_ДокТК_BU on "Счета"

-- DROP TRIGGER "tr_Счет_ДокТК_BU" ON "Счета";

CREATE TRIGGER "tr_Счет_ДокТК_BU"
  BEFORE UPDATE OF "КодТК", "ДокТК", "ДокТКДата"
  ON "Счета"
  FOR EACH ROW
  WHEN ((((new."КодТК" IS NOT NULL) AND (new."ДокТК" IS NOT NULL)) AND (new."ДокТКДата" IS NOT NULL)))
  EXECUTE PROCEDURE "fntr_Счет_Статус_10"();
COMMENT ON TRIGGER "tr_Счет_ДокТК_BU" ON "Счета" IS 'После обновления КодТК, ДокТК, ДокТКДата выставляет "Статус"=10 ';

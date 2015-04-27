-- Trigger: trg_Статус_AU on "Счета"

DROP TRIGGER "trg_Статус_AU" ON "Счета";

CREATE TRIGGER "trg_Статус_AU"
  AFTER UPDATE OF "Статус"
  ON "Счета"
  FOR EACH ROW
  -- WHEN (( ((NOT new."Интернет") AND (new."Код" <> 223719)) AND ((new."Статус" <> old."Статус") OR (old."Статус" IS NULL))))
  WHEN ((new."Статус" <> old."Статус") OR (old."Статус" IS NULL))
  EXECUTE PROCEDURE "fnCreateBillStatusMessage"();
COMMENT ON TRIGGER "trg_Статус_AU" ON "Счета" IS 'Заносит сообщение в СчетОчередьСообщений после "значимых" изменения статуса';

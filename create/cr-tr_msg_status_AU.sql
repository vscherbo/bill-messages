-- Trigger: trg_msg_status_AU on "СчетОчередьСообщений"

DROP TRIGGER "trg_msg_status_AU" ON "СчетОчередьСообщений";

CREATE TRIGGER "trg_msg_status_AU"
  AFTER UPDATE OF msg_status
  ON "СчетОчередьСообщений"
  FOR EACH ROW
  -- WHEN ((NEW.msg_status = 999) AND (NEW.msg_status <> OLD.msg_status))
  WHEN ((NEW.msg_status >= 10) AND (NEW.msg_status <> OLD.msg_status))
  EXECUTE PROCEDURE "fntr_Сообщение_в_ДозвонНТУ"();
-- COMMENT ON TRIGGER "trg_msg_status_AU" ON "СчетОчередьСообщений" IS 'При присвоении msg_status значения 999 (пришла квитанция о доставке) заносит сообщение в ДозвонНТУ';
COMMENT ON TRIGGER "trg_msg_status_AU" ON "СчетОчередьСообщений" IS 'При присвоении msg_status значения >= 10 (сообщение об ошибке или пришла квитанция о доставке) заносит сообщение в ДозвонНТУ';

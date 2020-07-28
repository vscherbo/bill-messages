
DROP TRIGGER tr_ignore_message_bi ON "СчетОчередьСообщений";

CREATE TRIGGER tr_ignore_message_bi
  BEFORE INSERT
  ON "СчетОчередьСообщений"
  FOR EACH ROW
  EXECUTE PROCEDURE fntr_check_ignored();
COMMENT ON TRIGGER tr_ignore_message_bi ON "СчетОчередьСообщений" IS 'для СоотношениеСтатуса.СтатусПредприятия=14 устанавливает msg_status=-99 для игнорирования сообщения';

-- Foreign keys inside the schema, as in 06-data/models.md. A Reserva is never
-- deleted (modeling-conventions.md), so the key restricts the delete.
ALTER TABLE booking.idempotency_key
  ADD CONSTRAINT fk_idempotency_key_reservation
  FOREIGN KEY (reservation_id) REFERENCES booking.reservation (id) ON DELETE RESTRICT;

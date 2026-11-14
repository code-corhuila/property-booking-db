-- Indexes of 06-data/models.md.
-- "my reservations":                                 WHERE guest_id = ?
CREATE INDEX idx_reservation_guest_id ON booking.reservation (guest_id);
-- "PENDIENTE reservations created before an instant" (expiry job, ADR-014)
CREATE INDEX idx_reservation_pending_created_at ON booking.reservation (created_at)
  WHERE status = 'PENDIENTE';
-- Foreign key column.
CREATE INDEX idx_idempotency_key_reservation_id ON booking.idempotency_key (reservation_id);
-- "events the relay has not published yet"
CREATE INDEX idx_outbox_event_unpublished ON booking.outbox_event (created_at) WHERE published = FALSE;

-- booking_app, through booking_writer, reads, inserts and updates in booking,
-- and can neither delete nor change structure (migration-strategy.md). The
-- check of Annex J.10: it writes only in its own schema.
-- Everything runs in one transaction that is rolled back.
BEGIN;
SET LOCAL ROLE booking_app;

INSERT INTO booking.reservation (id, property_id, guest_id, start_date, end_date, total_amount_cents)
VALUES ('55555555-5555-4555-8555-555555555555', '11111111-1111-4111-8111-111111111111',
        '22222222-2222-4222-8222-222222222222', '2027-01-10', '2027-01-12', 180000);
INSERT INTO booking.idempotency_key (key, reservation_id)
VALUES ('saga-0001:crear-reserva', '55555555-5555-4555-8555-555555555555');
INSERT INTO booking.outbox_event (aggregate_id, event_type, payload)
VALUES ('55555555-5555-4555-8555-555555555555', 'ReservaCreada', '{}');
UPDATE booking.reservation SET status = 'CONFIRMADA', updated_at = now()
WHERE id = '55555555-5555-4555-8555-555555555555';
SELECT count(*) AS visible_reservations FROM booking.reservation;

DO $$
BEGIN
  DELETE FROM booking.outbox_event;
  RAISE EXCEPTION 'booking_app could delete';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'booking_app cannot delete';
END
$$;

DO $$
BEGIN
  CREATE TABLE booking.not_allowed (id int);
  RAISE EXCEPTION 'booking_app could create a table';
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'booking_app cannot change structure';
END
$$;

RESET ROLE;

-- Annex J.10: the schemas where booking_app can write.
DO $$
DECLARE
  schemas text;
BEGIN
  SELECT string_agg(DISTINCT n.nspname, ', ') INTO schemas
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname NOT LIKE 'pg\_%' AND n.nspname <> 'information_schema'
    AND has_schema_privilege('booking_app', n.nspname, 'USAGE')
    AND (has_table_privilege('booking_app', c.oid, 'INSERT')
         OR has_table_privilege('booking_app', c.oid, 'UPDATE')
         OR has_table_privilege('booking_app', c.oid, 'DELETE'));
  IF schemas IS DISTINCT FROM 'booking' THEN
    RAISE EXCEPTION 'booking_app writes in: %', schemas;
  END IF;
  RAISE NOTICE 'Annex J.10: booking_app writes only in booking';
END
$$;

ROLLBACK;

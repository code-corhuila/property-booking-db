-- INV-001: a property cannot have two PENDIENTE or CONFIRMADA reservations with
-- overlapping date ranges (02-domain/entities-and-rules.md). The database is the
-- second line of defence: excl_reservation_overlapping_dates.
-- Everything runs in one transaction that is rolled back: no row is left behind.
BEGIN;

-- Property A, 10 to 15 December, PENDIENTE.
INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents)
VALUES ('11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222',
        '2026-12-10', '2026-12-15', 450000);

-- Allowed: the check-out day is free (half-open range), CONFIRMADA from the 15th.
INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents, status)
VALUES ('11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333',
        '2026-12-15', '2026-12-18', 270000, 'CONFIRMADA');

-- Allowed: the same dates on another property.
INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents)
VALUES ('44444444-4444-4444-8444-444444444444', '33333333-3333-4333-8333-333333333333',
        '2026-12-10', '2026-12-15', 450000);

-- Allowed: a closed reservation does not hold its dates.
INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents,
                                 status, closure_reason)
VALUES ('11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333',
        '2026-12-11', '2026-12-13', 180000, 'CANCELADA', 'CANCELADA_POR_HUESPED');

-- Rejected: overlaps the PENDIENTE one.
DO $$
BEGIN
  INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents)
  VALUES ('11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333',
          '2026-12-12', '2026-12-14', 180000);
  RAISE EXCEPTION 'INV-001 not enforced: an overlap with a PENDIENTE reservation was accepted';
EXCEPTION WHEN exclusion_violation THEN
  RAISE NOTICE 'INV-001: overlap with a PENDIENTE reservation rejected';
END
$$;

-- Rejected: overlaps the CONFIRMADA one.
DO $$
BEGIN
  INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents)
  VALUES ('11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333',
          '2026-12-17', '2026-12-20', 270000);
  RAISE EXCEPTION 'INV-001 not enforced: an overlap with a CONFIRMADA reservation was accepted';
EXCEPTION WHEN exclusion_violation THEN
  RAISE NOTICE 'INV-001: overlap with a CONFIRMADA reservation rejected';
END
$$;

-- Rejected: an empty range (fechaInicio = fechaFin) never reaches the exclusion.
DO $$
BEGIN
  INSERT INTO booking.reservation (property_id, guest_id, start_date, end_date, total_amount_cents)
  VALUES ('11111111-1111-4111-8111-111111111111', '33333333-3333-4333-8333-333333333333',
          '2026-12-20', '2026-12-20', 90000);
  RAISE EXCEPTION 'chk_reservation_dates not enforced: an empty range was accepted';
EXCEPTION WHEN check_violation THEN
  RAISE NOTICE 'chk_reservation_dates: empty range rejected';
END
$$;

ROLLBACK;

-- The Reserva aggregate, as in 06-data/models.md. The exclusion constraint
-- needs btree_gist, created by the instance (ADR-008).
CREATE TABLE booking.reservation (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Business fields
  property_id         UUID        NOT NULL,   -- owned by catalog: referenced by id, no FK
  guest_id            UUID        NOT NULL,   -- owned by identity: referenced by id, no FK
  start_date          DATE        NOT NULL,
  end_date            DATE        NOT NULL,
  total_amount_cents  BIGINT      NOT NULL
                      CONSTRAINT chk_reservation_total_positive CHECK (total_amount_cents > 0),
  currency            TEXT        NOT NULL DEFAULT 'COP'
                      CONSTRAINT chk_reservation_currency CHECK (char_length(currency) = 3),

  -- Lifecycle
  status              TEXT        NOT NULL DEFAULT 'PENDIENTE'
                      CONSTRAINT chk_reservation_status
                      CHECK (status IN ('PENDIENTE', 'CONFIRMADA', 'CANCELADA', 'EXPIRADA')),
  closure_reason      TEXT,       -- filled on CANCELADA / EXPIRADA

  -- Audit
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Half-open ranges: an empty range never overlaps, so it is rejected here
  CONSTRAINT chk_reservation_dates CHECK (start_date < end_date),

  -- Filled exactly when the Reserva is closed, with one of the documented codes
  CONSTRAINT chk_reservation_closure_reason CHECK (
    (status IN ('CANCELADA', 'EXPIRADA')) = (closure_reason IS NOT NULL)
    AND closure_reason IN ('TIMEOUT_PAGO_EXCEDIDO', 'CANCELADA_POR_HUESPED', 'SAGA_COMPENSADA',
                           'FONDOS_INSUFICIENTES', 'TARJETA_RECHAZADA', 'TARJETA_VENCIDA',
                           'PASARELA_NO_DISPONIBLE')
  ),

  -- INV-001: no two active (PENDIENTE/CONFIRMADA) bookings on the same property
  -- may have overlapping date ranges. '[)' = half-open: the check-out day is free
  CONSTRAINT excl_reservation_overlapping_dates
    EXCLUDE USING gist (
      property_id WITH =,
      daterange(start_date, end_date, '[)') WITH &&
    ) WHERE (status IN ('PENDIENTE', 'CONFIRMADA'))
);

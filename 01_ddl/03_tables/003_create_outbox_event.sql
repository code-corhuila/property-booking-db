-- Outbox of the domain events of the Reserva (ADR-005), as in 06-data/models.md.
CREATE TABLE booking.outbox_event (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_id      UUID        NOT NULL,               -- reservation id
  aggregate_type    TEXT        NOT NULL DEFAULT 'Reserva',
  event_type        TEXT        NOT NULL                -- wire-format name, as in domain-events.md
                    CONSTRAINT chk_outbox_event_type CHECK (event_type IN
                      ('ReservaCreada', 'ReservaConfirmada', 'ReservaCancelada', 'ReservaExpirada')),
  payload           JSONB       NOT NULL,               -- full event envelope
  published         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at      TIMESTAMPTZ
);

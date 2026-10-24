-- The key each Reserva was created with, as in 06-data/models.md. Its foreign
-- key goes in 04_alter. The Saga sends <sagaId>:crear-reserva.
CREATE TABLE booking.idempotency_key (
  key             TEXT        PRIMARY KEY
                  CONSTRAINT chk_idempotency_key_length CHECK (char_length(key) BETWEEN 8 AND 128),
  reservation_id  UUID        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Least privilege. The writer reads, inserts and updates: a Reserva is never
-- deleted, and nobody but the runner changes structure (migration-strategy.md).
-- The reader is granted to nobody: this project has no cross-domain reads
-- (ADR-008, rule 5).
GRANT USAGE ON SCHEMA booking TO booking_reader, booking_writer;
GRANT SELECT ON ALL TABLES IN SCHEMA booking TO booking_reader;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA booking TO booking_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA booking GRANT SELECT ON TABLES TO booking_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA booking GRANT SELECT, INSERT, UPDATE ON TABLES TO booking_writer;

-- The service connects as booking_app, which holds the writer role (Annex J.7).
GRANT booking_writer TO booking_app;

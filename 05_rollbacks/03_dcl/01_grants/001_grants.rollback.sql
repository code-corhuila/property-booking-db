REVOKE booking_writer FROM booking_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA booking REVOKE ALL ON TABLES FROM booking_reader, booking_writer;
REVOKE ALL ON ALL TABLES IN SCHEMA booking FROM booking_reader, booking_writer;
REVOKE USAGE ON SCHEMA booking FROM booking_reader, booking_writer;

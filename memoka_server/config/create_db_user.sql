-- Database Security: Create Dedicated Application User
-- This script creates a non-superuser account with minimal privileges
--
-- Usage:
--   1. Connect to PostgreSQL as superuser (postgres)
--   2. Run this script: psql -U postgres -d on_air -f create_db_user.sql
--   3. Update your passwords.yaml to use the new user
--
-- IMPORTANT: Replace 'STRONG_PASSWORD_HERE' with a secure password!

-- Create dedicated user for the application
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'on_air_app') THEN
    CREATE USER on_air_app WITH PASSWORD 'STRONG_PASSWORD_HERE';
  END IF;
END
$$;

-- Grant connect permission
GRANT CONNECT ON DATABASE on_air TO on_air_app;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO on_air_app;

-- Grant table permissions (data manipulation only, no DDL)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO on_air_app;

-- Grant sequence permissions (for auto-incrementing IDs)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO on_air_app;

-- Grant permissions on future tables (for migrations)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO on_air_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO on_air_app;

-- Explicitly deny superuser privileges
ALTER USER on_air_app WITH NOSUPERUSER;

-- Deny table/schema creation
ALTER USER on_air_app WITH NOCREATEDB;
ALTER USER on_air_app WITH NOCREATEROLE;

-- Show current privileges
\du on_air_app

-- Verify permissions
SELECT
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'on_air_app'
LIMIT 10;

-- After running this script:
-- 1. Update config/development.yaml:
--    database:
--      user: on_air_app
--
-- 2. Update config/passwords.yaml:
--    development:
--      database: 'your_new_password_here'
--
-- 3. Test connection:
--    psql -U on_air_app -d on_air -h localhost -p 8090

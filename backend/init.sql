-- Create the aquadetection_user role if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'aquadetection_user') THEN
        CREATE ROLE aquadetection_user WITH LOGIN PASSWORD 'aquadetection_secure_pass';
    END IF;
END
$$;

-- Grant necessary permissions
ALTER ROLE aquadetection_user CREATEDB;
ALTER ROLE aquadetection_user CREATEROLE;

-- Grant all privileges on the aquadetection_db database
GRANT ALL PRIVILEGES ON DATABASE aquadetection_db TO aquadetection_user;

-- Ensure the user is owner
ALTER DATABASE aquadetection_db OWNER TO aquadetection_user;

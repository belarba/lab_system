DO $$
BEGIN
  -- Criar usuário lab se não existir
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'lab') THEN
    CREATE USER lab WITH CREATEDB PASSWORD 'lab123';
  END IF;
  
  -- Dar permissões ao usuário lab
  GRANT ALL PRIVILEGES ON DATABASE lab_system TO lab;
  ALTER USER lab CREATEDB;
END; $$;

-- Criar databases se não existirem
SELECT 'CREATE DATABASE lab_system_development OWNER lab'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lab_system_development')\gexec

SELECT 'CREATE DATABASE lab_system_test OWNER lab'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lab_system_test')\gexec
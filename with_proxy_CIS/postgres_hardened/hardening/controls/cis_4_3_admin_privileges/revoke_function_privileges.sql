-- CIS 4.5: Revoke excessive function privileges from PUBLIC.

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

DO $$
DECLARE
    function_record RECORD;
BEGIN
    FOR function_record IN
        SELECT
            n.nspname AS schema_name,
            p.proname AS function_name,
            pg_catalog.pg_get_function_identity_arguments(p.oid) AS identity_arguments
        FROM pg_catalog.pg_proc AS p
        JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.prokind = 'f'
          AND p.proname NOT LIKE 'pgaudit%'
        ORDER BY p.oid
    LOOP
        EXECUTE format(
            'REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC',
            function_record.schema_name,
            function_record.function_name,
            function_record.identity_arguments
        );
    END LOOP;
END $$;
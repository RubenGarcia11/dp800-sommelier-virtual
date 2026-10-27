USE master;
GO

IF SUSER_ID(N'api_sommelier') IS NULL
    CREATE LOGIN api_sommelier WITH PASSWORD = N'$(API_DB_PASSWORD)', CHECK_POLICY = OFF;
GO

USE SommelierVirtual;
GO

IF DATABASE_PRINCIPAL_ID(N'rol_api') IS NULL
    CREATE ROLE rol_api;
GO

IF DATABASE_PRINCIPAL_ID(N'api_sommelier') IS NULL
    CREATE USER api_sommelier FOR LOGIN api_sommelier;
GO

ALTER ROLE rol_api ADD MEMBER api_sommelier;
GO

-- El servicio de la API lee todas las notas para construir el contexto del RAG
ALTER SECURITY POLICY seguridad.pol_notas_por_catador WITH (STATE = OFF);
GO

ALTER SECURITY POLICY seguridad.pol_notas_por_catador
    DROP FILTER PREDICATE ON dbo.NotasCata,
    DROP BLOCK PREDICATE ON dbo.NotasCata AFTER INSERT;
GO

DROP FUNCTION seguridad.fn_filtro_catador;
GO

CREATE FUNCTION seguridad.fn_filtro_catador(@Catador NVARCHAR(100))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS permitido
    WHERE IS_MEMBER(N'rol_gestor') = 1
       OR IS_MEMBER(N'rol_api') = 1
       OR IS_MEMBER(N'db_owner') = 1
       OR @Catador = CAST(SESSION_CONTEXT(N'catador') AS NVARCHAR(100));
GO

ALTER SECURITY POLICY seguridad.pol_notas_por_catador
    ADD FILTER PREDICATE seguridad.fn_filtro_catador(Catador) ON dbo.NotasCata,
    ADD BLOCK PREDICATE seguridad.fn_filtro_catador(Catador) ON dbo.NotasCata AFTER INSERT;
GO

ALTER SECURITY POLICY seguridad.pol_notas_por_catador WITH (STATE = ON);
GO

GRANT SELECT ON dbo.vw_CatalogoVinos TO rol_api;
GRANT EXECUTE ON dbo.usp_BuscarVinos TO rol_api;
GRANT EXECUTE ON dbo.usp_FichaVinoJson TO rol_api;
GO

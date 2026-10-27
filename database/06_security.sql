USE SommelierVirtual;
GO

-- Roles y permisos mínimos
CREATE ROLE rol_consulta;
CREATE ROLE rol_catador;
CREATE ROLE rol_gestor;
GO

GRANT SELECT ON dbo.vw_CatalogoVinos  TO rol_consulta;
GRANT SELECT ON dbo.vw_RankingPorTipo TO rol_consulta;
GRANT EXECUTE ON dbo.usp_BuscarVinos      TO rol_consulta;
GRANT EXECUTE ON dbo.usp_FichaVinoJson    TO rol_consulta;

ALTER ROLE rol_consulta ADD MEMBER rol_catador;
GRANT SELECT ON dbo.NotasCata TO rol_catador;
GRANT EXECUTE ON dbo.usp_RegistrarNotaCata TO rol_catador;

ALTER ROLE rol_catador ADD MEMBER rol_gestor;
GRANT SELECT, INSERT, UPDATE ON dbo.Inventario TO rol_gestor;
GRANT SELECT ON dbo.vw_MargenInventario TO rol_gestor;
GRANT EXECUTE ON dbo.usp_ActualizarStock TO rol_gestor;
GRANT EXECUTE ON dbo.usp_MejorVinoPorBodega TO rol_gestor;
GO

-- Row-Level Security: cada catador solo ve y registra sus propias notas;
-- el gestor y el propietario de la base de datos ven todas.
CREATE SCHEMA seguridad;
GO

CREATE FUNCTION seguridad.fn_filtro_catador(@Catador NVARCHAR(100))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS permitido
    WHERE IS_MEMBER(N'rol_gestor') = 1
       OR IS_MEMBER(N'db_owner') = 1
       OR @Catador = CAST(SESSION_CONTEXT(N'catador') AS NVARCHAR(100));
GO

CREATE SECURITY POLICY seguridad.pol_notas_por_catador
    ADD FILTER PREDICATE seguridad.fn_filtro_catador(Catador) ON dbo.NotasCata,
    ADD BLOCK PREDICATE seguridad.fn_filtro_catador(Catador) ON dbo.NotasCata AFTER INSERT
WITH (STATE = ON);
GO

-- Enmascarado dinámico del precio de compra para quien no sea gestor
ALTER TABLE dbo.Inventario
    ALTER COLUMN PrecioCompra ADD MASKED WITH (FUNCTION = 'default()');
GO

GRANT UNMASK TO rol_gestor;
GO

-- Usuarios de ejemplo para comprobar el comportamiento
CREATE USER usr_consulta WITHOUT LOGIN;
CREATE USER usr_laura    WITHOUT LOGIN;
CREATE USER usr_gestor   WITHOUT LOGIN;

ALTER ROLE rol_consulta ADD MEMBER usr_consulta;
ALTER ROLE rol_catador  ADD MEMBER usr_laura;
ALTER ROLE rol_gestor   ADD MEMBER usr_gestor;
GO

GRANT SELECT ON dbo.Inventario TO rol_consulta;
GO

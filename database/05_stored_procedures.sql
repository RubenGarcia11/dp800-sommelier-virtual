USE SommelierVirtual;
GO

CREATE OR ALTER PROCEDURE dbo.usp_BuscarVinos
    @Tipo        NVARCHAR(20)  = NULL,
    @PrecioMax   DECIMAL(10,2) = NULL,
    @Region      NVARCHAR(80)  = NULL,
    @SoloConStock BIT          = 1,
    @Denominacion NVARCHAR(80) = NULL,
    @Pais         NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT VinoId, Nombre, Tipo, Uva, Anada, Denominacion, Bodega, Pais, Region, Stock, PrecioVenta, PuntuacionMedia
    FROM dbo.vw_CatalogoVinos
    WHERE (@Tipo IS NULL OR Tipo = @Tipo)
      AND (@PrecioMax IS NULL OR PrecioVenta <= @PrecioMax)
      AND (@Region IS NULL OR Region = @Region)
      AND (@Denominacion IS NULL OR Denominacion = @Denominacion)
      AND (@Pais IS NULL OR Pais = @Pais)
      AND (@SoloConStock = 0 OR Stock > 0)
    ORDER BY PuntuacionMedia DESC, PrecioVenta;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegistrarNotaCata
    @VinoId     INT,
    @Vista      NVARCHAR(300) = NULL,
    @Nariz      NVARCHAR(500) = NULL,
    @Boca       NVARCHAR(500) = NULL,
    @Maridaje   NVARCHAR(300) = NULL,
    @Puntuacion TINYINT,
    @Catador    NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Vinos WHERE VinoId = @VinoId)
        THROW 50001, 'El vino indicado no existe.', 1;

    INSERT INTO dbo.NotasCata (VinoId, Vista, Nariz, Boca, Maridaje, Puntuacion, Catador)
    VALUES (@VinoId, @Vista, @Nariz, @Boca, @Maridaje, @Puntuacion, @Catador);

    SELECT SCOPE_IDENTITY() AS NotaId;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_ActualizarStock
    @VinoId   INT,
    @Cantidad INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    UPDATE dbo.Inventario
    SET Stock = Stock + @Cantidad,
        ActualizadoEn = SYSDATETIME()
    WHERE VinoId = @VinoId;

    IF @@ROWCOUNT = 0
        THROW 50002, 'El vino no tiene registro de inventario.', 1;

    COMMIT TRANSACTION;
END
GO

-- Ficha completa de un vino con sus notas de cata en formato JSON
CREATE OR ALTER PROCEDURE dbo.usp_FichaVinoJson
    @VinoId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.VinoId,
        v.Nombre,
        v.Tipo,
        v.Uva,
        v.Anada,
        v.Graduacion,
        v.Denominacion AS denominacion,
        b.Nombre AS [bodega.nombre],
        b.Region AS [bodega.region],
        b.Pais   AS [bodega.pais],
        i.PrecioVenta AS [inventario.precio],
        i.Stock       AS [inventario.stock],
        (
            SELECT n.Vista AS vista, n.Nariz AS nariz, n.Boca AS boca,
                   n.Maridaje AS maridaje, n.Puntuacion AS puntuacion, n.Catador AS catador
            FROM dbo.NotasCata n
            WHERE n.VinoId = v.VinoId
            FOR JSON PATH
        ) AS notas
    FROM dbo.Vinos v
    INNER JOIN dbo.Bodegas b ON b.BodegaId = v.BodegaId
    LEFT JOIN dbo.Inventario i ON i.VinoId = v.VinoId
    WHERE v.VinoId = @VinoId
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END
GO

-- Mejor vino de cada bodega según la puntuación media (CTE + ROW_NUMBER)
CREATE OR ALTER PROCEDURE dbo.usp_MejorVinoPorBodega
AS
BEGIN
    SET NOCOUNT ON;

    WITH Medias AS (
        SELECT v.VinoId, v.Nombre, v.BodegaId, AVG(CAST(n.Puntuacion AS DECIMAL(5,2))) AS Media
        FROM dbo.Vinos v
        INNER JOIN dbo.NotasCata n ON n.VinoId = v.VinoId
        GROUP BY v.VinoId, v.Nombre, v.BodegaId
    ),
    Ordenados AS (
        SELECT m.*, ROW_NUMBER() OVER (PARTITION BY m.BodegaId ORDER BY m.Media DESC) AS rn
        FROM Medias m
    )
    SELECT b.Nombre AS Bodega, o.Nombre AS Vino, CAST(o.Media AS DECIMAL(5,2)) AS PuntuacionMedia
    FROM Ordenados o
    INNER JOIN dbo.Bodegas b ON b.BodegaId = o.BodegaId
    WHERE o.rn = 1
    ORDER BY o.Media DESC;
END
GO

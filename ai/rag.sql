USE SommelierVirtual;
GO

-- Recupera los vinos más cercanos a la pregunta junto con sus notas de cata, en JSON.
-- @Tipos admite varios tipos separados por comas (por ejemplo N'Tinto,Rosado').
CREATE OR ALTER PROCEDURE dbo.usp_ContextoRag
    @Consulta     NVARCHAR(500),
    @Top          INT = 4,
    @Tipos        NVARCHAR(100) = NULL,
    @Denominacion NVARCHAR(80)  = NULL,
    @Paises       NVARCHAR(200) = NULL,
    @PrecioMin    DECIMAL(10,2) = NULL,
    @PrecioMax    DECIMAL(10,2) = NULL,
    @StockMin     INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @vector VECTOR(1024) = AI_GENERATE_EMBEDDINGS(@Consulta USE MODEL ModeloEmbeddings);

    WITH Cercanos AS (
        SELECT TOP (@Top)
            v.VinoId,
            VECTOR_DISTANCE('cosine', v.Embedding, @vector) AS Distancia
        FROM dbo.Vinos v
        INNER JOIN dbo.Inventario inv ON inv.VinoId = v.VinoId
        INNER JOIN dbo.Bodegas bod ON bod.BodegaId = v.BodegaId
        WHERE v.Embedding IS NOT NULL
          AND inv.Stock >= ISNULL(@StockMin, 1)
          AND (@PrecioMin IS NULL OR inv.PrecioVenta >= @PrecioMin)
          AND (@PrecioMax IS NULL OR inv.PrecioVenta <= @PrecioMax)
          AND (@Denominacion IS NULL OR v.Denominacion = @Denominacion)
          AND (@Paises IS NULL OR bod.Pais IN (SELECT TRIM(value) FROM STRING_SPLIT(@Paises, N',')))
          AND (@Tipos IS NULL OR v.Tipo IN (SELECT TRIM(value) FROM STRING_SPLIT(@Tipos, N',')))
        ORDER BY VECTOR_DISTANCE('cosine', v.Embedding, @vector)
    )
    SELECT
        v.VinoId AS id,
        v.Nombre AS nombre,
        v.Tipo AS tipo,
        v.Uva AS uva,
        v.Anada AS anada,
        v.Denominacion AS denominacion,
        v.Descripcion AS descripcion,
        b.Nombre AS bodega,
        b.Pais AS pais,
        i.PrecioVenta AS precio,
        i.Stock AS stock,
        CAST(1 - c.Distancia AS DECIMAL(6,4)) AS similitud,
        (
            SELECT n.Nariz AS nariz, n.Boca AS boca, n.Maridaje AS maridaje, n.Puntuacion AS puntuacion
            FROM dbo.NotasCata n
            WHERE n.VinoId = v.VinoId
            FOR JSON PATH
        ) AS notas
    FROM Cercanos c
    INNER JOIN dbo.Vinos v ON v.VinoId = c.VinoId
    INNER JOIN dbo.Bodegas b ON b.BodegaId = v.BodegaId
    LEFT JOIN dbo.Inventario i ON i.VinoId = v.VinoId
    ORDER BY c.Distancia
    FOR JSON PATH;
END
GO

GRANT EXECUTE ON dbo.usp_ContextoRag TO rol_api;
GRANT EXECUTE ON dbo.usp_BuscarVinosSemantico TO rol_api;
GRANT EXECUTE ON EXTERNAL MODEL::ModeloEmbeddings TO rol_api;
GO

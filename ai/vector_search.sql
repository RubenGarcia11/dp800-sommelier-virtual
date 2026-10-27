USE SommelierVirtual;
GO

CREATE OR ALTER PROCEDURE dbo.usp_BuscarVinosSemantico
    @Consulta NVARCHAR(500),
    @Top      INT = 5,
    @Tipo     NVARCHAR(20) = NULL,
    @Denominacion NVARCHAR(80) = NULL,
    @Pais         NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @vector VECTOR(1024) = AI_GENERATE_EMBEDDINGS(@Consulta USE MODEL ModeloEmbeddings);

    SELECT TOP (@Top)
        v.VinoId,
        v.Nombre,
        v.Tipo,
        v.Uva,
        v.Denominacion,
        b.Nombre AS Bodega,
        i.PrecioVenta,
        CAST(1 - VECTOR_DISTANCE('cosine', v.Embedding, @vector) AS DECIMAL(6,4)) AS Similitud
    FROM dbo.Vinos v
    INNER JOIN dbo.Bodegas b ON b.BodegaId = v.BodegaId
    LEFT JOIN dbo.Inventario i ON i.VinoId = v.VinoId
    WHERE v.Embedding IS NOT NULL
      AND (@Tipo IS NULL OR v.Tipo = @Tipo)
      AND (@Denominacion IS NULL OR v.Denominacion = @Denominacion)
      AND (@Pais IS NULL OR b.Pais = @Pais)
    ORDER BY VECTOR_DISTANCE('cosine', v.Embedding, @vector);
END
GO

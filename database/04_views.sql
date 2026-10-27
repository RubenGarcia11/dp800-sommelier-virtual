USE SommelierVirtual;
GO

CREATE OR ALTER VIEW dbo.vw_CatalogoVinos
AS
SELECT
    v.VinoId,
    v.Nombre,
    v.Tipo,
    v.Uva,
    v.Anada,
    v.Graduacion,
    v.Crianza,
    v.Denominacion,
    b.Nombre AS Bodega,
    b.Pais,
    b.Region,
    i.Stock,
    i.PrecioVenta,
    CAST(AVG(CAST(n.Puntuacion AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS PuntuacionMedia,
    COUNT(n.NotaId) AS NumeroNotas
FROM dbo.Vinos v
INNER JOIN dbo.Bodegas b ON b.BodegaId = v.BodegaId
LEFT JOIN dbo.Inventario i ON i.VinoId = v.VinoId
LEFT JOIN dbo.NotasCata n ON n.VinoId = v.VinoId
GROUP BY v.VinoId, v.Nombre, v.Tipo, v.Uva, v.Anada, v.Graduacion, v.Crianza, v.Denominacion,
         b.Nombre, b.Pais, b.Region, i.Stock, i.PrecioVenta;
GO

CREATE OR ALTER VIEW dbo.vw_MargenInventario
AS
SELECT
    v.VinoId,
    v.Nombre,
    i.Stock,
    i.PrecioCompra,
    i.PrecioVenta,
    i.PrecioVenta - i.PrecioCompra AS MargenUnitario,
    CAST((i.PrecioVenta - i.PrecioCompra) * 100.0 / i.PrecioCompra AS DECIMAL(6,2)) AS MargenPorcentaje,
    (i.PrecioVenta - i.PrecioCompra) * i.Stock AS BeneficioPotencial
FROM dbo.Inventario i
INNER JOIN dbo.Vinos v ON v.VinoId = i.VinoId;
GO

-- Ranking por tipo de vino y regiones con mejor puntuación media (CTE + funciones de ventana)
CREATE OR ALTER VIEW dbo.vw_RankingPorTipo
AS
WITH Puntuaciones AS (
    SELECT
        v.VinoId,
        v.Nombre,
        v.Tipo,
        v.Denominacion,
        AVG(CAST(n.Puntuacion AS DECIMAL(5,2))) AS Media,
        COUNT(*) AS Notas
    FROM dbo.Vinos v
    INNER JOIN dbo.Bodegas b ON b.BodegaId = v.BodegaId
    INNER JOIN dbo.NotasCata n ON n.VinoId = v.VinoId
    GROUP BY v.VinoId, v.Nombre, v.Tipo, v.Denominacion
)
SELECT
    VinoId,
    Nombre,
    Tipo,
    Denominacion,
    CAST(Media AS DECIMAL(5,2)) AS PuntuacionMedia,
    Notas,
    RANK() OVER (PARTITION BY Tipo ORDER BY Media DESC) AS PosicionEnTipo,
    CAST(Media - AVG(Media) OVER (PARTITION BY Tipo) AS DECIMAL(5,2)) AS DiferenciaVsMediaTipo,
    DENSE_RANK() OVER (ORDER BY Media DESC) AS PosicionGlobal
FROM Puntuaciones;
GO

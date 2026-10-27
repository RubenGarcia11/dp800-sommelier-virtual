USE SommelierVirtual;
GO

-- Tabla de pedidos sin índice clustered (heap) para simular el estado inicial
CREATE TABLE dbo.Pedidos (
    PedidoId   INT IDENTITY(1,1) NOT NULL,
    ClienteId  INT           NOT NULL,
    VinoId     INT           NOT NULL,
    FechaPedido DATE         NOT NULL,
    Cantidad   SMALLINT      NOT NULL,
    Importe    DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Pedidos PRIMARY KEY NONCLUSTERED (PedidoId),
    CONSTRAINT FK_Pedidos_Vinos FOREIGN KEY (VinoId) REFERENCES dbo.Vinos (VinoId)
);
GO

WITH Numeros AS (
    SELECT TOP (200000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Pedidos (ClienteId, VinoId, FechaPedido, Cantidad, Importe)
SELECT
    1 + (ABS(CHECKSUM(NEWID())) % 5000),
    1 + (ABS(CHECKSUM(NEWID())) % 21),
    DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 1095), CAST(SYSDATETIME() AS DATE)),
    1 + (ABS(CHECKSUM(NEWID())) % 6),
    0
FROM Numeros;

UPDATE p
SET Importe = p.Cantidad * i.PrecioVenta
FROM dbo.Pedidos p
INNER JOIN dbo.Inventario i ON i.VinoId = p.VinoId;
GO

-- Consulta compleja: gasto por tipo de vino de un cliente en el último año,
-- con el acumulado mensual mediante funciones de ventana
CREATE OR ALTER PROCEDURE dbo.usp_GastoClientePorMes
    @ClienteId INT,
    @Desde     DATE
AS
BEGIN
    SET NOCOUNT ON;

    WITH Mensual AS (
        SELECT
            DATEFROMPARTS(YEAR(p.FechaPedido), MONTH(p.FechaPedido), 1) AS Mes,
            v.Tipo,
            SUM(p.Importe)  AS Gasto,
            SUM(p.Cantidad) AS Botellas
        FROM dbo.Pedidos p
        INNER JOIN dbo.Vinos v ON v.VinoId = p.VinoId
        WHERE p.ClienteId = @ClienteId
          AND p.FechaPedido >= @Desde
        GROUP BY DATEFROMPARTS(YEAR(p.FechaPedido), MONTH(p.FechaPedido), 1), v.Tipo
    )
    SELECT
        Mes, Tipo, Gasto, Botellas,
        SUM(Gasto) OVER (PARTITION BY Tipo ORDER BY Mes ROWS UNBOUNDED PRECEDING) AS GastoAcumulado
    FROM Mensual
    ORDER BY Mes, Tipo;
END
GO

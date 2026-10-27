USE SommelierVirtual;
GO

CREATE NONCLUSTERED INDEX IX_Pedidos_Cliente_Fecha
ON dbo.Pedidos (ClienteId, FechaPedido)
INCLUDE (VinoId, Cantidad, Importe);
GO

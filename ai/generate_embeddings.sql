USE SommelierVirtual;
GO

IF COL_LENGTH('dbo.Vinos', 'Embedding') IS NOT NULL
    ALTER TABLE dbo.Vinos DROP COLUMN Embedding;
GO

ALTER TABLE dbo.Vinos ADD Embedding VECTOR(1024) NULL;
GO

-- Texto descriptivo del vino que se vectoriza: ficha + notas de cata
CREATE OR ALTER VIEW dbo.vw_TextoVino
AS
SELECT
    v.VinoId,
    CONCAT(
        v.Nombre, N'. Tipo: ', v.Tipo, N'. Uva: ', v.Uva,
        N'. Denominación de origen: ', v.Denominacion, N'. Bodega: ', b.Nombre, N' (', b.Pais, N'). ',
        ISNULL(v.Descripcion, N''), N' ',
        ISNULL((
            SELECT STRING_AGG(CONCAT(n.Vista, N'. ', n.Nariz, N'. ', n.Boca, N'. Maridaje: ', n.Maridaje), N' ')
            FROM dbo.NotasCata n
            WHERE n.VinoId = v.VinoId
        ), N'')
    ) AS Texto
FROM dbo.Vinos v
INNER JOIN dbo.Bodegas b ON b.BodegaId = v.BodegaId;
GO

UPDATE v
SET Embedding = AI_GENERATE_EMBEDDINGS(t.Texto USE MODEL ModeloEmbeddings)
FROM dbo.Vinos v
INNER JOIN dbo.vw_TextoVino t ON t.VinoId = v.VinoId
WHERE v.Embedding IS NULL;
GO

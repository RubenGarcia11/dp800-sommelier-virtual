USE SommelierVirtual;
GO

EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = N'ModeloEmbeddings')
    DROP EXTERNAL MODEL ModeloEmbeddings;
GO

CREATE EXTERNAL MODEL ModeloEmbeddings
WITH (
    LOCATION   = 'https://ollama-tls:443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL      = 'bge-m3'
);
GO

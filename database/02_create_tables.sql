USE SommelierVirtual;
GO

CREATE TABLE dbo.Bodegas (
    BodegaId        INT IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(120) NOT NULL,
    Pais            NVARCHAR(60)  NOT NULL,
    Region          NVARCHAR(80)  NOT NULL,
    AnioFundacion   SMALLINT      NULL,
    CONSTRAINT PK_Bodegas PRIMARY KEY (BodegaId),
    CONSTRAINT UQ_Bodegas_Nombre UNIQUE (Nombre),
    CONSTRAINT CK_Bodegas_Anio CHECK (AnioFundacion IS NULL OR AnioFundacion BETWEEN 1000 AND 2100)
);
GO

CREATE TABLE dbo.Vinos (
    VinoId          INT IDENTITY(1,1) NOT NULL,
    BodegaId        INT           NOT NULL,
    Nombre          NVARCHAR(150) NOT NULL,
    Tipo            NVARCHAR(20)  NOT NULL,
    Uva             NVARCHAR(120) NOT NULL,
    Anada           SMALLINT      NULL,
    Graduacion      DECIMAL(3,1)  NOT NULL,
    Crianza         NVARCHAR(40)  NULL,
    Denominacion    NVARCHAR(80)  NOT NULL,
    Descripcion     NVARCHAR(MAX) NULL,
    CONSTRAINT PK_Vinos PRIMARY KEY (VinoId),
    CONSTRAINT FK_Vinos_Bodegas FOREIGN KEY (BodegaId) REFERENCES dbo.Bodegas (BodegaId),
    CONSTRAINT CK_Vinos_Tipo CHECK (Tipo IN (N'Tinto', N'Blanco', N'Rosado', N'Espumoso', N'Dulce')),
    CONSTRAINT CK_Vinos_Graduacion CHECK (Graduacion BETWEEN 5 AND 23)
);
GO

CREATE TABLE dbo.NotasCata (
    NotaId          INT IDENTITY(1,1) NOT NULL,
    VinoId          INT           NOT NULL,
    Vista           NVARCHAR(300) NULL,
    Nariz           NVARCHAR(500) NULL,
    Boca            NVARCHAR(500) NULL,
    Maridaje        NVARCHAR(300) NULL,
    Puntuacion      TINYINT       NOT NULL,
    Catador         NVARCHAR(100) NOT NULL,
    FechaCata       DATE          NOT NULL CONSTRAINT DF_NotasCata_Fecha DEFAULT (CAST(SYSDATETIME() AS DATE)),
    CONSTRAINT PK_NotasCata PRIMARY KEY (NotaId),
    CONSTRAINT FK_NotasCata_Vinos FOREIGN KEY (VinoId) REFERENCES dbo.Vinos (VinoId) ON DELETE CASCADE,
    CONSTRAINT CK_NotasCata_Puntuacion CHECK (Puntuacion BETWEEN 50 AND 100)
);
GO

CREATE TABLE dbo.Inventario (
    InventarioId    INT IDENTITY(1,1) NOT NULL,
    VinoId          INT           NOT NULL,
    Stock           INT           NOT NULL CONSTRAINT DF_Inventario_Stock DEFAULT (0),
    PrecioCompra    DECIMAL(10,2) NOT NULL,
    PrecioVenta     DECIMAL(10,2) NOT NULL,
    ActualizadoEn   DATETIME2(0)  NOT NULL CONSTRAINT DF_Inventario_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Inventario PRIMARY KEY (InventarioId),
    CONSTRAINT FK_Inventario_Vinos FOREIGN KEY (VinoId) REFERENCES dbo.Vinos (VinoId) ON DELETE CASCADE,
    CONSTRAINT UQ_Inventario_Vino UNIQUE (VinoId),
    CONSTRAINT CK_Inventario_Stock CHECK (Stock >= 0),
    CONSTRAINT CK_Inventario_Precios CHECK (PrecioCompra > 0 AND PrecioVenta >= PrecioCompra)
);
GO

CREATE INDEX IX_Vinos_BodegaId ON dbo.Vinos (BodegaId);
CREATE INDEX IX_Vinos_Denominacion ON dbo.Vinos (Denominacion) INCLUDE (Nombre, Tipo);
CREATE INDEX IX_Vinos_Tipo ON dbo.Vinos (Tipo) INCLUDE (Nombre, Uva, Anada);
CREATE INDEX IX_NotasCata_VinoId ON dbo.NotasCata (VinoId) INCLUDE (Puntuacion);
GO

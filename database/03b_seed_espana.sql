USE SommelierVirtual;
GO

-- Vinos españoles por denominación de origen

INSERT INTO dbo.Bodegas (Nombre, Pais, Region, AnioFundacion) VALUES
(N'Bodega Pesquera', N'España', N'Ribera del Duero', 1972),
(N'Bodegas Emilio Moro', N'España', N'Ribera del Duero', NULL),
(N'Dominio de Pingus', N'España', N'Ribera del Duero', 1995),
(N'Bodegas Aalto', N'España', N'Ribera del Duero', 1999),
(N'Bodegas Protos', N'España', N'Ribera del Duero', 1927),
(N'La Rioja Alta', N'España', N'Rioja', 1890),
(N'CVNE', N'España', N'Rioja', 1879),
(N'Contino', N'España', N'Rioja', 1973),
(N'Remelluri', N'España', N'Rioja', NULL),
(N'Marqués de Murrieta', N'España', N'Rioja', 1852),
(N'Bodegas Roda', N'España', N'Rioja', 1987),
(N'Artadi', N'España', N'Rioja', NULL),
(N'Martín Códax', N'España', N'Rías Baixas', 1986),
(N'Granbazán', N'España', N'Rías Baixas', NULL),
(N'Terras Gauda', N'España', N'Rías Baixas', NULL),
(N'Pazo Baión', N'España', N'Rías Baixas', NULL),
(N'Bodegas Belondrade', N'España', N'Rueda', NULL),
(N'José Pariente', N'España', N'Rueda', NULL),
(N'Clos Mogador', N'España', N'Priorat', NULL),
(N'Álvaro Palacios', N'España', N'Priorat', NULL),
(N'Scala Dei', N'España', N'Priorat', NULL),
(N'Bodegas Numanthia', N'España', N'Toro', NULL),
(N'Descendientes de J. Palacios', N'España', N'Bierzo', NULL),
(N'Raúl Pérez', N'España', N'Bierzo', NULL),
(N'Bodegas Juan Gil', N'España', N'Jumilla', NULL),
(N'Casa Castillo', N'España', N'Jumilla', NULL),
(N'Bodegas Chivite', N'España', N'Navarra', NULL),
(N'Familia Torres', N'España', N'Penedès', NULL),
(N'Recaredo', N'España', N'Penedès', NULL),
(N'Juvé & Camps', N'España', N'Penedès', NULL),
(N'González Byass', N'España', N'Jerez-Xérès-Sherry', NULL),
(N'Lustau', N'España', N'Jerez-Xérès-Sherry', NULL),
(N'Bodega Enate', N'España', N'Somontano', NULL),
(N'Rafael Palacios', N'España', N'Valdeorras', NULL),
(N'Txomin Etxaniz', N'España', N'Getariako Txakolina', NULL),
(N'Ànima Negra', N'España', N'Mallorca', NULL),
(N'Joan d''Anguera', N'España', N'Montsant', NULL),
(N'Bodegas Borsao', N'España', N'Campo de Borja', NULL),
(N'Emilio Rojo', N'España', N'Ribeiro', NULL);
GO

SELECT * INTO #Nuevos FROM (VALUES
(N'Bodega Pesquera', N'Pesquera Crianza', N'Tinto', N'Tempranillo', 2021, 14.5, N'Crianza', N'Ribera del Duero', N'Tinto fino de la casa, potente y muy frutal, con personalidad ribereña.', N'Cereza picota intensa', N'Mora, ciruela negra, vainilla y toques lácteos', N'Carnoso, taninos firmes y final largo', N'Cordero lechal, chuletillas', 92, N'Pablo Serrano', 30, 22.00, 32.50),
(N'Bodega Pesquera', N'Janus Gran Reserva', N'Tinto', N'Tempranillo', 2011, 14.5, N'Gran Reserva', N'Ribera del Duero', N'Gran reserva de añadas excepcionales, profundo y de larga guarda.', N'Granate con ribete teja', N'Cuero, tabaco, higos y especias', N'Sedoso, complejo y persistente', N'Caza, quesos curados', 96, N'Laura Ibáñez', 6, 135.00, 195.00),
(N'Bodegas Emilio Moro', N'Emilio Moro', N'Tinto', N'Tempranillo', 2021, 14.5, N'Crianza', N'Ribera del Duero', N'Tempranillo de viñedos propios, fruta madura y roble bien integrado.', N'Cereza oscura', N'Fruta negra, regaliz y notas balsámicas', N'Jugoso, redondo, taninos pulidos', N'Asados, embutidos', 91, N'Marta Quintana', 40, 17.00, 26.00),
(N'Bodegas Emilio Moro', N'Malleolus', N'Tinto', N'Tempranillo', 2020, 15.0, N'Reserva', N'Ribera del Duero', N'Viñedos de más de treinta años, concentrado y mineral.', N'Rojo cereza muy cubierto', N'Fruta negra, cacao y tostados', N'Intenso, estructurado, final largo', N'Chuletón, caza menor', 94, N'Pablo Serrano', 18, 42.00, 62.00),
(N'Dominio de Pingus', N'Flor de Pingus', N'Tinto', N'Tempranillo', 2020, 14.5, N'Crianza', N'Ribera del Duero', N'Tinto de viñedos viejos, elegante y de gran concentración.', N'Cereza oscura con ribete violáceo', N'Fruta negra, flores y especias', N'Redondo, fresco y muy largo', N'Carnes rojas, setas', 95, N'Laura Ibáñez', 10, 110.00, 160.00),
(N'Bodegas Aalto', N'Aalto', N'Tinto', N'Tempranillo', 2020, 14.5, N'Crianza', N'Ribera del Duero', N'Ribera moderno, preciso y de gran elegancia.', N'Rojo cereza profundo', N'Fruta roja y negra, tostados finos', N'Estructurado, equilibrado, final persistente', N'Solomillo, cordero asado', 94, N'Marta Quintana', 14, 38.00, 55.00),
(N'Bodegas Protos', N'Protos Reserva', N'Tinto', N'Tempranillo', 2018, 14.0, N'Reserva', N'Ribera del Duero', N'Clásico de Peñafiel, equilibrado y de crianza larga.', N'Granate', N'Fruta madura, cuero y especias', N'Elegante, taninos suaves, final largo', N'Lechazo asado', 91, N'Pablo Serrano', 28, 20.00, 29.00),
(N'Bodegas Vega Sicilia', N'Pintia', N'Tinto', N'Tinta de Toro', 2018, 15.0, N'Crianza', N'Toro', N'Proyecto de Vega Sicilia en Toro, potente y de fruta negra.', N'Violáceo, muy cubierto', N'Mora, ciruela, chocolate y especias', N'Potente, tánico, jugoso y largo', N'Carnes a la brasa', 94, N'Laura Ibáñez', 12, 58.00, 85.00),
(N'Bodegas Numanthia', N'Numanthia', N'Tinto', N'Tinta de Toro', 2019, 15.0, N'Reserva', N'Toro', N'Viñedos prefiloxéricos, concentrado y mineral.', N'Rojo picota casi opaco', N'Fruta negra, violetas y tostados', N'Macizo, aterciopelado, final larguísimo', N'Estofados, quesos fuertes', 95, N'Pablo Serrano', 9, 90.00, 130.00),
(N'La Rioja Alta', N'Viña Ardanza Reserva', N'Tinto', N'Tempranillo, Garnacha', 2015, 13.5, N'Reserva', N'Rioja', N'Rioja de larga crianza en roble americano, clásico y elegante.', N'Rojo rubí con ribete teja', N'Fruta roja confitada, vainilla y tabaco', N'Fino, sedoso, acidez viva', N'Cochinillo, cordero asado', 94, N'Laura Ibáñez', 32, 25.00, 36.00),
(N'La Rioja Alta', N'Gran Reserva 904', N'Tinto', N'Tempranillo, Graciano', 2015, 13.5, N'Gran Reserva', N'Rioja', N'Gran reserva con cuatro años en barrica, de enorme finura.', N'Granate brillante', N'Cuero, cerezas en licor y especias dulces', N'Elegante, complejo, final interminable', N'Caza, carnes asadas', 96, N'Marta Quintana', 12, 55.00, 80.00),
(N'CVNE', N'Imperial Reserva', N'Tinto', N'Tempranillo, Graciano, Mazuelo', 2018, 14.0, N'Reserva', N'Rioja', N'Reserva histórico de la casa, equilibrio entre fruta y crianza.', N'Rojo cereza intenso', N'Frutas rojas, cedro y toques de eneldo', N'Fresco, elegante, taninos finos', N'Carnes rojas, quesos curados', 93, N'Pablo Serrano', 20, 35.00, 52.00),
(N'Contino', N'Contino Reserva', N'Tinto', N'Tempranillo, Graciano', 2018, 14.0, N'Reserva', N'Rioja', N'Viñedo singular de Rioja Alavesa, fruta fresca y mineralidad.', N'Rojo picota', N'Frutos negros, flores y especias', N'Fresco, tenso, final largo', N'Cordero, carrilleras', 93, N'Laura Ibáñez', 22, 28.00, 41.00),
(N'Remelluri', N'Remelluri Blanco', N'Blanco', N'Garnacha Blanca, Viura, Chardonnay', 2020, 13.5, N'Crianza', N'Rioja', N'Blanco de altura, mineral y gastronómico.', N'Amarillo pajizo', N'Fruta blanca, hierbas y notas salinas', N'Fresco, untuoso, mineral', N'Pescados al horno, pollo de corral', 92, N'Marta Quintana', 16, 26.00, 39.00),
(N'Marqués de Murrieta', N'Capellanía Blanco Reserva', N'Blanco', N'Viura', 2018, 13.0, N'Reserva', N'Rioja', N'Blanco clásico de Rioja con crianza en barrica, cremoso y complejo.', N'Amarillo dorado', N'Fruta madura, almendra y vainilla', N'Untuoso, equilibrado, final largo', N'Arroces, pescados en salsa', 91, N'Pablo Serrano', 18, 18.00, 27.00),
(N'Bodegas Roda', N'Roda I Reserva', N'Tinto', N'Tempranillo', 2017, 14.0, N'Reserva', N'Rioja', N'Estilo moderno de Haro, fruta negra y fresca.', N'Rojo cereza oscuro', N'Fruta negra, tostados y especias', N'Potente, fresco, taninos finos', N'Carnes a la brasa', 94, N'Marta Quintana', 15, 40.00, 58.00),
(N'Artadi', N'Viñas de Gain', N'Tinto', N'Tempranillo', 2020, 14.5, N'Crianza', N'Rioja', N'Rioja Alavesa de viñedos propios, fruta y frescura.', N'Rojo cereza vivo', N'Frutos rojos, flores y notas minerales', N'Fresco, jugoso y de buen final', N'Embutidos, platos de cuchara', 91, N'Pablo Serrano', 24, 20.00, 30.00),
(N'Martín Códax', N'Martín Códax Albariño', N'Blanco', N'Albariño', 2023, 12.5, NULL, N'Rías Baixas', N'El albariño de referencia, fresco y aromático.', N'Amarillo pajizo con reflejos verdosos', N'Manzana, flor blanca y cítricos', N'Fresco, salino, de buena acidez', N'Marisco, pescado, pulpo', 89, N'Marta Quintana', 60, 8.00, 13.50),
(N'Granbazán', N'Granbazán Etiqueta Ámbar', N'Blanco', N'Albariño', 2023, 12.5, NULL, N'Rías Baixas', N'Albariño del Salnés, afrutado y untuoso.', N'Amarillo brillante', N'Melocotón, hierba luisa y frutas tropicales', N'Untuoso, fresco, final cítrico', N'Mejillones, arroces de marisco', 90, N'Laura Ibáñez', 45, 10.00, 16.50),
(N'Pazo Baión', N'Pazo Baión Albariño', N'Blanco', N'Albariño', 2022, 12.5, NULL, N'Rías Baixas', N'Albariño del Val do Salnés, floral y mineral.', N'Pajizo verdoso', N'Flores blancas, pera y notas yodadas', N'Equilibrado, salino y persistente', N'Ostras, merluza', 90, N'Pablo Serrano', 34, 11.00, 17.50),
(N'Terras Gauda', N'Terras Gauda O Rosal', N'Blanco', N'Albariño, Loureiro, Caíño Blanco', 2023, 12.5, NULL, N'Rías Baixas', N'Ensamblaje de O Rosal, aromático y de gran frescura.', N'Amarillo limón', N'Cítricos, hierba fresca y fruta de hueso', N'Fresco, largo, con amargor agradable', N'Pescado a la plancha, mariscos', 91, N'Marta Quintana', 38, 11.50, 18.00),
(N'Bodegas Belondrade', N'Belondrade y Lurton', N'Blanco', N'Verdejo', 2021, 13.5, N'Crianza sobre lías', N'Rueda', N'Verdejo fermentado en barrica, complejo y cremoso.', N'Amarillo dorado', N'Fruta madura, hierbas y tostados suaves', N'Graso, largo y mineral', N'Pescados azules, aves', 93, N'Laura Ibáñez', 14, 28.00, 42.00),
(N'José Pariente', N'José Pariente Verdejo', N'Blanco', N'Verdejo', 2023, 13.0, NULL, N'Rueda', N'Verdejo de viñedos viejos, fresco y expresivo.', N'Amarillo verdoso', N'Hinojo, pomelo y hierba recién cortada', N'Vivo, sápido, final amargoso', N'Ensaladas, marisco', 89, N'Pablo Serrano', 42, 8.50, 14.00),
(N'Clos Mogador', N'Clos Mogador', N'Tinto', N'Garnacha, Cariñena, Syrah', 2020, 14.5, N'Reserva', N'Priorat', N'Icono del Priorat, de suelos de licorella y gran mineralidad.', N'Rojo granate profundo', N'Fruta negra, hierbas de monte y mineral', N'Intenso, tenso y larguísimo', N'Estofados, caza', 96, N'Laura Ibáñez', 8, 75.00, 110.00),
(N'Álvaro Palacios', N'Finca Dofí', N'Tinto', N'Garnacha, Cariñena, Syrah', 2021, 14.5, N'Crianza', N'Priorat', N'Garnacha del Priorat, fruta intensa y especiada.', N'Cereza oscura', N'Frutos negros, especias y licorella', N'Amplio, fresco, taninos redondos', N'Cordero, carnes de caza', 94, N'Marta Quintana', 10, 60.00, 88.00),
(N'Scala Dei', N'Scala Dei Negre', N'Tinto', N'Garnacha, Cariñena', 2021, 14.0, N'Crianza', N'Priorat', N'Priorat clásico y accesible, de fruta madura y toques minerales.', N'Rojo cereza', N'Frutos rojos, hierbas y pizarra', N'Fresco, amable y bien estructurado', N'Platos de cuchara, carnes rojas', 90, N'Pablo Serrano', 26, 16.00, 24.00),
(N'Descendientes de J. Palacios', N'Pétalos', N'Tinto', N'Mencía', 2021, 14.0, N'Crianza', N'Bierzo', N'Mencía fresca y floral del Bierzo.', N'Rojo cereza con reflejos violáceos', N'Frutas rojas, violetas y notas minerales', N'Fresco, sedoso, final sápido', N'Pulpo, carnes blancas, embutidos', 92, N'Laura Ibáñez', 24, 17.00, 25.50),
(N'Raúl Pérez', N'Ultreia Saint Jacques', N'Tinto', N'Mencía', 2020, 13.5, N'Crianza', N'Bierzo', N'Mencía de viñedos viejos, elegante y mineral.', N'Rojo rubí', N'Frutos rojos, flores y piedra húmeda', N'Fino, fresco y de acidez vibrante', N'Cecina, setas', 91, N'Marta Quintana', 20, 14.00, 21.50),
(N'Bodegas Juan Gil', N'Juan Gil 12 Meses', N'Tinto', N'Monastrell', 2021, 15.0, N'Crianza', N'Jumilla', N'Monastrell de altura, potente y de gran valor.', N'Rojo picota intenso', N'Mora, ciruela, especias y chocolate', N'Carnoso, sabroso y de taninos amables', N'Carnes asadas, arroces con carne', 90, N'Pablo Serrano', 50, 8.50, 13.90),
(N'Casa Castillo', N'Las Gravas', N'Tinto', N'Monastrell, Garnacha, Syrah', 2019, 15.0, N'Reserva', N'Jumilla', N'Monastrell de finca singular, concentrado y fresco.', N'Granate oscuro', N'Fruta negra, hierbas mediterráneas y tostados', N'Potente, equilibrado, final largo', N'Cordero, estofados', 93, N'Laura Ibáñez', 12, 28.00, 42.00),
(N'Bodegas Chivite', N'Gran Feudo Rosado', N'Rosado', N'Garnacha', 2023, 13.0, NULL, N'Navarra', N'Rosado navarro clásico, fresco y afrutado.', N'Rosa frambuesa', N'Fresa, frambuesa y caramelo suave', N'Ligero, goloso y de acidez viva', N'Ensaladas, pastas, arroces', 88, N'Marta Quintana', 36, 5.00, 8.90),
(N'Bodegas Chivite', N'Colección 125 Chardonnay', N'Blanco', N'Chardonnay', 2020, 13.5, N'Crianza', N'Navarra', N'Chardonnay navarro con fermentación en barrica.', N'Dorado pálido', N'Fruta madura, mantequilla y tostados', N'Untuoso, fresco y de final largo', N'Pescados azules, quesos suaves', 92, N'Pablo Serrano', 14, 18.00, 28.00),
(N'Familia Torres', N'Mas La Plana', N'Tinto', N'Cabernet Sauvignon', 2018, 14.5, N'Reserva', N'Penedès', N'Cabernet pionero del Penedès, estructurado y elegante.', N'Rojo cereza profundo', N'Cassis, notas vegetales suaves y especias', N'Potente, aterciopelado, taninos firmes', N'Carnes rojas, caza', 93, N'Laura Ibáñez', 16, 32.00, 47.00),
(N'Familia Torres', N'Viña Esmeralda', N'Blanco', N'Moscatel, Gewürztraminer', 2023, 11.5, NULL, N'Penedès', N'Blanco aromático y ligero, muy fácil de beber.', N'Amarillo pálido', N'Rosas, lichi y cítricos', N'Ligero, fresco y de ligero dulzor', N'Aperitivo, cocina asiática', 87, N'Marta Quintana', 44, 6.00, 10.50),
(N'Recaredo', N'Recaredo Brut Nature Reserva', N'Espumoso', N'Xarel·lo, Macabeo, Parellada', 2019, 12.0, N'Gran Reserva', N'Cava', N'Cava de larga crianza, sin azúcar añadido, de gran precisión.', N'Dorado con burbuja fina', N'Brioche, manzana asada y frutos secos', N'Seco, cremoso y muy fresco', N'Ibéricos, pescados, aperitivo', 94, N'Pablo Serrano', 18, 24.00, 36.00),
(N'Juvé & Camps', N'Reserva de la Familia', N'Espumoso', N'Macabeo, Xarel·lo, Parellada', 2020, 11.5, N'Gran Reserva', N'Cava', N'Cava clásico de reserva, fino y equilibrado.', N'Amarillo pálido, burbuja persistente', N'Manzana, brioche y hierbas', N'Cremoso, fresco y largo', N'Aperitivos, mariscos, arroces', 91, N'Marta Quintana', 30, 13.00, 20.00),
(N'González Byass', N'Tío Pepe Fino', N'Blanco', N'Palomino Fino', NULL, 15.0, N'Crianza biológica', N'Jerez-Xérès-Sherry', N'El fino de referencia, seco, punzante y salino.', N'Amarillo pajizo', N'Almendra, levadura y flor', N'Seco, ligero, final salino', N'Jamón ibérico, aceitunas, pescaíto frito', 91, N'Laura Ibáñez', 48, 7.00, 11.50),
(N'Lustau', N'Oloroso Don Nuño', N'Blanco', N'Palomino Fino', NULL, 20.0, N'Crianza oxidativa', N'Jerez-Xérès-Sherry', N'Oloroso seco de gran carácter, con notas de frutos secos y madera noble.', N'Caoba brillante', N'Nueces, cuero y tabaco', N'Seco, potente, profundo y largo', N'Rabo de toro, quesos curados', 93, N'Pablo Serrano', 16, 14.00, 22.00),
(N'Lustau', N'Pedro Ximénez San Emilio', N'Dulce', N'Pedro Ximénez', NULL, 17.0, N'Solera', N'Jerez-Xérès-Sherry', N'PX denso y untuoso de pasas, café y miel.', N'Caoba casi negro', N'Pasas, higos, café y regaliz', N'Denso, dulce y de acidez equilibrada', N'Helado de vainilla, chocolate, quesos azules', 95, N'Marta Quintana', 20, 16.00, 25.00),
(N'Bodega Enate', N'Enate Crianza', N'Tinto', N'Tempranillo, Cabernet Sauvignon', 2019, 14.0, N'Crianza', N'Somontano', N'Somontano moderno y equilibrado.', N'Rojo cereza', N'Fruta roja, especias suaves y tostados', N'Fresco, amable y bien estructurado', N'Embutidos, carnes asadas', 88, N'Laura Ibáñez', 32, 8.00, 13.00),
(N'Bodega Enate', N'Enate Chardonnay 234', N'Blanco', N'Chardonnay', 2022, 13.5, N'Crianza', N'Somontano', N'Chardonnay de Somontano, fresco y cremoso.', N'Amarillo pajizo', N'Manzana, piña y notas de brioche', N'Fresco, graso y de final cítrico', N'Verduras asadas, pollo', 88, N'Pablo Serrano', 26, 9.50, 15.00),
(N'Rafael Palacios', N'Louro Godello', N'Blanco', N'Godello', 2022, 13.5, N'Crianza', N'Valdeorras', N'Godello de Valdeorras, fresco, mineral y de largo recorrido.', N'Amarillo verdoso', N'Fruta blanca, hierbas y notas minerales', N'Fresco, mineral y de gran persistencia', N'Pescados, mariscos', 92, N'Marta Quintana', 20, 14.00, 21.00),
(N'Txomin Etxaniz', N'Txakoli Txomin Etxaniz', N'Blanco', N'Hondarrabi Zuri', 2023, 11.0, NULL, N'Getariako Txakolina', N'Txakoli vivo y ligeramente burbujeante, ideal con pescado.', N'Amarillo pálido con reflejos verdes', N'Manzana verde, cítricos y notas salinas', N'Seco, ácido, vivo y refrescante', N'Anchoas, pescados a la parrilla', 88, N'Laura Ibáñez', 40, 9.00, 14.50),
(N'Ànima Negra', N'ÀN/2', N'Tinto', N'Callet, Manto Negro, Fogoneu', 2021, 14.0, N'Crianza', N'Mallorca', N'Tinto mallorquín de variedades autóctonas, fresco y especiado.', N'Rojo cereza claro', N'Frutos rojos, hierbas y pimienta', N'Fresco, ligero y de acidez viva', N'Cochinillo, arroces de carne', 89, N'Marta Quintana', 14, 16.00, 24.00),
(N'Joan d''Anguera', N'Finca L''Argata', N'Tinto', N'Syrah', 2020, 14.5, N'Crianza', N'Montsant', N'Syrah de Montsant, intenso y especiado.', N'Rojo granate con ribete violáceo', N'Mora, pimienta negra y regaliz', N'Potente, goloso y de final largo', N'Carnes a la brasa, quesos curados', 90, N'Pablo Serrano', 18, 13.00, 20.00),
(N'Bodegas Borsao', N'Borsao Selección', N'Tinto', N'Garnacha, Tempranillo', 2021, 14.0, N'Crianza', N'Campo de Borja', N'Garnacha del Moncayo de gran relación calidad-precio.', N'Rojo cereza', N'Fruta roja madura y especias', N'Redondo, frutal y sabroso', N'Platos de cuchara, embutidos', 87, N'Laura Ibáñez', 55, 5.50, 9.20),
(N'Emilio Rojo', N'Emilio Rojo', N'Blanco', N'Treixadura, Lado, Albariño', 2022, 12.5, NULL, N'Ribeiro', N'Blanco del Ribeiro, de largo recorrido y complejidad.', N'Amarillo pálido', N'Flores blancas, fruta de hueso y hierbas', N'Fresco, complejo y mineral', N'Pescados, arroces con marisco', 93, N'Marta Quintana', 10, 24.00, 36.00)
) AS t (Bodega, Nombre, Tipo, Uva, Anada, Graduacion, Crianza, Denominacion, Descripcion, Vista, Nariz, Boca, Maridaje, Puntuacion, Catador, Stock, PrecioCompra, PrecioVenta);
GO

INSERT INTO dbo.Vinos (BodegaId, Nombre, Tipo, Uva, Anada, Graduacion, Crianza, Denominacion, Descripcion)
SELECT b.BodegaId, n.Nombre, n.Tipo, n.Uva, n.Anada, n.Graduacion, n.Crianza, n.Denominacion, n.Descripcion
FROM #Nuevos n INNER JOIN dbo.Bodegas b ON b.Nombre = n.Bodega;
GO

INSERT INTO dbo.NotasCata (VinoId, Vista, Nariz, Boca, Maridaje, Puntuacion, Catador)
SELECT v.VinoId, n.Vista, n.Nariz, n.Boca, n.Maridaje, n.Puntuacion, n.Catador
FROM #Nuevos n INNER JOIN dbo.Vinos v ON v.Nombre = n.Nombre;
GO

INSERT INTO dbo.Inventario (VinoId, Stock, PrecioCompra, PrecioVenta)
SELECT v.VinoId, n.Stock, n.PrecioCompra, n.PrecioVenta
FROM #Nuevos n INNER JOIN dbo.Vinos v ON v.Nombre = n.Nombre;
GO

DROP TABLE #Nuevos;
GO

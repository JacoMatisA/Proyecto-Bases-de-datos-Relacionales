-- PROYECTO FINAL: PlayScope - SISTEMA HÍBRIDO RELACIONAL-VECTORIAL (RAG)

-- Se habilita la extension vectorial; para pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Limpieza preventiva en orden inverso de dependencias, se vacian
DROP TABLE IF EXISTS embeddings_imagen CASCADE;
DROP TABLE IF EXISTS embeddings_texto CASCADE;
DROP TABLE IF EXISTS evaluaciones CASCADE;
DROP TABLE IF EXISTS resultados CASCADE;
DROP TABLE IF EXISTS consultas CASCADE;
DROP TABLE IF EXISTS imagenes CASCADE;
DROP TABLE IF EXISTS documentos CASCADE;
DROP TABLE IF EXISTS recomendaciones CASCADE;
DROP TABLE IF EXISTS favoritos CASCADE;
DROP TABLE IF EXISTS resenas CASCADE;
DROP TABLE IF EXISTS duracion CASCADE;
DROP TABLE IF EXISTS juegos_modos_juego CASCADE;
DROP TABLE IF EXISTS juegos_plataforma CASCADE;
DROP TABLE IF EXISTS generos_juego CASCADE;
DROP TABLE IF EXISTS participaciones CASCADE;
DROP TABLE IF EXISTS personajes CASCADE;
DROP TABLE IF EXISTS juegos CASCADE;
DROP TABLE IF EXISTS generos CASCADE;
DROP TABLE IF EXISTS modos_juego CASCADE;
DROP TABLE IF EXISTS plataformas CASCADE;
DROP TABLE IF EXISTS desarrolladoras CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

--Tablas sin dependencias primero

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(100) NOT NULL,
    correo_usuario VARCHAR(150) NOT NULL UNIQUE,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo', 'Inactivo', 'Suspendido'))
);

CREATE TABLE desarrolladoras (
    id_desarrolladora SERIAL PRIMARY KEY,
    nombre_desarrolladora VARCHAR(150) NOT NULL UNIQUE,
    pais_desarrolladora VARCHAR(100)
);

CREATE TABLE plataformas (
    id_plataforma SERIAL PRIMARY KEY,
    nombre_plataforma VARCHAR(100) NOT NULL UNIQUE,
    fabricante_plataforma VARCHAR(100) NOT NULL
);

CREATE TABLE modos_juego (
    id_modo SERIAL PRIMARY KEY,
    nombre_modo VARCHAR(80) NOT NULL UNIQUE,
    requiere_conexion BOOLEAN NOT NULL DEFAULT FALSE,
    descripcion_modo TEXT
);

CREATE TABLE generos (
    id_genero SERIAL PRIMARY KEY,
    nombre_genero VARCHAR(80) NOT NULL UNIQUE,
    descripcion_genero TEXT
);

CREATE TABLE personajes (
    id_personaje SERIAL PRIMARY KEY,
    nombre_personaje VARCHAR(120) NOT NULL,
    biografia TEXT
);


CREATE TABLE juegos (
    id_juego SERIAL PRIMARY KEY,
    id_desarrolladora INT NOT NULL REFERENCES desarrolladoras(id_desarrolladora) ON DELETE RESTRICT,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    fecha_lanzamiento DATE NOT NULL,
    clasificacion_edad VARCHAR(20),
    precio DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (precio >= 0)
);

CREATE TABLE participaciones (
    id_participacion SERIAL PRIMARY KEY,
    id_personaje INT NOT NULL REFERENCES personajes(id_personaje) ON DELETE CASCADE,
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    papel_personaje VARCHAR(60) NOT NULL,
    es_jugable BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (id_personaje, id_juego)
);

-- Entidad Asociativa (Géneros por Juego)
CREATE TABLE generos_juego (
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    id_genero INT NOT NULL REFERENCES generos(id_genero) ON DELETE RESTRICT,
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    orden_prioridad SMALLINT DEFAULT 1,
    peso_relevancia DECIMAL(3,2) DEFAULT 1.00 CHECK (peso_relevancia BETWEEN 0.00 AND 1.00),
    PRIMARY KEY (id_juego, id_genero)
);

-- Entidad Asociativa (Versiones por Plataforma) 
CREATE TABLE juegos_plataforma (
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    id_plataforma INT NOT NULL REFERENCES plataformas(id_plataforma) ON DELETE RESTRICT,
    peso_gb DECIMAL(6,2) NOT NULL CHECK (peso_gb > 0),
    fecha_lanzamiento DATE,
    precio_tienda DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (precio_tienda >= 0),
    PRIMARY KEY (id_juego, id_plataforma)
);

-- Entidad Asociativa (Soporte de Modos por Juego)
CREATE TABLE juegos_modos_juego (
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    id_modo INT NOT NULL REFERENCES modos_juego(id_modo) ON DELETE RESTRICT,
    maximo_jugadores INT NOT NULL DEFAULT 1 CHECK (maximo_jugadores >= 1),
    soporte_pantalla_dividida BOOLEAN NOT NULL DEFAULT FALSE,
    permite_crossplay BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_juego, id_modo)
);


CREATE TABLE duracion (
    id_juego INT PRIMARY KEY REFERENCES juegos(id_juego) ON DELETE CASCADE,
    horas_historia_principal DECIMAL(5,1) NOT NULL DEFAULT 0.0 CHECK (horas_historia_principal >= 0),
    horas_extras DECIMAL(5,1) NOT NULL DEFAULT 0.0 CHECK (horas_extras >= 0),
    horas_completista100 DECIMAL(5,1) NOT NULL DEFAULT 0.0 CHECK (horas_completista100 >= 0)
);



CREATE TABLE resenas (
    id_resena SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    calificacion SMALLINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    contenido_resena TEXT,
    fecha_resena TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    horas_jugadas DECIMAL(6,1) DEFAULT 0.0 CHECK (horas_jugadas >= 0),
    UNIQUE (id_usuario, id_juego)
);

CREATE TABLE favoritos (
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    fecha_agregado TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nota_personal VARCHAR(200),
    PRIMARY KEY (id_usuario, id_juego)
);

CREATE TABLE recomendaciones (
    id_recomendacion SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_juego INT NOT NULL REFERENCES juegos(id_juego) ON DELETE CASCADE,
    score_afinidad DECIMAL(4,3) NOT NULL CHECK (score_afinidad BETWEEN 0.000 AND 1.000),
    motivo VARCHAR(255),
    fecha_generada TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE documentos (
    id_doc SERIAL PRIMARY KEY,
    id_juego INT NOT NULL UNIQUE REFERENCES juegos(id_juego) ON DELETE CASCADE,
    titulo VARCHAR(200) NOT NULL,
    idioma VARCHAR(10) NOT NULL DEFAULT 'es',
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    fuente VARCHAR(100) NOT NULL,
    contenido_texto TEXT NOT NULL
);

-- Catálogo de imágenes para CLIP
CREATE TABLE imagenes (
    id_img SERIAL PRIMARY KEY,
    id_doc INT NOT NULL REFERENCES documentos(id_doc) ON DELETE CASCADE,
    ruta_archivo VARCHAR(255) NOT NULL,
    descripcion TEXT,
    tipo_imagen VARCHAR(50) DEFAULT 'Portada',
    formato VARCHAR(10) DEFAULT 'JPEG'
);

-- Registro de consultas en lenguaje natural
CREATE TABLE consultas (
    id_consulta SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    texto_pregunta TEXT NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE resultados (
    id_resultado SERIAL PRIMARY KEY,
    id_consulta INT NOT NULL REFERENCES consultas(id_consulta) ON DELETE CASCADE,
    id_doc INT REFERENCES documentos(id_doc) ON DELETE SET NULL,
    id_img INT REFERENCES imagenes(id_img) ON DELETE SET NULL,
    score_similitud DECIMAL(5,4) NOT NULL CHECK (score_similitud BETWEEN 0.0000 AND 1.0000),
    orden_ranking INT NOT NULL DEFAULT 1,
    
    CONSTRAINT chk_resultado_tipo CHECK (
        (id_doc IS NOT NULL AND id_img IS NULL) OR 
        (id_doc IS NULL AND id_img IS NOT NULL)
    )
);


CREATE TABLE evaluaciones (
    id_eval SERIAL PRIMARY KEY,
    id_consulta INT NOT NULL UNIQUE REFERENCES consultas(id_consulta) ON DELETE CASCADE,
    faithfulness DECIMAL(4,3) NOT NULL CHECK (faithfulness BETWEEN 0.000 AND 1.000),
    answer_relevancy DECIMAL(4,3) NOT NULL CHECK (answer_relevancy BETWEEN 0.000 AND 1.000),
    context_recall DECIMAL(4,3) NOT NULL CHECK (context_recall BETWEEN 0.000 AND 1.000),
    modelo_eval VARCHAR(100) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);




CREATE TABLE embeddings_texto (
    id_embedding SERIAL PRIMARY KEY,
    id_doc INT NOT NULL REFERENCES documentos(id_doc) ON DELETE CASCADE,
    chunk_id INT NOT NULL,
    estrategia_chunking VARCHAR(20) NOT NULL CHECK (
        estrategia_chunking IN ('fixed-size', 'sentence-aware', 'semantic')
    ),
    chunk_texto TEXT NOT NULL,
    vector_embedding VECTOR(384) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    UNIQUE (id_doc, estrategia_chunking, chunk_id)
);


CREATE TABLE embeddings_imagen (
    id_embedding SERIAL PRIMARY KEY,
    id_img INT NOT NULL REFERENCES imagenes(id_img) ON DELETE CASCADE,
    vector_embedding VECTOR(512) NOT NULL,
    modelo VARCHAR(100) NOT NULL
);


CREATE INDEX idx_embeddings_texto_hnsw 
    ON embeddings_texto USING hnsw (vector_embedding vector_cosine_ops);

CREATE INDEX idx_embeddings_imagen_hnsw 
    ON embeddings_imagen USING hnsw (vector_embedding vector_cosine_ops);


CREATE INDEX idx_juegos_precio ON juegos(precio);
CREATE INDEX idx_juegos_fecha ON juegos(fecha_lanzamiento);
CREATE INDEX idx_resultados_consulta ON resultados(id_consulta);
CREATE INDEX idx_documentos_juego ON documentos(id_juego);

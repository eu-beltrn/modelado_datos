-- Descripción: Modelo analítico dimensional para Recursos Humanos

-- 1. PREPARACIÓN DEL ENTORNO Y LIMPIEZA
CREATE DATABASE IF NOT EXISTS hr_analytics;
USE hr_analytics;

-- Drop en orden inverso a las dependencias para evitar errores de restricción de FK
DROP VIEW IF EXISTS vw_analisis_salarial;
DROP TABLE IF EXISTS fact_salarios;
DROP TABLE IF EXISTS dim_empleados;
DROP TABLE IF EXISTS dim_departamentos;

-- 2. DIMENSIÓN: DEPARTAMENTOS
CREATE TABLE dim_departamentos (
    departamento_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Llave subrogada del departamento',
    nombre_departamento VARCHAR(100) NOT NULL UNIQUE COMMENT 'Nombre oficial del departamento',
    centro_costo VARCHAR(20) NOT NULL COMMENT 'Código financiero para asignación de presupuesto',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Bandera de borrado lógico (Soft Delete)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tabla de dimensión que almacena la estructura organizacional';

-- 3. DIMENSIÓN: EMPLEADOS
CREATE TABLE dim_empleados (
    empleado_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Llave subrogada del empleado',
    departamento_id INT NOT NULL COMMENT 'Referencia a dim_departamentos',
    nombre_completo VARCHAR(150) NOT NULL,
    email_corporativo VARCHAR(150) UNIQUE NOT NULL,
    nivel_seniority ENUM('Junior', 'Semi-Senior', 'Senior', 'Lead', 'Manager') NOT NULL COMMENT 'Nivel de experiencia/jerarquía',
    fecha_contratacion DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Bandera para saber si el empleado sigue en la empresa',
    
    CONSTRAINT fk_departamento 
        FOREIGN KEY (departamento_id) 
        REFERENCES dim_departamentos(departamento_id)
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tabla de dimensión con información demográfica y laboral del empleado';

CREATE INDEX idx_emp_departamento ON dim_empleados(departamento_id);
CREATE INDEX idx_emp_is_active ON dim_empleados(is_active);

-- 4. TABLA DE HECHOS (FACT): SALARIOS
CREATE TABLE fact_salarios (
    salario_id INT AUTO_INCREMENT PRIMARY KEY,
    empleado_id INT NOT NULL COMMENT 'Referencia a dim_empleados',
    fecha_pago DATE NOT NULL COMMENT 'Fecha en que se generó la nómina',
    salario_base DECIMAL(12, 2) NOT NULL CHECK (salario_base > 0),
    bonificaciones DECIMAL(12, 2) DEFAULT 0.00,
    impuestos DECIMAL(12, 2) DEFAULT 0.00,
    -- Columna calculada de forma nativa en MySQL para optimizar lectura
    salario_neto DECIMAL(12, 2) GENERATED ALWAYS AS (salario_base + bonificaciones - impuestos) STORED COMMENT 'Métrica calculada físicamente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_empleado 
        FOREIGN KEY (empleado_id) 
        REFERENCES dim_empleados(empleado_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tabla de hechos transaccional que almacena los pagos de nómina';

CREATE INDEX idx_fact_fecha_pago ON fact_salarios(fecha_pago);
CREATE INDEX idx_fact_empleado ON fact_salarios(empleado_id);

-- 5. POBLADO DE DATOS

-- Inserción de Departamentos
INSERT INTO dim_departamentos (nombre_departamento, centro_costo) VALUES 
('Ingeniería', 'CC-100'),
('Ventas', 'CC-200'),
('Recursos Humanos', 'CC-300'),
('Finanzas', 'CC-400'),
('Operaciones', 'CC-500');

-- Inserción de Empleados
INSERT INTO dim_empleados (departamento_id, nombre_completo, email_corporativo, nivel_seniority, fecha_contratacion) VALUES
(1, 'Carlos Mendoza', 'carlos.mendoza@empresa.com', 'Senior', '2021-03-15'),
(1, 'Ana Torres', 'ana.torres@empresa.com', 'Lead', '2019-11-01'),
(1, 'Luis Ortiz', 'luis.ortiz@empresa.com', 'Junior', '2023-05-20'),
(1, 'Marta Rojas', 'marta.rojas@empresa.com', 'Semi-Senior', '2022-08-10'),
(1, 'Javier Silva', 'javier.silva@empresa.com', 'Senior', '2020-02-14'),
(1, 'Elena Castro', 'elena.castro@empresa.com', 'Junior', '2023-11-05'),
(1, 'Diego Navarro', 'diego.navarro@empresa.com', 'Semi-Senior', '2022-01-25'),
(1, 'Sofía Reyes', 'sofia.reyes@empresa.com', 'Manager', '2018-06-30'),
(2, 'Roberto Gómez', 'roberto.gomez@empresa.com', 'Semi-Senior', '2021-09-12'),
(2, 'Laura Pineda', 'laura.pineda@empresa.com', 'Senior', '2020-04-18'),
(2, 'Andrés Vargas', 'andres.vargas@empresa.com', 'Junior', '2024-01-10'),
(2, 'Carmen López', 'carmen.lopez@empresa.com', 'Lead', '2019-07-22'),
(2, 'Jorge Marín', 'jorge.marin@empresa.com', 'Semi-Senior', '2022-10-30'),
(2, 'Isabel Ramos', 'isabel.ramos@empresa.com', 'Junior', '2023-06-15'),
(2, 'Fernando Gil', 'fernando.gil@empresa.com', 'Manager', '2017-03-05'),
(3, 'Patricia Ruiz', 'patricia.ruiz@empresa.com', 'Lead', '2018-09-20'),
(3, 'Ricardo Soto', 'ricardo.soto@empresa.com', 'Senior', '2020-11-11'),
(3, 'Mónica Cruz', 'monica.cruz@empresa.com', 'Semi-Senior', '2021-05-19'),
(3, 'Óscar Peña', 'oscar.pena@empresa.com', 'Junior', '2023-02-28'),
(3, 'Lorena Mora', 'lorena.mora@empresa.com', 'Manager', '2016-12-01'),
(4, 'Raúl Vega', 'raul.vega@empresa.com', 'Senior', '2019-08-08'),
(4, 'Silvia Blanco', 'silvia.blanco@empresa.com', 'Lead', '2018-01-15'),
(4, 'Héctor León', 'hector.leon@empresa.com', 'Semi-Senior', '2022-04-03'),
(4, 'Diana Ríos', 'diana.rios@empresa.com', 'Junior', '2024-03-01'),
(4, 'Mario Aguilar', 'mario.aguilar@empresa.com', 'Junior', '2023-09-17'),
(4, 'Beatriz Núñez', 'beatriz.nunez@empresa.com', 'Manager', '2017-05-25'),
(5, 'Hugo Salazar', 'hugo.salazar@empresa.com', 'Lead', '2019-10-10'),
(5, 'Camila Paredes', 'camila.paredes@empresa.com', 'Senior', '2020-07-07'),
(5, 'Víctor Campos', 'victor.campos@empresa.com', 'Semi-Senior', '2021-12-12'),
(5, 'Teresa Domínguez', 'teresa.dominguez@empresa.com', 'Junior', '2023-04-22'),
(5, 'Gabriel Fuentes', 'gabriel.fuentes@empresa.com', 'Semi-Senior', '2022-06-08'),
(5, 'Natalia Cárdenas', 'natalia.cardenas@empresa.com', 'Manager', '2015-11-20');

-- Inserción de  Nóminas
INSERT INTO fact_salarios (empleado_id, fecha_pago, salario_base, bonificaciones, impuestos) VALUES
(1, '2026-05-31', 4500.00, 300.00, 960.00),
(2, '2026-05-31', 6500.00, 500.00, 1400.00),
(3, '2026-05-31', 1800.00, 0.00, 360.00),
(4, '2026-05-31', 3200.00, 150.00, 670.00),
(5, '2026-05-31', 4800.00, 400.00, 1040.00),
(6, '2026-05-31', 1900.00, 50.00, 390.00),
(7, '2026-05-31', 3500.00, 200.00, 740.00),
(8, '2026-05-31', 9500.00, 1200.00, 2140.00),
(9, '2026-05-31', 3100.00, 800.00, 780.00),
(10, '2026-05-31', 4200.00, 1000.00, 1040.00),
(11, '2026-05-31', 1700.00, 100.00, 360.00),
(12, '2026-05-31', 6100.00, 1500.00, 1520.00),
(13, '2026-05-31', 2900.00, 400.00, 660.00),
(14, '2026-05-31', 1850.00, 200.00, 410.00),
(15, '2026-05-31', 9000.00, 2500.00, 2300.00),
(16, '2026-05-31', 5800.00, 200.00, 1200.00),
(17, '2026-05-31', 4100.00, 100.00, 840.00),
(18, '2026-05-31', 2800.00, 0.00, 560.00),
(19, '2026-05-31', 1600.00, 0.00, 320.00),
(20, '2026-05-31', 8500.00, 500.00, 1800.00),
(21, '2026-05-31', 5200.00, 300.00, 1100.00),
(22, '2026-05-31', 6800.00, 450.00, 1450.00),
(23, '2026-05-31', 3600.00, 100.00, 740.00),
(24, '2026-05-31', 1750.00, 0.00, 350.00),
(25, '2026-05-31', 1650.00, 0.00, 330.00),
(26, '2026-05-31', 8800.00, 600.00, 1880.00),
(27, '2026-05-31', 6300.00, 250.00, 1310.00),
(28, '2026-05-31', 4700.00, 150.00, 970.00),
(29, '2026-05-31', 3300.00, 100.00, 680.00),
(30, '2026-05-31', 1950.00, 50.00, 400.00),
(31, '2026-05-31', 3400.00, 150.00, 710.00),
(32, '2026-05-31', 9200.00, 800.00, 2000.00);

-- 6. CAPA DE PRESENTACIÓN (Data Mart / BI)
-- Optimizada con CTEs y Window Functions

CREATE OR REPLACE VIEW vw_analisis_salarial AS
-- Definición del CTE
-- Nos permite preparar la base de datos desnormalizada antes de aplicar cálculos analíticos
WITH DatosBase AS (
    SELECT 
        f.salario_id,
        e.empleado_id,
        e.nombre_completo,
        e.nivel_seniority,
        d.departamento_id,
        d.nombre_departamento,
        d.centro_costo,
        f.fecha_pago,
        f.salario_base,
        f.bonificaciones,
        f.salario_neto,
        DATE_FORMAT(f.fecha_pago, '%Y-%m') AS periodo_pago
    FROM 
        fact_salarios f
    INNER JOIN 
        dim_empleados e ON f.empleado_id = e.empleado_id
    INNER JOIN 
        dim_departamentos d ON e.departamento_id = d.departamento_id
    WHERE 
        e.is_active = TRUE AND d.is_active = TRUE
)
-- Consulta con el CTE y Window Functions
SELECT 
    db.salario_id,
    db.empleado_id,
    db.nombre_completo,
    db.nivel_seniority,
    db.nombre_departamento,
    db.centro_costo,
    db.fecha_pago,
    db.salario_base,
    db.salario_neto,
    db.periodo_pago,
    
    -- Genera un ranking de los que más ganan dentro de su propio departamento
    RANK() OVER (
        PARTITION BY db.departamento_id 
        ORDER BY db.salario_neto DESC
    ) AS ranking_salarial_dept,
    
    -- Calcula el salario promedio del departamento para compararlo fila a fila con el salario del empleado
    AVG(db.salario_neto) OVER (
        PARTITION BY db.departamento_id
    ) AS promedio_salarial_dept,
    
    -- Muestra cuánto por encima o por debajo del promedio del departamento está el empleado
    (db.salario_neto - AVG(db.salario_neto) OVER (PARTITION BY db.departamento_id)) AS diff_vs_promedio_dept
    
FROM 
    DatosBase db;
    

-- Descripción: Consultas de validación y análisis de negocio sobre la vista.
USE hr_analytics;

-- 1. VISIÓN GENERAL: Top 10 Empleados mejor pagados
-- Verifica la correcta integración de datos y ordena por la métrica principal.
SELECT 
    nombre_completo,
    nombre_departamento,
    nivel_seniority,
    salario_base,
    salario_neto
FROM 
    vw_analisis_salarial
ORDER BY 
    salario_neto DESC
LIMIT 10;


-- 2. KPIs POR DEPARTAMENTO: Resumen Financiero

SELECT 
    nombre_departamento,
    centro_costo,
    COUNT(empleado_id) AS total_empleados,
    SUM(salario_neto) AS gasto_total_nomina,
    ROUND(AVG(salario_neto), 2) AS salario_promedio,
    MAX(salario_neto) AS salario_maximo
FROM 
    vw_analisis_salarial
GROUP BY 
    nombre_departamento, 
    centro_costo
ORDER BY 
    gasto_total_nomina DESC;

-- 3. AUDITORÍA SALARIAL
-- ¿Qué empleados están ganando POR ENCIMA del promedio de su propio departamento?
SELECT 
    nombre_departamento,
    nombre_completo,
    nivel_seniority,
    salario_neto,
    ROUND(promedio_salarial_dept, 2) AS promedio_del_departamento,
    ROUND(diff_vs_promedio_dept, 2) AS ganancia_sobre_promedio
FROM 
    vw_analisis_salarial
WHERE 
    diff_vs_promedio_dept > 0 -- Solo los que ganan más que la media de su área
ORDER BY 
    ganancia_sobre_promedio DESC;

-- 4. ANÁLISIS DE EQUIDAD
-- Analiza cómo está distribuida el salario según el nivel de experiencia.
SELECT 
    nivel_seniority,
    COUNT(empleado_id) AS cantidad_empleados,
    ROUND(AVG(salario_base), 2) AS salario_base_promedio,
    ROUND(MIN(salario_base), 2) AS salario_minimo,
    ROUND(MAX(salario_base), 2) AS salario_maximo
FROM 
    vw_analisis_salarial
GROUP BY 
    nivel_seniority
ORDER BY 
    salario_base_promedio DESC;

-- 5. RANKING DEPARTAMENTAL
-- Obtiene únicamente al empleado que MÁS GANA dentro de CADA departamento.
SELECT 
    nombre_departamento,
    nombre_completo,
    nivel_seniority,
    salario_neto
FROM 
    vw_analisis_salarial
WHERE 
    ranking_salarial_dept = 1 -- Filtra solo el Top 1 de cada partición
ORDER BY 
    salario_neto DESC;
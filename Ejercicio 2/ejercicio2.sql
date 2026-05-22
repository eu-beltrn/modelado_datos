
-- 1. CREACIÓN DE LA BASE DE DATOS
CREATE DATABASE IF NOT EXISTS hr_nicole_analytics;
USE hr_nicole_analytics;

-- Limpieza preventiva por si necesitas volver a correr el código desde cero
DROP VIEW IF EXISTS vw_analisis_salarial_nicole;
DROP TABLE IF EXISTS fact_salarios;
DROP TABLE IF EXISTS dim_tiempo;
DROP TABLE IF EXISTS dim_empleados;
DROP TABLE IF EXISTS dim_departamentos;


-- 2. CREACIÓN DE DIMENSIÓN: DEPARTAMENTOS
CREATE TABLE dim_departamentos (
    departamento_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_departamento VARCHAR(100) NOT NULL UNIQUE,
    centro_costo VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO dim_departamentos (nombre_departamento, centro_costo) VALUES
('Recursos Humanos', 'CC-001'),
('Tecnología', 'CC-002'),
('Ventas', 'CC-003'),
('Finanzas', 'CC-004'),
('Marketing', 'CC-005');


-- 3. CREACIÓN DE DIMENSIÓN: TIEMPO 
CREATE TABLE dim_tiempo (
    tiempo_id INT PRIMARY KEY,
    mes_nombre VARCHAR(20) NOT NULL,
    trimestre VARCHAR(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO dim_tiempo (tiempo_id, mes_nombre, trimestre) VALUES
(1, 'Enero', 'Q1'), (2, 'Febrero', 'Q1'), (3, 'Marzo', 'Q1'),
(4, 'Abril', 'Q2'), (5, 'Mayo', 'Q2'), (6, 'Junio', 'Q2'),
(7, 'Julio', 'Q3'), (8, 'Agosto', 'Q3'), (9, 'Septiembre', 'Q3'),
(10, 'Octubre', 'Q4'), (11, 'Noviembre', 'Q4'), (12, 'Diciembre', 'Q4');


-- 4. CREACIÓN DE DIMENSIÓN: EMPLEADOS
CREATE TABLE dim_empleados (
    empleado_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    nivel_seniority VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 5. CREACIÓN DE LA TABLA DE HECHOS: SALARIOS
CREATE TABLE fact_salarios (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    empleado_id INT NOT NULL,
    departamento_id INT NOT NULL,
    tiempo_id INT NOT NULL,
    salario_base DECIMAL(10,2) NOT NULL,
    bono DECIMAL(10,2) NOT NULL,
    salario_neto DECIMAL(10,2) GENERATED ALWAYS AS (salario_base + bono) STORED,
    FOREIGN KEY (empleado_id) REFERENCES dim_empleados(empleado_id),
    FOREIGN KEY (departamento_id) REFERENCES dim_departamentos(departamento_id),
    FOREIGN KEY (tiempo_id) REFERENCES dim_tiempo(tiempo_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 6. PROCEDIMIENTO ALMACENADO PARA GENERAR LOS 105 REGISTROS AUTOMÁTICOS
DELIMITER $$
CREATE PROCEDURE GenerarDatosNicole()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_depto INT;
    DECLARE random_mes INT;
    DECLARE random_base DECIMAL(10,2);
    DECLARE random_bono DECIMAL(10,2);
    DECLARE seniority VARCHAR(50);
    
    WHILE i <= 105 DO
        -- Asignamos niveles de experiencia aleatorios
        SET seniority = ELT(FLOOR(1 + RAND() * 4), 'Junior', 'Analista', 'Especialista', 'Gerente');
        
        -- Insertamos empleados con un identificador numérico correlativo uniforme
        INSERT INTO dim_empleados (nombre_completo, nivel_seniority) 
        VALUES (CONCAT('Empleado Nicole ', i), seniority);
        
        -- Generamos valores numéricos aleatorios pero con coherencia empresarial
        SET random_depto = FLOOR(1 + RAND() * 5);
        SET random_mes = FLOOR(1 + RAND() * 12);
        SET random_base = ROUND(900 + (RAND() * 3100), 2);
        SET random_bono = ROUND(50 + (RAND() * 450), 2);
        
        -- Insertamos directamente en la tabla central de hechos
        INSERT INTO fact_salarios (empleado_id, departamento_id, tiempo_id, salario_base, bono)
        VALUES (i, random_depto, random_mes, random_base, random_bono);
        
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Ejecutamos de inmediato el procedimiento creado arriba
CALL GenerarDatosNicole();


-- 7. CAPA DE PRESENTACIÓN: VISTA ANALÍTICA CONSOLIDADA 
CREATE VIEW vw_analisis_salarial_nicole AS
SELECT 
    f.fact_id,
    e.nombre_completo,
    e.nivel_seniority,
    d.nombre_departamento,
    d.centro_costo,
    t.tiempo_id,
    t.mes_nombre,
    t.trimestre,
    f.salario_base,
    f.bono,
    f.salario_neto
FROM fact_salarios f
JOIN dim_empleados e ON f.empleado_id = e.empleado_id
JOIN dim_departamentos d ON f.departamento_id = d.departamento_id
JOIN dim_tiempo t ON f.tiempo_id = t.tiempo_id;
-- CREAR BASE DE DATOS

CREATE DATABASE recursos_humanos_dw;
USE recursos_humanos_dw;

-- DIMENSIÓN EMPLEADOS

CREATE TABLE dim_empleados (
    empleado_key INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empleado VARCHAR(100),
    genero VARCHAR(1),
    puesto VARCHAR(50),
    nivel_academico VARCHAR(50)

);

-- DIMENSIÓN DEPARTAMENTOS

CREATE TABLE dim_departamentos (
    departamento_key INT AUTO_INCREMENT PRIMARY KEY,
    nombre_departamento VARCHAR(100),
    ubicacion VARCHAR(100)

);

-- DIMENSIÓN TIEMPO

CREATE TABLE dim_tiempo (
    fecha_key INT AUTO_INCREMENT PRIMARY KEY,
    dia INT,
    mes VARCHAR(20),
    anio INT
);

-- FACT SALARIOS

CREATE TABLE fact_salarios (
    salario_id INT AUTO_INCREMENT PRIMARY KEY,
    empleado_key INT,
    departamento_key INT,
    fecha_key INT,
    salario_base DECIMAL(10,2),
    bono DECIMAL(10,2),
    descuento DECIMAL(10,2),
    salario_total DECIMAL(10,2),
    CONSTRAINT fk_empleado
        FOREIGN KEY (empleado_key)
        REFERENCES dim_empleados(empleado_key),
    CONSTRAINT fk_departamento
        FOREIGN KEY (departamento_key)
        REFERENCES dim_departamentos(departamento_key),
    CONSTRAINT fk_fecha
        FOREIGN KEY (fecha_key)
        REFERENCES dim_tiempo(fecha_key)
);

-- registros

INSERT INTO dim_departamentos (
    nombre_departamento,
    ubicacion
)
VALUES
('Finanzas', 'Edificio A'),
('Tecnología', 'Edificio B'),
('Recursos Humanos', 'Edificio C'),
('Ventas', 'Edificio D'),
('Operaciones', 'Edificio E');

INSERT INTO dim_empleados (
    nombre_empleado,
    genero,
    puesto,
    nivel_academico
)
VALUES
('Ana López', 'F', 'Analista', 'Universitario'),
('Carlos Pérez', 'M', 'Gerente', 'Maestría'),
('Sofía Ramírez', 'F', 'Asistente', 'Técnico'),
('Luis Martínez', 'M', 'Supervisor', 'Universitario'),
('María Hernández', 'F', 'Coordinador', 'Maestría'),
('José Rivera', 'M', 'Analista', 'Universitario'),
('Elena Flores', 'F', 'Asistente', 'Técnico'),
('Ricardo Gómez', 'M', 'Supervisor', 'Universitario'),
('Patricia Castro', 'F', 'Gerente', 'Maestría'),
('Fernando Ruiz', 'M', 'Coordinador', 'Universitario');

INSERT INTO dim_tiempo (
    dia,
    mes,
    anio
)
VALUES
(1, 'Enero', 2026),
(2, 'Enero', 2026),
(3, 'Enero', 2026),
(4, 'Enero', 2026),
(5, 'Enero', 2026),
(6, 'Febrero', 2026),
(7, 'Febrero', 2026),
(8, 'Febrero', 2026),
(9, 'Febrero', 2026),
(10, 'Febrero', 2026),
(11, 'Marzo', 2026),
(12, 'Marzo', 2026),
(13, 'Marzo', 2026),
(14, 'Marzo', 2026),
(15, 'Marzo', 2026);

DELIMITER $$
CREATE PROCEDURE insertar_salarios()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 300 DO
        INSERT INTO fact_salarios (
            empleado_key,
            departamento_key,
            fecha_key,
            salario_base,
            bono,
            descuento,
            salario_total
        )
        VALUES (
            FLOOR(1 + RAND() * 10),
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 15),
            ROUND(500 + RAND() * 2500, 2),
            ROUND(50 + RAND() * 500, 2),
            ROUND(10 + RAND() * 300, 2),
            ROUND(
                (
                    (500 + RAND() * 2500)
                    +
                    (50 + RAND() * 500)
                    -
                    (10 + RAND() * 300)
                ),
            2)
        );
        SET i = i + 1;
    END WHILE;
END $$
DELIMITER ;

CALL insertar_salarios();

-- consulta resultado final del modelo analítico
SELECT
    fs.salario_id,
    de.nombre_empleado,
    dd.nombre_departamento,
    dt.mes,
    fs.salario_base,
    fs.bono,
    fs.descuento,
    fs.salario_total
FROM fact_salarios fs
INNER JOIN dim_empleados de
    ON fs.empleado_key = de.empleado_key
INNER JOIN dim_departamentos dd
    ON fs.departamento_key = dd.departamento_key
INNER JOIN dim_tiempo dt
    ON fs.fecha_key = dt.fecha_key
LIMIT 20;

select * from dim_empleados;
select * from dim_departamentos;
select * from dim_tiempo;
select * from fact_salarios;
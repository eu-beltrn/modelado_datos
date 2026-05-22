USE hr_nicole_analytics;

SELECT 
    'GENERAL' AS reporte_tipo,
    'Todos los Departamentos' AS clasificacion,
    ROUND(AVG(salario_neto), 2) AS salario_promedio,
    ROUND(MAX(salario_neto), 2) AS salario_maximo,
    COUNT(fact_id) AS total_registros
FROM vw_analisis_salarial_nicole

UNION ALL

-- 2. ANALISIS POR DEPARTAMENTO
SELECT 
    'POR DEPARTAMENTO' AS reporte_tipo,
    nombre_departamento AS clasificacion,
    ROUND(AVG(salario_neto), 2) AS salario_promedio,
    ROUND(MAX(salario_neto), 2) AS salario_maximo,
    COUNT(fact_id) AS total_registros
FROM vw_analisis_salarial_nicole
GROUP BY nombre_departamento

UNION ALL

-- 3. ANALISIS POR MES (Ordenado internamente por el ID del tiempo)
SELECT 
    'POR MES' AS reporte_tipo,
    mes_nombre AS clasificacion,
    ROUND(AVG(salario_neto), 2) AS salario_promedio,
    ROUND(MAX(salario_neto), 2) AS salario_maximo,
    COUNT(fact_id) AS total_registros
FROM vw_analisis_salarial_nicole
GROUP BY tiempo_id, mes_nombre
ORDER BY reporte_tipo ASC, salario_promedio DESC;
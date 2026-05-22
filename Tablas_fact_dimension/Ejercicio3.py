import pandas as pd
import matplotlib.pyplot as plt
import mysql.connector


# Importa librerías para análisis, gráficas y conexión a la base de datos


# Crea conexión con MySQL o MariaDB


conexion = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="recursos_humanos_dw"
)


# Lee tablas dimensión desde la base de datos


dim_empleados = pd.read_sql(
    "SELECT * FROM dim_empleados",
    conexion
)

dim_departamentos = pd.read_sql(
    "SELECT * FROM dim_departamentos",
    conexion
)

dim_tiempo = pd.read_sql(
    "SELECT * FROM dim_tiempo",
    conexion
)


# Lee tabla fact desde la base de datos


fact_salarios = pd.read_sql(
    "SELECT * FROM fact_salarios",
    conexion
)


# Construye modelo analítico uniendo fact y dimensiones


modelo = fact_salarios.merge(
    dim_empleados,
    on="empleado_key"
).merge(
    dim_departamentos,
    on="departamento_key"
).merge(
    dim_tiempo,
    on="fecha_key"
)


# Calcula salario promedio


salario_promedio = round(
    modelo["salario_total"].mean(),
    2
)

print(
    "Salario Promedio:",
    salario_promedio
)


# Calcula salario máximo


salario_maximo = modelo[
    "salario_total"
].max()

print(
    "Salario Máximo:",
    salario_maximo
)


# Calcula salarios agrupados por departamento


salarios_departamento = modelo.groupby(
    "nombre_departamento"
)["salario_total"].sum()

print("\nSalarios por Departamento:\n")

print(salarios_departamento)


# Calcula salarios agrupados por mes


salarios_mes = modelo.groupby(
    "mes"
)["salario_total"].sum()

print("\nSalarios por Mes:\n")

print(salarios_mes)


# Obtiene top 10 empleados con mayor salario


top_empleados = modelo.groupby(
    "nombre_empleado"
)["salario_total"].sum().sort_values(
    ascending=False
).head(10)

print("\nTop 10 Empleados:\n")

print(top_empleados)


# Grafica salarios por departamento


salarios_departamento.plot(
    kind="bar",
    figsize=(10,5),
    title="Salarios por Departamento"
)

plt.ylabel("Total Salarios")

plt.show()


# Cierra conexión con la base de datos


conexion.close()
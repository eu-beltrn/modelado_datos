# ==============================================================================
# MÓDULO INTEGRADO: ANÁLISIS DIMENSIONAL DE RECURSOS HUMANOS (EJERCICIO 2)
# Alumna: Nicole
# Arquitectura: Script Autónomo (.py) de Ejecución Continua
# ==============================================================================

import pandas as pd
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import seaborn as sns


url_conexion = "mysql+pymysql://root:2006@127.0.0.1:3306/hr_nicole_analytics"

try:
    engine = create_engine(url_conexion)
    print("==================================================")
    print("🚀 INICIANDO PROCESAMIENTO ANALÍTICO CONTINUO")
    print("==================================================\n")
except Exception as e:
    print(f"❌ Error crítico al inicializar el motor: {e}")
    exit()

# ------------------------------------------------------------------------------
# 2. EXTRACCIÓN DE DATOS (REGISTROS)
# ------------------------------------------------------------------------------
try:
    # Usamos la conexión explícita por IP numérica para extraer la vista analítica
    modelo_completo = pd.read_sql("SELECT * FROM vw_analisis_salarial_nicole", con=url_conexion)
    print("==================================================")
    print(f"📦 REGISTROS: Se han extraído {len(modelo_completo)} filas desde MySQL con éxito.")
    print("==================================================\n")
except Exception as e:
    print(f"❌ Error al extraer los datos desde SQL: {e}")
    
    exit()

# ------------------------------------------------------------------------------
# 3. PROCESAMIENTO Y MÉTRICAS (RESULTADOS)
# ------------------------------------------------------------------------------
print("==================================================")
print("             RESULTADOS Y MÉTRICAS ANALÍTICAS     ")
print("==================================================\n")

# Requerimiento A: Salario promedio y máximo general
promedio_general = modelo_completo["salario_neto"].mean()
maximo_general = modelo_completo["salario_neto"].max()

print(f"📊 SALARIO PROMEDIO GENERAL: ${promedio_general:,.2f}")
print(f"🚀 SALARIO MÁXIMO GENERAL:  ${maximo_general:,.2f}")
print("-" * 60)

# Requerimiento B: Salarios promedio y máximo por departamento
print("🏢 ANÁLISIS DE SALARIOS POR DEPARTAMENTO:")
por_depto = modelo_completo.groupby("nombre_departamento").agg(
    salario_promedio=("salario_neto", "mean"),
    salario_maximo=("salario_neto", "max"),
    empleados_en_area=("fact_id", "count")
).reset_index()
print(por_depto.to_string(index=False))
print("-" * 60)

# Requerimiento C: Salarios promedio por mes (Ordenados cronológicamente)
print("📅 ANÁLISIS DE SALARIOS POR MES:")
por_mes = modelo_completo.groupby(["tiempo_id", "mes_nombre"]).agg(
    salario_promedio=("salario_neto", "mean"),
    monto_total_pago=("salario_neto", "sum")
).reset_index().sort_values(by="tiempo_id")
print(por_mes[["mes_nombre", "salario_promedio", "monto_total_pago"]].to_string(index=False))
print("-" * 60)

# Requerimiento D: Top 5 empleados con mayor salario
print("🏆 TOP 5 EMPLEADOS CON MAYOR SALARIO:")
top_5 = modelo_completo.sort_values(by="salario_neto", ascending=False).head(5)
print(top_5[["nombre_completo", "nombre_departamento", "nivel_seniority", "salario_neto"]].to_string(index=False))
print("-" * 60 + "\n")

# ------------------------------------------------------------------------------
# 4. CAPA DE PRESENTACIÓN (VISUALIZACIÓN)
# ------------------------------------------------------------------------------
print("📊 Generando interfaz de gráficos estadísticos...")

fig, axes = plt.subplots(1, 2, figsize=(15, 6))
sns.set_theme(style="whitegrid")

# Gráfico 1: Barras - Salarios por Área
sns.barplot(data=por_depto, x="nombre_departamento", y="salario_promedio", palette="Blues_r", ax=axes[0])
axes[0].set_title("Salario Promedio por Departamento (Nicole)", fontsize=12, fontweight='bold')
axes[0].set_xlabel("Departamento")
axes[0].set_ylabel("Promedio ($)")
axes[0].tick_params(axis='x', rotation=15)

# Gráfico 2: Tendencia Lineal - Salarios por Mes (Mantiene el orden cronológico de pandas)
sns.lineplot(data=por_mes, x="mes_nombre", y="salario_promedio", marker="o", color="teal", linewidth=2.5, ax=axes[1], sort=False)
axes[1].set_title("Evolución del Salario Promedio por Mes", fontsize=12, fontweight='bold')
axes[1].set_xlabel("Mes del Año")
axes[1].set_ylabel("Promedio ($)")
axes[1].tick_params(axis='x', rotation=30)

plt.tight_layout()
print("✔ Gráficos construidos con éxito.")
print("ℹ Cierra la ventana flotante de las gráficas para finalizar el proceso.")

plt.show()
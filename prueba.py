import pandas as pd
import random
from faker import Faker

fake = Faker()

# =====================================
# CREACIÓN DE DIMENSIÓN CLIENTES
# =====================================

clientes = []

for i in range(1, 11):

    clientes.append({
        "cliente_id": i,
        "nombre_cliente": fake.name(),
        "ciudad": fake.city(),
        "edad": random.randint(18, 65)
    })

dim_clientes = pd.DataFrame(clientes)

print(dim_clientes.head())

# =====================================
# CREACIÓN DE DIMENSIÓN PRODUCTOS
# =====================================

categorias = [
    "Laptops",
    "Monitores",
    "Mouse",
    "Teclados"
]

productos = []

for i in range(1, 11):

    productos.append({
        "producto_id": i,
        "producto": fake.word(),
        "categoria": random.choice(categorias),
        "precio": round(random.uniform(200, 5000), 2)
    })

dim_productos = pd.DataFrame(productos)

print(dim_productos.head())

# =====================================
# CREACIÓN DE DIMENSIÓN TIEMPO
# =====================================

fechas = []

for i in range(1, 31):

    fechas.append({
        "fecha_id": i,
        "dia": i,
        "mes": "Mayo",
        "anio": 2026
    })

dim_tiempo = pd.DataFrame(fechas)

print(dim_tiempo.head())

# =====================================
# CREACIÓN DE TABLA FACT
# =====================================

ventas = []

for i in range(1, 101):

    cantidad = random.randint(1, 5)

    precio = round(random.uniform(200, 5000), 2)

    ventas.append({
        "venta_id": i,
        "cliente_id": random.randint(1, 10),
        "producto_id": random.randint(1, 10),
        "fecha_id": random.randint(1, 30),
        "cantidad": cantidad,
        "total": round(cantidad * precio, 2)
    })

fact_ventas = pd.DataFrame(ventas)

print(fact_ventas.head())

# =====================================
# INTEGRACIÓN DEL MODELO
# =====================================

modelo = fact_ventas.merge(
    dim_clientes,
    on="cliente_id"
).merge(
    dim_productos,
    on="producto_id"
).merge(
    dim_tiempo,
    on="fecha_id"
)

print(modelo.head())

# =====================================
# ANÁLISIS ANALÍTICO
# =====================================

ventas_categoria = modelo.groupby(
    "categoria"
)["total"].sum()

print(ventas_categoria)

# =====================================
# ANÁLISIS POR CIUDAD
# =====================================

ventas_ciudad = modelo.groupby(
    "ciudad"
)["total"].sum()

print(ventas_ciudad)

# =====================================
# TOP 5 CLIENTES
# =====================================

top_clientes = modelo.groupby(
    "nombre_cliente"
)["total"].sum().sort_values(
    ascending=False
).head(5)

print(top_clientes)
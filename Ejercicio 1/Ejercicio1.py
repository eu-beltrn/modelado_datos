# ==============================================================================
# Descripción: Módulo de extracción, análisis y visualización (BI) conectado a MySQL.
# Arquitectura: Lee directamente de la capa de presentación (Vista SQL)  
#               y optimiza el rendimiento.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IMPORTACIÓN DE LIBRERÍAS
# ------------------------------------------------------------------------------
import pandas as pd # La librería principal para análisis y manipulación de datos en Python.
from sqlalchemy import create_engine, exc # SQLAlchemy nos permite crear la conexión a la base de datos de forma segura. 'exc' captura errores de SQL.
import logging # Usado para registrar eventos, advertencias y errores (Trazabilidad). Fundamental en producción.
import matplotlib.pyplot as plt # Librería base para crear gráficos.
import seaborn as sns # Librería de visualización construida sobre matplotlib, ofrece gráficos más atractivos estadísticamente.

# ------------------------------------------------------------------------------
# 2. CONFIGURACIÓN DE TRAZABILIDAD
# ------------------------------------------------------------------------------
# Esto nos permite:
# - Saber la hora exacta en que ocurrió algo.
# - Clasificar mensajes (INFO, WARNING, ERROR, CRITICAL).
# - Enviar estos mensajes a un archivo de registro en un entorno de servidor real.
logging.basicConfig(
    level=logging.INFO, # Mostramos mensajes de nivel INFO en adelante.
    format='%(asctime)s - %(levelname)s - [HR_BI_ENGINE] - %(message)s' # Formato: Fecha - Nivel - [Etiqueta] - Mensaje
)
logger = logging.getLogger(__name__)

# ------------------------------------------------------------------------------
# 3. CLASE PRINCIPAL DEL MOTOR BI
# ------------------------------------------------------------------------------
# Usamos Programación Orientada a Objetos (POO) para mantener el código modular,
# organizado y fácil de mantener o expandir en el futuro.
class HRAnalyticsBI:
    
    # -- Método Constructor --
    # Se ejecuta automáticamente al crear un objeto (instancia) de la clase.
    # Recibe los parámetros de conexión. 
    # NOTA: En producción, NUNCA se ponen credenciales en texto plano;
    # se usan variables de entorno (ej: os.environ.get('DB_PASS')).
    def __init__(self, db_user='root', db_pass='', db_host='localhost', db_port='3306', db_name='hr_analytics'):
        """
        Inicializa el motor de análisis y la conexión a MySQL mediante SQLAlchemy.
        """
        # Se construye la 'Connection String' (Cadena de Conexión) en formato SQLAlchemy para MySQL
        self.db_uri = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"
        
        # Inicializamos variables que usaremos después. 'None' y DataFrames vacíos como buena práctica.
        self.engine = None 
        self.df_analisis = pd.DataFrame() # Aquí guardaremos los datos extraídos
        self.kpi_deptos = pd.DataFrame()  # Aquí guardaremos los cálculos agrupados

    # -- Método para Conectar a la Base de Datos --
    def connect(self):
        """Establece la conexión a la base de datos con manejo de excepciones (try-except)."""
        try:
            # create_engine() prepara la conexión, pero no conecta inmediatamente
            self.engine = create_engine(self.db_uri)
            
            # Usamos el bloque 'with' para abrir la conexión, probarla y asegurarnos de que se cierre al terminar.
            with self.engine.connect():
                logger.info(f"Conexión exitosa a MySQL (Base de datos: {self.engine.url.database})")
                
        # Capturamos cualquier error específico de SQLAlchemy (ej. base de datos apagada, contraseña incorrecta)
        except exc.SQLAlchemyError as e:
            logger.critical(f"Error crítico al conectar a la base de datos: {e}")
            raise # Detenemos la ejecución del programa, no podemos continuar sin base de datos.

    # -- Método para Extraer los Datos --
    def fetch_data(self):
        """
        Extrae los datos desde la Vista SQL (`vw_analisis_salarial`).
        """
        logger.info("Extrayendo datos de la capa de presentación (vw_analisis_salarial)...")
        
        # OJO: Solo hacemos un 'SELECT *' porque la VISTA ya hizo todo el trabajo pesado 
        # (JOINs, Window Functions, filtros). Esto es una excelente práctica de rendimiento.
        query = "SELECT * FROM vw_analisis_salarial;"
        
        try:
            # pandas.read_sql() ejecuta la consulta usando el 'engine' y devuelve un DataFrame
            self.df_analisis = pd.read_sql(query, self.engine)
            logger.info(f"Datos extraídos correctamente. Total de registros analíticos: {len(self.df_analisis)}")
        except Exception as e:
            logger.error(f"Error al ejecutar la consulta analítica: {e}")
            raise

    # -- Método para Calcular los Indicadores Clave (KPIs) --
    def calculate_kpis(self):
        """Calcula las métricas de negocio solicitadas."""
        
        # Verificamos que el DataFrame no esté vacío antes de operar
        if self.df_analisis.empty:
            logger.warning("No hay datos para analizar en la vista. Deteniendo cálculos.")
            return

        logger.info("Calculando KPIs empresariales con Pandas...")

        # -- KPI 1: Promedio y Máximo Global --
        # Utilizamos funciones nativas de pandas (.mean() y .max()) sobre la columna 'salario_base'
        salario_promedio = self.df_analisis['salario_base'].mean()
        salario_maximo = self.df_analisis['salario_base'].max()
        
        # Para dar contexto, buscamos el nombre de la persona que tiene el salario máximo.
        # idxmax() nos da el 'índice' (la fila) donde está el valor máximo, y luego extraemos la columna 'nombre_completo'
        emp_max_salario = self.df_analisis.loc[self.df_analisis['salario_base'].idxmax(), 'nombre_completo']

        # -- KPI 2: Agrupación por Departamento --
        # Usamos .groupby() para agrupar por el nombre del departamento
        # y .agg() para aplicar múltiples cálculos matemáticos a distintas columnas al mismo tiempo.
        self.kpi_deptos = self.df_analisis.groupby('nombre_departamento').agg(
            total_empleados=('empleado_id', 'count'),    # Cuenta cuántos empleados hay
            salario_promedio=('salario_base', 'mean'),   # Promedio del salario base
            salario_maximo=('salario_base', 'max'),      # Máximo salario base
            gasto_total_nomina=('salario_neto', 'sum')   # Suma total de los salarios netos a pagar
        ).reset_index() # .reset_index() convierte 'nombre_departamento' de vuelta a una columna normal

        # Ordenamos los resultados de mayor a menor salario promedio
        self.kpi_deptos = self.kpi_deptos.sort_values(by='salario_promedio', ascending=False)

        # -- 3. Impresión del Reporte Ejecutivo en Consola --
        print("\n" + "="*70)
        print("📊 REPORTE EJECUTIVO - ANALÍTICA DE RECURSOS HUMANOS")
        print("="*70)
        # ':,.2f' formatea el número: coma para miles, punto decimal y 2 decimales.
        print(f"🔹 Salario Promedio Global: ${salario_promedio:,.2f}")
        print(f"🔹 Salario Máximo Global:   ${salario_maximo:,.2f} (Empleado: {emp_max_salario})")
        print("-" * 70)
        print("🔹 MÉTRICAS DETALLADAS POR DEPARTAMENTO:")
        
        # Creamos una función rápida (lambda) para formatear los números de las columnas como moneda
        formato_moneda = lambda x: f"${x:,.2f}"
        
        # Convertimos el DataFrame agrupado a texto (String) aplicando el formato de moneda a las columnas pertinentes
        reporte_str = self.kpi_deptos.to_string(
            index=False, # Ocultamos los números de fila (0, 1, 2...)
            formatters={
                'salario_promedio': formato_moneda,
                'salario_maximo': formato_moneda,
                'gasto_total_nomina': formato_moneda
            }
        )
        print(reporte_str) # Imprimimos la tabla formateada
        print("="*70 + "\n")

    # -- Método para Crear Gráficos (Visualización) --
    def visualize_data(self):
        """Genera un dashboard visual con calidad para presentación a directivos."""
        if self.kpi_deptos.empty:
            return

        logger.info("Renderizando visualizaciones con Seaborn...")
        
        # Definimos el estilo base del gráfico (cuadrícula blanca, texto grande 'talk')
        sns.set_theme(style="whitegrid", context="talk")
        
        # Creamos la figura y los ejes definiendo su tamaño (12 de ancho x 7 de alto)
        fig, ax = plt.subplots(figsize=(12, 7))
        
        # Usamos Seaborn para crear un gráfico de barras horizontales (sns.barplot)
        barplot = sns.barplot(
            x='salario_promedio',       # Eje X: El valor numérico
            y='nombre_departamento',    # Eje Y: Las categorías
            data=self.kpi_deptos,       # Origen de datos: Nuestro DataFrame agrupado
            hue='nombre_departamento',  # Colorea cada barra distinto según el departamento
            palette='mako',             # Paleta de colores profesional predefinida
            legend=False,               # Ocultamos la leyenda porque los nombres ya están en el eje Y
            ax=ax                       # Le indicamos que dibuje en los ejes creados arriba
        )
        
        # Bucle para añadir los números (etiquetas) al lado de cada barra
        for p in barplot.patches:
            width = p.get_width() # Obtenemos el valor de la barra (el salario promedio)
            
            # plt.text() dibuja texto en coordenadas específicas del gráfico
            plt.text(width + 100, # Posición X: al final de la barra + un pequeño margen (100)
                     p.get_y() + p.get_height() / 2, # Posición Y: A la mitad de la altura de la barra
                     f'${width:,.0f}', # El texto a mostrar (formateado sin decimales)
                     ha='left', va='center', # Alineación horizontal (izquierda) y vertical (centro)
                     fontsize=11, fontweight='bold', color='#333333')

        # -- Formateo y limpieza visual del gráfico --
        ax.set_title('Promedio Salarial por Departamento', fontsize=18, fontweight='bold', pad=20)
        ax.set_xlabel('Salario Base Promedio (USD)', fontsize=14, fontweight='bold')
        ax.set_ylabel('Departamento', fontsize=14, fontweight='bold')
        
        # sns.despine() quita las líneas del recuadro superior y derecho del gráfico para un diseño más moderno y limpio.
        sns.despine(left=True, bottom=True)
        
        # Ajusta automáticamente los márgenes para que no se corte ningún texto
        plt.tight_layout()
        
        # Muestra la ventana con el gráfico terminado
        plt.show()

# ------------------------------------------------------------------------------
# 4. PUNTO DE ENTRADA (MAIN)
# ------------------------------------------------------------------------------
# Esta condición asegura que el código solo se ejecute si corremos el archivo directamente 
# (ej. 'python hr_bi_analytics.py') y NO si lo importamos desde otro archivo.
if __name__ == "__main__":
    
    # Creamos un objeto de nuestra clase configurando la conexión a Laragon/MySQL
    bi_engine = HRAnalyticsBI(
        db_user='root', 
        db_pass='',        # En Laragon suele venir sin contraseña por defecto
        db_host='localhost', 
        db_port='3306', 
        db_name='hr_analytics'
    )
    
    # Ejecutamos los métodos en orden lógico envueltos en un try-except para atrapar 
    # errores no previstos durante todo el proceso.
    try:
        bi_engine.connect()          # 1. Conectamos
        bi_engine.fetch_data()       # 2. Extraemos datos
        bi_engine.calculate_kpis()   # 3. Hacemos cálculos e imprimimos el reporte
        bi_engine.visualize_data()   # 4. Dibujamos el gráfico
        
    except Exception as e:
        # Si algo falla en los 4 pasos anteriores, el script no "explota", sino que registra este error
        # e incluye el detalle de la variable 'e' que causó el problema.
        logger.critical(f"El proceso de Business Intelligence ha fallado. Revisa los logs. Detalle: {e}")
# Proyecto inicial

## Estructura

```
data/original/     CSV originales de Olist (no se modifican)
data/trabajo/      copia con errores controlados (la genera el notebook)
data/processed/    dataset limpio en Parquet (*_clean.parquet)
notebooks/         01_pipeline_etl.ipynb: el pipeline completo
reports/           reporte de calidad: quality_report, comparación antes/después,
                   validación final, resumen de cuarentena, errores inyectados
sql/               pipeline_etl.sql: todas las sentencias ejecutadas, en orden
informe/           informe técnico
ecommerce.duckdb   base con tablas RAW, STG, CLEAN, cuarentena y quality_report
```

## Cómo ejecutarlo

Requiere Python 3.11 o superior.

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows  (Linux/macOS: source .venv/bin/activate)
pip install -r requirements.txt
```

Después hay que copiar en `data/original/` los CSV de Olist
([Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)). Se usan estos cinco:

- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_customers_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_products_dataset.csv`

Además se usa `product_category_name_translation.csv`.

Por último, se abre `notebooks/01_pipeline_etl.ipynb` y se ejecutan todas las celdas en orden (**Run All**).
Tarda unos 2 minutos. El notebook detecta la carpeta del proyecto aunque se abra desde `notebooks/`.

El pipeline es idempotente: se puede volver a ejecutar completo y produce exactamente las mismas tablas y archivos.
La sección 7 del notebook lo demuestra.
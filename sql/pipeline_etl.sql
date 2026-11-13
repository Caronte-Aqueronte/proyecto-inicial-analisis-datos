-- Pipeline ETL generado por notebooks/01_pipeline_etl.ipynb
-- Sentencias en orden de ejecución. Ejecutarlo de nuevo reproduce las mismas tablas.

-- R14: TRUE si el valor existe pero en realidad no contiene un dato ('', '   ', 'N/A', 'null'...)
CREATE OR REPLACE MACRO es_vacio(x) AS
    x IS NOT NULL
    AND (NULLIF(trim(CAST(x AS VARCHAR)), '') IS NULL
         OR upper(trim(CAST(x AS VARCHAR))) IN ('NULL', 'N/A', 'NA', 'NONE', 'NAN', '-'));

CREATE OR REPLACE MACRO limpiar_vacio(x) AS
    CASE WHEN es_vacio(x) THEN NULL ELSE x END;

-- R03: sin espacios sobrantes, en minúsculas y sin tildes
CREATE OR REPLACE MACRO normalizar_texto(x) AS
    lower(strip_accents(regexp_replace(trim(x), '[[:space:]]+', ' ', 'g')));

-- R04: texto -> número (acepta coma decimal) y texto -> timestamp (acepta dd/mm/aaaa). NULL si no se puede.
CREATE OR REPLACE MACRO a_numero(x) AS
    TRY_CAST(replace(trim(CAST(x AS VARCHAR)), ',', '.') AS DECIMAL(12, 2));

CREATE OR REPLACE MACRO a_fecha(x) AS
    TRY_STRPTIME(trim(CAST(x AS VARCHAR)),
                 ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d', '%d/%m/%Y %H:%M:%S', '%d/%m/%Y']);

CREATE OR REPLACE TABLE quality_report (
    nombre_regla        VARCHAR,
    tabla_evaluada      VARCHAR,
    etapa               VARCHAR,     -- 'antes' = capa RAW, 'despues' = capa CLEAN
    registros_evaluados BIGINT,
    registros_invalidos BIGINT,
    porcentaje_error    DOUBLE,
    politica            VARCHAR,
    fecha_ejecucion     TIMESTAMP
);

CREATE OR REPLACE TEMP TABLE w_pedidos AS
SELECT *, ROW_NUMBER() OVER (ORDER BY md5(order_id || 'miicc409')) AS _rn
FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/original/olist_orders_dataset.csv', all_varchar = true);

CREATE OR REPLACE TEMP TABLE w_items AS
SELECT *, ROW_NUMBER() OVER (ORDER BY md5(order_id || '-' || order_item_id || 'miicc409')) AS _rn
FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/original/olist_order_items_dataset.csv', all_varchar = true);

CREATE OR REPLACE TEMP TABLE w_clientes AS
SELECT *, ROW_NUMBER() OVER (ORDER BY md5(customer_id || 'miicc409')) AS _rn
FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/original/olist_customers_dataset.csv', all_varchar = true);

CREATE OR REPLACE TEMP TABLE w_pagos AS
SELECT *, ROW_NUMBER() OVER (ORDER BY md5(order_id || '-' || payment_sequential || 'miicc409')) AS _rn
FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/original/olist_order_payments_dataset.csv', all_varchar = true);

CREATE OR REPLACE TEMP TABLE w_productos AS
SELECT *, ROW_NUMBER() OVER (ORDER BY md5(product_id || 'miicc409')) AS _rn
FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/original/olist_products_dataset.csv', all_varchar = true);

INSERT INTO w_pedidos SELECT * FROM w_pedidos WHERE _rn BETWEEN 1 AND 60;

INSERT INTO w_pedidos SELECT * REPLACE (upper(order_status) AS order_status) FROM w_pedidos WHERE _rn BETWEEN 61 AND 80;

UPDATE w_pedidos SET order_status = CASE _rn % 3 WHEN 0 THEN upper(order_status) WHEN 1 THEN '  ' || order_status || ' ' ELSE upper(left(order_status, 1)) || substr(order_status, 2) END WHERE _rn BETWEEN 101 AND 400;

UPDATE w_pedidos SET order_purchase_timestamp = strftime(CAST(order_purchase_timestamp AS TIMESTAMP), '%d/%m/%Y %H:%M:%S') WHERE _rn BETWEEN 401 AND 440;

UPDATE w_pedidos SET order_purchase_timestamp = CASE _rn % 3 WHEN 0 THEN 'fecha_invalida' WHEN 1 THEN '2017-02-30 10:00:00' ELSE '0000-00-00 00:00:00' END WHERE _rn BETWEEN 441 AND 452;

UPDATE w_pedidos SET order_delivered_customer_date = strftime(CAST(order_purchase_timestamp AS TIMESTAMP) - INTERVAL 5 DAY, '%Y-%m-%d %H:%M:%S') WHERE _rn BETWEEN 461 AND 500 AND order_delivered_customer_date IS NOT NULL;

UPDATE w_pedidos SET order_estimated_delivery_date = strftime(CAST(order_purchase_timestamp AS TIMESTAMP) - INTERVAL 3 DAY, '%Y-%m-%d 00:00:00') WHERE _rn BETWEEN 501 AND 520;

UPDATE w_pedidos SET customer_id = md5('cliente-fantasma-' || _rn) WHERE _rn BETWEEN 531 AND 560;

UPDATE w_pedidos SET order_approved_at = CASE _rn % 4 WHEN 0 THEN '' WHEN 1 THEN '   ' WHEN 2 THEN 'N/A' ELSE 'null' END WHERE _rn BETWEEN 561 AND 600;

UPDATE w_pedidos SET order_status = '   ' WHERE _rn BETWEEN 601 AND 610;

UPDATE w_pedidos SET order_status = 'canceled' WHERE _rn BETWEEN 611 AND 650 AND order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;

UPDATE w_pedidos SET order_delivered_customer_date = NULL WHERE _rn BETWEEN 651 AND 680 AND order_status = 'delivered';

INSERT INTO w_items SELECT * FROM w_items WHERE _rn BETWEEN 1 AND 80;

UPDATE w_items SET price = CASE WHEN _rn % 2 = 0 THEN '0' ELSE '0.00' END WHERE _rn BETWEEN 101 AND 130;

UPDATE w_items SET price = '-' || price WHERE _rn BETWEEN 131 AND 160;

UPDATE w_items SET freight_value = '-' || freight_value WHERE _rn BETWEEN 161 AND 190 AND CAST(freight_value AS DOUBLE) > 0;

UPDATE w_items SET price = replace(price, '.', ',') WHERE _rn BETWEEN 201 AND 240;

UPDATE w_items SET price = CASE _rn % 3 WHEN 0 THEN 'abc' WHEN 1 THEN 'sin precio' ELSE '12.3.4' END WHERE _rn BETWEEN 241 AND 252;

UPDATE w_items SET product_id = md5('producto-fantasma-' || _rn) WHERE _rn BETWEEN 261 AND 290;

UPDATE w_items SET order_id = md5('pedido-fantasma-' || _rn) WHERE _rn BETWEEN 291 AND 310;

INSERT INTO w_clientes SELECT * FROM w_clientes WHERE _rn BETWEEN 1 AND 50;

UPDATE w_clientes SET customer_city = CASE _rn % 3 WHEN 0 THEN upper(customer_city) WHEN 1 THEN '  ' || customer_city || '  ' ELSE upper(left(customer_city, 1)) || substr(customer_city, 2) END WHERE _rn BETWEEN 101 AND 400;

UPDATE w_clientes SET customer_city = replace(customer_city, 'sao ', 'são ') WHERE _rn BETWEEN 401 AND 1000 AND customer_city LIKE 'sao %';

UPDATE w_clientes SET customer_state = CASE _rn % 2 WHEN 0 THEN lower(customer_state) ELSE ' ' || customer_state || ' ' END WHERE _rn BETWEEN 1001 AND 1200;

UPDATE w_clientes SET customer_zip_code_prefix = ltrim(customer_zip_code_prefix, '0') WHERE _rn BETWEEN 1201 AND 2400 AND customer_zip_code_prefix LIKE '0%';

UPDATE w_clientes SET customer_zip_code_prefix = CASE _rn % 3 WHEN 0 THEN 'ABCDE' WHEN 1 THEN '123456' ELSE '12-34' END WHERE _rn BETWEEN 2401 AND 2415;

UPDATE w_clientes SET customer_city = CASE _rn % 4 WHEN 0 THEN '' WHEN 1 THEN '   ' WHEN 2 THEN 'N/A' ELSE 'NULL' END WHERE _rn BETWEEN 2501 AND 2540;

INSERT INTO w_pagos SELECT * FROM w_pagos WHERE _rn BETWEEN 1 AND 40;

UPDATE w_pagos SET payment_type = CASE payment_type WHEN 'credit_card' THEN (CASE _rn % 3 WHEN 0 THEN 'Credit Card' WHEN 1 THEN 'CREDIT_CARD' ELSE 'cartao_credito' END) WHEN 'boleto' THEN (CASE _rn % 2 WHEN 0 THEN ' Boleto ' ELSE 'BOLETO' END) WHEN 'debit_card' THEN 'debit card' WHEN 'voucher' THEN 'Voucher ' ELSE payment_type END WHERE _rn BETWEEN 101 AND 500;

UPDATE w_pagos SET payment_type = CASE _rn % 3 WHEN 0 THEN 'pix' WHEN 1 THEN 'cripto' ELSE '???' END WHERE _rn BETWEEN 501 AND 515;

UPDATE w_pagos SET payment_value = replace(payment_value, '.', ',') WHERE _rn BETWEEN 521 AND 550;

UPDATE w_pagos SET order_id = md5('pedido-fantasma-pago-' || _rn) WHERE _rn BETWEEN 561 AND 580;

UPDATE w_pagos SET payment_type = CASE _rn % 2 WHEN 0 THEN '' ELSE '  ' END WHERE _rn BETWEEN 591 AND 600;

UPDATE w_pagos SET payment_value = '' WHERE _rn BETWEEN 601 AND 610;

INSERT INTO w_productos SELECT * FROM w_productos WHERE _rn BETWEEN 1 AND 30;

UPDATE w_productos SET product_category_name = CASE _rn % 2 WHEN 0 THEN upper(product_category_name) ELSE ' ' || product_category_name || '  ' END WHERE _rn BETWEEN 101 AND 300 AND product_category_name IS NOT NULL;

UPDATE w_productos SET product_category_name = CASE _rn % 2 WHEN 0 THEN replace(product_category_name, '_', ' ') ELSE replace(product_category_name, '_', '-') END WHERE _rn BETWEEN 301 AND 500 AND contains(product_category_name, '_');

UPDATE w_productos SET product_category_name = replace(replace(replace(product_category_name, 'informatica', 'informática'), 'moveis', 'móveis'), 'eletrodomesticos', 'eletrodomésticos') WHERE _rn BETWEEN 501 AND 1500 AND regexp_matches(product_category_name, 'informatica|moveis|eletrodomesticos');

UPDATE w_productos SET product_category_name = CASE _rn % 3 WHEN 0 THEN '' WHEN 1 THEN '  ' ELSE 'N/A' END WHERE _rn BETWEEN 1601 AND 1630;

UPDATE w_productos SET product_weight_g = CASE _rn % 2 WHEN 0 THEN 'sin_dato' ELSE '1,2kg' END WHERE _rn BETWEEN 1701 AND 1710;

CREATE OR REPLACE TABLE errores_inyectados AS
SELECT * FROM (VALUES
    ('R01', 'pedidos', 'Pedido duplicado exacto', 60),
    ('R01', 'pedidos', 'Pedido duplicado con el estado en MAYÚSCULAS (solo se detecta por clave)', 20),
    ('R03', 'pedidos', 'Estado con espacios o mayúsculas', 300),
    ('R04', 'pedidos', 'Fecha de compra en formato dd/mm/aaaa', 40),
    ('R04', 'pedidos', 'Fecha de compra imposible o texto', 12),
    ('R05', 'pedidos', 'Entrega al cliente anterior a la compra', 39),
    ('R05', 'pedidos', 'Fecha estimada de entrega anterior a la compra', 20),
    ('R09', 'pedidos', 'Pedido de un cliente inexistente', 30),
    ('R14', 'pedidos', 'Fecha de aprobación vacía, con espacios, ''N/A'' o ''null''', 40),
    ('R14', 'pedidos', 'Estado del pedido en blanco', 10),
    ('R10', 'pedidos', 'Pedido entregado marcado como cancelado', 39),
    ('R10', 'pedidos', 'Pedido ''delivered'' sin fecha de entrega', 30),
    ('R01', 'items', 'Ítem duplicado (mismo pedido y número de ítem)', 80),
    ('R06', 'items', 'Precio igual a cero', 30),
    ('R06', 'items', 'Precio negativo', 30),
    ('R06', 'items', 'Flete negativo', 30),
    ('R04', 'items', 'Precio con coma decimal', 40),
    ('R04', 'items', 'Precio no numérico', 12),
    ('R09', 'items', 'Ítem de un producto inexistente', 30),
    ('R09', 'items', 'Ítem de un pedido inexistente', 20),
    ('R01', 'clientes', 'Cliente duplicado', 50),
    ('R03', 'clientes', 'Ciudad con mayúsculas o espacios', 300),
    ('R03', 'clientes', 'Ciudad con tilde (''são paulo'')', 138),
    ('R03', 'clientes', 'Estado (UF) en minúsculas o con espacios', 200),
    ('R11', 'clientes', 'Código postal sin el cero inicial (como lo deja Excel)', 289),
    ('R11', 'clientes', 'Código postal inválido', 15),
    ('R14', 'clientes', 'Ciudad vacía, con espacios, ''N/A'' o ''NULL''', 40),
    ('R01', 'pagos', 'Pago duplicado', 40),
    ('R13', 'pagos', 'Método de pago escrito de otra forma', 400),
    ('R13', 'pagos', 'Método de pago desconocido', 15),
    ('R04', 'pagos', 'Monto con coma decimal', 30),
    ('R09', 'pagos', 'Pago de un pedido inexistente', 20),
    ('R14', 'pagos', 'Método de pago vacío o con espacios', 10),
    ('R02', 'pagos', 'Monto de pago vacío (campo crítico)', 10),
    ('R01', 'productos', 'Producto duplicado', 30),
    ('R03', 'productos', 'Categoría con mayúsculas o espacios', 195),
    ('R08', 'productos', 'Categoría con espacios o guiones en lugar de guion bajo', 141),
    ('R03', 'productos', 'Categoría con tildes', 165),
    ('R14', 'productos', 'Categoría vacía, con espacios o ''N/A''', 30),
    ('R04', 'productos', 'Peso no numérico', 10)
) AS v(regla, tabla, descripcion, registros_afectados);

COPY (SELECT * EXCLUDE (_rn) FROM w_pedidos ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_orders_dataset.csv' (HEADER, DELIMITER ',');

COPY (SELECT * EXCLUDE (_rn) FROM w_items ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_order_items_dataset.csv' (HEADER, DELIMITER ',');

COPY (SELECT * EXCLUDE (_rn) FROM w_clientes ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_customers_dataset.csv' (HEADER, DELIMITER ',');

COPY (SELECT * EXCLUDE (_rn) FROM w_pagos ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_order_payments_dataset.csv' (HEADER, DELIMITER ',');

COPY (SELECT * EXCLUDE (_rn) FROM w_productos ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_products_dataset.csv' (HEADER, DELIMITER ',');

CREATE OR REPLACE TABLE pedidos_raw AS
SELECT * FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_orders_dataset.csv', all_varchar = true, allow_quoted_nulls = false);

CREATE OR REPLACE TABLE items_raw AS
SELECT * FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_order_items_dataset.csv', all_varchar = true, allow_quoted_nulls = false);

CREATE OR REPLACE TABLE clientes_raw AS
SELECT * FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_customers_dataset.csv', all_varchar = true, allow_quoted_nulls = false);

CREATE OR REPLACE TABLE pagos_raw AS
SELECT * FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_order_payments_dataset.csv', all_varchar = true, allow_quoted_nulls = false);

CREATE OR REPLACE TABLE productos_raw AS
SELECT * FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/trabajo/olist_products_dataset.csv', all_varchar = true, allow_quoted_nulls = false);

CREATE OR REPLACE TABLE categorias_raw AS
SELECT * FROM read_csv('d:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/original/product_category_name_translation.csv', all_varchar = true);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("order_id") OR es_vacio("customer_id") OR es_vacio("order_status") OR es_vacio("order_purchase_timestamp") OR es_vacio("order_approved_at") OR es_vacio("order_delivered_carrier_date") OR es_vacio("order_delivered_customer_date") OR es_vacio("order_estimated_delivery_date")) FROM pedidos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("order_id") OR es_vacio("order_item_id") OR es_vacio("product_id") OR es_vacio("seller_id") OR es_vacio("shipping_limit_date") OR es_vacio("price") OR es_vacio("freight_value")) FROM items_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'clientes' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'clientes', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("customer_id") OR es_vacio("customer_unique_id") OR es_vacio("customer_zip_code_prefix") OR es_vacio("customer_city") OR es_vacio("customer_state")) FROM clientes_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("order_id") OR es_vacio("payment_sequential") OR es_vacio("payment_type") OR es_vacio("payment_installments") OR es_vacio("payment_value")) FROM pagos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("product_id") OR es_vacio("product_category_name") OR es_vacio("product_name_lenght") OR es_vacio("product_description_lenght") OR es_vacio("product_photos_qty") OR es_vacio("product_weight_g") OR es_vacio("product_length_cm") OR es_vacio("product_height_cm") OR es_vacio("product_width_cm")) FROM productos_raw) AS m(evaluados, invalidos);

CREATE OR REPLACE TABLE pedidos_stg AS
SELECT limpiar_vacio("order_id") AS "order_id",
       limpiar_vacio("customer_id") AS "customer_id",
       limpiar_vacio("order_status") AS "order_status",
       limpiar_vacio("order_purchase_timestamp") AS "order_purchase_timestamp",
       limpiar_vacio("order_approved_at") AS "order_approved_at",
       limpiar_vacio("order_delivered_carrier_date") AS "order_delivered_carrier_date",
       limpiar_vacio("order_delivered_customer_date") AS "order_delivered_customer_date",
       limpiar_vacio("order_estimated_delivery_date") AS "order_estimated_delivery_date",
       CAST(NULL AS VARCHAR) AS motivo_cuarentena,   -- por qué el registro no pasa a CLEAN
       CAST(NULL AS VARCHAR) AS observaciones        -- problemas conservados y marcados
FROM pedidos_raw;

CREATE OR REPLACE TABLE items_stg AS
SELECT limpiar_vacio("order_id") AS "order_id",
       limpiar_vacio("order_item_id") AS "order_item_id",
       limpiar_vacio("product_id") AS "product_id",
       limpiar_vacio("seller_id") AS "seller_id",
       limpiar_vacio("shipping_limit_date") AS "shipping_limit_date",
       limpiar_vacio("price") AS "price",
       limpiar_vacio("freight_value") AS "freight_value",
       CAST(NULL AS VARCHAR) AS motivo_cuarentena,   -- por qué el registro no pasa a CLEAN
       CAST(NULL AS VARCHAR) AS observaciones        -- problemas conservados y marcados
FROM items_raw;

CREATE OR REPLACE TABLE clientes_stg AS
SELECT limpiar_vacio("customer_id") AS "customer_id",
       limpiar_vacio("customer_unique_id") AS "customer_unique_id",
       limpiar_vacio("customer_zip_code_prefix") AS "customer_zip_code_prefix",
       limpiar_vacio("customer_city") AS "customer_city",
       limpiar_vacio("customer_state") AS "customer_state",
       CAST(NULL AS VARCHAR) AS motivo_cuarentena,   -- por qué el registro no pasa a CLEAN
       CAST(NULL AS VARCHAR) AS observaciones        -- problemas conservados y marcados
FROM clientes_raw;

CREATE OR REPLACE TABLE pagos_stg AS
SELECT limpiar_vacio("order_id") AS "order_id",
       limpiar_vacio("payment_sequential") AS "payment_sequential",
       limpiar_vacio("payment_type") AS "payment_type",
       limpiar_vacio("payment_installments") AS "payment_installments",
       limpiar_vacio("payment_value") AS "payment_value",
       CAST(NULL AS VARCHAR) AS motivo_cuarentena,   -- por qué el registro no pasa a CLEAN
       CAST(NULL AS VARCHAR) AS observaciones        -- problemas conservados y marcados
FROM pagos_raw;

CREATE OR REPLACE TABLE productos_stg AS
SELECT limpiar_vacio("product_id") AS "product_id",
       limpiar_vacio("product_category_name") AS "product_category_name",
       limpiar_vacio("product_name_lenght") AS "product_name_lenght",
       limpiar_vacio("product_description_lenght") AS "product_description_lenght",
       limpiar_vacio("product_photos_qty") AS "product_photos_qty",
       limpiar_vacio("product_weight_g") AS "product_weight_g",
       limpiar_vacio("product_length_cm") AS "product_length_cm",
       limpiar_vacio("product_height_cm") AS "product_height_cm",
       limpiar_vacio("product_width_cm") AS "product_width_cm",
       CAST(NULL AS VARCHAR) AS motivo_cuarentena,   -- por qué el registro no pasa a CLEAN
       CAST(NULL AS VARCHAR) AS observaciones        -- problemas conservados y marcados
FROM productos_raw;

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE order_status <> normalizar_texto(order_status) AND NOT es_vacio(order_status)) FROM pedidos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'clientes' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'clientes', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE (customer_city <> normalizar_texto(customer_city) AND NOT es_vacio(customer_city)) OR customer_state <> upper(trim(customer_state))) FROM clientes_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE product_category_name <> normalizar_texto(product_category_name) AND NOT es_vacio(product_category_name)) FROM productos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE payment_type <> normalizar_texto(payment_type) AND NOT es_vacio(payment_type)) FROM pagos_raw) AS m(evaluados, invalidos);

UPDATE pedidos_stg   SET order_status = normalizar_texto(order_status);

UPDATE clientes_stg  SET customer_city = normalizar_texto(customer_city), customer_state = upper(trim(customer_state));

UPDATE productos_stg SET product_category_name = normalizar_texto(product_category_name);

UPDATE pagos_stg     SET payment_type = normalizar_texto(payment_type);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_purchase_timestamp" IS NOT NULL AND NOT es_vacio("order_purchase_timestamp") AND a_fecha("order_purchase_timestamp") IS NULL) OR ("order_approved_at" IS NOT NULL AND NOT es_vacio("order_approved_at") AND a_fecha("order_approved_at") IS NULL) OR ("order_delivered_carrier_date" IS NOT NULL AND NOT es_vacio("order_delivered_carrier_date") AND a_fecha("order_delivered_carrier_date") IS NULL) OR ("order_delivered_customer_date" IS NOT NULL AND NOT es_vacio("order_delivered_customer_date") AND a_fecha("order_delivered_customer_date") IS NULL) OR ("order_estimated_delivery_date" IS NOT NULL AND NOT es_vacio("order_estimated_delivery_date") AND a_fecha("order_estimated_delivery_date") IS NULL)) FROM pedidos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_item_id" IS NOT NULL AND NOT es_vacio("order_item_id") AND TRY_CAST(a_numero("order_item_id") AS INTEGER) IS NULL) OR ("shipping_limit_date" IS NOT NULL AND NOT es_vacio("shipping_limit_date") AND a_fecha("shipping_limit_date") IS NULL) OR ("price" IS NOT NULL AND NOT es_vacio("price") AND TRY_CAST(a_numero("price") AS DECIMAL(10,2)) IS NULL) OR ("freight_value" IS NOT NULL AND NOT es_vacio("freight_value") AND TRY_CAST(a_numero("freight_value") AS DECIMAL(10,2)) IS NULL)) FROM items_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("payment_sequential" IS NOT NULL AND NOT es_vacio("payment_sequential") AND TRY_CAST(a_numero("payment_sequential") AS INTEGER) IS NULL) OR ("payment_installments" IS NOT NULL AND NOT es_vacio("payment_installments") AND TRY_CAST(a_numero("payment_installments") AS INTEGER) IS NULL) OR ("payment_value" IS NOT NULL AND NOT es_vacio("payment_value") AND TRY_CAST(a_numero("payment_value") AS DECIMAL(10,2)) IS NULL)) FROM pagos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("product_name_lenght" IS NOT NULL AND NOT es_vacio("product_name_lenght") AND TRY_CAST(a_numero("product_name_lenght") AS INTEGER) IS NULL) OR ("product_description_lenght" IS NOT NULL AND NOT es_vacio("product_description_lenght") AND TRY_CAST(a_numero("product_description_lenght") AS INTEGER) IS NULL) OR ("product_photos_qty" IS NOT NULL AND NOT es_vacio("product_photos_qty") AND TRY_CAST(a_numero("product_photos_qty") AS INTEGER) IS NULL) OR ("product_weight_g" IS NOT NULL AND NOT es_vacio("product_weight_g") AND TRY_CAST(a_numero("product_weight_g") AS INTEGER) IS NULL) OR ("product_length_cm" IS NOT NULL AND NOT es_vacio("product_length_cm") AND TRY_CAST(a_numero("product_length_cm") AS INTEGER) IS NULL) OR ("product_height_cm" IS NOT NULL AND NOT es_vacio("product_height_cm") AND TRY_CAST(a_numero("product_height_cm") AS INTEGER) IS NULL) OR ("product_width_cm" IS NOT NULL AND NOT es_vacio("product_width_cm") AND TRY_CAST(a_numero("product_width_cm") AS INTEGER) IS NULL)) FROM productos_raw) AS m(evaluados, invalidos);

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R04 order_purchase_timestamp no convertible a TIMESTAMP')
WHERE ("order_purchase_timestamp" IS NOT NULL AND a_fecha("order_purchase_timestamp") IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R04 order_purchase_timestamp no convertible a TIMESTAMP%';

ALTER TABLE pedidos_stg ALTER COLUMN "order_purchase_timestamp" TYPE TIMESTAMP USING a_fecha("order_purchase_timestamp");

ALTER TABLE pedidos_stg ALTER COLUMN "order_approved_at" TYPE TIMESTAMP USING a_fecha("order_approved_at");

ALTER TABLE pedidos_stg ALTER COLUMN "order_delivered_carrier_date" TYPE TIMESTAMP USING a_fecha("order_delivered_carrier_date");

ALTER TABLE pedidos_stg ALTER COLUMN "order_delivered_customer_date" TYPE TIMESTAMP USING a_fecha("order_delivered_customer_date");

ALTER TABLE pedidos_stg ALTER COLUMN "order_estimated_delivery_date" TYPE TIMESTAMP USING a_fecha("order_estimated_delivery_date");

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R04 order_item_id no convertible a INTEGER')
WHERE ("order_item_id" IS NOT NULL AND TRY_CAST(a_numero("order_item_id") AS INTEGER) IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R04 order_item_id no convertible a INTEGER%';

ALTER TABLE items_stg ALTER COLUMN "order_item_id" TYPE INTEGER USING TRY_CAST(a_numero("order_item_id") AS INTEGER);

ALTER TABLE items_stg ALTER COLUMN "shipping_limit_date" TYPE TIMESTAMP USING a_fecha("shipping_limit_date");

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R04 price no convertible a DECIMAL(10,2)')
WHERE ("price" IS NOT NULL AND TRY_CAST(a_numero("price") AS DECIMAL(10,2)) IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R04 price no convertible a DECIMAL(10,2)%';

ALTER TABLE items_stg ALTER COLUMN "price" TYPE DECIMAL(10,2) USING TRY_CAST(a_numero("price") AS DECIMAL(10,2));

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R04 freight_value no convertible a DECIMAL(10,2)')
WHERE ("freight_value" IS NOT NULL AND TRY_CAST(a_numero("freight_value") AS DECIMAL(10,2)) IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R04 freight_value no convertible a DECIMAL(10,2)%';

ALTER TABLE items_stg ALTER COLUMN "freight_value" TYPE DECIMAL(10,2) USING TRY_CAST(a_numero("freight_value") AS DECIMAL(10,2));

UPDATE pagos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R04 payment_sequential no convertible a INTEGER')
WHERE ("payment_sequential" IS NOT NULL AND TRY_CAST(a_numero("payment_sequential") AS INTEGER) IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R04 payment_sequential no convertible a INTEGER%';

ALTER TABLE pagos_stg ALTER COLUMN "payment_sequential" TYPE INTEGER USING TRY_CAST(a_numero("payment_sequential") AS INTEGER);

ALTER TABLE pagos_stg ALTER COLUMN "payment_installments" TYPE INTEGER USING TRY_CAST(a_numero("payment_installments") AS INTEGER);

UPDATE pagos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R04 payment_value no convertible a DECIMAL(10,2)')
WHERE ("payment_value" IS NOT NULL AND TRY_CAST(a_numero("payment_value") AS DECIMAL(10,2)) IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R04 payment_value no convertible a DECIMAL(10,2)%';

ALTER TABLE pagos_stg ALTER COLUMN "payment_value" TYPE DECIMAL(10,2) USING TRY_CAST(a_numero("payment_value") AS DECIMAL(10,2));

ALTER TABLE productos_stg ALTER COLUMN "product_name_lenght" TYPE INTEGER USING TRY_CAST(a_numero("product_name_lenght") AS INTEGER);

ALTER TABLE productos_stg ALTER COLUMN "product_description_lenght" TYPE INTEGER USING TRY_CAST(a_numero("product_description_lenght") AS INTEGER);

ALTER TABLE productos_stg ALTER COLUMN "product_photos_qty" TYPE INTEGER USING TRY_CAST(a_numero("product_photos_qty") AS INTEGER);

ALTER TABLE productos_stg ALTER COLUMN "product_weight_g" TYPE INTEGER USING TRY_CAST(a_numero("product_weight_g") AS INTEGER);

ALTER TABLE productos_stg ALTER COLUMN "product_length_cm" TYPE INTEGER USING TRY_CAST(a_numero("product_length_cm") AS INTEGER);

ALTER TABLE productos_stg ALTER COLUMN "product_height_cm" TYPE INTEGER USING TRY_CAST(a_numero("product_height_cm") AS INTEGER);

ALTER TABLE productos_stg ALTER COLUMN "product_width_cm" TYPE INTEGER USING TRY_CAST(a_numero("product_width_cm") AS INTEGER);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT order_id FROM pedidos_raw)) FROM pedidos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT order_id, order_item_id FROM items_raw)) FROM items_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'clientes' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'clientes', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT customer_id FROM clientes_raw)) FROM clientes_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT order_id, payment_sequential FROM pagos_raw)) FROM pagos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT product_id FROM productos_raw)) FROM productos_raw) AS m(evaluados, invalidos);

CREATE OR REPLACE TABLE pedidos_stg AS
SELECT * EXCLUDE (n_copia)
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY (s.motivo_cuarentena IS NOT NULL),  -- 1) la copia sin problemas
                        ("order_id" IS NULL)::INT + ("customer_id" IS NULL)::INT + ("order_status" IS NULL)::INT + ("order_purchase_timestamp" IS NULL)::INT + ("order_approved_at" IS NULL)::INT + ("order_delivered_carrier_date" IS NULL)::INT + ("order_delivered_customer_date" IS NULL)::INT + ("order_estimated_delivery_date" IS NULL)::INT,  -- 2) la más completa
                        md5(CAST(s AS VARCHAR))             -- 3) desempate determinista
           ) AS n_copia
    FROM pedidos_stg AS s
)
WHERE n_copia = 1;

CREATE OR REPLACE TABLE items_stg AS
SELECT * EXCLUDE (n_copia)
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, order_item_id
               ORDER BY (s.motivo_cuarentena IS NOT NULL),  -- 1) la copia sin problemas
                        ("order_id" IS NULL)::INT + ("order_item_id" IS NULL)::INT + ("product_id" IS NULL)::INT + ("seller_id" IS NULL)::INT + ("shipping_limit_date" IS NULL)::INT + ("price" IS NULL)::INT + ("freight_value" IS NULL)::INT,  -- 2) la más completa
                        md5(CAST(s AS VARCHAR))             -- 3) desempate determinista
           ) AS n_copia
    FROM items_stg AS s
)
WHERE n_copia = 1;

CREATE OR REPLACE TABLE clientes_stg AS
SELECT * EXCLUDE (n_copia)
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY (s.motivo_cuarentena IS NOT NULL),  -- 1) la copia sin problemas
                        ("customer_id" IS NULL)::INT + ("customer_unique_id" IS NULL)::INT + ("customer_zip_code_prefix" IS NULL)::INT + ("customer_city" IS NULL)::INT + ("customer_state" IS NULL)::INT,  -- 2) la más completa
                        md5(CAST(s AS VARCHAR))             -- 3) desempate determinista
           ) AS n_copia
    FROM clientes_stg AS s
)
WHERE n_copia = 1;

CREATE OR REPLACE TABLE pagos_stg AS
SELECT * EXCLUDE (n_copia)
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, payment_sequential
               ORDER BY (s.motivo_cuarentena IS NOT NULL),  -- 1) la copia sin problemas
                        ("order_id" IS NULL)::INT + ("payment_sequential" IS NULL)::INT + ("payment_type" IS NULL)::INT + ("payment_installments" IS NULL)::INT + ("payment_value" IS NULL)::INT,  -- 2) la más completa
                        md5(CAST(s AS VARCHAR))             -- 3) desempate determinista
           ) AS n_copia
    FROM pagos_stg AS s
)
WHERE n_copia = 1;

CREATE OR REPLACE TABLE productos_stg AS
SELECT * EXCLUDE (n_copia)
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (
               PARTITION BY product_id
               ORDER BY (s.motivo_cuarentena IS NOT NULL),  -- 1) la copia sin problemas
                        ("product_id" IS NULL)::INT + ("product_category_name" IS NULL)::INT + ("product_name_lenght" IS NULL)::INT + ("product_description_lenght" IS NULL)::INT + ("product_photos_qty" IS NULL)::INT + ("product_weight_g" IS NULL)::INT + ("product_length_cm" IS NULL)::INT + ("product_height_cm" IS NULL)::INT + ("product_width_cm" IS NULL)::INT,  -- 2) la más completa
                        md5(CAST(s AS VARCHAR))             -- 3) desempate determinista
           ) AS n_copia
    FROM productos_stg AS s
)
WHERE n_copia = 1;

DELETE FROM quality_report WHERE nombre_regla = 'R11 Códigos postales' AND tabla_evaluada = 'clientes' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R11 Códigos postales', 'clientes', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'LPAD a 5 dígitos si falta el cero inicial; inválido -> NULL y marcado', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE customer_zip_code_prefix IS NULL OR NOT regexp_matches(customer_zip_code_prefix, '^[0-9]{5}$')) FROM clientes_raw) AS m(evaluados, invalidos);

ALTER TABLE clientes_stg ADD COLUMN IF NOT EXISTS cp_corregido BOOLEAN DEFAULT false;

UPDATE clientes_stg
SET cp_corregido = true,
    observaciones = concat_ws('; ', observaciones, 'R11 código postal completado con LPAD')
WHERE (regexp_matches(trim(customer_zip_code_prefix), '^[0-9]{4}$'))
  AND coalesce(observaciones, '') NOT LIKE '%R11 código postal completado con LPAD%';

ALTER TABLE clientes_stg ADD COLUMN IF NOT EXISTS cp_invalido BOOLEAN DEFAULT false;

UPDATE clientes_stg
SET cp_invalido = true,
    observaciones = concat_ws('; ', observaciones, 'R11 código postal inválido')
WHERE (customer_zip_code_prefix IS NOT NULL AND NOT regexp_matches(trim(customer_zip_code_prefix), '^[0-9]{4,5}$'))
  AND coalesce(observaciones, '') NOT LIKE '%R11 código postal inválido%';

UPDATE clientes_stg
SET customer_zip_code_prefix = CASE
        WHEN regexp_matches(trim(customer_zip_code_prefix), '^[0-9]{4,5}$')
        THEN lpad(trim(customer_zip_code_prefix), 5, '0')
    END   -- inválido -> NULL;

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_id" IS NULL OR es_vacio("order_id")) OR ("customer_id" IS NULL OR es_vacio("customer_id")) OR ("order_purchase_timestamp" IS NULL OR es_vacio("order_purchase_timestamp"))) FROM pedidos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_id" IS NULL OR es_vacio("order_id")) OR ("order_item_id" IS NULL OR es_vacio("order_item_id")) OR ("product_id" IS NULL OR es_vacio("product_id")) OR ("price" IS NULL OR es_vacio("price")) OR ("freight_value" IS NULL OR es_vacio("freight_value"))) FROM items_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'clientes' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'clientes', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("customer_id" IS NULL OR es_vacio("customer_id"))) FROM clientes_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_id" IS NULL OR es_vacio("order_id")) OR ("payment_sequential" IS NULL OR es_vacio("payment_sequential")) OR ("payment_value" IS NULL OR es_vacio("payment_value"))) FROM pagos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("product_id" IS NULL OR es_vacio("product_id"))) FROM productos_raw) AS m(evaluados, invalidos);

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R02 campo crítico nulo')
WHERE (("order_id" IS NULL OR "customer_id" IS NULL OR "order_purchase_timestamp" IS NULL) AND motivo_cuarentena IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R02 campo crítico nulo%';

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R02 campo crítico nulo')
WHERE (("order_id" IS NULL OR "order_item_id" IS NULL OR "product_id" IS NULL OR "price" IS NULL OR "freight_value" IS NULL) AND motivo_cuarentena IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R02 campo crítico nulo%';

UPDATE clientes_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R02 campo crítico nulo')
WHERE (("customer_id" IS NULL) AND motivo_cuarentena IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R02 campo crítico nulo%';

UPDATE pagos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R02 campo crítico nulo')
WHERE (("order_id" IS NULL OR "payment_sequential" IS NULL OR "payment_value" IS NULL) AND motivo_cuarentena IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R02 campo crítico nulo%';

UPDATE productos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R02 campo crítico nulo')
WHERE (("product_id" IS NULL) AND motivo_cuarentena IS NULL)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R02 campo crítico nulo%';

CREATE OR REPLACE TEMP TABLE ciudad_por_cp AS
SELECT customer_zip_code_prefix, any_value(customer_city) AS ciudad
FROM clientes_stg
WHERE customer_city IS NOT NULL AND customer_zip_code_prefix IS NOT NULL
GROUP BY customer_zip_code_prefix
HAVING count(DISTINCT customer_city) = 1;

ALTER TABLE clientes_stg ADD COLUMN IF NOT EXISTS ciudad_imputada BOOLEAN DEFAULT false;

UPDATE clientes_stg
SET ciudad_imputada = true,
    observaciones = concat_ws('; ', observaciones, 'R02 ciudad imputada desde el código postal')
WHERE (customer_city IS NULL AND customer_zip_code_prefix IN (SELECT customer_zip_code_prefix FROM ciudad_por_cp))
  AND coalesce(observaciones, '') NOT LIKE '%R02 ciudad imputada desde el código postal%';

UPDATE clientes_stg AS c
SET customer_city = z.ciudad
FROM ciudad_por_cp AS z
WHERE c.customer_city IS NULL AND c.customer_zip_code_prefix = z.customer_zip_code_prefix;

ALTER TABLE productos_stg ADD COLUMN IF NOT EXISTS categoria_imputada BOOLEAN DEFAULT false;

UPDATE productos_stg
SET categoria_imputada = true,
    observaciones = concat_ws('; ', observaciones, 'R02 categoría imputada como sin_categoria')
WHERE (product_category_name IS NULL)
  AND coalesce(observaciones, '') NOT LIKE '%R02 categoría imputada como sin_categoria%';

UPDATE productos_stg SET product_category_name = COALESCE(product_category_name, 'sin_categoria');

CREATE OR REPLACE TABLE catalogo_categorias AS
WITH traduccion AS (
    -- Archivo de traducción oficial del dataset
    SELECT normalizar_texto(product_category_name) AS categoria,
           normalizar_texto(product_category_name_english) AS categoria_en
    FROM categorias_raw
    UNION ALL
    -- Categorías presentes en productos pero ausentes del archivo de traducción
    SELECT * FROM (VALUES
        ('pc_gamer', 'pc_gamer'),
        ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'),
        ('sin_categoria', 'uncategorized')
    ) AS v(categoria, categoria_en)
),
equivalencias AS (
    -- El sufijo _2 es la misma categoría duplicada en el catálogo de Olist
    SELECT * FROM (VALUES
        ('casa_conforto_2', 'casa_conforto'),
        ('eletrodomesticos_2', 'eletrodomesticos')
    ) AS v(categoria, categoria_estandar)
)
SELECT t.categoria                                 AS categoria_original,
       coalesce(e.categoria_estandar, t.categoria) AS categoria_estandar,
       coalesce(t2.categoria_en, t.categoria_en)   AS categoria_en
FROM traduccion AS t
LEFT JOIN equivalencias AS e  ON e.categoria = t.categoria
LEFT JOIN traduccion    AS t2 ON t2.categoria = e.categoria_estandar;

DELETE FROM quality_report WHERE nombre_regla = 'R08 Categorías' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R08 Categorías', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir con catálogo de correspondencias', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE NOT es_vacio(product_category_name) AND product_category_name NOT IN (SELECT categoria_estandar FROM catalogo_categorias)) FROM productos_raw) AS m(evaluados, invalidos);

UPDATE productos_stg SET product_category_name = replace(replace(product_category_name, ' ', '_'), '-', '_');

ALTER TABLE productos_stg ADD COLUMN IF NOT EXISTS product_category_name_english VARCHAR;

UPDATE productos_stg AS p
SET product_category_name = c.categoria_estandar,
    product_category_name_english = c.categoria_en
FROM catalogo_categorias AS c
WHERE p.product_category_name = c.categoria_original;

ALTER TABLE productos_stg ADD COLUMN IF NOT EXISTS categoria_no_catalogada BOOLEAN DEFAULT false;

UPDATE productos_stg
SET categoria_no_catalogada = true,
    observaciones = concat_ws('; ', observaciones, 'R08 categoría fuera del catálogo')
WHERE (product_category_name_english IS NULL)
  AND coalesce(observaciones, '') NOT LIKE '%R08 categoría fuera del catálogo%';

DELETE FROM quality_report WHERE nombre_regla = 'R13 Métodos de pago' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R13 Métodos de pago', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Normalizar con CASE; valores desconocidos -> desconocido y marcado', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE coalesce(payment_type, '') NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')) FROM pagos_raw) AS m(evaluados, invalidos);

ALTER TABLE pagos_stg ADD COLUMN IF NOT EXISTS metodo_desconocido BOOLEAN DEFAULT false;

UPDATE pagos_stg
    SET metodo_desconocido = true,
        observaciones = concat_ws('; ', observaciones, 'R13 método de pago desconocido')
    WHERE ((
CASE replace(payment_type, ' ', '_')
    WHEN 'credit_card'    THEN 'credit_card'
    WHEN 'creditcard'     THEN 'credit_card'
    WHEN 'cartao_credito' THEN 'credit_card'
    WHEN 'debit_card'     THEN 'debit_card'
    WHEN 'cartao_debito'  THEN 'debit_card'
    WHEN 'boleto'         THEN 'boleto'
    WHEN 'voucher'        THEN 'voucher'
    ELSE 'desconocido'    -- not_defined, valores nuevos o NULL
END) = 'desconocido')
      AND coalesce(observaciones, '') NOT LIKE '%R13 método de pago desconocido%';

UPDATE pagos_stg SET payment_type = 
    CASE replace(payment_type, ' ', '_')
        WHEN 'credit_card'    THEN 'credit_card'
        WHEN 'creditcard'     THEN 'credit_card'
        WHEN 'cartao_credito' THEN 'credit_card'
        WHEN 'debit_card'     THEN 'debit_card'
        WHEN 'cartao_debito'  THEN 'debit_card'
        WHEN 'boleto'         THEN 'boleto'
        WHEN 'voucher'        THEN 'voucher'
        ELSE 'desconocido'    -- not_defined, valores nuevos o NULL
    END;

DELETE FROM quality_report WHERE nombre_regla = 'R05 Fechas inconsistentes' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R05 Fechas inconsistentes', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si la secuencia es imposible; marcar desfases de registro', current_timestamp
FROM (WITH p AS (SELECT a_fecha(order_purchase_timestamp) AS order_purchase_timestamp, a_fecha(order_approved_at) AS order_approved_at, a_fecha(order_delivered_carrier_date) AS order_delivered_carrier_date, a_fecha(order_delivered_customer_date) AS order_delivered_customer_date, a_fecha(order_estimated_delivery_date) AS order_estimated_delivery_date FROM pedidos_raw) SELECT count(*), count(*) FILTER (WHERE (order_delivered_customer_date < order_purchase_timestamp) OR (CAST(order_estimated_delivery_date AS DATE) < CAST(order_purchase_timestamp AS DATE)) OR (order_approved_at < order_purchase_timestamp) OR (order_purchase_timestamp NOT BETWEEN TIMESTAMP '2016-01-01' AND TIMESTAMP '2018-12-31 23:59:59') OR (order_delivered_carrier_date < order_purchase_timestamp) OR (order_delivered_customer_date < order_delivered_carrier_date)) FROM p) AS m(evaluados, invalidos);

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R05 entrega al cliente anterior a la compra')
WHERE (order_delivered_customer_date < order_purchase_timestamp)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R05 entrega al cliente anterior a la compra%';

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R05 fecha estimada anterior a la compra')
WHERE (CAST(order_estimated_delivery_date AS DATE) < CAST(order_purchase_timestamp AS DATE))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R05 fecha estimada anterior a la compra%';

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R05 aprobación anterior a la compra')
WHERE (order_approved_at < order_purchase_timestamp)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R05 aprobación anterior a la compra%';

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R05 compra fuera del periodo del dataset')
WHERE (order_purchase_timestamp NOT BETWEEN TIMESTAMP '2016-01-01' AND TIMESTAMP '2018-12-31 23:59:59')
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R05 compra fuera del periodo del dataset%';

ALTER TABLE pedidos_stg ADD COLUMN IF NOT EXISTS fecha_inconsistente BOOLEAN DEFAULT false;

UPDATE pedidos_stg
SET fecha_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R05 entrega al transportista anterior a la compra')
WHERE (order_delivered_carrier_date < order_purchase_timestamp)
  AND coalesce(observaciones, '') NOT LIKE '%R05 entrega al transportista anterior a la compra%';

UPDATE pedidos_stg
SET fecha_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R05 entrega al cliente anterior a la entrega al transportista')
WHERE (order_delivered_customer_date < order_delivered_carrier_date)
  AND coalesce(observaciones, '') NOT LIKE '%R05 entrega al cliente anterior a la entrega al transportista%';

DELETE FROM quality_report WHERE nombre_regla = 'R10 Estados de pedido' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R10 Estados de pedido', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar contradicciones entre estado y fechas', current_timestamp
FROM (WITH p AS (SELECT normalizar_texto(order_status) AS order_status, a_fecha(order_delivered_carrier_date) AS order_delivered_carrier_date, a_fecha(order_delivered_customer_date) AS order_delivered_customer_date FROM pedidos_raw) SELECT count(*), count(*) FILTER (WHERE (order_status = 'delivered' AND order_delivered_customer_date IS NULL) OR (order_status IN ('canceled', 'unavailable') AND order_delivered_customer_date IS NOT NULL) OR (order_status IN ('created', 'approved', 'invoiced', 'processing') AND (order_delivered_carrier_date IS NOT NULL OR order_delivered_customer_date IS NOT NULL)) OR (order_status IN ('shipped', 'delivered') AND order_delivered_carrier_date IS NULL) OR (order_status IS NULL OR order_status NOT IN ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'canceled', 'unavailable'))) FROM p) AS m(evaluados, invalidos);

ALTER TABLE pedidos_stg ADD COLUMN IF NOT EXISTS estado_inconsistente BOOLEAN DEFAULT false;

UPDATE pedidos_stg
SET estado_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R10 entregado sin fecha de entrega')
WHERE (order_status = 'delivered' AND order_delivered_customer_date IS NULL)
  AND coalesce(observaciones, '') NOT LIKE '%R10 entregado sin fecha de entrega%';

UPDATE pedidos_stg
SET estado_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R10 cancelado o no disponible con fecha de entrega')
WHERE (order_status IN ('canceled', 'unavailable') AND order_delivered_customer_date IS NOT NULL)
  AND coalesce(observaciones, '') NOT LIKE '%R10 cancelado o no disponible con fecha de entrega%';

UPDATE pedidos_stg
SET estado_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R10 estado previo al envío con fecha de envío o entrega')
WHERE (order_status IN ('created', 'approved', 'invoiced', 'processing') AND (order_delivered_carrier_date IS NOT NULL OR order_delivered_customer_date IS NOT NULL))
  AND coalesce(observaciones, '') NOT LIKE '%R10 estado previo al envío con fecha de envío o entrega%';

UPDATE pedidos_stg
SET estado_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R10 enviado o entregado sin fecha de transportista')
WHERE (order_status IN ('shipped', 'delivered') AND order_delivered_carrier_date IS NULL)
  AND coalesce(observaciones, '') NOT LIKE '%R10 enviado o entregado sin fecha de transportista%';

UPDATE pedidos_stg
SET estado_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R10 estado vacío o no reconocido')
WHERE (order_status IS NULL OR order_status NOT IN ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'canceled', 'unavailable'))
  AND coalesce(observaciones, '') NOT LIKE '%R10 estado vacío o no reconocido%';

UPDATE pedidos_stg SET order_status = 'desconocido'
WHERE order_status IS NULL OR order_status NOT IN ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'canceled', 'unavailable');

DELETE FROM quality_report WHERE nombre_regla = 'R06 Precios inválidos' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R06 Precios inválidos', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena: precio <= 0, flete < 0 o pago < 0', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE a_numero(price) <= 0 OR a_numero(freight_value) < 0) FROM items_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R06 Precios inválidos' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R06 Precios inválidos', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena: precio <= 0, flete < 0 o pago < 0', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE a_numero(payment_value) < 0) FROM pagos_raw) AS m(evaluados, invalidos);

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R06 precio menor o igual a cero')
WHERE (price <= 0)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R06 precio menor o igual a cero%';

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R06 flete negativo')
WHERE (freight_value < 0)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R06 flete negativo%';

UPDATE pagos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R06 monto de pago negativo')
WHERE (payment_value < 0)
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R06 monto de pago negativo%';

ALTER TABLE pagos_stg ADD COLUMN IF NOT EXISTS pago_cero BOOLEAN DEFAULT false;

UPDATE pagos_stg
SET pago_cero = true,
    observaciones = concat_ws('; ', observaciones, 'R06 pago con valor cero')
WHERE (payment_value = 0)
  AND coalesce(observaciones, '') NOT LIKE '%R06 pago con valor cero%';

DELETE FROM quality_report WHERE nombre_regla = 'R09 Integridad referencial' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R09 Integridad referencial', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena de huérfanos y, en cascada, de hijos de pedidos en cuarentena', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE c.customer_id IS NULL) FROM pedidos_raw AS p LEFT JOIN (SELECT DISTINCT customer_id FROM clientes_raw) AS c USING (customer_id)) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R09 Integridad referencial' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R09 Integridad referencial', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena de huérfanos y, en cascada, de hijos de pedidos en cuarentena', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM pedidos_raw p WHERE p.order_id = i.order_id) OR NOT EXISTS (SELECT 1 FROM productos_raw pr WHERE pr.product_id = i.product_id)) FROM items_raw AS i) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R09 Integridad referencial' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R09 Integridad referencial', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena de huérfanos y, en cascada, de hijos de pedidos en cuarentena', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM pedidos_raw p WHERE p.order_id = g.order_id)) FROM pagos_raw AS g) AS m(evaluados, invalidos);

UPDATE pedidos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R09 cliente inexistente')
WHERE (NOT EXISTS (SELECT 1 FROM clientes_stg c WHERE c.customer_id = pedidos_stg.customer_id))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R09 cliente inexistente%';

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R09 pedido inexistente')
WHERE (NOT EXISTS (SELECT 1 FROM pedidos_stg p WHERE p.order_id = items_stg.order_id))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R09 pedido inexistente%';

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R09 pedido en cuarentena')
WHERE (EXISTS (SELECT 1 FROM pedidos_stg p WHERE p.order_id = items_stg.order_id AND p.motivo_cuarentena IS NOT NULL))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R09 pedido en cuarentena%';

UPDATE pagos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R09 pedido inexistente')
WHERE (NOT EXISTS (SELECT 1 FROM pedidos_stg p WHERE p.order_id = pagos_stg.order_id))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R09 pedido inexistente%';

UPDATE pagos_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R09 pedido en cuarentena')
WHERE (EXISTS (SELECT 1 FROM pedidos_stg p WHERE p.order_id = pagos_stg.order_id AND p.motivo_cuarentena IS NOT NULL))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R09 pedido en cuarentena%';

UPDATE items_stg
SET motivo_cuarentena = concat_ws('; ', motivo_cuarentena, 'R09 producto inexistente')
WHERE (NOT EXISTS (SELECT 1 FROM productos_stg pr WHERE pr.product_id = items_stg.product_id))
  AND coalesce(motivo_cuarentena, '') NOT LIKE '%R09 producto inexistente%';

ALTER TABLE pedidos_stg ADD COLUMN IF NOT EXISTS sin_items BOOLEAN DEFAULT false;

UPDATE pedidos_stg
SET sin_items = true,
    observaciones = concat_ws('; ', observaciones, 'R09 pedido sin ítems válidos')
WHERE (motivo_cuarentena IS NULL AND NOT EXISTS (SELECT 1 FROM items_stg i WHERE i.order_id = pedidos_stg.order_id AND i.motivo_cuarentena IS NULL))
  AND coalesce(observaciones, '') NOT LIKE '%R09 pedido sin ítems válidos%';

ALTER TABLE pedidos_stg ADD COLUMN IF NOT EXISTS sin_pagos BOOLEAN DEFAULT false;

UPDATE pedidos_stg
SET sin_pagos = true,
    observaciones = concat_ws('; ', observaciones, 'R09 pedido sin pagos válidos')
WHERE (motivo_cuarentena IS NULL AND NOT EXISTS (SELECT 1 FROM pagos_stg g WHERE g.order_id = pedidos_stg.order_id AND g.motivo_cuarentena IS NULL))
  AND coalesce(observaciones, '') NOT LIKE '%R09 pedido sin pagos válidos%';

DELETE FROM quality_report WHERE nombre_regla = 'R07 Valores atípicos (IQR)' AND tabla_evaluada = 'items.price' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R07 Valores atípicos (IQR)', 'items.price', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar: un atípico no es necesariamente un error', current_timestamp
FROM (
WITH v AS (SELECT a_numero(price) AS x FROM items_raw WHERE a_numero(price) IS NOT NULL),
     l AS (SELECT quantile_cont(x, 0.25) AS q1, quantile_cont(x, 0.75) AS q3 FROM v)
SELECT count(*), count(*) FILTER (WHERE x < q1 - 1.5 * (q3 - q1) OR x > q3 + 1.5 * (q3 - q1))
FROM v, l) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R07 Valores atípicos (IQR)' AND tabla_evaluada = 'items.freight_value' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R07 Valores atípicos (IQR)', 'items.freight_value', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar: un atípico no es necesariamente un error', current_timestamp
FROM (
WITH v AS (SELECT a_numero(freight_value) AS x FROM items_raw WHERE a_numero(freight_value) IS NOT NULL),
     l AS (SELECT quantile_cont(x, 0.25) AS q1, quantile_cont(x, 0.75) AS q3 FROM v)
SELECT count(*), count(*) FILTER (WHERE x < q1 - 1.5 * (q3 - q1) OR x > q3 + 1.5 * (q3 - q1))
FROM v, l) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R07 Valores atípicos (IQR)' AND tabla_evaluada = 'pagos.payment_value' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R07 Valores atípicos (IQR)', 'pagos.payment_value', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar: un atípico no es necesariamente un error', current_timestamp
FROM (
WITH v AS (SELECT a_numero(payment_value) AS x FROM pagos_raw WHERE a_numero(payment_value) IS NOT NULL),
     l AS (SELECT quantile_cont(x, 0.25) AS q1, quantile_cont(x, 0.75) AS q3 FROM v)
SELECT count(*), count(*) FILTER (WHERE x < q1 - 1.5 * (q3 - q1) OR x > q3 + 1.5 * (q3 - q1))
FROM v, l) AS m(evaluados, invalidos);

CREATE OR REPLACE TABLE limites_iqr AS
WITH valores AS (
    SELECT 'price' AS variable, CAST(price AS DOUBLE) AS valor FROM items_stg WHERE motivo_cuarentena IS NULL
    UNION ALL
    SELECT 'freight_value', CAST(freight_value AS DOUBLE) FROM items_stg WHERE motivo_cuarentena IS NULL
    UNION ALL
    SELECT 'payment_value', CAST(payment_value AS DOUBLE) FROM pagos_stg WHERE motivo_cuarentena IS NULL
),
cuartiles AS (
    SELECT variable, count(*) AS n,
           quantile_cont(valor, 0.25) AS q1,
           quantile_cont(valor, 0.75) AS q3
    FROM valores GROUP BY variable
)
SELECT variable, n, q1, q3, q3 - q1 AS iqr,
       q1 - 1.5 * (q3 - q1) AS limite_inferior,
       q3 + 1.5 * (q3 - q1) AS limite_superior
FROM cuartiles;

ALTER TABLE items_stg ADD COLUMN IF NOT EXISTS atipico_precio BOOLEAN DEFAULT false;

UPDATE items_stg
SET atipico_precio = true,
    observaciones = concat_ws('; ', observaciones, 'R07 precio atípico (IQR)')
WHERE (motivo_cuarentena IS NULL AND (price < (SELECT limite_inferior FROM limites_iqr WHERE variable = 'price') OR price > (SELECT limite_superior FROM limites_iqr WHERE variable = 'price')))
  AND coalesce(observaciones, '') NOT LIKE '%R07 precio atípico (IQR)%';

ALTER TABLE items_stg ADD COLUMN IF NOT EXISTS atipico_flete BOOLEAN DEFAULT false;

UPDATE items_stg
SET atipico_flete = true,
    observaciones = concat_ws('; ', observaciones, 'R07 flete atípico (IQR)')
WHERE (motivo_cuarentena IS NULL AND (freight_value < (SELECT limite_inferior FROM limites_iqr WHERE variable = 'freight_value') OR freight_value > (SELECT limite_superior FROM limites_iqr WHERE variable = 'freight_value')))
  AND coalesce(observaciones, '') NOT LIKE '%R07 flete atípico (IQR)%';

ALTER TABLE pagos_stg ADD COLUMN IF NOT EXISTS atipico_pago BOOLEAN DEFAULT false;

UPDATE pagos_stg
SET atipico_pago = true,
    observaciones = concat_ws('; ', observaciones, 'R07 pago atípico (IQR)')
WHERE (motivo_cuarentena IS NULL AND (payment_value < (SELECT limite_inferior FROM limites_iqr WHERE variable = 'payment_value') OR payment_value > (SELECT limite_superior FROM limites_iqr WHERE variable = 'payment_value')))
  AND coalesce(observaciones, '') NOT LIKE '%R07 pago atípico (IQR)%';

DELETE FROM quality_report WHERE nombre_regla = 'R12 Pagos vs ítems' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'R12 Pagos vs ítems', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar pedidos con diferencia mayor a la tolerancia', current_timestamp
FROM (
WITH it AS (SELECT order_id, sum(a_numero(price) + a_numero(freight_value)) AS total_items
            FROM items_raw GROUP BY order_id),
     pg AS (SELECT order_id, sum(a_numero(payment_value)) AS total_pagado
            FROM pagos_raw GROUP BY order_id)
SELECT count(*), count(*) FILTER (WHERE abs(total_pagado - total_items) > 1.0)
FROM it JOIN pg USING (order_id)) AS m(evaluados, invalidos);

CREATE OR REPLACE TABLE conciliacion_pagos AS
WITH it AS (
    SELECT order_id, count(*) AS num_items, sum(price + freight_value) AS total_items
    FROM items_stg WHERE motivo_cuarentena IS NULL GROUP BY order_id
),
pg AS (
    SELECT order_id, count(*) AS num_pagos, count(DISTINCT payment_type) AS num_metodos,
           max(payment_installments) AS max_cuotas, sum(payment_value) AS total_pagado
    FROM pagos_stg WHERE motivo_cuarentena IS NULL GROUP BY order_id
)
SELECT p.order_id, p.order_status,
       coalesce(it.num_items, 0)    AS num_items,
       coalesce(it.total_items, 0)  AS total_items,
       coalesce(pg.num_pagos, 0)    AS num_pagos,
       coalesce(pg.num_metodos, 0)  AS num_metodos,
       pg.max_cuotas,
       coalesce(pg.total_pagado, 0) AS total_pagado,
       coalesce(pg.total_pagado, 0) - coalesce(it.total_items, 0) AS diferencia,
       CASE
           WHEN it.order_id IS NULL OR pg.order_id IS NULL THEN 'sin ítems o sin pagos'
           WHEN abs(diferencia) <= 1.0 THEN 'cuadra'
           WHEN diferencia > 0 THEN 'pagado de más'
           ELSE 'pagado de menos'
       END AS resultado
FROM pedidos_stg AS p
LEFT JOIN it USING (order_id)
LEFT JOIN pg USING (order_id)
WHERE p.motivo_cuarentena IS NULL;

ALTER TABLE pedidos_stg ADD COLUMN IF NOT EXISTS pago_inconsistente BOOLEAN DEFAULT false;

UPDATE pedidos_stg
SET pago_inconsistente = true,
    observaciones = concat_ws('; ', observaciones, 'R12 pagos no cuadran con ítems + flete')
WHERE (order_id IN (SELECT order_id FROM conciliacion_pagos WHERE resultado IN ('pagado de más', 'pagado de menos')))
  AND coalesce(observaciones, '') NOT LIKE '%R12 pagos no cuadran con ítems + flete%';

CREATE OR REPLACE TABLE pedidos_clean AS SELECT * EXCLUDE (motivo_cuarentena) FROM pedidos_stg WHERE motivo_cuarentena IS NULL;

CREATE OR REPLACE TABLE pedidos_cuarentena AS SELECT * FROM pedidos_stg WHERE motivo_cuarentena IS NOT NULL;

CREATE OR REPLACE TABLE items_clean AS SELECT * EXCLUDE (motivo_cuarentena) FROM items_stg WHERE motivo_cuarentena IS NULL;

CREATE OR REPLACE TABLE items_cuarentena AS SELECT * FROM items_stg WHERE motivo_cuarentena IS NOT NULL;

CREATE OR REPLACE TABLE clientes_clean AS SELECT * EXCLUDE (motivo_cuarentena) FROM clientes_stg WHERE motivo_cuarentena IS NULL;

CREATE OR REPLACE TABLE clientes_cuarentena AS SELECT * FROM clientes_stg WHERE motivo_cuarentena IS NOT NULL;

CREATE OR REPLACE TABLE pagos_clean AS SELECT * EXCLUDE (motivo_cuarentena) FROM pagos_stg WHERE motivo_cuarentena IS NULL;

CREATE OR REPLACE TABLE pagos_cuarentena AS SELECT * FROM pagos_stg WHERE motivo_cuarentena IS NOT NULL;

CREATE OR REPLACE TABLE productos_clean AS SELECT * EXCLUDE (motivo_cuarentena) FROM productos_stg WHERE motivo_cuarentena IS NULL;

CREATE OR REPLACE TABLE productos_cuarentena AS SELECT * FROM productos_stg WHERE motivo_cuarentena IS NOT NULL;

CREATE OR REPLACE TABLE resumen_cuarentena AS
SELECT tabla, motivo, count(*) AS registros FROM (SELECT 'pedidos' AS tabla, unnest(string_split(motivo_cuarentena, '; ')) AS motivo FROM pedidos_cuarentena UNION ALL SELECT 'items' AS tabla, unnest(string_split(motivo_cuarentena, '; ')) AS motivo FROM items_cuarentena UNION ALL SELECT 'clientes' AS tabla, unnest(string_split(motivo_cuarentena, '; ')) AS motivo FROM clientes_cuarentena UNION ALL SELECT 'pagos' AS tabla, unnest(string_split(motivo_cuarentena, '; ')) AS motivo FROM pagos_cuarentena UNION ALL SELECT 'productos' AS tabla, unnest(string_split(motivo_cuarentena, '; ')) AS motivo FROM productos_cuarentena) GROUP BY ALL;

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'pedidos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'pedidos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 8, count(*) FILTER (WHERE "order_id" IS NULL OR es_vacio("order_id")) + count(*) FILTER (WHERE "customer_id" IS NULL OR es_vacio("customer_id")) + count(*) FILTER (WHERE "order_status" IS NULL OR es_vacio("order_status")) + count(*) FILTER (WHERE "order_purchase_timestamp" IS NULL OR es_vacio("order_purchase_timestamp")) + count(*) FILTER (WHERE "order_approved_at" IS NULL OR es_vacio("order_approved_at")) + count(*) FILTER (WHERE "order_delivered_carrier_date" IS NULL OR es_vacio("order_delivered_carrier_date")) + count(*) FILTER (WHERE "order_delivered_customer_date" IS NULL OR es_vacio("order_delivered_customer_date")) + count(*) FILTER (WHERE "order_estimated_delivery_date" IS NULL OR es_vacio("order_estimated_delivery_date")) FROM pedidos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'items' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'items', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 7, count(*) FILTER (WHERE "order_id" IS NULL OR es_vacio("order_id")) + count(*) FILTER (WHERE "order_item_id" IS NULL OR es_vacio("order_item_id")) + count(*) FILTER (WHERE "product_id" IS NULL OR es_vacio("product_id")) + count(*) FILTER (WHERE "seller_id" IS NULL OR es_vacio("seller_id")) + count(*) FILTER (WHERE "shipping_limit_date" IS NULL OR es_vacio("shipping_limit_date")) + count(*) FILTER (WHERE "price" IS NULL OR es_vacio("price")) + count(*) FILTER (WHERE "freight_value" IS NULL OR es_vacio("freight_value")) FROM items_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'clientes' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'clientes', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 5, count(*) FILTER (WHERE "customer_id" IS NULL OR es_vacio("customer_id")) + count(*) FILTER (WHERE "customer_unique_id" IS NULL OR es_vacio("customer_unique_id")) + count(*) FILTER (WHERE "customer_zip_code_prefix" IS NULL OR es_vacio("customer_zip_code_prefix")) + count(*) FILTER (WHERE "customer_city" IS NULL OR es_vacio("customer_city")) + count(*) FILTER (WHERE "customer_state" IS NULL OR es_vacio("customer_state")) FROM clientes_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'pagos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'pagos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 5, count(*) FILTER (WHERE "order_id" IS NULL OR es_vacio("order_id")) + count(*) FILTER (WHERE "payment_sequential" IS NULL OR es_vacio("payment_sequential")) + count(*) FILTER (WHERE "payment_type" IS NULL OR es_vacio("payment_type")) + count(*) FILTER (WHERE "payment_installments" IS NULL OR es_vacio("payment_installments")) + count(*) FILTER (WHERE "payment_value" IS NULL OR es_vacio("payment_value")) FROM pagos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'productos' AND etapa = 'antes';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'productos', 'antes', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 9, count(*) FILTER (WHERE "product_id" IS NULL OR es_vacio("product_id")) + count(*) FILTER (WHERE "product_category_name" IS NULL OR es_vacio("product_category_name")) + count(*) FILTER (WHERE "product_name_lenght" IS NULL OR es_vacio("product_name_lenght")) + count(*) FILTER (WHERE "product_description_lenght" IS NULL OR es_vacio("product_description_lenght")) + count(*) FILTER (WHERE "product_photos_qty" IS NULL OR es_vacio("product_photos_qty")) + count(*) FILTER (WHERE "product_weight_g" IS NULL OR es_vacio("product_weight_g")) + count(*) FILTER (WHERE "product_length_cm" IS NULL OR es_vacio("product_length_cm")) + count(*) FILTER (WHERE "product_height_cm" IS NULL OR es_vacio("product_height_cm")) + count(*) FILTER (WHERE "product_width_cm" IS NULL OR es_vacio("product_width_cm")) FROM productos_raw) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("order_id") OR es_vacio("customer_id") OR es_vacio("order_status") OR es_vacio("order_purchase_timestamp") OR es_vacio("order_approved_at") OR es_vacio("order_delivered_carrier_date") OR es_vacio("order_delivered_customer_date") OR es_vacio("order_estimated_delivery_date")) FROM pedidos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("order_id") OR es_vacio("order_item_id") OR es_vacio("product_id") OR es_vacio("seller_id") OR es_vacio("shipping_limit_date") OR es_vacio("price") OR es_vacio("freight_value")) FROM items_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'clientes' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'clientes', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("customer_id") OR es_vacio("customer_unique_id") OR es_vacio("customer_zip_code_prefix") OR es_vacio("customer_city") OR es_vacio("customer_state")) FROM clientes_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("order_id") OR es_vacio("payment_sequential") OR es_vacio("payment_type") OR es_vacio("payment_installments") OR es_vacio("payment_value")) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R14 Cadenas vacías' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R14 Cadenas vacías', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: '''', espacios y textos tipo N/A pasan a NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE es_vacio("product_id") OR es_vacio("product_category_name") OR es_vacio("product_name_lenght") OR es_vacio("product_description_lenght") OR es_vacio("product_photos_qty") OR es_vacio("product_weight_g") OR es_vacio("product_length_cm") OR es_vacio("product_height_cm") OR es_vacio("product_width_cm")) FROM productos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE order_status <> normalizar_texto(order_status) AND NOT es_vacio(order_status)) FROM pedidos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'clientes' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'clientes', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE (customer_city <> normalizar_texto(customer_city) AND NOT es_vacio(customer_city)) OR customer_state <> upper(trim(customer_state))) FROM clientes_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE product_category_name <> normalizar_texto(product_category_name) AND NOT es_vacio(product_category_name)) FROM productos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R03 Estandarización de texto' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R03 Estandarización de texto', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: TRIM, minúsculas (UF en mayúsculas) y sin tildes', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE payment_type <> normalizar_texto(payment_type) AND NOT es_vacio(payment_type)) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_purchase_timestamp" IS NOT NULL AND NOT es_vacio("order_purchase_timestamp") AND a_fecha("order_purchase_timestamp") IS NULL) OR ("order_approved_at" IS NOT NULL AND NOT es_vacio("order_approved_at") AND a_fecha("order_approved_at") IS NULL) OR ("order_delivered_carrier_date" IS NOT NULL AND NOT es_vacio("order_delivered_carrier_date") AND a_fecha("order_delivered_carrier_date") IS NULL) OR ("order_delivered_customer_date" IS NOT NULL AND NOT es_vacio("order_delivered_customer_date") AND a_fecha("order_delivered_customer_date") IS NULL) OR ("order_estimated_delivery_date" IS NOT NULL AND NOT es_vacio("order_estimated_delivery_date") AND a_fecha("order_estimated_delivery_date") IS NULL)) FROM pedidos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_item_id" IS NOT NULL AND NOT es_vacio("order_item_id") AND TRY_CAST(a_numero("order_item_id") AS INTEGER) IS NULL) OR ("shipping_limit_date" IS NOT NULL AND NOT es_vacio("shipping_limit_date") AND a_fecha("shipping_limit_date") IS NULL) OR ("price" IS NOT NULL AND NOT es_vacio("price") AND TRY_CAST(a_numero("price") AS DECIMAL(10,2)) IS NULL) OR ("freight_value" IS NOT NULL AND NOT es_vacio("freight_value") AND TRY_CAST(a_numero("freight_value") AS DECIMAL(10,2)) IS NULL)) FROM items_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("payment_sequential" IS NOT NULL AND NOT es_vacio("payment_sequential") AND TRY_CAST(a_numero("payment_sequential") AS INTEGER) IS NULL) OR ("payment_installments" IS NOT NULL AND NOT es_vacio("payment_installments") AND TRY_CAST(a_numero("payment_installments") AS INTEGER) IS NULL) OR ("payment_value" IS NOT NULL AND NOT es_vacio("payment_value") AND TRY_CAST(a_numero("payment_value") AS DECIMAL(10,2)) IS NULL)) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R04 Tipos de datos' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R04 Tipos de datos', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Convertir; valor crítico no convertible -> cuarentena; no crítico -> NULL', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("product_name_lenght" IS NOT NULL AND NOT es_vacio("product_name_lenght") AND TRY_CAST(a_numero("product_name_lenght") AS INTEGER) IS NULL) OR ("product_description_lenght" IS NOT NULL AND NOT es_vacio("product_description_lenght") AND TRY_CAST(a_numero("product_description_lenght") AS INTEGER) IS NULL) OR ("product_photos_qty" IS NOT NULL AND NOT es_vacio("product_photos_qty") AND TRY_CAST(a_numero("product_photos_qty") AS INTEGER) IS NULL) OR ("product_weight_g" IS NOT NULL AND NOT es_vacio("product_weight_g") AND TRY_CAST(a_numero("product_weight_g") AS INTEGER) IS NULL) OR ("product_length_cm" IS NOT NULL AND NOT es_vacio("product_length_cm") AND TRY_CAST(a_numero("product_length_cm") AS INTEGER) IS NULL) OR ("product_height_cm" IS NOT NULL AND NOT es_vacio("product_height_cm") AND TRY_CAST(a_numero("product_height_cm") AS INTEGER) IS NULL) OR ("product_width_cm" IS NOT NULL AND NOT es_vacio("product_width_cm") AND TRY_CAST(a_numero("product_width_cm") AS INTEGER) IS NULL)) FROM productos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT order_id FROM pedidos_clean)) FROM pedidos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT order_id, order_item_id FROM items_clean)) FROM items_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'clientes' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'clientes', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT customer_id FROM clientes_clean)) FROM clientes_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT order_id, payment_sequential FROM pagos_clean)) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R01 Duplicados' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R01 Duplicados', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir: se conserva un registro por clave de negocio (el más completo)', current_timestamp
FROM (SELECT count(*), count(*) - (SELECT count(*) FROM (SELECT DISTINCT product_id FROM productos_clean)) FROM productos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R11 Códigos postales' AND tabla_evaluada = 'clientes' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R11 Códigos postales', 'clientes', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'LPAD a 5 dígitos si falta el cero inicial; inválido -> NULL y marcado', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE customer_zip_code_prefix IS NULL OR NOT regexp_matches(customer_zip_code_prefix, '^[0-9]{5}$')) FROM clientes_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_id" IS NULL OR es_vacio("order_id")) OR ("customer_id" IS NULL OR es_vacio("customer_id")) OR ("order_purchase_timestamp" IS NULL OR es_vacio("order_purchase_timestamp"))) FROM pedidos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_id" IS NULL OR es_vacio("order_id")) OR ("order_item_id" IS NULL OR es_vacio("order_item_id")) OR ("product_id" IS NULL OR es_vacio("product_id")) OR ("price" IS NULL OR es_vacio("price")) OR ("freight_value" IS NULL OR es_vacio("freight_value"))) FROM items_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'clientes' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'clientes', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("customer_id" IS NULL OR es_vacio("customer_id"))) FROM clientes_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("order_id" IS NULL OR es_vacio("order_id")) OR ("payment_sequential" IS NULL OR es_vacio("payment_sequential")) OR ("payment_value" IS NULL OR es_vacio("payment_value"))) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R02 Valores nulos' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R02 Valores nulos', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si falta un campo crítico; imputar ciudad y categoría; conservar el resto', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE ("product_id" IS NULL OR es_vacio("product_id"))) FROM productos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R08 Categorías' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R08 Categorías', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Corregir con catálogo de correspondencias', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE NOT es_vacio(product_category_name) AND product_category_name NOT IN (SELECT categoria_estandar FROM catalogo_categorias)) FROM productos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R13 Métodos de pago' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R13 Métodos de pago', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Normalizar con CASE; valores desconocidos -> desconocido y marcado', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE coalesce(payment_type, '') NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R05 Fechas inconsistentes' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R05 Fechas inconsistentes', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena si la secuencia es imposible; marcar desfases de registro', current_timestamp
FROM (WITH p AS (SELECT a_fecha(order_purchase_timestamp) AS order_purchase_timestamp, a_fecha(order_approved_at) AS order_approved_at, a_fecha(order_delivered_carrier_date) AS order_delivered_carrier_date, a_fecha(order_delivered_customer_date) AS order_delivered_customer_date, a_fecha(order_estimated_delivery_date) AS order_estimated_delivery_date FROM pedidos_clean) SELECT count(*), count(*) FILTER (WHERE (order_delivered_customer_date < order_purchase_timestamp) OR (CAST(order_estimated_delivery_date AS DATE) < CAST(order_purchase_timestamp AS DATE)) OR (order_approved_at < order_purchase_timestamp) OR (order_purchase_timestamp NOT BETWEEN TIMESTAMP '2016-01-01' AND TIMESTAMP '2018-12-31 23:59:59') OR (order_delivered_carrier_date < order_purchase_timestamp) OR (order_delivered_customer_date < order_delivered_carrier_date)) FROM p) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R10 Estados de pedido' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R10 Estados de pedido', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar contradicciones entre estado y fechas', current_timestamp
FROM (WITH p AS (SELECT normalizar_texto(order_status) AS order_status, a_fecha(order_delivered_carrier_date) AS order_delivered_carrier_date, a_fecha(order_delivered_customer_date) AS order_delivered_customer_date FROM pedidos_clean) SELECT count(*), count(*) FILTER (WHERE (order_status = 'delivered' AND order_delivered_customer_date IS NULL) OR (order_status IN ('canceled', 'unavailable') AND order_delivered_customer_date IS NOT NULL) OR (order_status IN ('created', 'approved', 'invoiced', 'processing') AND (order_delivered_carrier_date IS NOT NULL OR order_delivered_customer_date IS NOT NULL)) OR (order_status IN ('shipped', 'delivered') AND order_delivered_carrier_date IS NULL) OR (order_status IS NULL OR order_status NOT IN ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'canceled', 'unavailable'))) FROM p) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R06 Precios inválidos' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R06 Precios inválidos', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena: precio <= 0, flete < 0 o pago < 0', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE a_numero(price) <= 0 OR a_numero(freight_value) < 0) FROM items_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R06 Precios inválidos' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R06 Precios inválidos', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena: precio <= 0, flete < 0 o pago < 0', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE a_numero(payment_value) < 0) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R09 Integridad referencial' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R09 Integridad referencial', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena de huérfanos y, en cascada, de hijos de pedidos en cuarentena', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE c.customer_id IS NULL) FROM pedidos_clean AS p LEFT JOIN (SELECT DISTINCT customer_id FROM clientes_clean) AS c USING (customer_id)) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R09 Integridad referencial' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R09 Integridad referencial', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena de huérfanos y, en cascada, de hijos de pedidos en cuarentena', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM pedidos_clean p WHERE p.order_id = i.order_id) OR NOT EXISTS (SELECT 1 FROM productos_clean pr WHERE pr.product_id = i.product_id)) FROM items_clean AS i) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R09 Integridad referencial' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R09 Integridad referencial', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Cuarentena de huérfanos y, en cascada, de hijos de pedidos en cuarentena', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM pedidos_clean p WHERE p.order_id = g.order_id)) FROM pagos_clean AS g) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R07 Valores atípicos (IQR)' AND tabla_evaluada = 'items.price' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R07 Valores atípicos (IQR)', 'items.price', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar: un atípico no es necesariamente un error', current_timestamp
FROM (
WITH v AS (SELECT a_numero(price) AS x FROM items_clean WHERE a_numero(price) IS NOT NULL),
     l AS (SELECT quantile_cont(x, 0.25) AS q1, quantile_cont(x, 0.75) AS q3 FROM v)
SELECT count(*), count(*) FILTER (WHERE x < q1 - 1.5 * (q3 - q1) OR x > q3 + 1.5 * (q3 - q1))
FROM v, l) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R07 Valores atípicos (IQR)' AND tabla_evaluada = 'items.freight_value' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R07 Valores atípicos (IQR)', 'items.freight_value', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar: un atípico no es necesariamente un error', current_timestamp
FROM (
WITH v AS (SELECT a_numero(freight_value) AS x FROM items_clean WHERE a_numero(freight_value) IS NOT NULL),
     l AS (SELECT quantile_cont(x, 0.25) AS q1, quantile_cont(x, 0.75) AS q3 FROM v)
SELECT count(*), count(*) FILTER (WHERE x < q1 - 1.5 * (q3 - q1) OR x > q3 + 1.5 * (q3 - q1))
FROM v, l) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R07 Valores atípicos (IQR)' AND tabla_evaluada = 'pagos.payment_value' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R07 Valores atípicos (IQR)', 'pagos.payment_value', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar: un atípico no es necesariamente un error', current_timestamp
FROM (
WITH v AS (SELECT a_numero(payment_value) AS x FROM pagos_clean WHERE a_numero(payment_value) IS NOT NULL),
     l AS (SELECT quantile_cont(x, 0.25) AS q1, quantile_cont(x, 0.75) AS q3 FROM v)
SELECT count(*), count(*) FILTER (WHERE x < q1 - 1.5 * (q3 - q1) OR x > q3 + 1.5 * (q3 - q1))
FROM v, l) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'R12 Pagos vs ítems' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R12 Pagos vs ítems', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Conservar y marcar pedidos con diferencia mayor a la tolerancia', current_timestamp
FROM (
WITH it AS (SELECT order_id, sum(a_numero(price) + a_numero(freight_value)) AS total_items
            FROM items_clean GROUP BY order_id),
     pg AS (SELECT order_id, sum(a_numero(payment_value)) AS total_pagado
            FROM pagos_clean GROUP BY order_id)
SELECT count(*), count(*) FILTER (WHERE abs(total_pagado - total_items) > 1.0)
FROM it JOIN pg USING (order_id)) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'pedidos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'pedidos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 8, count(*) FILTER (WHERE "order_id" IS NULL OR es_vacio("order_id")) + count(*) FILTER (WHERE "customer_id" IS NULL OR es_vacio("customer_id")) + count(*) FILTER (WHERE "order_status" IS NULL OR es_vacio("order_status")) + count(*) FILTER (WHERE "order_purchase_timestamp" IS NULL OR es_vacio("order_purchase_timestamp")) + count(*) FILTER (WHERE "order_approved_at" IS NULL OR es_vacio("order_approved_at")) + count(*) FILTER (WHERE "order_delivered_carrier_date" IS NULL OR es_vacio("order_delivered_carrier_date")) + count(*) FILTER (WHERE "order_delivered_customer_date" IS NULL OR es_vacio("order_delivered_customer_date")) + count(*) FILTER (WHERE "order_estimated_delivery_date" IS NULL OR es_vacio("order_estimated_delivery_date")) FROM pedidos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'items' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'items', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 7, count(*) FILTER (WHERE "order_id" IS NULL OR es_vacio("order_id")) + count(*) FILTER (WHERE "order_item_id" IS NULL OR es_vacio("order_item_id")) + count(*) FILTER (WHERE "product_id" IS NULL OR es_vacio("product_id")) + count(*) FILTER (WHERE "seller_id" IS NULL OR es_vacio("seller_id")) + count(*) FILTER (WHERE "shipping_limit_date" IS NULL OR es_vacio("shipping_limit_date")) + count(*) FILTER (WHERE "price" IS NULL OR es_vacio("price")) + count(*) FILTER (WHERE "freight_value" IS NULL OR es_vacio("freight_value")) FROM items_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'clientes' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'clientes', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 5, count(*) FILTER (WHERE "customer_id" IS NULL OR es_vacio("customer_id")) + count(*) FILTER (WHERE "customer_unique_id" IS NULL OR es_vacio("customer_unique_id")) + count(*) FILTER (WHERE "customer_zip_code_prefix" IS NULL OR es_vacio("customer_zip_code_prefix")) + count(*) FILTER (WHERE "customer_city" IS NULL OR es_vacio("customer_city")) + count(*) FILTER (WHERE "customer_state" IS NULL OR es_vacio("customer_state")) FROM clientes_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'pagos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'pagos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 5, count(*) FILTER (WHERE "order_id" IS NULL OR es_vacio("order_id")) + count(*) FILTER (WHERE "payment_sequential" IS NULL OR es_vacio("payment_sequential")) + count(*) FILTER (WHERE "payment_type" IS NULL OR es_vacio("payment_type")) + count(*) FILTER (WHERE "payment_installments" IS NULL OR es_vacio("payment_installments")) + count(*) FILTER (WHERE "payment_value" IS NULL OR es_vacio("payment_value")) FROM pagos_clean) AS m(evaluados, invalidos);

DELETE FROM quality_report WHERE nombre_regla = 'M01 Completitud' AND tabla_evaluada = 'productos' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'M01 Completitud', 'productos', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Porcentaje de celdas sin dato (NULL o vacías)', current_timestamp
FROM (SELECT count(*) * 9, count(*) FILTER (WHERE "product_id" IS NULL OR es_vacio("product_id")) + count(*) FILTER (WHERE "product_category_name" IS NULL OR es_vacio("product_category_name")) + count(*) FILTER (WHERE "product_name_lenght" IS NULL OR es_vacio("product_name_lenght")) + count(*) FILTER (WHERE "product_description_lenght" IS NULL OR es_vacio("product_description_lenght")) + count(*) FILTER (WHERE "product_photos_qty" IS NULL OR es_vacio("product_photos_qty")) + count(*) FILTER (WHERE "product_weight_g" IS NULL OR es_vacio("product_weight_g")) + count(*) FILTER (WHERE "product_length_cm" IS NULL OR es_vacio("product_length_cm")) + count(*) FILTER (WHERE "product_height_cm" IS NULL OR es_vacio("product_height_cm")) + count(*) FILTER (WHERE "product_width_cm" IS NULL OR es_vacio("product_width_cm")) FROM productos_clean) AS m(evaluados, invalidos);

CREATE OR REPLACE TABLE comparacion_antes_despues AS
SELECT a.nombre_regla AS regla, a.tabla_evaluada AS tabla,
       a.registros_evaluados AS evaluados_antes,  a.registros_invalidos AS invalidos_antes,  a.porcentaje_error AS pct_antes,
       d.registros_evaluados AS evaluados_despues, d.registros_invalidos AS invalidos_despues, d.porcentaje_error AS pct_despues,
       CASE
           WHEN d.registros_invalidos = 0 THEN 'resuelto'
           WHEN d.registros_invalidos < a.registros_invalidos THEN 'reducido'
           ELSE 'conservado y marcado'
       END AS resultado,
       a.politica
FROM quality_report AS a
JOIN quality_report AS d
  ON d.nombre_regla = a.nombre_regla AND d.tabla_evaluada = a.tabla_evaluada AND d.etapa = 'despues'
WHERE a.etapa = 'antes';

CREATE OR REPLACE TABLE validacion_final AS SELECT *, CASE WHEN violaciones = 0 THEN 'OK' ELSE 'FALLA' END AS resultado FROM (SELECT 'Unicidad' AS grupo, 'pedidos_clean: clave (order_id) única' AS verificacion, (SELECT count(*) FROM (SELECT order_id FROM pedidos_clean GROUP BY ALL HAVING count(*) > 1)) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pedidos_clean: campos críticos sin NULL' AS verificacion, (SELECT count(*) FROM pedidos_clean WHERE "order_id" IS NULL OR "customer_id" IS NULL OR "order_purchase_timestamp" IS NULL) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pedidos_clean: sin cadenas vacías' AS verificacion, (SELECT count(*) FROM pedidos_clean WHERE es_vacio("order_id") OR es_vacio("customer_id") OR es_vacio("order_status") OR es_vacio("order_purchase_timestamp") OR es_vacio("order_approved_at") OR es_vacio("order_delivered_carrier_date") OR es_vacio("order_delivered_customer_date") OR es_vacio("order_estimated_delivery_date")) AS violaciones UNION ALL SELECT 'Balance' AS grupo, 'pedidos: raw = clean + cuarentena + duplicados' AS verificacion, (SELECT abs((SELECT count(*) FROM pedidos_raw) - (SELECT count(*) FROM pedidos_clean) - (SELECT count(*) FROM pedidos_cuarentena) - (SELECT registros_invalidos FROM quality_report WHERE nombre_regla LIKE 'R01 %' AND tabla_evaluada = 'pedidos' AND etapa = 'antes'))) AS violaciones UNION ALL SELECT 'Unicidad' AS grupo, 'items_clean: clave (order_id, order_item_id) única' AS verificacion, (SELECT count(*) FROM (SELECT order_id, order_item_id FROM items_clean GROUP BY ALL HAVING count(*) > 1)) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'items_clean: campos críticos sin NULL' AS verificacion, (SELECT count(*) FROM items_clean WHERE "order_id" IS NULL OR "order_item_id" IS NULL OR "product_id" IS NULL OR "price" IS NULL OR "freight_value" IS NULL) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'items_clean: sin cadenas vacías' AS verificacion, (SELECT count(*) FROM items_clean WHERE es_vacio("order_id") OR es_vacio("order_item_id") OR es_vacio("product_id") OR es_vacio("seller_id") OR es_vacio("shipping_limit_date") OR es_vacio("price") OR es_vacio("freight_value")) AS violaciones UNION ALL SELECT 'Balance' AS grupo, 'items: raw = clean + cuarentena + duplicados' AS verificacion, (SELECT abs((SELECT count(*) FROM items_raw) - (SELECT count(*) FROM items_clean) - (SELECT count(*) FROM items_cuarentena) - (SELECT registros_invalidos FROM quality_report WHERE nombre_regla LIKE 'R01 %' AND tabla_evaluada = 'items' AND etapa = 'antes'))) AS violaciones UNION ALL SELECT 'Unicidad' AS grupo, 'clientes_clean: clave (customer_id) única' AS verificacion, (SELECT count(*) FROM (SELECT customer_id FROM clientes_clean GROUP BY ALL HAVING count(*) > 1)) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'clientes_clean: campos críticos sin NULL' AS verificacion, (SELECT count(*) FROM clientes_clean WHERE "customer_id" IS NULL) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'clientes_clean: sin cadenas vacías' AS verificacion, (SELECT count(*) FROM clientes_clean WHERE es_vacio("customer_id") OR es_vacio("customer_unique_id") OR es_vacio("customer_zip_code_prefix") OR es_vacio("customer_city") OR es_vacio("customer_state")) AS violaciones UNION ALL SELECT 'Balance' AS grupo, 'clientes: raw = clean + cuarentena + duplicados' AS verificacion, (SELECT abs((SELECT count(*) FROM clientes_raw) - (SELECT count(*) FROM clientes_clean) - (SELECT count(*) FROM clientes_cuarentena) - (SELECT registros_invalidos FROM quality_report WHERE nombre_regla LIKE 'R01 %' AND tabla_evaluada = 'clientes' AND etapa = 'antes'))) AS violaciones UNION ALL SELECT 'Unicidad' AS grupo, 'pagos_clean: clave (order_id, payment_sequential) única' AS verificacion, (SELECT count(*) FROM (SELECT order_id, payment_sequential FROM pagos_clean GROUP BY ALL HAVING count(*) > 1)) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pagos_clean: campos críticos sin NULL' AS verificacion, (SELECT count(*) FROM pagos_clean WHERE "order_id" IS NULL OR "payment_sequential" IS NULL OR "payment_value" IS NULL) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pagos_clean: sin cadenas vacías' AS verificacion, (SELECT count(*) FROM pagos_clean WHERE es_vacio("order_id") OR es_vacio("payment_sequential") OR es_vacio("payment_type") OR es_vacio("payment_installments") OR es_vacio("payment_value")) AS violaciones UNION ALL SELECT 'Balance' AS grupo, 'pagos: raw = clean + cuarentena + duplicados' AS verificacion, (SELECT abs((SELECT count(*) FROM pagos_raw) - (SELECT count(*) FROM pagos_clean) - (SELECT count(*) FROM pagos_cuarentena) - (SELECT registros_invalidos FROM quality_report WHERE nombre_regla LIKE 'R01 %' AND tabla_evaluada = 'pagos' AND etapa = 'antes'))) AS violaciones UNION ALL SELECT 'Unicidad' AS grupo, 'productos_clean: clave (product_id) única' AS verificacion, (SELECT count(*) FROM (SELECT product_id FROM productos_clean GROUP BY ALL HAVING count(*) > 1)) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'productos_clean: campos críticos sin NULL' AS verificacion, (SELECT count(*) FROM productos_clean WHERE "product_id" IS NULL) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'productos_clean: sin cadenas vacías' AS verificacion, (SELECT count(*) FROM productos_clean WHERE es_vacio("product_id") OR es_vacio("product_category_name") OR es_vacio("product_name_lenght") OR es_vacio("product_description_lenght") OR es_vacio("product_photos_qty") OR es_vacio("product_weight_g") OR es_vacio("product_length_cm") OR es_vacio("product_height_cm") OR es_vacio("product_width_cm")) AS violaciones UNION ALL SELECT 'Balance' AS grupo, 'productos: raw = clean + cuarentena + duplicados' AS verificacion, (SELECT abs((SELECT count(*) FROM productos_raw) - (SELECT count(*) FROM productos_clean) - (SELECT count(*) FROM productos_cuarentena) - (SELECT registros_invalidos FROM quality_report WHERE nombre_regla LIKE 'R01 %' AND tabla_evaluada = 'productos' AND etapa = 'antes'))) AS violaciones UNION ALL SELECT 'Integridad' AS grupo, 'items_clean -> pedidos_clean' AS verificacion, (SELECT count(*) FROM items_clean i WHERE NOT EXISTS (SELECT 1 FROM pedidos_clean p WHERE p.order_id = i.order_id)) AS violaciones UNION ALL SELECT 'Integridad' AS grupo, 'items_clean -> productos_clean' AS verificacion, (SELECT count(*) FROM items_clean i WHERE NOT EXISTS (SELECT 1 FROM productos_clean p WHERE p.product_id = i.product_id)) AS violaciones UNION ALL SELECT 'Integridad' AS grupo, 'pedidos_clean -> clientes_clean' AS verificacion, (SELECT count(*) FROM pedidos_clean p WHERE NOT EXISTS (SELECT 1 FROM clientes_clean c WHERE c.customer_id = p.customer_id)) AS violaciones UNION ALL SELECT 'Integridad' AS grupo, 'pagos_clean -> pedidos_clean' AS verificacion, (SELECT count(*) FROM pagos_clean g WHERE NOT EXISTS (SELECT 1 FROM pedidos_clean p WHERE p.order_id = g.order_id)) AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pedidos_clean.order_purchase_timestamp es TIMESTAMP' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pedidos_clean' AND column_name = 'order_purchase_timestamp' AND data_type <> 'TIMESTAMP') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pedidos_clean.order_approved_at es TIMESTAMP' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pedidos_clean' AND column_name = 'order_approved_at' AND data_type <> 'TIMESTAMP') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pedidos_clean.order_delivered_carrier_date es TIMESTAMP' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pedidos_clean' AND column_name = 'order_delivered_carrier_date' AND data_type <> 'TIMESTAMP') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pedidos_clean.order_delivered_customer_date es TIMESTAMP' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pedidos_clean' AND column_name = 'order_delivered_customer_date' AND data_type <> 'TIMESTAMP') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pedidos_clean.order_estimated_delivery_date es TIMESTAMP' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pedidos_clean' AND column_name = 'order_estimated_delivery_date' AND data_type <> 'TIMESTAMP') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'items_clean.order_item_id es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'items_clean' AND column_name = 'order_item_id' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'items_clean.shipping_limit_date es TIMESTAMP' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'items_clean' AND column_name = 'shipping_limit_date' AND data_type <> 'TIMESTAMP') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'items_clean.price es DECIMAL(10,2)' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'items_clean' AND column_name = 'price' AND data_type <> 'DECIMAL(10,2)') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'items_clean.freight_value es DECIMAL(10,2)' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'items_clean' AND column_name = 'freight_value' AND data_type <> 'DECIMAL(10,2)') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pagos_clean.payment_sequential es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pagos_clean' AND column_name = 'payment_sequential' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pagos_clean.payment_installments es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pagos_clean' AND column_name = 'payment_installments' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'pagos_clean.payment_value es DECIMAL(10,2)' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'pagos_clean' AND column_name = 'payment_value' AND data_type <> 'DECIMAL(10,2)') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_name_lenght es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_name_lenght' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_description_lenght es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_description_lenght' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_photos_qty es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_photos_qty' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_weight_g es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_weight_g' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_length_cm es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_length_cm' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_height_cm es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_height_cm' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Tipos' AS grupo, 'productos_clean.product_width_cm es INTEGER' AS verificacion, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'productos_clean' AND column_name = 'product_width_cm' AND data_type <> 'INTEGER') AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'items_clean: precio > 0 y flete >= 0' AS verificacion, (SELECT count(*) FROM items_clean WHERE price <= 0 OR freight_value < 0) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pagos_clean: monto >= 0' AS verificacion, (SELECT count(*) FROM pagos_clean WHERE payment_value < 0) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pedidos_clean: sin secuencias de fechas imposibles' AS verificacion, (SELECT count(*) FROM pedidos_clean WHERE (order_delivered_customer_date < order_purchase_timestamp) OR (CAST(order_estimated_delivery_date AS DATE) < CAST(order_purchase_timestamp AS DATE)) OR (order_approved_at < order_purchase_timestamp) OR (order_purchase_timestamp NOT BETWEEN TIMESTAMP '2016-01-01' AND TIMESTAMP '2018-12-31 23:59:59')) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pedidos_clean: estado dentro del dominio' AS verificacion, (SELECT count(*) FROM pedidos_clean WHERE order_status NOT IN ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'canceled', 'unavailable', 'desconocido')) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'pagos_clean: método dentro del dominio' AS verificacion, (SELECT count(*) FROM pagos_clean WHERE payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'desconocido')) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'clientes_clean: CP NULL o de 5 dígitos' AS verificacion, (SELECT count(*) FROM clientes_clean WHERE NOT regexp_matches(customer_zip_code_prefix, '^[0-9]{5}$')) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'clientes_clean: ciudad y UF estandarizadas' AS verificacion, (SELECT count(*) FROM clientes_clean WHERE customer_city <> normalizar_texto(customer_city) OR customer_state <> upper(trim(customer_state))) AS violaciones UNION ALL SELECT 'Errores críticos' AS grupo, 'productos_clean: categoría del catálogo y traducida' AS verificacion, (SELECT count(*) FROM productos_clean WHERE product_category_name NOT IN (SELECT categoria_estandar FROM catalogo_categorias) OR product_category_name_english IS NULL) AS violaciones);

DELETE FROM quality_report WHERE nombre_regla = 'R15 Validación final' AND tabla_evaluada = 'todas' AND etapa = 'despues';

INSERT INTO quality_report
SELECT 'R15 Validación final', 'todas', 'despues', evaluados, invalidos,
       round(100.0 * invalidos / nullif(evaluados, 0), 2), 'Todas las verificaciones deben dar 0 violaciones', current_timestamp
FROM (SELECT count(*), count(*) FILTER (WHERE resultado = 'FALLA') FROM validacion_final) AS m(evaluados, invalidos);

COPY pedidos_clean TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/processed/pedidos_clean.parquet' (FORMAT parquet);

COPY items_clean TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/processed/items_clean.parquet' (FORMAT parquet);

COPY clientes_clean TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/processed/clientes_clean.parquet' (FORMAT parquet);

COPY pagos_clean TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/processed/pagos_clean.parquet' (FORMAT parquet);

COPY productos_clean TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/data/processed/productos_clean.parquet' (FORMAT parquet);

COPY (SELECT * FROM quality_report ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/reports/quality_report.csv' (HEADER);

COPY (SELECT * FROM comparacion_antes_despues ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/reports/comparacion_antes_despues.csv' (HEADER);

COPY (SELECT * FROM validacion_final ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/reports/validacion_final.csv' (HEADER);

COPY (SELECT * FROM resumen_cuarentena ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/reports/resumen_cuarentena.csv' (HEADER);

COPY (SELECT * FROM errores_inyectados ORDER BY ALL) TO 'd:/Users/luism/Documents/Personal/Uni/Maestria/analisis -de-datos/proyecto-inicial/reports/errores_inyectados.csv' (HEADER);

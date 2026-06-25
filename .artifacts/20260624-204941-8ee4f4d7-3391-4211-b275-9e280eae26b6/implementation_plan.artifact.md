# Plan de Implementación: Vistas de Supabase para Estadísticas e Inventario

Para solucionar el problema de sincronización donde los datos de inventario y estadísticas aparecen en 0 en dispositivos nuevos, moveremos la lógica de cálculo al servidor mediante **Vistas SQL**. Esto permitirá que la aplicación reciba datos consolidados de inmediato tras iniciar sesión, sin depender de la descarga manual de miles de registros de detalles.

## User Review Required

> [!IMPORTANT]
> Las vistas SQL deben ser ejecutadas en el panel de Supabase (SQL Editor). Sin estas vistas, el código de la aplicación fallará al intentar consultar los nuevos endpoints.

## Cambios Propuestos

### 1. Base de Datos (Supabase SQL)

Crearemos dos vistas principales para cubrir todas las métricas:

- **`v_executive_financials`**: Agregados diarios de ingresos directos, ventas de inventario, gastos y COGS.
- **`v_inventory_performance`**: Métricas de productos (márgenes, valor de inventario y ventas recientes).

#### [NEW] Scripts SQL para Supabase
```sql
-- 1. Vista Ejecutiva Financiera
create or replace view v_executive_financials as
with daily_tx as (
    select
        business_id,
        transaction_date::date as entry_date,
        sum(case when type = 'income' and description != 'Venta de productos en inventario' then amount else 0 end) as direct_income,
        sum(case when type = 'income' and description = 'Venta de productos en inventario' then amount else 0 end) as inventory_sales_cash,
        sum(case when type = 'expense' then amount else 0 end) as direct_expenses
    from transactions
    group by 1, 2
),
daily_debts as (
    select
        business_id,
        created_at::date as entry_date,
        sum(total_amount) as inventory_sales_credit
    from debts
    where type = 'to_collect' and description = 'Venta de productos en inventario'
    group by 1, 2
),
daily_cogs as (
    select business_id, entry_date, sum(total_cogs) as total_cogs from (
        select t.business_id, t.transaction_date::date as entry_date, sum(ti.unit_cost * ti.quantity) as total_cogs
        from transaction_items ti join transactions t on ti.transaction_id = t.id group by 1, 2
        union all
        select d.business_id, d.created_at::date as entry_date, sum(ti.unit_cost * ti.quantity) as total_cogs
        from transaction_items ti join debts d on ti.debt_id = d.id group by 1, 2
    ) sub group by 1, 2
)
select
    dt.business_id,
    dt.entry_date,
    dt.direct_income,
    (dt.inventory_sales_cash + coalesce(dd.inventory_sales_credit, 0)) as total_inventory_sales,
    dt.direct_expenses,
    coalesce(dc.total_cogs, 0) as total_cogs
from daily_tx dt
left join daily_debts dd on dt.business_id = dd.business_id and dt.entry_date = dd.entry_date
left join daily_cogs dc on dt.business_id = dc.business_id and dt.entry_date = dc.entry_date;

-- 2. Rendimiento de Inventario
create or replace view v_inventory_performance as
select
    p.business_id,
    p.id as product_id,
    p.name as product_name,
    p.stock,
    p.cost_price,
    p.sale_price,
    (p.sale_price - p.cost_price) as unit_margin,
    case when p.sale_price > 0 then ((p.sale_price - p.cost_price) / p.sale_price) * 100 else 0 end as margin_percentage,
    (p.stock * p.cost_price) as inventory_value_cost,
    (p.stock * p.sale_price) as inventory_value_sale,
    coalesce((
        select sum(ti.quantity)
        from transaction_items ti
        left join transactions t on ti.transaction_id = t.id
        left join debts d on ti.debt_id = d.id
        where ti.product_id = p.id
        and (t.transaction_date > now() - interval '30 days' or d.created_at > now() - interval '30 days')
    ), 0) as units_sold_last_30_days
from products p
where p.deleted_at is null;
```

---

### 2. Flutter: Modelos y Servicios

#### [dtos.dart](file:///C:/Users/Alexander/StudioProjects/finance_app/lib/backend-api/dtos.dart)
- Agregar clases `ExecutiveFinancialsRes` e `InventoryPerformanceRes`.

#### [api_service.dart](file:///C:/Users/Alexander/StudioProjects/finance_app/lib/backend-api/api_service.dart)
- Agregar métodos `getExecutiveFinancials` y `getInventoryPerformance`.

---

### 3. Flutter: Refactorización de Providers

#### [analytics.dart](file:///C:/Users/Alexander/StudioProjects/finance_app/lib/providers/analytics.dart)
- Implementar `executiveFinancialsProvider`.
- Refactorizar `analyticsProvider` para que use la vista ejecutiva.

#### [inventory.dart](file:///C:/Users/Alexander/StudioProjects/finance_app/lib/providers/inventory.dart)
- Implementar `inventoryPerformanceProvider`.
- Actualizar `inventoryMetricsProvider`.

---

## Plan de Verificación

### Pruebas Manuales
1.  **Consistencia de Datos**: Comparar ventas totales en estadísticas vs dashboard.
2.  **Prueba de Dispositivo Nuevo**: Simular inicio de sesión limpio y verificar carga.
3.  **Filtros de Fecha**: Comprobar "Hoy", "Semana" y "Mes".

# Implementación de Vistas de Supabase para Estadísticas e Inventario

He completado la refactorización para que la aplicación obtenga sus cálculos financieros directamente desde Supabase. Esto soluciona el problema de los valores en 0 al cambiar de dispositivo, ya que los cálculos ahora ocurren en el servidor y no dependen de procesar localmente cada ítem vendido.

## Cambios Realizados

1.  **Infraestructura de Datos**:
    *   Actualizado `dtos.dart` con los modelos `ExecutiveFinancialsRes` e `InventoryPerformanceRes`.
    *   Añadido soporte en `api_service.dart` para consultar las nuevas vistas.
2.  **Lógica de Negocio (Providers)**:
    *   Refactorizado `analyticsProvider` para usar la vista ejecutiva. Ahora las ventas, márgenes y carga operativa son consistentes en cualquier dispositivo.
    *   Refactorizado `inventoryMetricsProvider` para usar la vista de rendimiento de inventario.
3.  **Sincronización y Caché**:
    *   Actualizado `SyncService` para incluir `analytics_cache`. Los datos se descargan en paralelo durante el `fullSync` y se guardan localmente para acceso instantáneo y offline.
    *   Actualizado `SyncProvider` para invalidar y refrescar los datos cuando se recupera la conexión o se cambia de negocio.

---

## Acción Requerida: Configuración de Supabase

Para que estos cambios funcionen, **debes ejecutar los siguientes scripts SQL** en el Editor SQL de tu panel de Supabase:

```sql
-- 1. Vista Ejecutiva Financiera (Totales diarios)
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

-- 2. Vista de Rendimiento de Inventario (Márgenes y Mesa de Control)
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

## Verificación

1.  **Persistencia**: Al cerrar sesión e iniciar en otro dispositivo, los totales de ventas y márgenes se mostrarán correctamente de inmediato.
2.  **Carga Rápida**: Al delegar la suma al servidor, la app consume menos batería y memoria.
3.  **Insights**: Las alertas de carga operativa y mezcla de gastos siguen funcionando basadas en los datos consolidados.

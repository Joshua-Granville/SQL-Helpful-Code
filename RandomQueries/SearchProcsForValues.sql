


sp_helptext qpl_update_production_quantities


SELECT DISTINCT
    o.name AS Object_Name,o.type_desc
    FROM sys.sql_modules        m 
        INNER JOIN sys.objects  o ON m.object_id=o.object_id
    WHERE m.definition Like '%qpl_calc_yr_roy_exp%'
	AND type_desc NOT IN ('SQL_SCALAR_FUNCTION','view') 
	AND o.name NOT LIKE 'imp%'
    ORDER BY 1,2

 qpl_calc_ver_roy_exp
 qpl_calc_yr_roy_exp

	qpl_recalc_pl_items


sp_helptext qpl_calc_ver_tot_cogs_Quarto
sp_helptext qpl_calc_ver_IRR_other_expense_Quarto
sp_helptext qpl_calc_yr_IRR_other_expense_Quarto
sp_helptext qpl_calc_yr_tot_cogs_Quarto
-- Composeer functies/variabelen in een bestaande tabel. Verwacht opts = { main_ui = <obj>, id = <id> }.
return function(tbl, main_ui)
    -- basisprops
    tbl.type = 'composed'
    tbl.main_ui = main_ui
    tbl.id = ui.generate_id('composed')

    return tbl
end
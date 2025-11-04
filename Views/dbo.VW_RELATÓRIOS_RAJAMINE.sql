SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VW_RELATÓRIOS_RAJAMINE] 
AS SELECT 
Id, Identificador, Descricao, Categoria, SubCategoria, Tipo,
  
  CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX)) AS XmlContent,
    REPLACE(
        REPLACE(
            REPLACE(
                SUBSTRING(
                    CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX)), 
                    CHARINDEX('<SqlCommand>', CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX))) + LEN('<SqlCommand>'), 
                    CHARINDEX('</SqlCommand>', CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX))) - 
                    CHARINDEX('<SqlCommand>', CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX))) - LEN('<SqlCommand>')
                ),
                '&gt;', '>'
            ),
            '&lt;', '<'
        ),
        '&amp;', '&'
    ) AS SQL
  
  
  
  
  
  
  
  
  
  
--  SUBSTRING(
--        CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX)), 
--        CHARINDEX('<SqlCommand>', CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX))) + LEN('<SqlCommand>'), 
--        CHARINDEX('</SqlCommand>', CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX))) - 
--        CHARINDEX('<SqlCommand>', CAST(CAST(relatorio AS VARBINARY(MAX)) AS VARCHAR(MAX))) - LEN('<SqlCommand>')
--    ) AS SQL

FROM RajaMine.dbo.Relatorio
GO
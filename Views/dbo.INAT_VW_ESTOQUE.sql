SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   VIEW [dbo].[INAT_VW_ESTOQUE] 
AS SELECT 
'MIB' AS 'SERVIDOR',
CONCAT_WS('-','MIB', ESTOQUE.CODEMP) 'COD EMP', 
CONCAT_WS('-','MIB', ESTOQUE.CODMAT) 'COD MATERIAL',             --Reduzido do Material
CONCAT_WS('-','MIB', ESTOQUE.CODESTOQUE) 'COD ESTOQUE',             --Reduzido
CONCAT_WS('-','MIB', ESTOQUE.LOTE) 'LOTE',             --Lote
ESTOQUE.QTDEBLOQ '#QUANTIDADE BLOQUEADA',             --Quantidade Bloqueada
ESTOQUE.CUSTO '#CUSTO UNITÁRIO',             --Custo unitário do material
ESTOQUE.CUSTOMEDIO '#CUSTO MÉDIO',             --Custo Médio do Material
ESTOQUE.VALOR '#VALOR',             --Valor
ESTOQUE.QTDERESERV '#QUANTIDADE REGISTRO SERVIÇO',             --Quantidade do Registro de Serviço
ESTOQUE.SALDO '#SALDO',             --Saldo
ESTOQUE.TIPOSOLMAT 'TIPO SOLICITAÇÃO',             --Tipo de Solicitação de Material
ESTOQUE.CODALM 'COD ALMOXARIFADO',             --Reduzido do Almoxarifado
ALMOX.DESCRICAO 'ALMOXARIFADO',
CAST(ESTOQUE.DATALT AS DATE) 'DATA ALTERAÇÃO'             --Data de Alteração


FROM Engeman.Engeman.ESTOQUE WITH (NOLOCK)

LEFT JOIN Engeman.Engeman.ALMOX WITH (NOLOCK)
ON ESTOQUE.CODALM = ALMOX.CODALM
 


UNION ALL


SELECT 
'MML' AS 'SERVIDOR',
CONCAT_WS('-','MML', ESTOQUE.CODEMP) 'COD EMP', 
CONCAT_WS('-','MML', ESTOQUE.CODMAT) 'COD MATERIAL',             --Reduzido do Material
CONCAT_WS('-','MML', ESTOQUE.CODESTOQUE) 'COD ESTOQUE',             --Reduzido
CONCAT_WS('-','MML', ESTOQUE.LOTE) 'LOTE',             --Lote
ESTOQUE.QTDEBLOQ '#QUANTIDADE BLOQUEADA',             --Quantidade Bloqueada
ESTOQUE.CUSTO '#CUSTO UNITÁRIO',             --Custo unitário do material
ESTOQUE.CUSTOMEDIO '#CUSTO MÉDIO',             --Custo Médio do Material
ESTOQUE.VALOR '#VALOR',             --Valor
ESTOQUE.QTDERESERV '#QUANTIDADE REGISTRO SERVIÇO',             --Quantidade do Registro de Serviço
ESTOQUE.SALDO '#SALDO',             --Saldo
ESTOQUE.TIPOSOLMAT 'TIPO SOLICITAÇÃO',             --Tipo de Solicitação de Material
ESTOQUE.CODALM 'COD ALMOXARIFADO',             --Reduzido do Almoxarifado
ALMOX.DESCRICAO 'ALMOXARIFADO',
CAST(ESTOQUE.DATALT AS DATE) 'DATA ALTERAÇÃO'             --Data de Alteração


FROM [SQLMML].[ENGEMAN].[engeman].[ESTOQUE] WITH (NOLOCK)

LEFT JOIN [SQLMML].[ENGEMAN].[engeman].[ALMOX] WITH (NOLOCK)
ON ESTOQUE.CODALM = ALMOX.CODALM
 
GO
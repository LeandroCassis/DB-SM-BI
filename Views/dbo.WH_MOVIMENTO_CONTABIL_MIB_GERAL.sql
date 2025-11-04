SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_MOVIMENTO_CONTABIL_MIB_GERAL] 
AS -- =====================================================
-- SCRIPT: MML - Consulta de Lançamentos Contábeis
-- DESCRIÇÃO: Extração de dados contábeis com rateio
-- DATA: 30/07/2025
-- =====================================================

SELECT 
    -- INFORMAÇÕES DE CONTROLE E AUDITORIA
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MIB'                                       AS 'SERVIDOR',
    
    -- INFORMAÇÕES ORGANIZACIONAIS
    LCT.CODEMP                                  AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                          AS 'EMPRESA',
    LCT.CODFIL                                  AS 'COD FILIAL',
    LCT.CTADEB                                  AS 'COD REDUZIDO CONTA CONTÁBIL',
    PLA.CLACTA                               AS 'COD CONTA CONTÁBIL',
    UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL',
    
    -- INFORMAÇÕES CONTÁBEIS
    LCT.NUMLCT                                  AS 'NUM LANÇAMENTO',
    LCT.NUMFTC                                  AS 'NUM FATO CONTÁBIL',
    CAST(LCT.DATLCT AS DATE)                   AS 'DATA LANÇAMENTO',
        'DÉBITO'                                  AS 'TIPO CD',
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.TIPLCT                                  AS 'TIPO LANÇAMENTO',
    LCT.ORILCT                                  AS 'ORIGEM LANÇAMENTO',
    
    -- HISTORICO E COMPLEMENTO
    LCT.CODHPD                                  AS 'COD HISTORICO',
    UPPER(ISNULL(HPD.DESHPD, '') + ' ' + 
          ISNULL(LCT.CPLLCT, ''))              AS 'HISTORICO COMPLEMENTO',
  UPPER(NULLIF(                                   -- vira NULL se ficar vazio
  REPLACE(
  REPLACE(
  LTRIM(RTRIM(
  RIGHT(
  LCT.CPLLCT,
  NULLIF(CHARINDEX(',', REVERSE(LCT.CPLLCT)) - 1, -1)  -- se não achar vírgula => NULL
  )
  )),
  '"', ''    -- remove aspas duplas
  ),
  '''', ''     -- remove aspas simples
  ),
  ''
  )) AS 'PESSOA',
    
    -- INFORMAÇÕES DE RATEIO
    CASE 
        WHEN LCT.TEMRAT = 0 THEN 'NÃO' 
        ELSE 'SIM' 
    END                                         AS 'TEM RATEIO',
    ISNULL(RAT.CODCCU, 'NA')                   AS 'COD CENTRO RESULTADO',
    UPPER(ISNULL(CCU.DESCCU, 'SEM CR'))        AS 'CENTRO RESULTADO',
    CCU.CLACCU                                  AS 'CLASSIFICAÇÃO CR',
    LEFT(CCU.CLACCU, 2)                        AS 'GRUPO CLASSIFICAÇÃO',
    
    -- CLASSIFICAÇÃO OPERACIONAL OTIMIZADA
IIF(LCT.CODEMP = 5, --FERGUMINAS
CASE LEFT(CLACCU,2)
WHEN '11' THEN 'ADM'
WHEN '12' THEN 'PRODUCAO'
WHEN '13' THEN 'TERMOELETRICA'
WHEN '14' THEN 'PELOTIZACAO'
WHEN '15' THEN 'OXIGENIO'
WHEN '16' THEN 'TRASNPORTE INTERNO'
ELSE 'OUTROS' END,

IIF(LCT.CODEMP = 2, --MIG
CASE LEFT(CLACCU,2)
WHEN 21 THEN 'ADM'
WHEN 22 THEN 'LAVRA'
WHEN 23 THEN 'PRODUCAO'
WHEN 24 THEN 'OFICINA'
WHEN 25 THEN 'M.AMBIENTE'
ELSE 'OUTROS' END,

IIF(LCT.CODEMP = 1, --MIB
CASE LEFT(CCU.CLACCU, 2)
WHEN '21' THEN 'ADM'
WHEN '22' THEN 'LAVRA'
WHEN '23' THEN 'PRODUCAO'
WHEN '24' THEN 'OFICINA'
WHEN '25' THEN 'M.AMBIENTE'
ELSE 'OUTROS' END, 

'NÃO LISTADO')))                                           AS 'CLASSIFICAÇÃO',
    
    -- VALORES
    LCT.VLRLCT                                  AS '#VALOR LANÇAMENTO',
    RAT.VLRRAT                                  AS '#VALOR RATEIO',
     ISNULL(RAT.VLRRAT,LCT.VLRLCT ) AS '#MOVIMENTO',
     CONCAT_WS('-','MIB',LCT.CODEMP, PLA.CLACTA) 'KEY CONTA CONTÁBIL',
--     ISNULL(RAT.VLRRAT,LCT.VLRLCT)*IIF(LEFT(PLA.CLACTA ,1)=1,1,-1) AS '#MOVIMENTO CONTÁBIL'

ISNULL(RAT.VLRRAT, LCT.VLRLCT)*-1           AS '#MOVIMENTO CONTÁBIL'


FROM SAPIENS.SAPIENS.E640LCT LCT WITH (NOLOCK) -- TABELA PRINCIPAL OTIMIZADA

    -- JOIN: INFORMAÇÕES DA EMPRESA (HASH JOIN PARA PARALELISMO)
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: HISTORICO PADRÃO (HASH JOIN)
    LEFT JOIN SAPIENS.SAPIENS.E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: RATEIOS (HASH JOIN - OTIMIZADO PARA PARALELISMO)
    LEFT JOIN SAPIENS.SAPIENS.E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
         AND RAT.DEBCRE = 'D'
    
    -- JOIN: CENTRO DE CUSTO (HASH JOIN)
    LEFT JOIN SAPIENS.SAPIENS.E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU

    -- JOIN: PLANO DE CONTAS
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTADEB = PLA.CTARED
    
WHERE 
    LCT.CTADEB <> 0                            -- ELIMINA REGISTROS SEM MOVIMENTO
-- AND YEAR(LCT.DATLCT) >= 2000    -- FILTRO DE ANO ATUAL
    AND LCT.SITLCT IN(1,2)
    -- AND LCT.NUMLCT = '1301352271'            -- FILTRO OPCIONAL PARA TESTE

-- =====================================================
-- UNION ALL - SEGUNDA PARTE DA CONSULTA
-- =====================================================

UNION ALL

SELECT 
    -- INFORMAÇÕES DE CONTROLE E AUDITORIA
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MIB'                                       AS 'SERVIDOR',
    
    -- INFORMAÇÕES ORGANIZACIONAIS
    LCT.CODEMP                                  AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                          AS 'EMPRESA',
    LCT.CODFIL                                  AS 'COD FILIAL',
    LCT.CTACRE                                  AS 'COD REDUZIDO CONTA CONTÁBIL',
    PLA.CLACTA                                 AS 'COD CONTA CONTÁBIL',
    UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL',
    
    -- INFORMAÇÕES CONTÁBEIS
    LCT.NUMLCT                                  AS 'NUM LANÇAMENTO',
    LCT.NUMFTC                                  AS 'NUM FATO CONTÁBIL',
    CAST(LCT.DATLCT AS DATE)                    AS 'DATA LANÇAMENTO',
   'CRÉDITO'                                  AS 'TIPO CD',
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.TIPLCT                                  AS 'TIPO LANÇAMENTO',
    LCT.ORILCT                                  AS 'ORIGEM LANÇAMENTO',
    
    -- HISTORICO E COMPLEMENTO
    LCT.CODHPD                                  AS 'COD HISTORICO',
    UPPER(ISNULL(HPD.DESHPD, '') + ' ' + 
          ISNULL(LCT.CPLLCT, ''))              AS 'HISTORICO COMPLEMENTO',
  UPPER(NULLIF(                                   -- vira NULL se ficar vazio
  REPLACE(
  REPLACE(
  LTRIM(RTRIM(
  RIGHT(
  LCT.CPLLCT,
  NULLIF(CHARINDEX(',', REVERSE(LCT.CPLLCT)) - 1, -1)  -- se não achar vírgula => NULL
  )
  )),
  '"', ''    -- remove aspas duplas
  ),
  '''', ''     -- remove aspas simples
  ),
  ''
  )) AS 'PESSOA',
    
    -- INFORMAÇÕES DE RATEIO
    CASE 
        WHEN LCT.TEMRAT = 0 THEN 'NÃO' 
        ELSE 'SIM' 
    END                                         AS 'TEM RATEIO',
    ISNULL(RAT.CODCCU, 'NA')                   AS 'COD CENTRO RESULTADO',
    UPPER(ISNULL(CCU.DESCCU, 'SEM CR'))        AS 'CENTRO RESULTADO',
    CCU.CLACCU                                  AS 'CLASSIFICAÇÃO CR',
    LEFT(CCU.CLACCU, 2)                        AS 'GRUPO CLASSIFICAÇÃO',
    
    -- CLASSIFICAÇÃO OPERACIONAL OTIMIZADA
IIF(LCT.CODEMP = 5, --FERGUMINAS
CASE LEFT(CLACCU,2)
WHEN '11' THEN 'ADM'
WHEN '12' THEN 'PRODUCAO'
WHEN '13' THEN 'TERMOELETRICA'
WHEN '14' THEN 'PELOTIZACAO'
WHEN '15' THEN 'OXIGENIO'
WHEN '16' THEN 'TRASNPORTE INTERNO'
ELSE 'OUTROS' END,

IIF(LCT.CODEMP = 2, --MIG
CASE LEFT(CLACCU,2)
WHEN 21 THEN 'ADM'
WHEN 22 THEN 'LAVRA'
WHEN 23 THEN 'PRODUCAO'
WHEN 24 THEN 'OFICINA'
WHEN 25 THEN 'M.AMBIENTE'
ELSE 'OUTROS' END,

IIF(LCT.CODEMP = 1, --MIB
CASE LEFT(CCU.CLACCU, 2)
WHEN '21' THEN 'ADM'
WHEN '22' THEN 'LAVRA'
WHEN '23' THEN 'PRODUCAO'
WHEN '24' THEN 'OFICINA'
WHEN '25' THEN 'M.AMBIENTE'
ELSE 'OUTROS' END, 

'NÃO LISTADO')))                                           AS 'CLASSIFICAÇÃO',
    
    -- VALORES
    LCT.VLRLCT                                  AS '#VALOR LANÇAMENTO',
    RAT.VLRRAT                                  AS '#VALOR RATEIO',
   ISNULL(RAT.VLRRAT,LCT.VLRLCT ) AS '#MOVIMENTO',
   CONCAT_WS('-','MIB',LCT.CODEMP, PLA.CLACTA) 'KEY CONTA CONTÁBIL',
--   ISNULL(RAT.VLRRAT,LCT.VLRLCT )*IIF(LEFT(PLA.CLACTA ,1)=1,-1,1) AS '#MOVIMENTO CONTÁBIL'
ISNULL(RAT.VLRRAT, LCT.VLRLCT)          AS '#MOVIMENTO CONTÁBIL'


FROM SAPIENS.SAPIENS.E640LCT LCT WITH (NOLOCK) -- TABELA PRINCIPAL OTIMIZADA

    -- JOIN: INFORMAÇÕES DA EMPRESA (HASH JOIN PARA PARALELISMO)
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: HISTORICO PADRÃO (HASH JOIN)
    LEFT JOIN SAPIENS.SAPIENS.E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: RATEIOS (HASH JOIN - OTIMIZADO PARA PARALELISMO)
    LEFT JOIN SAPIENS.SAPIENS.E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
         AND RAT.DEBCRE = 'C'
    
    -- JOIN: CENTRO DE CUSTO (HASH JOIN)
    LEFT JOIN SAPIENS.SAPIENS.E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU

    -- JOIN: PLANO DE CONTAS
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTACRE = PLA.CTARED
    
WHERE 
    LCT.CTACRE <> 0                            -- ELIMINA REGISTROS SEM MOVIMENTO
-- AND YEAR(LCT.DATLCT) >= 2000   -- FILTRO DE ANO ATUAL
        AND LCT.SITLCT IN(1,2)
    -- AND LCT.NUMLCT = '1301352271'            -- FILTRO OPCIONAL PARA TESTE
GO
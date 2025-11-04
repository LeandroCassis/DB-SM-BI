SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_MOVIMENTO_CONTABIL_MIB] 
AS -- =====================================================
-- SCRIPT: MML - Consulta Consolidada de Movimentação Contábil
-- DESCRIÇÃO: Extração unificada de lançamentos contábeis com rateios
--            Inclui dados de débito, crédito e saldos contábeis
-- VERSÃO: 3.0
-- DATA: 20/08/2025
-- AUTOR: Sistema de BI - Vesperttine
-- =====================================================

-- =====================================================
-- PRIMEIRA CONSULTA: LANÇAMENTOS A DÉBITO (MOVIMENTOS CORRENTES)
-- =====================================================
SELECT 
    -- ===============================================
    -- METADADOS DE CONTROLE E AUDITORIA
    -- ===============================================
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MIB'                                       AS 'SERVIDOR',
    
    -- ===============================================
    -- ESTRUTURA ORGANIZACIONAL
    -- ===============================================
    LCT.CODEMP                                  AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                          AS 'EMPRESA',
    LCT.CODFIL                                  AS 'COD FILIAL',
    LCT.CTADEB                                  AS 'COD REDUZIDO CONTA CONTÁBIL',
    PLA.CLACTA                                 AS 'COD CONTA CONTÁBIL',
    UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL',
    
    -- ===============================================
    -- INFORMAÇÕES DO LANÇAMENTO CONTÁBIL
    -- ===============================================
    LCT.NUMLCT                                  AS 'NUM LANÇAMENTO',
    LCT.NUMFTC                                  AS 'NUM FATO CONTÁBIL',
    CAST(LCT.DATLCT AS DATE)                   AS 'DATA LANÇAMENTO',
    'DÉBITO'                                   AS 'TIPO CD',
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.TIPLCT                                  AS 'TIPO LANÇAMENTO',
    LCT.ORILCT                                  AS 'ORIGEM LANÇAMENTO',
    
    -- ===============================================
    -- HISTÓRICO E COMPLEMENTO DO LANÇAMENTO
    -- ===============================================
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
    
    -- ===============================================
    -- INFORMAÇÕES DE RATEIO POR CENTRO DE RESULTADO
    -- ===============================================
    CASE 
        WHEN LCT.TEMRAT = 0 THEN 'NÃO' 
        ELSE 'SIM' 
    END                                         AS 'TEM RATEIO',
    ISNULL(RAT.CODCCU, 'NA')                   AS 'COD CENTRO RESULTADO',
    UPPER(ISNULL(CCU.DESCCU, 'SEM CR'))        AS 'CENTRO RESULTADO',
    CCU.CLACCU                                  AS 'CLASSIFICAÇÃO CR',
    LEFT(CCU.CLACCU, 2)                        AS 'GRUPO CLASSIFICAÇÃO',
    
    -- ===============================================
    -- CLASSIFICAÇÃO DEPARTAMENTAL POR EMPRESA
    -- Hierarquia aninhada de classificação por empresa:
    -- - FERGUMINAS (EMP 5): Departamentos industriais
    -- - MIG (EMP 2): Departamentos de mineração  
    -- - MIB (EMP 1): Departamentos operacionais
    -- ===============================================
    IIF(LCT.CODEMP = 5, -- FERGUMINAS - Operações Industriais
        CASE LEFT(CLACCU, 2)
            WHEN '11' THEN 'ADM'
            WHEN '12' THEN 'PRODUCAO'
            WHEN '13' THEN 'TERMOELETRICA'
            WHEN '14' THEN 'PELOTIZACAO'
            WHEN '15' THEN 'OXIGENIO'
            WHEN '16' THEN 'TRANSPORTE INTERNO'
            ELSE 'OUTROS' 
        END,
        IIF(LCT.CODEMP = 2, -- MIG - Operações de Mineração
            CASE LEFT(CLACCU, 2)
                WHEN '21' THEN 'ADM'
                WHEN '22' THEN 'LAVRA'
                WHEN '23' THEN 'PRODUCAO'
                WHEN '24' THEN 'OFICINA'
                WHEN '25' THEN 'M.AMBIENTE'
                ELSE 'OUTROS' 
            END,
            IIF(LCT.CODEMP = 1, -- MIB - Operações Corporativas
                CASE LEFT(CCU.CLACCU, 2)
                    WHEN '21' THEN 'ADM'
                    WHEN '22' THEN 'LAVRA'
                    WHEN '23' THEN 'PRODUCAO'
                    WHEN '24' THEN 'OFICINA'
                    WHEN '25' THEN 'M.AMBIENTE'
                    ELSE 'OUTROS' 
                END, 
                'NÃO LISTADO'
            )
        )
    )                                           AS 'CLASSIFICAÇÃO',
    
    -- ===============================================
    -- VALORES FINANCEIROS
    -- ===============================================
    LCT.VLRLCT                                  AS '#VALOR LANÇAMENTO',
    RAT.VLRRAT                                  AS '#VALOR RATEIO',
    ISNULL(RAT.VLRRAT, LCT.VLRLCT)             AS '#MOVIMENTO',
    CONCAT_WS('-', 'MIB', LCT.CODEMP, PLA.CLACTA) AS 'KEY CONTA CONTÁBIL',
    -- Valor negativo para débitos (convenção contábil)
    ISNULL(RAT.VLRRAT, LCT.VLRLCT) * -1        AS '#MOVIMENTO CONTÁBIL'

-- ===============================================
-- RELACIONAMENTOS E JOINS OTIMIZADOS
-- ===============================================
FROM SAPIENS.SAPIENS.E640LCT LCT WITH (NOLOCK) -- Tabela principal de lançamentos contábeis

    -- JOIN: Informações da empresa (otimizado para paralelismo)
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: Histórico padrão de lançamentos
    LEFT JOIN SAPIENS.SAPIENS.E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: Rateios para contas de débito (hash join otimizado)
    LEFT JOIN SAPIENS.SAPIENS.E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'D' -- Apenas rateios de débito
    
    -- JOIN: Centro de custo para análise de resultado
    LEFT JOIN SAPIENS.SAPIENS.E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU

    -- JOIN: Plano de contas contábeis
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTADEB = PLA.CTARED
    
WHERE 
    LCT.CTADEB <> 0                            -- Elimina registros sem conta de débito
    AND YEAR(LCT.DATLCT) >= 2025-- (SELECT dbo.F_FILTRO_ANO_CONTABILIDADE ())             -- Filtro para ano corrente
    AND LCT.SITLCT IN (1, 2)                   -- Apenas lançamentos válidos

-- =====================================================
-- SEGUNDA CONSULTA: LANÇAMENTOS A CRÉDITO (MOVIMENTOS CORRENTES)
-- =====================================================
UNION ALL

SELECT 
    -- ===============================================
    -- METADADOS DE CONTROLE E AUDITORIA
    -- ===============================================
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MIB'                                       AS 'SERVIDOR',
    
    -- ===============================================
    -- ESTRUTURA ORGANIZACIONAL
    -- ===============================================
    LCT.CODEMP                                  AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                          AS 'EMPRESA',
    LCT.CODFIL                                  AS 'COD FILIAL',
    LCT.CTACRE                                  AS 'COD REDUZIDO CONTA CONTÁBIL',
    PLA.CLACTA                                 AS 'COD CONTA CONTÁBIL',
    UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL',
    
    -- ===============================================
    -- INFORMAÇÕES DO LANÇAMENTO CONTÁBIL
    -- ===============================================
    LCT.NUMLCT                                  AS 'NUM LANÇAMENTO',
    LCT.NUMFTC                                  AS 'NUM FATO CONTÁBIL',
    CAST(LCT.DATLCT AS DATE)                   AS 'DATA LANÇAMENTO',
    'CRÉDITO'                                  AS 'TIPO CD',
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.TIPLCT                                  AS 'TIPO LANÇAMENTO',
    LCT.ORILCT                                  AS 'ORIGEM LANÇAMENTO',
    
    -- ===============================================
    -- HISTÓRICO E COMPLEMENTO DO LANÇAMENTO
    -- ===============================================
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
    
    -- ===============================================
    -- INFORMAÇÕES DE RATEIO POR CENTRO DE RESULTADO
    -- ===============================================
    CASE 
        WHEN LCT.TEMRAT = 0 THEN 'NÃO' 
        ELSE 'SIM' 
    END                                         AS 'TEM RATEIO',
    ISNULL(RAT.CODCCU, 'NA')                   AS 'COD CENTRO RESULTADO',
    UPPER(ISNULL(CCU.DESCCU, 'SEM CR'))        AS 'CENTRO RESULTADO',
    CCU.CLACCU                                  AS 'CLASSIFICAÇÃO CR',
    LEFT(CCU.CLACCU, 2)                        AS 'GRUPO CLASSIFICAÇÃO',

    -- ===============================================
    -- CLASSIFICAÇÃO DEPARTAMENTAL POR EMPRESA
    -- ===============================================
    IIF(LCT.CODEMP = 5, -- FERGUMINAS - Operações Industriais
        CASE LEFT(CLACCU, 2)
            WHEN '11' THEN 'ADM'
            WHEN '12' THEN 'PRODUCAO'
            WHEN '13' THEN 'TERMOELETRICA'
            WHEN '14' THEN 'PELOTIZACAO'
            WHEN '15' THEN 'OXIGENIO'
            WHEN '16' THEN 'TRANSPORTE INTERNO'
            ELSE 'OUTROS' 
        END,
        IIF(LCT.CODEMP = 2, -- MIG - Operações de Mineração
            CASE LEFT(CLACCU, 2)
                WHEN '21' THEN 'ADM'
                WHEN '22' THEN 'LAVRA'
                WHEN '23' THEN 'PRODUCAO'
                WHEN '24' THEN 'OFICINA'
                WHEN '25' THEN 'M.AMBIENTE'
                ELSE 'OUTROS' 
            END,
            IIF(LCT.CODEMP = 1, -- MIB - Operações Corporativas
                CASE LEFT(CCU.CLACCU, 2)
                    WHEN '21' THEN 'ADM'
                    WHEN '22' THEN 'LAVRA'
                    WHEN '23' THEN 'PRODUCAO'
                    WHEN '24' THEN 'OFICINA'
                    WHEN '25' THEN 'M.AMBIENTE'
                    ELSE 'OUTROS' 
                END, 
                'NÃO LISTADO'
            )
        )
    )                                           AS 'CLASSIFICAÇÃO',
    
    -- ===============================================
    -- VALORES FINANCEIROS
    -- ===============================================
    LCT.VLRLCT                                  AS '#VALOR LANÇAMENTO',
    RAT.VLRRAT                                  AS '#VALOR RATEIO',
    ISNULL(RAT.VLRRAT, LCT.VLRLCT)             AS '#MOVIMENTO',
    CONCAT_WS('-', 'MIB', LCT.CODEMP, PLA.CLACTA) AS 'KEY CONTA CONTÁBIL',
    -- Valor positivo para créditos (convenção contábil)
    ISNULL(RAT.VLRRAT, LCT.VLRLCT)             AS '#MOVIMENTO CONTÁBIL'

-- ===============================================
-- RELACIONAMENTOS E JOINS OTIMIZADOS
-- ===============================================
FROM SAPIENS.SAPIENS.E640LCT LCT WITH (NOLOCK) -- Tabela principal de lançamentos contábeis

    -- JOIN: Informações da empresa (otimizado para paralelismo)
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: Histórico padrão de lançamentos
    LEFT JOIN SAPIENS.SAPIENS.E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: Rateios para contas de crédito (hash join otimizado)
    LEFT JOIN SAPIENS.SAPIENS.E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'C' -- Apenas rateios de crédito
    
    -- JOIN: Centro de custo para análise de resultado
    LEFT JOIN SAPIENS.SAPIENS.E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU

    -- JOIN: Plano de contas contábeis
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTACRE = PLA.CTARED
    
WHERE 
    LCT.CTACRE <> 0                            -- Elimina registros sem conta de crédito
    AND YEAR(LCT.DATLCT) >= 2025-- (SELECT dbo.F_FILTRO_ANO_CONTABILIDADE ())              -- Filtro para ano corrente
    AND LCT.SITLCT IN (1, 2)                   -- Apenas lançamentos válidos
-- =====================================================
-- TERCEIRA CONSULTA: SALDOS CONTÁBEIS (CRÉDITOS HISTÓRICOS)
-- Fonte: Tabela de saldos contábeis para períodos anteriores
-- =====================================================
UNION ALL

SELECT
    -- ===============================================
    -- METADADOS DE CONTROLE E AUDITORIA
    -- ===============================================
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MIB'                                       AS 'SERVIDOR',
    
    -- ===============================================
    -- ESTRUTURA ORGANIZACIONAL
    -- ===============================================
    E650SAL.CODEMP                             AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                          AS 'EMPRESA',
    E650SAL.CODFIL                             AS 'COD FILIAL',
    E650SAL.CTARED                             AS 'COD REDUZIDO CONTA CONTÁBIL',
    PLA.CLACTA                                 AS 'COD CONTA CONTÁBIL',
    UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL',
    
    -- ===============================================
    -- INFORMAÇÕES DO LANÇAMENTO CONTÁBIL (SALDOS)
    -- ===============================================
    NULL                                        AS 'NUM LANÇAMENTO',
    NULL                                        AS 'NUM FATO CONTÁBIL',
    E650SAL.MESANO                             AS 'DATA LANÇAMENTO',
    'CRÉDITO'                                  AS 'TIPO CD',
    NULL                                        AS 'SITUAÇÃO',
    NULL                                        AS 'TIPO LANÇAMENTO',
    NULL                                        AS 'ORIGEM LANÇAMENTO',
    
    -- ===============================================
    -- HISTÓRICO E COMPLEMENTO (N/A PARA SALDOS)
    -- ===============================================
    NULL                                        AS 'COD HISTORICO',
    NULL                                        AS 'HISTORICO COMPLEMENTO',
    NULL                                        AS 'PESSOA',
    
    -- ===============================================
    -- INFORMAÇÕES DE RATEIO (N/A PARA SALDOS)
    -- ===============================================
    NULL                                        AS 'TEM RATEIO',
    NULL                                        AS 'COD CENTRO RESULTADO',
    NULL                                        AS 'CENTRO RESULTADO',
    NULL                                        AS 'CLASSIFICAÇÃO CR',
    NULL                                        AS 'GRUPO CLASSIFICAÇÃO',
    NULL                                        AS 'CLASSIFICAÇÃO',
    
    -- ===============================================
    -- VALORES FINANCEIROS - CRÉDITOS ACUMULADOS
    -- ===============================================
    (E650SAL.CRECAL + E650SAL.CREMES)          AS '#VALOR LANÇAMENTO',
    NULL                                        AS '#VALOR RATEIO',
    (E650SAL.CRECAL + E650SAL.CREMES)          AS '#MOVIMENTO',
    CONCAT_WS('-', 'MIB', E650SAL.CODEMP, PLA.CLACTA) AS 'KEY CONTA CONTÁBIL',
    -- Valor positivo para créditos históricos
    (E650SAL.CRECAL + E650SAL.CREMES)          AS '#MOVIMENTO CONTÁBIL'

-- ===============================================
-- RELACIONAMENTOS E JOINS PARA SALDOS
-- ===============================================
FROM SAPIENS.SAPIENS.E650SAL E650SAL WITH (NOLOCK) -- Tabela de saldos contábeis

    -- JOIN: Informações da empresa
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON E650SAL.CODEMP = EMP.CODEMP

    -- JOIN: Plano de contas contábeis
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON E650SAL.CODEMP = PLA.CODEMP
        AND E650SAL.CTARED = PLA.CTARED

WHERE 
    E650SAL.ANASIN = 'A'                       -- Apenas contas analíticas
    AND YEAR(E650SAL.MESANO) < 2025-- (SELECT dbo.F_FILTRO_ANO_CONTABILIDADE ())            -- Filtro para anos anteriores

-- =====================================================
-- QUARTA CONSULTA: SALDOS CONTÁBEIS (DÉBITOS HISTÓRICOS)
-- Fonte: Tabela de saldos contábeis para períodos anteriores
-- =====================================================
UNION ALL

SELECT
    -- ===============================================
    -- METADADOS DE CONTROLE E AUDITORIA
    -- ===============================================
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MIB'                                       AS 'SERVIDOR',
    
    -- ===============================================
    -- ESTRUTURA ORGANIZACIONAL
    -- ===============================================
    E650SAL.CODEMP                             AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                          AS 'EMPRESA',
    E650SAL.CODFIL                             AS 'COD FILIAL',
    E650SAL.CTARED                             AS 'COD REDUZIDO CONTA CONTÁBIL',
    PLA.CLACTA                                 AS 'COD CONTA CONTÁBIL',
    UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL',
    
    -- ===============================================
    -- INFORMAÇÕES DO LANÇAMENTO CONTÁBIL (SALDOS)
    -- ===============================================
    NULL                                        AS 'NUM LANÇAMENTO',
    NULL                                        AS 'NUM FATO CONTÁBIL',
    E650SAL.MESANO                             AS 'DATA LANÇAMENTO',
    'DÉBITO'                                   AS 'TIPO CD',
    NULL                                        AS 'SITUAÇÃO',
    NULL                                        AS 'TIPO LANÇAMENTO',
    NULL                                        AS 'ORIGEM LANÇAMENTO',
    
    -- ===============================================
    -- HISTÓRICO E COMPLEMENTO (N/A PARA SALDOS)
    -- ===============================================
    NULL                                        AS 'COD HISTORICO',
    NULL                                        AS 'HISTORICO COMPLEMENTO',
    NULL                                        AS 'PESSOA',
    
    -- ===============================================
    -- INFORMAÇÕES DE RATEIO (N/A PARA SALDOS)
    -- ===============================================
    NULL                                        AS 'TEM RATEIO',
    NULL                                        AS 'COD CENTRO RESULTADO',
    NULL                                        AS 'CENTRO RESULTADO',
    NULL                                        AS 'CLASSIFICAÇÃO CR',
    NULL                                        AS 'GRUPO CLASSIFICAÇÃO',
    NULL                                        AS 'CLASSIFICAÇÃO',
    
    -- ===============================================
    -- VALORES FINANCEIROS - DÉBITOS ACUMULADOS
    -- ===============================================
    (E650SAL.DEBCAL + E650SAL.DEBMES)          AS '#VALOR LANÇAMENTO',
    NULL                                        AS '#VALOR RATEIO',
    (E650SAL.DEBCAL + E650SAL.DEBMES)          AS '#MOVIMENTO',
    CONCAT_WS('-', 'MIB', E650SAL.CODEMP, PLA.CLACTA) AS 'KEY CONTA CONTÁBIL',
    -- Valor negativo para débitos históricos (convenção contábil)
    (E650SAL.DEBCAL + E650SAL.DEBMES) * -1     AS '#MOVIMENTO CONTÁBIL'

-- ===============================================
-- RELACIONAMENTOS E JOINS PARA SALDOS
-- ===============================================
FROM SAPIENS.SAPIENS.E650SAL E650SAL WITH (NOLOCK) -- Tabela de saldos contábeis

    -- JOIN: Informações da empresa
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON E650SAL.CODEMP = EMP.CODEMP

    -- JOIN: Plano de contas contábeis
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON E650SAL.CODEMP = PLA.CODEMP
        AND E650SAL.CTARED = PLA.CTARED

WHERE 
    E650SAL.ANASIN = 'A'                       -- Apenas contas analíticas
    AND YEAR(E650SAL.MESANO) < 2025-- (SELECT dbo.F_FILTRO_ANO_CONTABILIDADE ())           -- Filtro para anos anteriores

-- =====================================================
-- FIM DA CONSULTA CONSOLIDADA
-- Observações:
-- 1. Query otimizada para performance com NOLOCK hints
-- 2. Estrutura unificada para análise de movimentação contábil
-- 3. Separação clara entre débitos/créditos e períodos
-- 4. Chave única para integração com Power BI
-- 5. Classificação departamental customizada por empresa
-- =====================================================
GO
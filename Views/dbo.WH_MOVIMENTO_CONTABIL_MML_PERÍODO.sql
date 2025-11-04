SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   VIEW [dbo].[WH_MOVIMENTO_CONTABIL_MML_PERÍODO] 
AS -- =====================================================
-- SCRIPT: MML - Consulta de Lançamentos Contábeis
-- DESCRIÇÃO: Extração de dados contábeis com rateio
-- DATA: 30/07/2025
-- =====================================================

SELECT 
    -- INFORMAÇÕES DE CONTROLE E AUDITORIA
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MML'                                       AS 'SERVIDOR',
    
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
    IIF(LCT.CODEMP = 1, -- MML
        CASE LEFT(CCU.CLACCU, 2)
            WHEN '11' THEN 'ADM'
            WHEN '15' THEN 'PRODUÇÃO'
            WHEN '17' THEN 'APOIO'
            WHEN '21' THEN 'ADM'
            WHEN '22' THEN 'COMERCIAL'
            WHEN '23' THEN 'SUPRIMENTOS'
            WHEN '24' THEN 'LAVRA'
            WHEN '25' THEN 'PRODUÇÃO'
            WHEN '26' THEN 'OFICINA'
            WHEN '27' THEN 'MINÉRIO'
            ELSE 'OUTROS' 
        END, 
        'NÃO LISTADO'
    )                                            AS 'CLASSIFICAÇÃO',
    
    -- VALORES
    LCT.VLRLCT                                  AS '#VALOR LANÇAMENTO',
    RAT.VLRRAT                                  AS '#VALOR RATEIO',
     ISNULL(RAT.VLRRAT,LCT.VLRLCT ) AS '#MOVIMENTO',
     CONCAT_WS('-','MML',LCT.CODEMP, PLA.CLACTA) 'KEY CONTA CONTÁBIL',
     ISNULL(RAT.VLRRAT,LCT.VLRLCT)*IIF(LEFT(PLA.CLACTA ,1)=1,1,-1) AS '#MOVIMENTO CONTÁBIL'

FROM [SQLMML].[Sapiens_Prod].[dbo].[E640LCT] LCT WITH (NOLOCK) -- TABELA PRINCIPAL OTIMIZADA

    -- JOIN: INFORMAÇÕES DA EMPRESA (HASH JOIN PARA PARALELISMO)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E070EMP] EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: HISTORICO PADRÃO (HASH JOIN)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E046HPD] HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: RATEIOS (HASH JOIN - OTIMIZADO PARA PARALELISMO)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E640RAT] RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'D'
    
    -- JOIN: CENTRO DE CUSTO (HASH JOIN)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E044CCU] CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU

    -- JOIN: PLANO DE CONTAS
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E045PLA] PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTADEB = PLA.CTARED
    
WHERE 
    LCT.CTADEB <> 0                            -- ELIMINA REGISTROS SEM MOVIMENTO
    AND YEAR(LCT.DATLCT) >= 2025        -- FILTRO DE ANO ATUAL
        AND LCT.SITLCT IN(1,2)
    --AND LCT.NUMLCT = '1301296282'            -- FILTRO OPCIONAL PARA TESTE

-- =====================================================
-- UNION ALL - SEGUNDA PARTE DA CONSULTA
-- =====================================================

UNION ALL

SELECT 
    -- INFORMAÇÕES DE CONTROLE E AUDITORIA
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO',
    'MML'                                       AS 'SERVIDOR',
    
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
    IIF(LCT.CODEMP = 1, -- MML
        CASE LEFT(CCU.CLACCU, 2)
            WHEN '11' THEN 'ADM'
            WHEN '15' THEN 'PRODUÇÃO'
            WHEN '17' THEN 'APOIO'
            WHEN '21' THEN 'ADM'
            WHEN '22' THEN 'COMERCIAL'
            WHEN '23' THEN 'SUPRIMENTOS'
            WHEN '24' THEN 'LAVRA'
            WHEN '25' THEN 'PRODUÇÃO'
            WHEN '26' THEN 'OFICINA'
            WHEN '27' THEN 'MINÉRIO'
            ELSE 'OUTROS' 
        END, 
        'NÃO LISTADO'
    )                                            AS 'CLASSIFICAÇÃO',
    
    -- VALORES
    LCT.VLRLCT                                  AS '#VALOR LANÇAMENTO',
    RAT.VLRRAT                                  AS '#VALOR RATEIO',
   ISNULL(RAT.VLRRAT,LCT.VLRLCT ) AS '#MOVIMENTO',
   CONCAT_WS('-','MML',LCT.CODEMP, PLA.CLACTA) 'KEY CONTA CONTÁBIL',
   ISNULL(RAT.VLRRAT,LCT.VLRLCT )*IIF(LEFT(PLA.CLACTA ,1)=1,-1,1) AS '#MOVIMENTO CONTÁBIL'


FROM [SQLMML].[Sapiens_Prod].[dbo].[E640LCT] LCT WITH (NOLOCK) -- TABELA PRINCIPAL OTIMIZADA

    -- JOIN: INFORMAÇÕES DA EMPRESA (HASH JOIN PARA PARALELISMO)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E070EMP] EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: HISTORICO PADRÃO (HASH JOIN)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E046HPD] HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: RATEIOS (HASH JOIN - OTIMIZADO PARA PARALELISMO)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E640RAT] RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'C'
    
    -- JOIN: CENTRO DE CUSTO (HASH JOIN)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E044CCU] CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU

    -- JOIN: PLANO DE CONTAS
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E045PLA] PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTACRE = PLA.CTARED
    
WHERE 
    LCT.CTACRE <> 0                            -- ELIMINA REGISTROS SEM MOVIMENTO
    AND YEAR(LCT.DATLCT) >= 2025      -- FILTRO DE ANO ATUAL
        AND LCT.SITLCT IN(1,2)
    --AND LCT.NUMLCT = '1301296282'            -- FILTRO OPCIONAL PARA TESTE


UNION ALL


SELECT
 GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO'
 ,CONVERT(VARCHAR(10), GETDATE(), 103)       AS 'DATA ATUALIZAÇÃO'
 ,'MML'                                       AS 'SERVIDOR'
 ,E650SAL.codemp 'COD EMPRESA'
 ,UPPER(EMP.SIGEMP)                          AS 'EMPRESA'
 ,E650SAL.codfil 'COD FILIAL'
 ,E650SAL.ctared 'COD REDUZIDO CONTA CONTÁBIL'
 ,PLA.CLACTA                               AS 'COD CONTA CONTÁBIL'
 ,UPPER(PLA.DESCTA)                          AS 'CONTA CONTÁBIL'
 ,NULL AS 'NUM LANÇAMENTO'
 ,NULL AS 'NUM FATO CONTÁBIL'
 ,E650SAL.mesano 'DATA LANÇAMENTO'
 ,IIF(E650SAL.salmes<0,'DÉBITO','CRÉDITO') 'TIPO CD'
 ,NULL AS 'SITUAÇÃO'
 ,NULL AS 'TIPO LANÇAMENTO'
 ,NULL AS 'ORIGEM LANÇAMENTO'
 ,NULL AS 'COD HISTORICO'
 ,NULL AS 'HISTORICO COMPLEMENTO'
 ,NULL AS 'TEM RATEIO'
 ,NULL AS 'COD CENTRO RESULTADO'
 ,NULL AS 'CENTRO RESULTADO'
 ,NULL AS 'CLASSIFICAÇÃO CR'
 ,NULL AS 'GRUPO CLASSIFICAÇÃO'
 ,NULL AS CLASSIFICAÇÃO
 ,ABS(E650SAL.salmes) '#VALOR LANÇAMENTO'
 ,NULL AS '#VALOR RATEIO'
 ,ABS(E650SAL.salmes)  '#MOVIMENTO'
 ,CONCAT_WS('-','MML',E650SAL.codemp, PLA.CLACTA) 'KEY CONTA CONTÁBIL'
 --,E650SAL.salmes '#MOVIMENTO CONTÁBIL'
,ABS(E650SAL.salmes)*
 
 IIF(E650SAL.salmes<0,
 IIF(PLA.NATCTA = 'D',  1,
     IIF(PLA.NATCTA = 'C', 1, -1)),
 IIF(PLA.NATCTA = 'D', -1,
 IIF(PLA.NATCTA = 'C',  -1, 1))) '#MOVIMENTO CONTÁBIL'

FROM [SQLMML].[Sapiens_Prod].[dbo].[E650SAL]

-- JOIN: INFORMAÇÕES DA EMPRESA (HASH JOIN PARA PARALELISMO)
LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E070EMP] EMP WITH (NOLOCK)
ON E650SAL.CODEMP = EMP.CODEMP

-- JOIN: PLANO DE CONTAS
LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E045PLA] PLA WITH (NOLOCK)   
ON E650SAL.CODEMP = PLA.CODEMP
AND E650SAL.CTARED = PLA.CTARED



WHERE E650SAL.MESANO = '01/12/2024'
AND E650SAL.ANASIN = 'A'
GO
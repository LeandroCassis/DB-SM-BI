SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_MOVIMENTO_CONTABIL_IDENTIFICADO_MML] 
AS -- =====================================================
-- SCRIPT: EXTRAÇÃO DE LANÇAMENTOS CONTÁBEIS COM RATEIOS
-- DESCRIÇÃO: Consulta unificada de lançamentos a débito e crédito
--            incluindo rateios, centros de custo e identificação de pessoas
-- BANCO: Sapiens
-- DATA: 2025-01-01 em diante
-- =====================================================

-- =====================================================
-- CTE: _PESSOAS
-- OBJETIVO: Identificar pessoas (fornecedores e clientes) associadas aos lançamentos
-- TABELAS ENVOLVIDAS: e640lct, e644lvc, e644lti, e644lma, e644lff, e644lnf, 
--                     e645cfc, e644lam, e644lic, e644lim, e095for, e110for, e110cli
-- MODIFICAÇÃO: Expandido para identificar tanto fornecedores quanto clientes

-- =====================================================
-- PRIMEIRA CONSULTA: LANÇAMENTOS A DÉBITO
-- OBJETIVO: Extrair todos os lançamentos contábeis na coluna de débito
-- =====================================================
SELECT 
    'MML'                                       AS 'SERVIDOR',
    LCT.CODEMP                                  AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                           AS 'EMPRESA',
    LCT.CODFIL                                  AS 'COD FILIAL',
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)        AS 'DATA ATUALIZAÇÃO',
    ISNULL(RAT.CODCCU, 'NA')                    AS 'COD. CENTRO DE CUSTO',
    UPPER(ISNULL(CCU.DESCCU, 'SEM CR'))         AS 'DESC. CENTRO E CUSTO',
    LCT.CTADEB                                  AS 'COD. CONTA CONTABIL',
    UPPER(PLA.DESCTA)                           AS 'DESC CONTA CONTABIL',
    LCT.CODHPD                                  AS 'CODHPD',
    
    -- Concatenação do histórico padrão com complemento
    UPPER(ISNULL(HPD.DESHPD, '') + ' ' + 
          ISNULL(LCT.CPLLCT, ''))               AS 'HISTORICO COMPLEMENTO - LANCAMENTO',
    
    CAST(LCT.DATLCT AS DATE)                    AS 'DATA LANCAMENTO',
    ISNULL(RAT.VLRRAT, LCT.VLRLCT)              AS 'VALOR LANCAMENTO',
    'D'                                         AS 'DÉBITO OU CRÉDITO - LANÇAMENTO',
    CCU.CLACCU                                  AS 'CLASSIFICAÇÃO CENTRO CUSTO',
    LEFT(CCU.CLACCU, 2)                         AS 'CLASSIFICACAO - CC',
    
    -- Classificação hierárquica por empresa e centro de custo
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
    )                                            AS 'CLASSIFICACAO',
    
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.NUMLCT                                  AS 'SEQ. LANCAMENTO',
    
    -- Extração do número de requisição quando presente no histórico
    CASE 
        WHEN PATINDEX('%Requisicão%', HPD.DESHPD) = 0 THEN ''
        ELSE REPLACE(LCT.CPLLCT, '"', '')
    END                                         AS 'N° REQUISICAO',
    
    -- Identificação da pessoa (lógica idêntica)
    UPPER(CASE 
        WHEN LCT.orilct IN ('CPR', 'VEN', 'CRE', 'PAG', 'REC') AND CHARINDEX(',', LCT.cpllct) > 0 THEN 
            REPLACE(SUBSTRING(LCT.cpllct, CHARINDEX(',', LCT.cpllct) + 1, LEN(LCT.cpllct)), '"', '')
        ELSE '---'
    END) AS 'PESSOA',
LCT.orilct 'ORIGEM'

FROM [SQLMML].[Sapiens_Prod].[dbo].E640LCT LCT WITH (NOLOCK)  -- Tabela principal de lançamentos

    -- JOIN: Informações da empresa
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: Histórico padrão de lançamentos
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: Rateios para contas de débito
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'D'  -- Apenas rateios de débito
    
    -- JOIN: Centro de custo
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU
    
    -- JOIN: Plano de contas contábeis
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTADEB = PLA.CTARED
    
    -- JOIN: CTE de pessoas identificadas


WHERE 
    LCT.CTADEB <> 0                            -- Elimina registros sem conta de débito
    AND YEAR(LCT.DATLCT) >= 2025               -- Lançamentos de 2025 em diante
    AND LCT.SITLCT IN (1, 2)                   -- Apenas lançamentos válidos (ativo/processado)

-- =====================================================
-- SEGUNDA CONSULTA: LANÇAMENTOS A CRÉDITO
-- OBJETIVO: Extrair todos os lançamentos contábeis na coluna de crédito
-- ESTRUTURA: Idêntica à primeira consulta, porém utilizando CTACRE
-- =====================================================
UNION ALL

SELECT 
    'MML'                                       AS 'SERVIDOR',
    LCT.CODEMP                                  AS 'COD EMPRESA',
    UPPER(EMP.SIGEMP)                           AS 'EMPRESA',
    LCT.CODFIL                                  AS 'COD FILIAL',
    GETDATE()                                   AS 'DATA HORA ATUALIZAÇÃO',
    CONVERT(VARCHAR(10), GETDATE(), 103)        AS 'DATA ATUALIZAÇÃO',
    ISNULL(RAT.CODCCU, 'NA')                    AS 'COD. CENTRO DE CUSTO',
    UPPER(ISNULL(CCU.DESCCU, 'SEM CR'))         AS 'DESC. CENTRO E CUSTO',
    LCT.CTACRE                                  AS 'COD. CONTA CONTABIL',  -- Diferença: CTACRE
    UPPER(PLA.DESCTA)                           AS 'DESC CONTA CONTABIL',
    LCT.CODHPD                                  AS 'CODHPD',
    
    UPPER(ISNULL(HPD.DESHPD, '') + ' ' + 
          ISNULL(LCT.CPLLCT, ''))               AS 'HISTORICO COMPLEMENTO - LANCAMENTO',
    
    CAST(LCT.DATLCT AS DATE)                    AS 'DATA LANCAMENTO',
    ISNULL(RAT.VLRRAT, LCT.VLRLCT)              AS 'VALOR LANCAMENTO',
    'C'                                         AS 'DÉBITO OU CRÉDITO - LANÇAMENTO',  -- Diferença: 'C'
    CCU.CLACCU                                  AS 'CLASSIFICAÇÃO CENTRO CUSTO',
    LEFT(CCU.CLACCU, 2)                         AS 'CLASSIFICACAO - CC',
    
    -- Classificação hierárquica (idêntica à primeira consulta)
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
    )                                            AS 'CLASSIFICACAO',
    
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.NUMLCT                                  AS 'SEQ. LANCAMENTO',
    
    CASE 
        WHEN PATINDEX('%Requisicão%', HPD.DESHPD) = 0 THEN ''
        ELSE REPLACE(LCT.CPLLCT, '"', '')
    END                                         AS 'N° REQUISICAO',
    
    -- Identificação da pessoa (lógica idêntica)
    UPPER(CASE 
        WHEN LCT.orilct IN ('CPR', 'VEN', 'CRE', 'PAG', 'REC') AND CHARINDEX(',', LCT.cpllct) > 0 THEN 
            REPLACE(SUBSTRING(LCT.cpllct, CHARINDEX(',', LCT.cpllct) + 1, LEN(LCT.cpllct)), '"', '')
        ELSE '---'
    END) AS 'PESSOA',
LCT.orilct 'ORIGEM'

FROM [SQLMML].[Sapiens_Prod].[dbo].E640LCT LCT WITH (NOLOCK)

    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: Rateios para contas de crédito
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'C'  -- Diferença: Apenas rateios de crédito
    
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU
    
    -- JOIN: Plano de contas com CTACRE
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTACRE = PLA.CTARED  -- Diferença: CTACRE em vez de CTADEB
    


WHERE 
    LCT.CTACRE <> 0                            -- Elimina registros sem conta de crédito
    AND YEAR(LCT.DATLCT) >= 2025               -- Lançamentos de 2025 em diante
    AND LCT.SITLCT IN (1, 2)                   -- Apenas lançamentos válidos

-- =====================================================
-- FIM DO SCRIPT
-- RESULTADO: Dataset unificado com débitos e créditos separados por linha
-- =====================================================
GO
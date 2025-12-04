SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   VIEW [dbo].[WH_MOVIMENTO_CONTABIL_IDENTIFICADO_MIB] 
AS -- =====================================================
-- SCRIPT: EXTRAÇÃO DE LANÇAMENTOS CONTÁBEIS COM RATEIOS
-- DESCRIÇÃO: Consulta unificada de lançamentos a débito e crédito
--            incluindo rateios, centros de custo e identificação de pessoas
-- BANCO: Sapiens
-- DATA: 2025-01-01 em diante
-- =====================================================

-- =====================================================
-- CTE: _PESSOAS
-- OBJETIVO: Identificar pessoas (fornecedores/clientes) associadas aos lançamentos
-- TABELAS ENVOLVIDAS: e640lct, e644lvc, e644lti, e644lma, e644lff, e644lnf, 
--                     e645cfc, e644lam, e644lic, e095for, e110for, e110cli
-- =====================================================
WITH _PESSOAS AS (
    SELECT 
        -- TOP 500 -- Limitador opcional (comentado)
        l.codemp                                AS 'COD EMPRESA',
        l.numlct                                AS 'NUM LANÇAMENTO',
        MAX(UPPER(d.src_table))                 AS 'TABELA',
        MAX(COALESCE(d.codfor, d.codcli))       AS 'COD PESSOA',
        MAX(UPPER(COALESCE(
            f.nomfor,    -- Nome do fornecedor (e095for)
            f2.nomfor,   -- Nome do fornecedor (e110for)
            c.nomcli     -- Nome do cliente (e110cli)
        )))                                     AS 'PESSOA'
    FROM Sapiens.Sapiens.e640lct l
    
    -- Consolidação de múltiplas tabelas relacionadas a fornecedores/clientes
    LEFT JOIN (
        SELECT numlct, codfor, NULL AS codcli, 'e644lvc' AS src_table 
        FROM Sapiens.Sapiens.e644lvc  -- Lançamentos de vale combustível
        UNION ALL 
        SELECT numlct, codfor, NULL, 'e644lti' 
        FROM Sapiens.Sapiens.e644lti  -- Lançamentos de título
        UNION ALL 
        SELECT numlct, codfor, NULL, 'e644lma' 
        FROM Sapiens.Sapiens.e644lma  -- Lançamentos de material
        UNION ALL 
        SELECT numlct, codfor, NULL, 'e644lff' 
        FROM Sapiens.Sapiens.e644lff  -- Lançamentos de fatura fornecedor
        UNION ALL 
        SELECT numlct, codfor, NULL, 'e644lnf' 
        FROM Sapiens.Sapiens.e644lnf  -- Lançamentos de nota fiscal
        UNION ALL 
        SELECT numlct, codfor, NULL, 'e645cfc' 
        FROM Sapiens.Sapiens.e645cfc  -- Contas a pagar fornecedor
        UNION ALL 
        SELECT numlct, codfor, NULL, 'e644lam' 
        FROM Sapiens.Sapiens.e644lam  -- Lançamentos de ativo
        UNION ALL 
        SELECT numlct, NULL AS codfor, codcli, 'e644lic' 
        FROM Sapiens.Sapiens.e644lic  -- Lançamentos de cliente
    ) d ON l.numlct = d.numlct
    
    -- Joins para obter nomes de fornecedores e clientes
    LEFT JOIN Sapiens.Sapiens.e095for f   ON d.codfor = f.codfor   -- Cadastro fornecedor 1
    LEFT JOIN Sapiens.Sapiens.e110for f2  ON d.codfor = f2.codfor  -- Cadastro fornecedor 2
    LEFT JOIN Sapiens.Sapiens.e110cli c   ON d.codcli = c.codcli   -- Cadastro cliente
    
    WHERE l.datlct >= '2025-01-01'  -- Apenas lançamentos de 2025 em diante
        AND (
            d.codfor IS NOT NULL           -- Possui fornecedor
            OR d.codcli IS NOT NULL        -- OU possui cliente
            OR (l.cgccpf IS NOT NULL AND l.cgccpf <> 0)  -- OU possui CPF/CNPJ
        )
    
    GROUP BY l.codemp, l.numlct
)

-- =====================================================
-- PRIMEIRA CONSULTA: LANÇAMENTOS A DÉBITO
-- OBJETIVO: Extrair todos os lançamentos contábeis na coluna de débito
-- =====================================================
SELECT 
    'MIB'                                       AS 'SERVIDOR',
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
    )                                           AS 'CLASSIFICACAO',
    
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.NUMLCT                                  AS 'SEQ. LANCAMENTO',
    
    -- Extração do número de requisição quando presente no histórico
    CASE 
        WHEN PATINDEX('%Requisicão%', HPD.DESHPD) = 0 THEN ''
        ELSE REPLACE(LCT.CPLLCT, '"', '')
    END                                         AS 'N° REQUISICAO',
    
    -- Identificação da pessoa relacionada ao lançamento
    COALESCE(
        _PESSOAS.PESSOA,  -- Primeira prioridade: pessoa da CTE
        IIF(LCT.ORILCT = 'REC',  -- Se origem = Recebimento
            UPPER(NULLIF(
                REPLACE(REPLACE(
                    LTRIM(RTRIM(
                        RIGHT(
                            LCT.CPLLCT,
                            NULLIF(CHARINDEX(',', REVERSE(LCT.CPLLCT)) - 1, -1)
                        )
                    )),
                    '"', ''   -- Remove aspas duplas
                ),
                '''', ''      -- Remove aspas simples
                ),
                ''
            )),
            IIF(LCT.ORILCT = 'VEN',  -- Se origem = Venda
                UPPER(NULLIF(
                    REPLACE(REPLACE(
                        LTRIM(RTRIM(
                            RIGHT(
                                LCT.CPLLCT,
                                NULLIF(CHARINDEX(',', REVERSE(LCT.CPLLCT)) - 1, -1)
                            )
                        )),
                        '"', ''
                    ),
                    '''', ''
                    ),
                    ''
                )),
                NULL
            )
        )
    )                                           AS 'PESSOA'

FROM SAPIENS.SAPIENS.E640LCT LCT WITH (NOLOCK)  -- Tabela principal de lançamentos

    -- JOIN: Informações da empresa
    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    -- JOIN: Histórico padrão de lançamentos
    LEFT JOIN SAPIENS.SAPIENS.E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: Rateios para contas de débito
    LEFT JOIN SAPIENS.SAPIENS.E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'D'  -- Apenas rateios de débito
    
    -- JOIN: Centro de custo
    LEFT JOIN SAPIENS.SAPIENS.E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU
    
    -- JOIN: Plano de contas contábeis
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTADEB = PLA.CTARED
    
    -- JOIN: CTE de pessoas identificadas
    LEFT JOIN _PESSOAS
        ON LCT.CODEMP = _PESSOAS.[COD EMPRESA]
        AND LCT.NUMLCT = _PESSOAS.[NUM LANÇAMENTO]

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
    'MIB'                                       AS 'SERVIDOR',
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
    IIF(LCT.CODEMP = 5,
        CASE LEFT(CLACCU, 2)
            WHEN '11' THEN 'ADM'
            WHEN '12' THEN 'PRODUCAO'
            WHEN '13' THEN 'TERMOELETRICA'
            WHEN '14' THEN 'PELOTIZACAO'
            WHEN '15' THEN 'OXIGENIO'
            WHEN '16' THEN 'TRANSPORTE INTERNO'
            ELSE 'OUTROS' 
        END,
        IIF(LCT.CODEMP = 2,
            CASE LEFT(CLACCU, 2)
                WHEN '21' THEN 'ADM'
                WHEN '22' THEN 'LAVRA'
                WHEN '23' THEN 'PRODUCAO'
                WHEN '24' THEN 'OFICINA'
                WHEN '25' THEN 'M.AMBIENTE'
                ELSE 'OUTROS' 
            END,
            IIF(LCT.CODEMP = 1,
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
    )                                           AS 'CLASSIFICACAO',
    
    LCT.SITLCT                                  AS 'SITUAÇÃO',
    LCT.NUMLCT                                  AS 'SEQ. LANCAMENTO',
    
    CASE 
        WHEN PATINDEX('%Requisicão%', HPD.DESHPD) = 0 THEN ''
        ELSE REPLACE(LCT.CPLLCT, '"', '')
    END                                         AS 'N° REQUISICAO',
    
    -- Identificação da pessoa (lógica idêntica)
    COALESCE(
        _PESSOAS.PESSOA,
        IIF(LCT.ORILCT = 'REC',
            UPPER(NULLIF(
                REPLACE(REPLACE(
                    LTRIM(RTRIM(
                        RIGHT(
                            LCT.CPLLCT,
                            NULLIF(CHARINDEX(',', REVERSE(LCT.CPLLCT)) - 1, -1)
                        )
                    )),
                    '"', ''
                ),
                '''', ''
                ),
                ''
            )),
            IIF(LCT.ORILCT = 'VEN',
                UPPER(NULLIF(
                    REPLACE(REPLACE(
                        LTRIM(RTRIM(
                            RIGHT(
                                LCT.CPLLCT,
                                NULLIF(CHARINDEX(',', REVERSE(LCT.CPLLCT)) - 1, -1)
                            )
                        )),
                        '"', ''
                    ),
                    '''', ''
                    ),
                    ''
                )),
                NULL
            )
        )
    )                                           AS 'PESSOA'

FROM SAPIENS.SAPIENS.E640LCT LCT WITH (NOLOCK)

    LEFT JOIN SAPIENS.SAPIENS.E070EMP EMP WITH (NOLOCK)
        ON LCT.CODEMP = EMP.CODEMP
    
    LEFT JOIN SAPIENS.SAPIENS.E046HPD HPD WITH (NOLOCK)
        ON LCT.CODHPD = HPD.CODHPD
    
    -- JOIN: Rateios para contas de crédito
    LEFT JOIN SAPIENS.SAPIENS.E640RAT RAT WITH (NOLOCK)
        ON LCT.CODEMP = RAT.CODEMP 
        AND LCT.NUMLCT = RAT.NUMLCT
        AND RAT.DEBCRE = 'C'  -- Diferença: Apenas rateios de crédito
    
    LEFT JOIN SAPIENS.SAPIENS.E044CCU CCU WITH (NOLOCK)
        ON RAT.CODEMP = CCU.CODEMP 
        AND RAT.CODCCU = CCU.CODCCU
    
    -- JOIN: Plano de contas com CTACRE
    LEFT JOIN SAPIENS.SAPIENS.E045PLA PLA WITH (NOLOCK)   
        ON LCT.CODEMP = PLA.CODEMP
        AND LCT.CTACRE = PLA.CTARED  -- Diferença: CTACRE em vez de CTADEB
    
    LEFT JOIN _PESSOAS
        ON LCT.CODEMP = _PESSOAS.[COD EMPRESA]
        AND LCT.NUMLCT = _PESSOAS.[NUM LANÇAMENTO]

WHERE 
    LCT.CTACRE <> 0                            -- Elimina registros sem conta de crédito
    AND YEAR(LCT.DATLCT) >= 2025               -- Lançamentos de 2025 em diante
    AND LCT.SITLCT IN (1, 2)                   -- Apenas lançamentos válidos

-- =====================================================
-- FIM DO SCRIPT
-- RESULTADO: Dataset unificado com débitos e créditos separados por linha
-- =====================================================
GO
SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_PRODUTOS_E_SERVIÇOS] 
AS -- ===================================================================
-- CONSULTA: WAREHOUSE DE PRODUTOS E SERVIÇOS - CADASTRO UNIFICADO
-- ===================================================================
-- OBJETIVO: Unificar cadastro de produtos e serviços para warehouse
-- TABELAS PRINCIPAIS:
--   E080SER - Cadastro de Serviços
--   E075PRO - Cadastro de Produtos  
--   E012FAM - Cadastro de Famílias
-- OBSERVAÇÃO: União dos cadastros de produtos e serviços com chaves únicas
-- ===================================================================

-- PRIMEIRA PARTE: SERVIÇOS (E080SER)
SELECT 
    'MIB' 'SERVIDOR',  
    'SERVIÇO' 'TIPO ITEM',                                              -- Identificador do servidor
    CONCAT_WS('-','MIB',E080SER.CODEMP) 'KEY EMPRESA',                  -- Chave única da empresa
    E080SER.CODEMP 'CÓD EMPRESA',                                       -- Código da empresa
    E080SER.CODSER 'CÓD ITEM',                                          -- Código do serviço
    CONCAT_WS('-','MIB',E080SER.CODEMP,'S',E080SER.CODSER) 'KEY ITEM',      -- Chave única do item
    UPPER(E080SER.DESSER) 'ITEM',                                       -- Descrição do serviço
    UPPER(E080SER.UNIMED) 'UNIDADE',                                    -- Unidade de medida
    E080SER.CODFAM 'CÓD FAMÍLIA',                                       -- Código da família
    CONCAT_WS('-','MIB',E080SER.CODEMP,E080SER.CODFAM) 'KEY FAMÍLIA',   -- Chave única da família
    UPPER(E012FAM.DESFAM) 'FAMÍLIA'                                     -- Descrição da família

FROM SAPIENS.SAPIENS.E080SER WITH (NOLOCK)                             -- Tabela de serviços
LEFT JOIN SAPIENS.SAPIENS.E012FAM WITH (NOLOCK)                        -- Tabela de famílias
    ON E080SER.CODEMP = E012FAM.CODEMP                                  -- Join por empresa
    AND E080SER.CODFAM = E012FAM.CODFAM                                 -- Join por família

UNION ALL

-- SEGUNDA PARTE: PRODUTOS (E075PRO)
SELECT 
    'MIB' 'SERVIDOR',    
    'PRODUTO' 'TIPO ITEM',                                              -- Identificador do servidor
    CONCAT_WS('-','MIB',E075PRO.CODEMP) 'KEY EMPRESA',                  -- Chave única da empresa
    E075PRO.CODEMP 'CÓD EMPRESA',                                       -- Código da empresa
    E075PRO.CODPRO 'CÓD ITEM',                                          -- Código do produto
    CONCAT_WS('-','MIB',E075PRO.CODEMP,'P',E075PRO.CODPRO) 'KEY ITEM',      -- Chave única do item
    UPPER(E075PRO.DESPRO) 'ITEM',                                       -- Descrição do produto
    UPPER(E075PRO.UNIMED) 'UNIDADE',                                    -- Unidade de medida
    E075PRO.CODFAM 'CÓD FAMÍLIA',                                       -- Código da família
    CONCAT_WS('-','MIB',E075PRO.CODEMP,E075PRO.CODFAM) 'KEY FAMÍLIA',   -- Chave única da família
    UPPER(E012FAM.DESFAM) 'FAMÍLIA'                                     -- Descrição da família

FROM SAPIENS.SAPIENS.E075PRO WITH (NOLOCK)                             -- Tabela de produtos
LEFT JOIN SAPIENS.SAPIENS.E012FAM WITH (NOLOCK)                        -- Tabela de famílias
    ON E075PRO.CODEMP = E012FAM.CODEMP                                  -- Join por empresa
    AND E075PRO.CODFAM = E012FAM.CODFAM                                 -- Join por família



UNION ALL



-- PRIMEIRA PARTE: SERVIÇOS (E080SER)
SELECT 
    'MML' 'SERVIDOR',  
    'SERVIÇO' 'TIPO ITEM',                                              -- Identificador do servidor
    CONCAT_WS('-','MML',E080SER.CODEMP) 'KEY EMPRESA',                  -- Chave única da empresa
    E080SER.CODEMP 'CÓD EMPRESA',                                       -- Código da empresa
    E080SER.CODSER 'CÓD ITEM',                                          -- Código do serviço
    CONCAT_WS('-','MML',E080SER.CODEMP,'S',E080SER.CODSER) 'KEY ITEM',      -- Chave única do item
    UPPER(E080SER.DESSER) 'ITEM',                                       -- Descrição do serviço
    UPPER(E080SER.UNIMED) 'UNIDADE',                                    -- Unidade de medida
    E080SER.CODFAM 'CÓD FAMÍLIA',                                       -- Código da família
    CONCAT_WS('-','MML',E080SER.CODEMP,E080SER.CODFAM) 'KEY FAMÍLIA',   -- Chave única da família
    UPPER(E012FAM.DESFAM) 'FAMÍLIA'                                     -- Descrição da família

FROM [SQLMML].[Sapiens_Prod].[dbo].[E080SER] WITH (NOLOCK)                             -- Tabela de serviços
LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E012FAM] WITH (NOLOCK)                        -- Tabela de famílias
    ON E080SER.CODEMP = E012FAM.CODEMP                                  -- Join por empresa
    AND E080SER.CODFAM = E012FAM.CODFAM                                 -- Join por família

UNION ALL

-- SEGUNDA PARTE: PRODUTOS (E075PRO)
SELECT 
    'MML' 'SERVIDOR',    
    'PRODUTO' 'TIPO ITEM',                                              -- Identificador do servidor
    CONCAT_WS('-','MML',E075PRO.CODEMP) 'KEY EMPRESA',                  -- Chave única da empresa
    E075PRO.CODEMP 'CÓD EMPRESA',                                       -- Código da empresa
    E075PRO.CODPRO 'CÓD ITEM',                                          -- Código do produto
    CONCAT_WS('-','MML',E075PRO.CODEMP,'P',E075PRO.CODPRO) 'KEY ITEM',      -- Chave única do item
    UPPER(E075PRO.DESPRO) 'ITEM',                                       -- Descrição do produto
    UPPER(E075PRO.UNIMED) 'UNIDADE',                                    -- Unidade de medida
    E075PRO.CODFAM 'CÓD FAMÍLIA',                                       -- Código da família
    CONCAT_WS('-','MML',E075PRO.CODEMP,E075PRO.CODFAM) 'KEY FAMÍLIA',   -- Chave única da família
    UPPER(E012FAM.DESFAM) 'FAMÍLIA'                                     -- Descrição da família

FROM [SQLMML].[Sapiens_Prod].[dbo].[E075PRO] WITH (NOLOCK)                             -- Tabela de produtos
LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E012FAM] WITH (NOLOCK)                        -- Tabela de famílias
    ON E075PRO.CODEMP = E012FAM.CODEMP                                  -- Join por empresa
    AND E075PRO.CODFAM = E012FAM.CODFAM                                 -- Join por família
GO
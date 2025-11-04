SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_SOLICITAÇÕES] 
AS -- =====================================================================
-- CONSULTA: RELATÓRIO COMPLETO DE SOLICITAÇÕES DE COMPRAS
-- =====================================================================
-- TABELAS UTILIZADAS:
--   E405SOL - Solicitações de Compras (Principal)
--   E075PRO - Produtos
--   E044CCU - Centros de Custo
--   E045PLA - Plano de Contas Contábil
--   E091PLF - Plano de Contas Financeiro
--   E205DEP - Depósitos
--   R999USU - Usuários (múltiplos relacionamentos)
-- OBJETIVO: Relatório detalhado das solicitações com situações, valores,
--          usuários responsáveis e classificações por centro de custo
-- =====================================================================

SELECT 
    'MIB' 'SERVIDOR',                                                  -- Identificador do servidor
    GETDATE() 'ATUALIZAÇÃO',                                          -- Data/hora de execução da consulta
    
    -- DADOS DA EMPRESA E SOLICITAÇÃO
    E405SOL.CODEMP 'COD EMPRESA',                                   -- Código da empresa
    CONCAT_WS('-','MIB',E405SOL.CODEMP) 'KEY EMPRESA',               -- Chave única da empresa
    E405SOL.NUMSOL 'COD SOLICITAÇÃO',                              -- Número da solicitação
    CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.NUMSOL) 'KEY SOLICITAÇÃO', -- Chave única da solicitação
    E405SOL.NUMCOT 'COD COTAÇÃO',                                  -- Número da cotação vinculada
    CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.NUMCOT) 'KEY COTAÇÃO', -- Chave única da cotação
    E405SOL.NUMEME 'COD REQUISIÇÃO',                               -- Número da requisição
    CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.NUMEME) 'KEY REQUISIÇÃO', -- Chave única da requisição
    E405SOL.SEQEME 'SEQUÊNCIA REQUISIÇÃO',                            -- Sequência da requisição
    E405SOL.SEQSOL 'SEQUÊNCIA SOLICITAÇÃO',                           -- Sequência da solicitação
    
    -- DATAS DE CONTROLE
    E405SOL.DATSOL 'DATA SOLICITAÇÃO',                                -- Data da solicitação
    E405SOL.DATPRV 'DATA PREVISÃO ENTREGA',                           -- Data prevista para entrega
    E405SOL.DATCAN 'DATA CANCELAMENTO',                               -- Data de cancelamento
    E405SOL.DATEFC 'DATA ENVIO SOLICITAÇÃO',                          -- Data de envio da solicitação
    
    -- CÓDIGOS DE CONTROLE
    E405SOL.CODTNS 'COD TRANSAÇÃO',                                -- Código da transação


    -- DADOS DO PRODUTO/SERVIÇO
    IIF(E405SOL.PROSER='S', 'SERVIÇO', 'PRODUTO') 'TIPO ITEM',        -- Tipo serviço ou produto
    IIF(E405SOL.PROSER='S', E405SOL.CODSER, E405SOL.CODPRO) 'COD ITEM', -- Código do item
    UPPER(COALESCE(E075PRO.DESPRO,E080SER.DESSER))  'ITEM', -- Chave única do item

    CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.PROSER,IIF(E405SOL.PROSER='S', E405SOL.CODSER, E405SOL.CODPRO)) 'KEY ITEM', -- Chave única do item
    CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.NUMCOT,E405SOL.PROSER,IIF(E405SOL.PROSER='S', E405SOL.CODSER, E405SOL.CODPRO)) 'KEY ITEM COTAÇÃO', -- Chave única do item
    CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.NUMSOL,E405SOL.SEQSOL) 'KEY ITEM SEQUÊNCIA',
    
    -- QUANTIDADES
    E405SOL.QTDSOL '#QUANTIDADE SOLICITADA',                          -- Quantidade solicitada
    E405SOL.QTDAPR '#QUANTIDADE APROVADA',                            -- Quantidade aprovada
    E405SOL.QTDCAN '#QUANTIDADE CANCELADA',                           -- Quantidade cancelada

    -- VALORES FINANCEIROS
    E405SOL.PRESOL '#VALOR MÉDIO',                                    -- Preço médio unitário
    E405SOL.QTDSOL * E405SOL.PRESOL '#VALOR TOTAL',                   -- Valor total da solicitação
    
    -- DEPÓSITO
    UPPER(E205DEP.DESDEP) 'DESCRIÇÃO DEPÓSITO',                       -- Descrição do depósito
    E405SOL.UNIMED 'COD UNIDADE',                              -- Código unidade medida
    UPPER(E015MED.DESMED) 'UNIDADE MEDIDA',                       -- Descrição unidade medida
    -- SITUAÇÃO DA SOLICITAÇÃO
    CASE E405SOL.SITSOL                                               -- Descrição da situação
        WHEN '0' THEN 'DIGITADA'
        WHEN '1' THEN 'COTAÇÃO'
        WHEN '2' THEN 'ORDEM DE COMPRA'
        WHEN '3' THEN 'FINALIZADA'
        WHEN '9' THEN 'CANCELADA'
    END 'SITUAÇÃO SOLICITAÇÃO',

    -- CONTAS FINANCEIRAS E CONTÁBEIS
   IIF(E405SOL.CTAFIN IS NULL,NULL, CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.CTAFIN)) 'KEY CONTA FINANCEIRA', -- Chave única conta financeira
    UPPER(E091PLF.DESCTA) 'CONTA FINANCEIRA',                         -- Descrição da conta financeira
   IIF(E045PLA.CLACTA IS NULL,NULL, CONCAT_WS('-','MIB',E405SOL.CODEMP,E045PLA.CLACTA)) 'KEY CONTA CONTÁBIL', -- Chave única conta contábil
    UPPER(E045PLA.DESCTA) 'CONTA CONTÁBIL',                           -- Descrição da conta contábil
    
    -- CENTRO DE CUSTO
        UPPER(CONCAT_WS('-',E044CCU.CODCCU,E044CCU.DESCCU)) 'CHAVE CR', --CHAVE CR
   IIF(E405SOL.CCURES IS NULL,NULL, CONCAT_WS('-','MIB',E405SOL.CODEMP,E405SOL.CCURES)) 'KEY CR',      -- Chave única do centro de custo
    UPPER(E044CCU.DESCCU) 'CENTRO DE RESULTADO',                      -- Descrição do centro de custo
    E044CCU.CLACCU 'CLASSIFICAÇÃO CR',                                -- Classificação completa
    LEFT(E044CCU.CLACCU,2) 'GRUPO CLASSIFICAÇÃO',                     -- Primeiros 2 dígitos da classificação
    IIF(E405SOL.CODEMP= 5, -- FERGUMINAS - Operações Industriais
        CASE LEFT(E044CCU.CLACCU, 2)
            WHEN '11' THEN 'ADM'
            WHEN '12' THEN 'PRODUCAO'
            WHEN '13' THEN 'TERMOELETRICA'
            WHEN '14' THEN 'PELOTIZACAO'
            WHEN '15' THEN 'OXIGENIO'
            WHEN '16' THEN 'TRANSPORTE INTERNO'
            ELSE 'OUTROS' 
        END,
        IIF(E405SOL.CODEMP = 2, -- MIG - Operações de Mineração
            CASE LEFT(E044CCU.CLACCU, 2)
                WHEN '21' THEN 'ADM'
                WHEN '22' THEN 'LAVRA'
                WHEN '23' THEN 'PRODUCAO'
                WHEN '24' THEN 'OFICINA'
                WHEN '25' THEN 'M.AMBIENTE'
                ELSE 'OUTROS' 
            END,
            IIF(E405SOL.CODEMP = 1, -- MIB - Operações Corporativas
                CASE LEFT(E044CCU.CLACCU, 2)
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

    -- AGRUPAMENTOS DO PRODUTO
    E075PRO.CODAGE 'COD AGRUPAMENTO ESTOQUE',                      -- Agrupamento para estoque
    E075PRO.CODAGP 'COD AGRUPAMENTO PRODUÇÃO',                     -- Agrupamento para produção
    E075PRO.CODAGU 'COD AGRUPAMENTO CUSTOS',                       -- Agrupamento para custos


    -- USUÁRIOS RESPONSÁVEIS
    E405SOL.CODUSU 'COD USUÁRIO GERAÇÃO',                          -- Código do usuário que gerou
    REPLACE(UPPER(USU_GERACAO.NOMUSU),'.',' ') 'USUÁRIO GERAÇÃO',                 -- Nome do usuário que gerou
    E405SOL.USUSOL 'COD USUÁRIO SOLICITAÇÃO',                      -- Código do usuário solicitante
      REPLACE(UPPER(USU_SOLICITACAO.NOMUSU),'.',' ') 'USUÁRIO SOLICITAÇÃO',         -- Nome do usuário solicitante
    E405SOL.USURES 'COD USUÁRIO APLICAÇÃO',                        -- Código do usuário que aplicou
      REPLACE(UPPER(USU_APLICACAO.NOMUSU),'.',' ') 'USUÁRIO APLICAÇÃO',             -- Nome do usuário que aplicou
    E405SOL.USUCAN 'COD USUÁRIO CANCELAMENTO',                     -- Código do usuário que cancelou
      REPLACE(UPPER(USU_CANCELAMENTO.NOMUSU),'.',' ') 'USUÁRIO CANCELAMENTO',       -- Nome do usuário que cancelou
    E405SOL.USUCPR 'COD USUÁRIO COMPRA',                           -- Código do usuário que efetuou compra
      REPLACE(UPPER(USU_COMPRA.NOMUSU),'.',' ') 'USUÁRIO COMPRA',                   -- Nome do usuário que efetuou compra

    -- OBSERVAÇÕES
    UPPER(SUBSTRING(E405SOL.OBSSOL, 1, 80)) 'OBSERVAÇÃO SOLICITAÇÃO',  -- Observação limitada a 80 caracteres
    E405SOL.CODPRI 'COD PRIORIDADE'                          -- Código prioridade
-- =====================================================================
-- RELACIONAMENTOS E JOINS
-- =====================================================================

FROM SAPIENS.SAPIENS.E405SOL WITH (NOLOCK)                           -- Tabela principal: Solicitações de Compras

    -- PRODUTOS (apenas campos utilizados)
    LEFT JOIN SAPIENS.SAPIENS.E075PRO WITH (NOLOCK)                  -- Dados dos produtos
        ON E405SOL.CODEMP = E075PRO.CODEMP
        AND E405SOL.CODPRO = E075PRO.CODPRO

--SERVIÇOS
LEFT JOIN SAPIENS.SAPIENS.E080SER WITH (NOLOCK)                   --Dados Serviços
        ON E405SOL.CODEMP = E080SER.CODEMP
        AND E405SOL.CODSER = E080SER.CODSER

    -- UNIDADE DE MEDIDA
    LEFT OUTER JOIN SAPIENS.SAPIENS.E015MED WITH (NOLOCK)
        ON E405SOL.UNIMED = E015MED.UNIMED

 
    -- CENTROS DE CUSTO
    LEFT JOIN SAPIENS.SAPIENS.E044CCU WITH (NOLOCK)                  -- Centro de custo principal
        ON E405SOL.CODEMP = E044CCU.CODEMP
        AND E405SOL.CCURES = E044CCU.CODCCU

    -- CONTAS CONTÁBEIS
    LEFT JOIN SAPIENS.SAPIENS.E045PLA WITH (NOLOCK)                  -- Plano de contas contábil
        ON E405SOL.CODEMP = E045PLA.CODEMP
        AND E405SOL.CTARED = E045PLA.CTARED

    -- CONTAS FINANCEIRAS
    LEFT JOIN SAPIENS.SAPIENS.E091PLF WITH (NOLOCK)                  -- Plano de contas financeiro
        ON E405SOL.CODEMP = E091PLF.CODEMP
        AND E405SOL.CTAFIN = E091PLF.CTAFIN

    -- DEPÓSITOS
    LEFT JOIN SAPIENS.SAPIENS.E205DEP WITH (NOLOCK)                  -- Depósitos/locais de entrega
        ON E405SOL.CODEMP = E205DEP.CODEMP
        AND E405SOL.CODDEP = E205DEP.CODDEP


    -- USUÁRIOS (MÚLTIPLOS RELACIONAMENTOS COM ALIAS DESCRITIVOS)
    LEFT JOIN SAPIENS.SAPIENS.R999USU USU_GERACAO WITH (NOLOCK)      -- Usuário que gerou a solicitação
        ON E405SOL.CODUSU = USU_GERACAO.CODUSU

    LEFT JOIN SAPIENS.SAPIENS.R999USU USU_SOLICITACAO WITH (NOLOCK)  -- Usuário solicitante
        ON E405SOL.USUSOL = USU_SOLICITACAO.CODUSU

    LEFT JOIN SAPIENS.SAPIENS.R999USU USU_APLICACAO WITH (NOLOCK)    -- Usuário que aplicou
        ON E405SOL.USURES = USU_APLICACAO.CODUSU

    LEFT JOIN SAPIENS.SAPIENS.R999USU USU_CANCELAMENTO WITH (NOLOCK) -- Usuário que cancelou
        ON E405SOL.USUCAN = USU_CANCELAMENTO.CODUSU

    LEFT JOIN SAPIENS.SAPIENS.R999USU USU_COMPRA WITH (NOLOCK)       -- Usuário que efetuou compra
        ON E405SOL.USUCPR = USU_COMPRA.CODUSU



UNION ALL



SELECT 
    'MML' 'SERVIDOR',                                                  -- Identificador do servidor
    GETDATE() 'ATUALIZAÇÃO',                                          -- Data/hora de execução da consulta
    
    -- DADOS DA EMPRESA E SOLICITAÇÃO
    E405SOL.CODEMP 'COD EMPRESA',                                   -- Código da empresa
    CONCAT_WS('-','MML',E405SOL.CODEMP) 'KEY EMPRESA',               -- Chave única da empresa
    E405SOL.NUMSOL 'COD SOLICITAÇÃO',                              -- Número da solicitação
    CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.NUMSOL) 'KEY SOLICITAÇÃO', -- Chave única da solicitação
    E405SOL.NUMCOT 'COD COTAÇÃO',                                  -- Número da cotação vinculada
    CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.NUMCOT) 'KEY COTAÇÃO', -- Chave única da cotação
    E405SOL.NUMEME 'COD REQUISIÇÃO',                               -- Número da requisição
    CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.NUMEME) 'KEY REQUISIÇÃO', -- Chave única da requisição
    E405SOL.SEQEME 'SEQUÊNCIA REQUISIÇÃO',                            -- Sequência da requisição
    E405SOL.SEQSOL 'SEQUÊNCIA SOLICITAÇÃO',                           -- Sequência da solicitação
    
    -- DATAS DE CONTROLE
    E405SOL.DATSOL 'DATA SOLICITAÇÃO',                                -- Data da solicitação
    E405SOL.DATPRV 'DATA PREVISÃO ENTREGA',                           -- Data prevista para entrega
    E405SOL.DATCAN 'DATA CANCELAMENTO',                               -- Data de cancelamento
    E405SOL.DATEFC 'DATA ENVIO SOLICITAÇÃO',                          -- Data de envio da solicitação
    
    -- CÓDIGOS DE CONTROLE
    E405SOL.CODTNS 'COD TRANSAÇÃO',                                -- Código da transação


    -- DADOS DO PRODUTO/SERVIÇO
    IIF(E405SOL.PROSER='S', 'SERVIÇO', 'PRODUTO') 'TIPO ITEM',        -- Tipo serviço ou produto
    IIF(E405SOL.PROSER='S', E405SOL.CODSER, E405SOL.CODPRO) 'COD ITEM', -- Código do item
        UPPER(COALESCE(E075PRO.DESPRO,E080SER.DESSER))  'ITEM', -- Chave única do item
    CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.PROSER,IIF(E405SOL.PROSER='S', E405SOL.CODSER, E405SOL.CODPRO)) 'KEY ITEM', -- Chave única do item
    CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.NUMCOT,E405SOL.PROSER,IIF(E405SOL.PROSER='S', E405SOL.CODSER, E405SOL.CODPRO)) 'KEY ITEM COTAÇÃO', -- Chave única do item
        CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.NUMSOL,E405SOL.SEQSOL) 'KEY ITEM SEQUÊNCIA',
    -- QUANTIDADES
    E405SOL.QTDSOL '#QUANTIDADE SOLICITADA',                          -- Quantidade solicitada
    E405SOL.QTDAPR '#QUANTIDADE APROVADA',                            -- Quantidade aprovada
    E405SOL.QTDCAN '#QUANTIDADE CANCELADA',                           -- Quantidade cancelada

    -- VALORES FINANCEIROS
    E405SOL.PRESOL '#VALOR MÉDIO',                                    -- Preço médio unitário
    E405SOL.QTDSOL * E405SOL.PRESOL '#VALOR TOTAL',                   -- Valor total da solicitação
    
    -- DEPÓSITO
    UPPER(E205DEP.DESDEP) 'DESCRIÇÃO DEPÓSITO',                       -- Descrição do depósito
    E405SOL.UNIMED 'COD UNIDADE',                              -- Código unidade medida
    UPPER(E015MED.DESMED) 'UNIDADE MEDIDA',                       -- Descrição unidade medida
    
    -- SITUAÇÃO DA SOLICITAÇÃO
    CASE E405SOL.SITSOL                                               -- Descrição da situação
        WHEN '0' THEN 'DIGITADA'
        WHEN '1' THEN 'COTAÇÃO'
        WHEN '2' THEN 'ORDEM DE COMPRA'
        WHEN '3' THEN 'FINALIZADA'
        WHEN '9' THEN 'CANCELADA'
    END 'SITUAÇÃO SOLICITAÇÃO',

    -- CONTAS FINANCEIRAS E CONTÁBEIS
   IIF(E405SOL.CTAFIN IS NULL,NULL, CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.CTAFIN)) 'KEY CONTA FINANCEIRA', -- Chave única conta financeira
    UPPER(E091PLF.DESCTA) 'CONTA FINANCEIRA',                         -- Descrição da conta financeira
   IIF(E045PLA.CLACTA IS NULL,NULL, CONCAT_WS('-','MML',E405SOL.CODEMP,E045PLA.CLACTA)) 'KEY CONTA CONTÁBIL', -- Chave única conta contábil
    UPPER(E045PLA.DESCTA) 'CONTA CONTÁBIL',                           -- Descrição da conta contábil
    
    -- CENTRO DE CUSTO
    UPPER(CONCAT_WS('-',E044CCU.CODCCU,E044CCU.DESCCU)) 'CHAVE CR', --CHAVE CR
   IIF(E405SOL.CCURES IS NULL,NULL, CONCAT_WS('-','MML',E405SOL.CODEMP,E405SOL.CCURES)) 'KEY CR',      -- Chave única do centro de custo
    UPPER(E044CCU.DESCCU) 'CENTRO DE RESULTADO',                      -- Descrição do centro de custo
    E044CCU.CLACCU 'CLASSIFICAÇÃO CR',                                -- Classificação completa
    LEFT(E044CCU.CLACCU,2) 'GRUPO CLASSIFICAÇÃO',                     -- Primeiros 2 dígitos da classificação
    IIF(E405SOL.CODEMP = 1, -- MML
        CASE LEFT(E044CCU.CLACCU, 2)
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

    -- AGRUPAMENTOS DO PRODUTO
    E075PRO.CODAGE 'COD AGRUPAMENTO ESTOQUE',                      -- Agrupamento para estoque
    E075PRO.CODAGP 'COD AGRUPAMENTO PRODUÇÃO',                     -- Agrupamento para produção
    E075PRO.CODAGU 'COD AGRUPAMENTO CUSTOS',                       -- Agrupamento para custos


    -- USUÁRIOS RESPONSÁVEIS
    E405SOL.CODUSU 'COD USUÁRIO GERAÇÃO',                          -- Código do usuário que gerou
    REPLACE(UPPER(USU_GERACAO.NOMUSU),'.',' ') 'USUÁRIO GERAÇÃO',                 -- Nome do usuário que gerou
    E405SOL.USUSOL 'COD USUÁRIO SOLICITAÇÃO',                      -- Código do usuário solicitante
      REPLACE(UPPER(USU_SOLICITACAO.NOMUSU),'.',' ') 'USUÁRIO SOLICITAÇÃO',         -- Nome do usuário solicitante
    E405SOL.USURES 'COD USUÁRIO APLICAÇÃO',                        -- Código do usuário que aplicou
      REPLACE(UPPER(USU_APLICACAO.NOMUSU),'.',' ') 'USUÁRIO APLICAÇÃO',             -- Nome do usuário que aplicou
    E405SOL.USUCAN 'COD USUÁRIO CANCELAMENTO',                     -- Código do usuário que cancelou
      REPLACE(UPPER(USU_CANCELAMENTO.NOMUSU),'.',' ') 'USUÁRIO CANCELAMENTO',       -- Nome do usuário que cancelou
    E405SOL.USUCPR 'COD USUÁRIO COMPRA',                           -- Código do usuário que efetuou compra
      REPLACE(UPPER(USU_COMPRA.NOMUSU),'.',' ') 'USUÁRIO COMPRA',                   -- Nome do usuário que efetuou compra

    -- OBSERVAÇÕES
    UPPER(SUBSTRING(E405SOL.OBSSOL, 1, 80)) 'OBSERVAÇÃO SOLICITAÇÃO',  -- Observação limitada a 80 caracteres
    E405SOL.CODPRI 'COD PRIORIDADE'                          -- Código prioridade
-- =====================================================================
-- RELACIONAMENTOS E JOINS
-- =====================================================================

FROM [SQLMML].[Sapiens_Prod].[dbo].[E405SOL] WITH (NOLOCK)                           -- Tabela principal: Solicitações de Compras

    -- PRODUTOS (apenas campos utilizados)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E075PRO] WITH (NOLOCK)                  -- Dados dos produtos
        ON E405SOL.CODEMP = E075PRO.CODEMP
        AND E405SOL.CODPRO = E075PRO.CODPRO


--SERVIÇOS
LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E080SER] WITH (NOLOCK)                   --Dados Serviços
        ON E405SOL.CODEMP = E080SER.CODEMP
        AND E405SOL.CODSER = E080SER.CODSER

    -- UNIDADE DE MEDIDA
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E015MED] WITH (NOLOCK)
        ON E405SOL.UNIMED = E015MED.UNIMED

    -- CENTROS DE CUSTO
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E044CCU] WITH (NOLOCK)                  -- Centro de custo principal
        ON E405SOL.CODEMP = E044CCU.CODEMP
        AND E405SOL.CCURES = E044CCU.CODCCU

    -- CONTAS CONTÁBEIS
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E045PLA] WITH (NOLOCK)                  -- Plano de contas contábil
        ON E405SOL.CODEMP = E045PLA.CODEMP
        AND E405SOL.CTARED = E045PLA.CTARED

    -- CONTAS FINANCEIRAS
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E091PLF] WITH (NOLOCK)                  -- Plano de contas financeiro
        ON E405SOL.CODEMP = E091PLF.CODEMP
        AND E405SOL.CTAFIN = E091PLF.CTAFIN

    -- DEPÓSITOS
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E205DEP] WITH (NOLOCK)                  -- Depósitos/locais de entrega
        ON E405SOL.CODEMP = E205DEP.CODEMP
        AND E405SOL.CODDEP = E205DEP.CODDEP

    -- USUÁRIOS (MÚLTIPLOS RELACIONAMENTOS COM ALIAS DESCRITIVOS)
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] USU_GERACAO WITH (NOLOCK)      -- Usuário que gerou a solicitação
        ON E405SOL.CODUSU = USU_GERACAO.CODUSU

    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] USU_SOLICITACAO WITH (NOLOCK)  -- Usuário solicitante
        ON E405SOL.USUSOL = USU_SOLICITACAO.CODUSU

    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] USU_APLICACAO WITH (NOLOCK)    -- Usuário que aplicou
        ON E405SOL.USURES = USU_APLICACAO.CODUSU

    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] USU_CANCELAMENTO WITH (NOLOCK) -- Usuário que cancelou
        ON E405SOL.USUCAN = USU_CANCELAMENTO.CODUSU

    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] USU_COMPRA WITH (NOLOCK)       -- Usuário que efetuou compra
        ON E405SOL.USUCPR = USU_COMPRA.CODUSU
GO
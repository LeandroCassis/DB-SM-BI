SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_COTAÇÕES] 
AS -- CONSULTA: RELATÓRIO DE COTAÇÃO DE COMPRAS
-- TABELAS PRINCIPAIS: E410COT (Cotações), E405SOL (Solicitações), E410PCT (Processo Cotação)
-- OBJETIVO: Listar cotações de compras com dados de fornecedores, produtos/serviços e solicitações

SELECT
    'MIB' 'SERVIDOR',                                             -- Identificador do servidor
    GETDATE() 'ATUALIZAÇÃO',                                      -- Data/hora da consulta
    
    -- DADOS DA EMPRESA
    E410COT.CODEMP 'COD EMPRESA',                              -- Código da empresa
    CONCAT_WS('-','MIB',E410COT.CODEMP) 'KEY EMPRESA',            -- Chave única empresa
    
    -- DADOS DA COTAÇÃO
    E410COT.NUMCOT 'COD COTAÇÃO',                             -- Número da cotação
    CONCAT_WS('-','MIB',E410COT.CODEMP,E410COT.NUMCOT) 'KEY COTAÇÃO', -- Chave única cotação
    E410COT.SEQCOT 'SEQUÊNCIA COTAÇÃO',                           --Sequência cotação
    CAST(E410COT.DATCOT AS DATE) 'DATA COTAÇÃO',                  -- Data da cotação
    CAST(E410COT.DATPRV AS DATE) 'DATA PREVISÃO ENTREGA',         -- Data previsão entrega
    E410COT.PRZENT '#PRAZO ENTREGA DIAS',                         -- Prazo entrega em dias

    -- DADOS DO FORNECEDOR
    E410COT.CODFOR 'COD FORNECEDOR',                           -- Código do fornecedor
    UPPER(E095FOR.NOMFOR) 'FORNECEDOR',                      -- Nome do fornecedor
    UPPER(E410COT.MARFOR) 'MARCA FORNECEDOR',                     -- Marca do fornecedor
    
    -- DADOS QUANTITATIVOS E VALORES
    E410COT.QTDCOT '#QUANTIDADE COTADA',                                 -- Quantidade cotada
    E410COT.PRECOT '#PREÇO COTAÇÃO',                              -- Preço unitário cotado
    E410COT.QTDAPR '#QUANTIDADE APROVADA',                               -- Quantidade aprovada
    E410COT.VLRCOT '#VALOR COTAÇÃO',                              -- Valor total da cotação
    E410COT.VLRDSC '#VALOR DESCONTO',                             -- Valor do desconto
    E410COT.VLRDFA '#VALOR DIF ALÍQUOTA',                         -- Valor diferença de alíquota
    E410COT.VLRISN '#VALOR ICMS SIMPLES',                         -- Valor ICMS simples
    E410COT.VLRICS '#VALOR ICMS SUBSTITUÍDO',                     -- Valor ICMS substituído
    E410COT.FRECOT '#VALOR FRETE',                                -- Valor do frete
    E410COT.DARCOT '#VALOR ARREDONDAMENTO',                       -- Valor arredondamento
    
    -- CONDIÇÃO DE PAGAMENTO
    E410COT.CODCPG 'COD CONDIÇÃO PAGAMENTO',                   -- Código condição pagamento
    UPPER(E028CPG.DESCPG) 'CONDIÇÃO PAGAMENTO',                   -- Descrição condição pagamento
    E410COT.CIFFOB 'TIPO FRETE',                              -- Código tipo frete (C=CIF, F=FOB)
    -- SITUAÇÃO DA COTAÇÃO
    CASE E410COT.SITCOT
        WHEN '1' THEN 'EM PROCESSO DE COTAÇÃO'
        WHEN '2' THEN 'A APROVAR'
        WHEN '3' THEN 'APROVADA'
        WHEN '4' THEN 'FINALIZADA'
        WHEN '5' THEN 'CANCELADA'
        WHEN '6' THEN 'AGUARDANDO APROVAÇÃO SOLICITANTE'
        ELSE 'SITUAÇÃO INDEFINIDA'
    END 'SITUAÇÃO COTAÇÃO',
    
    -- DADOS DO PRODUTO/SERVIÇO
    IIF(E410COT.PROSER = 'S', 'SERVIÇO', 'PRODUTO') 'TIPO ITEM', -- Tipo do item
    IIF(E410COT.PROSER = 'S', E410COT.CODSER, E410COT.CODPRO) 'COD ITEM', -- Código do item
            UPPER(COALESCE(E075PRO.DESPRO,E080SER.DESSER))  'ITEM', -- Chave única do item
    CONCAT_WS('-','MIB',E410COT.CODEMP,E410COT.PROSER,IIF(E410COT.PROSER = 'S', E410COT.CODSER, E410COT.CODPRO)) 'KEY ITEM', -- Chave única do item
    CONCAT_WS('-','MIB',E410COT.CODEMP,E410COT.NUMCOT,E410COT.PROSER,IIF(E410COT.PROSER = 'S', E410COT.CODSER, E410COT.CODPRO)) 'KEY ITEM COTAÇÃO', 
    CONCAT_WS('-','MIB',E410COT.CODEMP,E405SOL.NUMSOL,E405SOL.SEQSOL) 'KEY ITEM SEQUÊNCIA',
    E410COT.UNIMED 'COD UNIDADE',                              -- Código unidade medida
    UPPER(E015MED.DESMED) 'UNIDADE MEDIDA',                       -- Descrição unidade medida
    E410COT.CODDER 'COD DERIVAÇÃO',                            -- Código derivação
    UPPER(E075DER.DESDER) 'DERIVAÇÃO',                            -- Descrição derivação
    UPPER(E410COT.CPLITE) 'COMPLEMENTO ITEM',                     -- Complemento produto/serviço
    
    -- AGRUPAMENTOS DO PRODUTO
    E075PRO.CODAGE 'COD AGRUP ESTOQUE',                        -- Código agrupamento estoque
    E075PRO.CODAGP 'COD AGRUP PRODUÇÃO',                       -- Código agrupamento produção
    E075PRO.CODAGU 'COD AGRUP CUSTOS',                         -- Código agrupamento custos
    
    -- USUÁRIOS E APROVAÇÃO
    E410COT.USUCOT 'COD USUÁRIO GERAÇÃO',                      -- Usuário que gerou cotação
    REPLACE(UPPER(G.NOMUSU),'.',' ') 'USUÁRIO GERAÇÃO',           -- Nome usuário geração
    E410COT.USUAPR 'COD USUÁRIO APROVAÇÃO',                    -- Usuário que aprovou
    REPLACE(UPPER(A.NOMUSU),'.',' ') 'USUÁRIO APROVAÇÃO',         -- Nome usuário aprovação
    IIF(CAST(E410COT.DATAPR AS DATE)='1900-12-31',NULL,CAST(E410COT.DATAPR AS DATE)) 'DATA APROVAÇÃO',                -- Data da aprovação
    
    -- ORDEM DE COMPRA
    E410COT.USUOCP 'COD USUÁRIO ORDEM COMPRA',                 -- Usuário geração ordem compra
    REPLACE(UPPER(O.NOMUSU),'.',' ') 'USUÁRIO ORDEM COMPRA',      -- Nome usuário ordem compra
    IIF(CAST(E410COT.DATOCP AS DATE)='1900-12-31',NULL,CAST(E410COT.DATOCP AS DATE)) 'DATA ORDEM COMPRA',             -- Data geração ordem compra
    E410COT.NUMOCP 'COD ORDEM COMPRA',                        -- Número ordem de compra
     CONCAT_WS('-','MIB',E410COT.CODEMP,E410COT.NUMOCP) 'KEY OC',
    IIF(E410COT.PROSER = 'S', E420ISO.SEQISO,E420IPO.SEQIPO) 'SEQ ITEM ORDEM COMPRA',                      -- Sequência item ordem compra
    -- DADOS DA SOLICITAÇÃO
    E405SOL.NUMSOL 'COD SOLICITAÇÃO',                         -- Número da solicitação
    E405SOL.SEQSOL 'SEQUÊNCIA SOLICITAÇÃO',                   -- Número da Sequência

    
    -- CRITÉRIO DE COTAÇÃO
    E410COT.CRICOT 'COD CRITÉRIO',                             -- Código critério cotação
    CASE E410COT.CRICOT 
        WHEN 'V' THEN 'MENOR VALOR PRESENTE'
        WHEN 'B' THEN 'MENOR VALOR COTADO'
        WHEN 'P' THEN 'MENOR PRAZO DE ENTREGA'
        WHEN 'A' THEN 'PERSONALIZADO'
        WHEN 'M' THEN 'MÚLTIPLOS'
        ELSE 'CRITÉRIO INDEFINIDO'
    END 'CRITÉRIO COTAÇÃO',
    
    -- PROCESSO DE COTAÇÃO
    E410PCT.NUMPCT 'COD PROCESSO',                            -- Número processo cotação
    CAST(E410PCT.DATENV AS DATE) 'DATA ENVIO PROCESSO',           -- Data envio processo
    E410PCT.USUGER 'COD USUÁRIO PROCESSO',                     -- Usuário geração processo
    CAST(E410PCT.DATGER AS DATE) 'DATA GERAÇÃO PROCESSO',         -- Data geração processo
    
    -- PRIORIDADE
    E405SOL.CODPRI 'COD PRIORIDADE',                           -- Código prioridade
    UPPER(E405PRI.DESPRI) 'PRIORIDADE',                           -- Descrição prioridade
    
    -- OBSERVAÇÕES
    UPPER(SUBSTRING(E410COT.OBSCOT, 1, 80)) 'OBSERVAÇÕES',         -- Observações da cotação



    
    -- NOTA FISCAL DE ENTRADA
    E440NFC.NUMNFC 'NUM NF',                 -- Número da nota fiscal de entrada
    CAST(E440NFC.DATEMI AS DATE) 'DATA EMISSÃO NF',      -- Data emissão NF entrada
    CAST(E440NFC.DATENT AS DATE) 'DATA ENTRADA NF'              -- Data entrada da NF
   , CASE 
        WHEN E410COT.SITCOT = '1' THEN 'EM PROCESSO DE COTAÇÃO'
        WHEN E410COT.SITCOT = '2' THEN 'AGUARDANDO APROVAÇÃO'
        WHEN E410COT.SITCOT = '3' THEN 'COTAÇÃO APROVADA'
        WHEN E410COT.SITCOT = '4' AND E410COT.NUMOCP > 0 THEN 'GEROU ORDEM DE COMPRA'
        WHEN E410COT.SITCOT = '4' AND E410COT.NUMOCP = 0 THEN 'FINALIZADA SEM OC'
        WHEN E410COT.SITCOT = '5' THEN 'COTAÇÃO CANCELADA'
        WHEN E410COT.SITCOT = '6' THEN 'AGUARDANDO APROVAÇÃO SOLICITANTE'
        ELSE 'SITUAÇÃO INDEFINIDA'
    END 'OPÇÃO'  

FROM SAPIENS.SAPIENS.E410COT WITH (NOLOCK)                        -- Tabela principal: Cotações

    -- FORNECEDOR
    LEFT OUTER JOIN SAPIENS.SAPIENS.E095FOR WITH (NOLOCK)
        ON E410COT.CODFOR = E095FOR.CODFOR 
    
    -- PRODUTO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E075PRO WITH (NOLOCK)
        ON E410COT.CODEMP = E075PRO.CODEMP
        AND E410COT.CODPRO = E075PRO.CODPRO


    --SERVIÇO
    LEFT JOIN SAPIENS.SAPIENS.E080SER WITH (NOLOCK)                     
        ON E410COT.CODEMP = E080SER.CODEMP
        AND E410COT.CODSER = E080SER.CODSER
    
    -- DERIVAÇÃO DO PRODUTO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E075DER WITH (NOLOCK)
        ON E410COT.CODEMP = E075DER.CODEMP 
        AND E410COT.CODPRO = E075DER.CODPRO
        AND E410COT.CODDER = E075DER.CODDER
    
    -- UNIDADE DE MEDIDA
    LEFT OUTER JOIN SAPIENS.SAPIENS.E015MED WITH (NOLOCK)
        ON E410COT.UNIMED = E015MED.UNIMED
    
    -- SOLICITAÇÃO DE COMPRAS
    LEFT OUTER JOIN SAPIENS.SAPIENS.E405SOL WITH (NOLOCK) 
        ON E410COT.CODEMP = E405SOL.CODEMP
        AND E410COT.NUMCOT = E405SOL.NUMCOT
    
    -- PRIORIDADE DA SOLICITAÇÃO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E405PRI WITH (NOLOCK)
        ON E405SOL.CODEMP = E405PRI.CODEMP
        AND E405SOL.CODPRI = E405PRI.CODPRI
    
    -- FORNECEDOR PROCESSO COTAÇÃO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E410FPC WITH (NOLOCK)
        ON E405SOL.CODEMP = E410FPC.CODEMP 
        AND E405SOL.NUMPCT = E410FPC.NUMPCT 
        AND e410cot.CODFOR = E410FPC.CODFOR
    -- PROCESSO DE COTAÇÃO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E410PCT WITH (NOLOCK)
        ON E410FPC.CODEMP = E410PCT.CODEMP
        AND E410FPC.NUMPCT = E410PCT.NUMPCT

    
    -- CONDIÇÃO DE PAGAMENTO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E028CPG WITH (NOLOCK)
        ON E410COT.CODEMP = E028CPG.CODEMP
        AND E410COT.CODCPG = E028CPG.CODCPG
    
    -- USUÁRIOS
    LEFT OUTER JOIN SAPIENS.SAPIENS.R999USU G WITH (NOLOCK)      -- Usuário geração cotação
        ON E410COT.USUCOT = G.CODUSU
    
    LEFT OUTER JOIN SAPIENS.SAPIENS.R999USU A WITH (NOLOCK)      -- Usuário aprovação cotação
        ON E410COT.USUAPR = A.CODUSU
    
    LEFT OUTER JOIN SAPIENS.SAPIENS.R999USU O WITH (NOLOCK)      -- Usuário ordem compra
        ON E410COT.USUOCP = O.CODUSU
 
     -- ORDEM DE COMPRA (para informações de frete)
    LEFT OUTER JOIN SAPIENS.SAPIENS.E420OCP WITH (NOLOCK)
        ON E410COT.CODEMP = E420OCP.CODEMP
        AND E410COT.NUMOCP = E420OCP.NUMOCP
           
    -- ITENS DA ORDEM DE COMPRA PRODUTO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E420IPO WITH (NOLOCK)
        ON E420OCP.CODEMP = E420IPO.CODEMP
        AND E420OCP.CODFIL = E420IPO.CODFIL
        AND E420OCP.NUMOCP = E420IPO.NUMOCP
       AND  E410COT.CODPRO = E420IPO.CODPRO

   -- ITENS DA NOTA FISCAL DE COMPRA PRODUTO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E440IPC WITH (NOLOCK)
        ON E420IPO.CODEMP = E440IPC.CODEMP
        AND E420IPO.CODFIL = E440IPC.CODFIL
        AND E420IPO.NUMOCP = E440IPC.NUMOCP
        AND E420IPO.SEQIPO = E440IPC.SEQIPO

  -- ITENS DA ORDEM DE COMPRA SERVIÇO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E420ISO WITH (NOLOCK)
        ON E420OCP.CODEMP = E420ISO.CODEMP
        AND E420OCP.CODFIL = E420ISO.CODFIL
        AND E420OCP.NUMOCP = E420ISO.NUMOCP
       AND  E410COT.CODSER = E420ISO.CODSER
   

   -- ITENS DA NOTA FISCAL DE COMPRA SERVIÇOS
    LEFT OUTER JOIN SAPIENS.SAPIENS.E440ISC WITH (NOLOCK)
        ON E420ISO.CODEMP = E440ISC.CODEMP
        AND E420ISO.CODFIL = E440ISC.CODFIL
        AND E420ISO.NUMOCP = E440ISC.NUMOCP
        AND E420ISO.SEQISO = E440ISC.seqisc
       --AND E420IPO.CODPNF = E440ISC.CODPNF

    LEFT OUTER JOIN SAPIENS.SAPIENS.E440NFC WITH (NOLOCK)

       ON IIF(E410COT.PROSER = 'S',E440ISC.CODEMP,E440IPC.CODEMP) = E440NFC.CODEMP
        AND IIF(E410COT.PROSER = 'S',E440ISC.CODFIL,E440IPC.CODFIL) = E440NFC.CODFIL
        AND IIF(E410COT.PROSER = 'S',E440ISC.NUMNFC,E440IPC.NUMNFC) = E440NFC.NUMNFC 
        AND IIF(E410COT.PROSER = 'S',E440ISC.CODFOR,E440IPC.CODFOR) = E440NFC.CODFOR 
        AND IIF(E410COT.PROSER = 'S',E440ISC.CODSNF,E440IPC.CODSNF) = E440NFC.CODSNF

UNION ALL

-- CONSULTA: RELATÓRIO DE COTAÇÃO DE COMPRAS
-- TABELAS PRINCIPAIS: E410COT (Cotações), E405SOL (Solicitações), E410PCT (Processo Cotação)
-- OBJETIVO: Listar cotações de compras com dados de fornecedores, produtos/serviços e solicitações

SELECT
    'MML' 'SERVIDOR',                                             -- Identificador do servidor
    GETDATE() 'ATUALIZAÇÃO',                                      -- Data/hora da consulta
    
    -- DADOS DA EMPRESA
    E410COT.CODEMP 'COD EMPRESA',                              -- Código da empresa
    CONCAT_WS('-','MML',E410COT.CODEMP) 'KEY EMPRESA',            -- Chave única empresa
    
    -- DADOS DA COTAÇÃO
    E410COT.NUMCOT 'COD COTAÇÃO',                             -- Número da cotação
    CONCAT_WS('-','MML',E410COT.CODEMP,E410COT.NUMCOT) 'KEY COTAÇÃO', -- Chave única cotação
    E410COT.SEQCOT 'SEQUÊNCIA COTAÇÃO',                           --Sequência cotação
    CAST(E410COT.DATCOT AS DATE) 'DATA COTAÇÃO',                  -- Data da cotação
    CAST(E410COT.DATPRV AS DATE) 'DATA PREVISÃO ENTREGA',         -- Data previsão entrega
    E410COT.PRZENT '#PRAZO ENTREGA DIAS',                         -- Prazo entrega em dias

    -- DADOS DO FORNECEDOR
    E410COT.CODFOR 'COD FORNECEDOR',                           -- Código do fornecedor
    UPPER(E095FOR.NOMFOR) 'FORNECEDOR',                      -- Nome do fornecedor
    UPPER(E410COT.MARFOR) 'MARCA FORNECEDOR',                     -- Marca do fornecedor
    
    -- DADOS QUANTITATIVOS E VALORES
    E410COT.QTDCOT '#QUANTIDADE COTADA',                                 -- Quantidade cotada
    E410COT.PRECOT '#PREÇO COTAÇÃO',                              -- Preço unitário cotado
    E410COT.QTDAPR '#QUANTIDADE APROVADA',                               -- Quantidade aprovada
    E410COT.VLRCOT '#VALOR COTAÇÃO',                              -- Valor total da cotação
    E410COT.VLRDSC '#VALOR DESCONTO',                             -- Valor do desconto
    E410COT.VLRDFA '#VALOR DIF ALÍQUOTA',                         -- Valor diferença de alíquota
    E410COT.VLRISN '#VALOR ICMS SIMPLES',                         -- Valor ICMS simples
    E410COT.VLRICS '#VALOR ICMS SUBSTITUÍDO',                     -- Valor ICMS substituído
    E410COT.FRECOT '#VALOR FRETE',                                -- Valor do frete
    E410COT.DARCOT '#VALOR ARREDONDAMENTO',                       -- Valor arredondamento
    
    -- CONDIÇÃO DE PAGAMENTO
    E410COT.CODCPG 'COD CONDIÇÃO PAGAMENTO',                   -- Código condição pagamento
    UPPER(E028CPG.DESCPG) 'CONDIÇÃO PAGAMENTO',                   -- Descrição condição pagamento
    E410COT.CIFFOB 'TIPO FRETE',                              -- Código tipo frete (C=CIF, F=FOB)
    -- SITUAÇÃO DA COTAÇÃO
    CASE E410COT.SITCOT
        WHEN '1' THEN 'EM PROCESSO DE COTAÇÃO'
        WHEN '2' THEN 'A APROVAR'
        WHEN '3' THEN 'APROVADA'
        WHEN '4' THEN 'FINALIZADA'
        WHEN '5' THEN 'CANCELADA'
        WHEN '6' THEN 'AGUARDANDO APROVAÇÃO SOLICITANTE'
        ELSE 'SITUAÇÃO INDEFINIDA'
    END 'SITUAÇÃO COTAÇÃO',
    
    -- DADOS DO PRODUTO/SERVIÇO
    IIF(E410COT.PROSER = 'S', 'SERVIÇO', 'PRODUTO') 'TIPO ITEM', -- Tipo do item
    IIF(E410COT.PROSER = 'S', E410COT.CODSER, E410COT.CODPRO) 'COD ITEM', -- Código do item
            UPPER(COALESCE(E075PRO.DESPRO,E080SER.DESSER))  'ITEM', -- Chave única do item
    CONCAT_WS('-','MML',E410COT.CODEMP,E410COT.PROSER,IIF(E410COT.PROSER = 'S', E410COT.CODSER, E410COT.CODPRO)) 'KEY ITEM', -- Chave única do item
    CONCAT_WS('-','MML',E410COT.CODEMP,E410COT.NUMCOT,E410COT.PROSER,IIF(E410COT.PROSER = 'S', E410COT.CODSER, E410COT.CODPRO)) 'KEY ITEM COTAÇÃO', 
    CONCAT_WS('-','MML',E410COT.CODEMP,E405SOL.NUMSOL,E405SOL.SEQSOL) 'KEY ITEM SEQUÊNCIA',
    E410COT.UNIMED 'COD UNIDADE',                              -- Código unidade medida
    UPPER(E015MED.DESMED) 'UNIDADE MEDIDA',                       -- Descrição unidade medida
    E410COT.CODDER 'COD DERIVAÇÃO',                            -- Código derivação
    UPPER(E075DER.DESDER) 'DERIVAÇÃO',                            -- Descrição derivação
    UPPER(E410COT.CPLITE) 'COMPLEMENTO ITEM',                     -- Complemento produto/serviço
    
    -- AGRUPAMENTOS DO PRODUTO
    E075PRO.CODAGE 'COD AGRUP ESTOQUE',                        -- Código agrupamento estoque
    E075PRO.CODAGP 'COD AGRUP PRODUÇÃO',                       -- Código agrupamento produção
    E075PRO.CODAGU 'COD AGRUP CUSTOS',                         -- Código agrupamento custos
    
    -- USUÁRIOS E APROVAÇÃO
    E410COT.USUCOT 'COD USUÁRIO GERAÇÃO',                      -- Usuário que gerou cotação
    REPLACE(UPPER(G.NOMUSU),'.',' ') 'USUÁRIO GERAÇÃO',           -- Nome usuário geração
    E410COT.USUAPR 'COD USUÁRIO APROVAÇÃO',                    -- Usuário que aprovou
    REPLACE(UPPER(A.NOMUSU),'.',' ') 'USUÁRIO APROVAÇÃO',         -- Nome usuário aprovação
    IIF(CAST(E410COT.DATAPR AS DATE)='1900-12-31',NULL,CAST(E410COT.DATAPR AS DATE)) 'DATA APROVAÇÃO',                -- Data da aprovação
    
    -- ORDEM DE COMPRA
    E410COT.USUOCP 'COD USUÁRIO ORDEM COMPRA',                 -- Usuário geração ordem compra
    REPLACE(UPPER(O.NOMUSU),'.',' ') 'USUÁRIO ORDEM COMPRA',      -- Nome usuário ordem compra
    IIF(CAST(E410COT.DATOCP AS DATE)='1900-12-31',NULL,CAST(E410COT.DATOCP AS DATE)) 'DATA ORDEM COMPRA',             -- Data geração ordem compra
    E410COT.NUMOCP 'COD ORDEM COMPRA',                        -- Número ordem de compra
     CONCAT_WS('-','MML',E410COT.CODEMP,E410COT.NUMOCP) 'KEY OC',
        -- ITENS DA ORDEM DE COMPRA
    IIF(E410COT.PROSER = 'S', E420ISO.SEQISO,E420IPO.SEQIPO) 'SEQ ITEM ORDEM COMPRA',                      -- Sequência item ordem compra
    -- DADOS DA SOLICITAÇÃO
    E405SOL.NUMSOL 'COD SOLICITAÇÃO',                         -- Número da solicitação
    E405SOL.SEQSOL 'SEQUÊNCIA SOLICITAÇÃO',                   -- Número da Sequência
    
    -- CRITÉRIO DE COTAÇÃO
    E410COT.CRICOT 'COD CRITÉRIO',                             -- Código critério cotação
    CASE E410COT.CRICOT 
        WHEN 'V' THEN 'MENOR VALOR PRESENTE'
        WHEN 'B' THEN 'MENOR VALOR COTADO'
        WHEN 'P' THEN 'MENOR PRAZO DE ENTREGA'
        WHEN 'A' THEN 'PERSONALIZADO'
        WHEN 'M' THEN 'MÚLTIPLOS'
        ELSE 'CRITÉRIO INDEFINIDO'
    END 'CRITÉRIO COTAÇÃO',
    
    -- PROCESSO DE COTAÇÃO
    E410PCT.NUMPCT 'COD PROCESSO',                            -- Número processo cotação
    CAST(E410PCT.DATENV AS DATE) 'DATA ENVIO PROCESSO',           -- Data envio processo
    E410PCT.USUGER 'COD USUÁRIO PROCESSO',                     -- Usuário geração processo
    CAST(E410PCT.DATGER AS DATE) 'DATA GERAÇÃO PROCESSO',         -- Data geração processo
    
    -- PRIORIDADE
    E405SOL.CODPRI 'COD PRIORIDADE',                           -- Código prioridade
    UPPER(E405PRI.DESPRI) 'PRIORIDADE',                           -- Descrição prioridade
    
    -- OBSERVAÇÕES
    UPPER(SUBSTRING(E410COT.OBSCOT, 1, 80)) 'OBSERVAÇÕES',         -- Observações da cotação



    
    -- NOTA FISCAL DE ENTRADA
    E440NFC.NUMNFC 'NUM NF',                 -- Número da nota fiscal de entrada
    CAST(E440NFC.DATEMI AS DATE) 'DATA EMISSÃO NF',      -- Data emissão NF entrada
    CAST(E440NFC.DATENT AS DATE) 'DATA ENTRADA NF'              -- Data entrada da NF
    -- CLASSIFICAÇÃO DA COTAÇÃO
   , CASE 
        WHEN E410COT.SITCOT = '1' THEN 'EM PROCESSO DE COTAÇÃO'
        WHEN E410COT.SITCOT = '2' THEN 'AGUARDANDO APROVAÇÃO'
        WHEN E410COT.SITCOT = '3' THEN 'COTAÇÃO APROVADA'
        WHEN E410COT.SITCOT = '4' AND E410COT.NUMOCP > 0 THEN 'GEROU ORDEM DE COMPRA'
        WHEN E410COT.SITCOT = '4' AND E410COT.NUMOCP = 0 THEN 'FINALIZADA SEM OC'
        WHEN E410COT.SITCOT = '5' THEN 'COTAÇÃO CANCELADA'
        WHEN E410COT.SITCOT = '6' THEN 'AGUARDANDO APROVAÇÃO SOLICITANTE'
        ELSE 'SITUAÇÃO INDEFINIDA'
    END 'OPÇÃO'      
FROM [SQLMML].[Sapiens_Prod].[dbo].[E410COT] WITH (NOLOCK)                        -- Tabela principal: Cotações


    -- FORNECEDOR
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E095FOR] WITH (NOLOCK)
        ON E410COT.CODFOR = E095FOR.CODFOR 
    
    -- PRODUTO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E075PRO] WITH (NOLOCK)
        ON E410COT.CODEMP = E075PRO.CODEMP
        AND E410COT.CODPRO = E075PRO.CODPRO


    --SERVIÇO
    LEFT JOIN [SQLMML].[Sapiens_Prod].[dbo].[E080SER] WITH (NOLOCK)                     
        ON E410COT.CODEMP = E080SER.CODEMP
        AND E410COT.CODSER = E080SER.CODSER
    
    -- DERIVAÇÃO DO PRODUTO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E075DER] WITH (NOLOCK)
        ON E410COT.CODEMP = E075DER.CODEMP 
        AND E410COT.CODPRO = E075DER.CODPRO
        AND E410COT.CODDER = E075DER.CODDER
    
    -- UNIDADE DE MEDIDA
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E015MED] WITH (NOLOCK)
        ON E410COT.UNIMED = E015MED.UNIMED
    
    -- SOLICITAÇÃO DE COMPRAS
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E405SOL] WITH (NOLOCK) 
        ON E410COT.CODEMP = E405SOL.CODEMP
        AND E410COT.NUMCOT = E405SOL.NUMCOT
    
    -- PRIORIDADE DA SOLICITAÇÃO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E405PRI] WITH (NOLOCK)
        ON E405SOL.CODEMP = E405PRI.CODEMP
        AND E405SOL.CODPRI = E405PRI.CODPRI
    
    -- FORNECEDOR PROCESSO COTAÇÃO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E410FPC] WITH (NOLOCK)
        ON E405SOL.CODEMP = E410FPC.CODEMP 
        AND E405SOL.NUMPCT = E410FPC.NUMPCT 
        AND e410cot.CODFOR = E410FPC.CODFOR
    -- PROCESSO DE COTAÇÃO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E410PCT] WITH (NOLOCK)
        ON E410FPC.CODEMP = E410PCT.CODEMP
        AND E410FPC.NUMPCT = E410PCT.NUMPCT

    
    -- CONDIÇÃO DE PAGAMENTO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E028CPG] WITH (NOLOCK)
        ON E410COT.CODEMP = E028CPG.CODEMP
        AND E410COT.CODCPG = E028CPG.CODCPG
    
    -- USUÁRIOS
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] G WITH (NOLOCK)      -- Usuário geração cotação
        ON E410COT.USUCOT = G.CODUSU
    
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] A WITH (NOLOCK)      -- Usuário aprovação cotação
        ON E410COT.USUAPR = A.CODUSU
    
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[R999USU] O WITH (NOLOCK)      -- Usuário ordem compra
        ON E410COT.USUOCP = O.CODUSU
 
     -- ORDEM DE COMPRA (para informações de frete)
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E420OCP] WITH (NOLOCK)
        ON E410COT.CODEMP = E420OCP.CODEMP
        AND E410COT.NUMOCP = E420OCP.NUMOCP
           
    -- ITENS DA ORDEM DE COMPRA PRODUTO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E420IPO] WITH (NOLOCK)
        ON E420OCP.CODEMP = E420IPO.CODEMP
        AND E420OCP.CODFIL = E420IPO.CODFIL
        AND E420OCP.NUMOCP = E420IPO.NUMOCP
       AND  E410COT.CODPRO = E420IPO.CODPRO

   -- ITENS DA NOTA FISCAL DE COMPRA PRODUTO
    LEFT OUTER JOIN SAPIENS.SAPIENS.E440IPC WITH (NOLOCK)
        ON E420IPO.CODEMP = E440IPC.CODEMP
        AND E420IPO.CODFIL = E440IPC.CODFIL
        AND E420IPO.NUMOCP = E440IPC.NUMOCP
        AND E420IPO.SEQIPO = E440IPC.SEQIPO

  -- ITENS DA ORDEM DE COMPRA SERVIÇO
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E420ISO] WITH (NOLOCK)
        ON E420OCP.CODEMP = E420ISO.CODEMP
        AND E420OCP.CODFIL = E420ISO.CODFIL
        AND E420OCP.NUMOCP = E420ISO.NUMOCP
       AND  E410COT.CODSER = E420ISO.CODSER
   

   -- ITENS DA NOTA FISCAL DE COMPRA SERVIÇOS
    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E440ISC] WITH (NOLOCK)
        ON E420ISO.CODEMP = E440ISC.CODEMP
        AND E420ISO.CODFIL = E440ISC.CODFIL
        AND E420ISO.NUMOCP = E440ISC.NUMOCP
        AND E420ISO.SEQISO = E440ISC.seqisc
       --AND E420IPO.CODPNF = E440ISC.CODPNF

    LEFT OUTER JOIN [SQLMML].[Sapiens_Prod].[dbo].[E440NFC] WITH (NOLOCK)
       ON IIF(E410COT.PROSER = 'S',E440ISC.CODEMP,E440IPC.CODEMP) = E440NFC.CODEMP
        AND IIF(E410COT.PROSER = 'S',E440ISC.CODFIL,E440IPC.CODFIL) = E440NFC.CODFIL
        AND IIF(E410COT.PROSER = 'S',E440ISC.NUMNFC,E440IPC.NUMNFC) = E440NFC.NUMNFC 
        AND IIF(E410COT.PROSER = 'S',E440ISC.CODFOR,E440IPC.CODFOR) = E440NFC.CODFOR 
        AND IIF(E410COT.PROSER = 'S',E440ISC.CODSNF,E440IPC.CODSNF) = E440NFC.CODSNF
GO
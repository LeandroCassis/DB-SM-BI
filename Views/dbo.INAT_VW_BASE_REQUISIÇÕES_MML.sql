SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE   VIEW [dbo].[INAT_VW_BASE_REQUISIÇÕES_MML] 
AS WITH BaseValores AS (
    SELECT 
        'MML' AS 'SERVIDOR',
        CONCAT('MML-', APLIC.CODAPL) AS 'COD EQUIPAMENTO ENGEMAN',
         CONCAT_WS('-', Aplic.CodApl,APLIC.TAG)'EQUIPAMENTO ENGEMAN',
        Aplic.CodApl AS COD_EQUIPAMENTO,
        CAST(ColAcu.DatHor AS DATE) AS DATA,
        Aplic.CodEmp 'COD EMPRESA',
        Aplic.DESCRICAO,
        Aplic.TAG,
        SUM(IIF(PonConAcu.CodTipPon = 3, ColAcu.Valor, 0)) AS KILOMETRAGEM_RAW,
        SUM(IIF(PonConAcu.CodTipPon = 1, ColAcu.Valor, 0)) AS HORIMETRO_RAW
    FROM [SQLMML].[ENGEMAN].[engeman].[Aplic] WITH (NOLOCK)
    LEFT JOIN [SQLMML].[ENGEMAN].[engeman].[CenCus] WITH (NOLOCK) ON Aplic.CodCen = CenCus.CodCen
    LEFT JOIN [SQLMML].[ENGEMAN].[engeman].[ColAcu] WITH (NOLOCK) ON Aplic.CodApl = ColAcu.CodApl
    JOIN [SQLMML].[ENGEMAN].[engeman].[PonConAcu] WITH (NOLOCK) ON Aplic.CodApl = PonConAcu.CodApl AND PonConAcu.CodPonAcu = ColAcu.CodPonAcu
    LEFT JOIN [SQLMML].[ENGEMAN].[engeman].[TipPon] WITH (NOLOCK) ON PonConAcu.CodTipPon = TipPon.CodTipPon
    LEFT JOIN [SQLMML].[ENGEMAN].[engeman].[TIPAPLIC] WITH (NOLOCK)
    ON APLIC.CODTIPAPL = TIPAPLIC.CODTIPAPL


   WHERE ColAcu.DatHor >= '20230101' -- Formato de data YYYYMMDD não ambíguo. Comentário removido.
   AND (
       TIPAPLIC.DESCRICAO LIKE '%CAMINHÃO%' OR
       TIPAPLIC.DESCRICAO LIKE '%ESCAVADEIRA%' OR
       TIPAPLIC.DESCRICAO LIKE '%CARREGADEIRA%'
       -- Para otimizar esta condição, considere usar uma tabela de lookup para os tipos de descrição
       -- ou explorar funcionalidades de full-text search se o volume de dados e a complexidade da busca justificarem.
   )
    GROUP BY Aplic.CodApl, CAST(ColAcu.DatHor AS DATE), Aplic.CodEmp, Aplic.DESCRICAO, Aplic.TAG
),
ComValoresPreenchidos AS (
    SELECT 
        B.*,
        COALESCE(NULLIF(B.KILOMETRAGEM_RAW, 0), LKP_KM.KILOMETRAGEM_RAW) AS KILOMETRAGEM,
        COALESCE(NULLIF(B.HORIMETRO_RAW, 0), LKP_HM.HORIMETRO_RAW) AS HORIMETRO
    FROM BaseValores B
    OUTER APPLY (
        SELECT TOP 1 KILOMETRAGEM_RAW 
        FROM BaseValores 
        WHERE COD_EQUIPAMENTO = B.COD_EQUIPAMENTO 
        AND DATA < B.DATA 
        AND KILOMETRAGEM_RAW > 0 
        ORDER BY DATA DESC
    ) LKP_KM
    OUTER APPLY (
        SELECT TOP 1 HORIMETRO_RAW 
        FROM BaseValores 
        WHERE COD_EQUIPAMENTO = B.COD_EQUIPAMENTO 
        AND DATA < B.DATA 
        AND HORIMETRO_RAW > 0 
        ORDER BY DATA DESC
    ) LKP_HM
)

    SELECT ComValoresPreenchidos.*,
        VW_EQUIPAMENTO_CR.[KEY CR SENIOR],
        KILOMETRAGEM - LAG(KILOMETRAGEM) OVER (PARTITION BY COD_EQUIPAMENTO ORDER BY DATA) AS VAR_KILOMETRAGEM,
        HORIMETRO - LAG(HORIMETRO) OVER (PARTITION BY COD_EQUIPAMENTO ORDER BY DATA) AS VAR_HORIMETRO
    FROM ComValoresPreenchidos
    LEFT JOIN VW_EQUIPAMENTO_CR
ON ComValoresPreenchidos.[COD EQUIPAMENTO ENGEMAN] = VW_EQUIPAMENTO_CR.[COD EQUIPAMENTO ENGEMAN]

WHERE ABS(COALESCE(KILOMETRAGEM,0)+COALESCE(HORIMETRO,0)) >0
GO
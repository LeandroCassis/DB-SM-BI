SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE VIEW [dbo].[WH_PREVISÃO_TEMPO_EQUIPAMENTOS] AS


WITH Parametros AS
(
    SELECT
        CAST('2026-01-01T00:00:00' AS DATETIME) AS DataInicial,
        GETDATE() AS Agora,
        CAST(1 AS NUMERIC(18,0)) AS CodEmp
),
Equipamentos AS
(
    SELECT

        'MIB' AS Servidor,
        A.TAG AS [TAG EQUIPAMENTO],
        CONCAT_WS('-',E.CODEMP,A.CODAPL,A.DESCRICAO) 'KEY EQUIPAMENTO',
        A.CODAPL,
        E.CODEMP AS [COD EMPRESA],
        E.RAZSOC AS Empresa,
        F.TAG + ' - ' + F.RAZSOC AS Filial,
        A.TAG + ' - ' + A.DESCRICAO AS Equipamento
    FROM [Engeman].[Engeman].[APLIC] A
    INNER JOIN [Engeman].[Engeman].[FILIAL] F ON F.CODFIL = A.CODFIL
    INNER JOIN [Engeman].[Engeman].[EMPRESA] E ON E.CODEMP = A.CODEMP
    CROSS JOIN Parametros P
    WHERE A.CODEMP = P.CodEmp

    UNION ALL

    SELECT
        'MML' AS Servidor,
        A.TAG AS [TAG EQUIPAMENTO],
        CONCAT_WS('-',E.CODEMP,A.CODAPL,A.DESCRICAO) 'KEY EQUIPAMENTO',
        A.CODAPL,
        E.CODEMP AS [COD EMPRESA],
        E.RAZSOC AS Empresa,
        F.TAG + ' - ' + F.RAZSOC AS Filial,
        A.TAG + ' - ' + A.DESCRICAO AS Equipamento
    FROM [SQLMML].[ENGEMAN].[engeman].[APLIC] A
    INNER JOIN [SQLMML].[ENGEMAN].[engeman].[FILIAL] F ON F.CODFIL = A.CODFIL
    INNER JOIN [SQLMML].[ENGEMAN].[engeman].[EMPRESA] E ON E.CODEMP = A.CODEMP
    CROSS JOIN Parametros P
    WHERE A.CODEMP = P.CodEmp
),
Numeros AS
(
    SELECT TOP (40000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS N
    FROM sys.all_objects O1
    CROSS JOIN sys.all_objects O2
),
Dias AS
(
    SELECT
        DATEADD(DAY, N.N, CAST(P.DataInicial AS DATE)) AS Dia,
        P.DataInicial,
        P.Agora
    FROM Numeros N
    CROSS JOIN Parametros P
    WHERE N.N <=
        CASE
            WHEN CAST(P.DataInicial AS DATE) <= CAST(P.Agora AS DATE)
                THEN DATEDIFF(DAY, CAST(P.DataInicial AS DATE), CAST(P.Agora AS DATE))
            ELSE -1
        END
)
SELECT
    EQ.Servidor AS [SERVIDOR],
    EQ.[COD EMPRESA] AS [COD EMPRESA],
    EQ.Empresa AS [EMPRESA],
    EQ.Filial AS [FILIAL],
    D.Dia AS [DATA],
    'TOTAL DO DIA' AS [TURNO],
    EQ.[TAG EQUIPAMENTO] AS [TAG EQUIPAMENTO],
    EQ.[KEY EQUIPAMENTO],
    EQ.Equipamento AS [EQUIPAMENTO],
    CAST(Calc.HorasPrevistas AS DECIMAL(18,4)) AS [#HORAS PREVISTAS],
    [Engeman].[Engeman].[fntoh](Calc.HorasPrevistas) AS [#TEMPO PREVISTO]
FROM Equipamentos EQ
CROSS JOIN Dias D
CROSS APPLY
(
    SELECT
        CASE
            WHEN D.Dia = CAST(D.DataInicial AS DATE) THEN D.DataInicial
            ELSE CAST(D.Dia AS DATETIME)
        END AS InicioDia,
        CASE
            WHEN D.Dia = CAST(D.Agora AS DATE) THEN D.Agora
            ELSE DATEADD(DAY, 1, CAST(D.Dia AS DATETIME))
        END AS FimDia
) Limites
CROSS APPLY
(
    SELECT
        DATEDIFF(SECOND, Limites.InicioDia, Limites.FimDia) AS SegundosPrevistos,
        DATEDIFF(SECOND, Limites.InicioDia, Limites.FimDia) / 3600.0 AS HorasPrevistas
) Calc
WHERE Calc.SegundosPrevistos > 0
GO
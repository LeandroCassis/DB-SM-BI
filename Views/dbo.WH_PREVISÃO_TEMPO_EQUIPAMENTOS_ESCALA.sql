SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE   VIEW [dbo].[WH_PREVISÃO_TEMPO_EQUIPAMENTOS_ESCALA]
AS
SELECT
    T.Servidor                                    AS [SERVIDOR],
    T.CodEmpresa                                  AS [COD EMPRESA],
    T.Empresa                                     AS [EMPRESA],
    T.Filial                                      AS [FILIAL],
    T.DataRef                                     AS [DATA],
    T.Turno                                       AS [TURNO],
    T.TagEquipamento                              AS [TAG EQUIPAMENTO],
    T.KeyEquipamento                              AS [KEY EQUIPAMENTO],
    T.Equipamento                                 AS [EQUIPAMENTO],
    CAST(T.HorasPrevistas AS DECIMAL(18,4))       AS [#HORAS PREVISTAS],
    [Engeman].[Engeman].[fntoh](T.HorasPrevistas) AS [#TEMPO PREVISTO]
FROM [dbo].[fn_WH_PREVISAO_TEMPO_EQUIPAMENTOS_ESCALA]() T
GO
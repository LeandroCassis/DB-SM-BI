SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE   FUNCTION [dbo].[fn_WH_PREVISAO_TEMPO_EQUIPAMENTOS_ESCALA]()
RETURNS @TABELA TABLE (
    Servidor          VARCHAR(10),
    CodEmpresa        NUMERIC(18,0),
    Empresa           VARCHAR(100),
    Filial            VARCHAR(100),
    DataRef           DATE,
    Turno             VARCHAR(20),
    TagEquipamento    VARCHAR(100),
    KeyEquipamento    VARCHAR(200),
    Equipamento       VARCHAR(200),
    HorasPrevistas    FLOAT
)
AS
BEGIN
    DECLARE
        @Servidor        VARCHAR(10),
        @CodEmp          NUMERIC(18,0),
        @CodApl          NUMERIC(18,0),
        @Empresa         VARCHAR(100),
        @Filial          VARCHAR(100),
        @TagEquipamento  VARCHAR(100),
        @KeyEquipamento  VARCHAR(200),
        @Equipamento     VARCHAR(200),
        @DiaAtual        DATETIME,
        @DiaIni          DATETIME,
        @DiaFim          DATETIME,
        @DiaLimite       DATETIME,
        @DataInicial     DATETIME,
        @Agora           DATETIME,
        @HorasPrevistas  FLOAT,
        @ParData         DATETIME,
        @TEMPOMANUAL     FLOAT,
        @RETORNO         FLOAT,
        @CONSIDERA       CHAR(1),
        @DATAESCALA      DATETIME,
        @APLICACAO       INTEGER,
        @TAMANHO         INTEGER,
        @PCODHOR         NUMERIC(18,0),
        @I               INTEGER,
        @TP              FLOAT,
        @FOLGA           INTEGER

    SET @DataInicial = CAST('2026-01-01T00:00:00' AS DATETIME)
    SET @Agora       = GETDATE()
    SET @DiaLimite   = CAST(FLOOR(CAST(@Agora AS FLOAT)) AS DATETIME)

    DECLARE EXECUCAO CURSOR LOCAL FAST_FORWARD FOR
        SELECT
            'MIB' AS Servidor,
            E.CODEMP, E.RAZSOC,
            F.TAG + ' - ' + F.RAZSOC,
            A.TAG,
            CONCAT_WS('-', E.CODEMP, A.CODAPL, A.DESCRICAO),
            A.TAG + ' - ' + A.DESCRICAO,
            A.CODAPL
        FROM [Engeman].[Engeman].[APLIC]   A
        INNER JOIN [Engeman].[Engeman].[FILIAL]  F ON F.CODFIL = A.CODFIL
        INNER JOIN [Engeman].[Engeman].[EMPRESA] E ON E.CODEMP = A.CODEMP
        WHERE E.CODEMP = 1

        UNION ALL

        SELECT
            'MML' AS Servidor,
            E.CODEMP, E.RAZSOC,
            F.TAG + ' - ' + F.RAZSOC,
            A.TAG,
            CONCAT_WS('-', E.CODEMP, A.CODAPL, A.DESCRICAO),
            A.TAG + ' - ' + A.DESCRICAO,
            A.CODAPL
        FROM [SQLMML].[ENGEMAN].[engeman].[APLIC]   A
        INNER JOIN [SQLMML].[ENGEMAN].[engeman].[FILIAL]  F ON F.CODFIL = A.CODFIL
        INNER JOIN [SQLMML].[ENGEMAN].[engeman].[EMPRESA] E ON E.CODEMP = A.CODEMP
        WHERE E.CODEMP = 1

    OPEN EXECUCAO
    FETCH NEXT FROM EXECUCAO INTO @Servidor, @CodEmp, @Empresa, @Filial,
                                   @TagEquipamento, @KeyEquipamento, @Equipamento, @CodApl

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM [Engeman].[Engeman].[APLXESC] X
            WHERE X.CODAPL = @CodApl
              AND X.CODAPLXESC <> 0
              AND X.DATINI < @Agora
              AND X.DATFIM > @DataInicial
        )
        AND NOT EXISTS (
            SELECT 1
            FROM [Engeman].[Engeman].[APLXESCPRO] X
            WHERE X.CODAPL = @CodApl
              AND CAST(FLOOR(CAST(X.DATA AS FLOAT)) AS DATETIME) <= @DiaLimite
        )
        BEGIN
            FETCH NEXT FROM EXECUCAO INTO @Servidor, @CodEmp, @Empresa, @Filial,
                                           @TagEquipamento, @KeyEquipamento, @Equipamento, @CodApl
            CONTINUE
        END

        SET @DiaAtual = CAST(FLOOR(CAST(@DataInicial AS FLOAT)) AS DATETIME)

        WHILE @DiaAtual <= @DiaLimite
        BEGIN
            SET @DiaIni = CASE WHEN @DiaAtual = CAST(FLOOR(CAST(@DataInicial AS FLOAT)) AS DATETIME)
                              THEN @DataInicial ELSE @DiaAtual END
            SET @DiaFim = CASE WHEN @DiaAtual = @DiaLimite
                              THEN @Agora ELSE DATEADD(DAY, 1, @DiaAtual) END

            SET @HorasPrevistas = 0
            SET @TEMPOMANUAL    = 0
            SET @RETORNO        = 0
            SET @ParData        = @DiaAtual

                        SELECT @RETORNO = ISNULL(
                                SUM(
                                        CAST(
                                                DATEDIFF(
                                                        MI,
                                                        CASE WHEN @DiaIni >= DATINI THEN @DiaIni ELSE DATINI END,
                                                        CASE WHEN @DiaFim >= DATFIM THEN DATFIM ELSE @DiaFim END
                                                )
                                        AS FLOAT) / 60.0
                                ),
                                0
                        )
                        FROM [Engeman].[Engeman].[APLXESC]
                        WHERE CODAPL    = @CodApl
                            AND CODAPLXESC <> 0
                            AND CAST(CONVERT(CHAR(11), DATINI, 113) AS DATETIME) = @ParData
                            AND ((DATINI BETWEEN @DiaIni AND @DiaFim)
                                OR (DATFIM BETWEEN @DiaIni AND @DiaFim)
                                OR (DATINI < @DiaIni AND DATFIM > @DiaFim))
                            AND DATINI < @DiaFim
                            AND DATFIM  > @DiaIni

            IF @RETORNO > 0
            BEGIN
                SET @TEMPOMANUAL = @RETORNO
                SET @RETORNO     = 0
            END

            SET @CONSIDERA  = NULL
            SET @DATAESCALA = NULL
            SET @APLICACAO  = 0

                        SELECT TOP (1)
                @CONSIDERA  = E.CONSISTE_ESC,
                                @DATAESCALA = CAST(FLOOR(CAST(A.DATA AS FLOAT)) AS DATETIME),
                                @APLICACAO  = 1
            FROM [Engeman].[Engeman].[APLXESCPRO] A
            INNER JOIN [Engeman].[Engeman].[ESCPRO] E ON A.CODESCPRO = E.CODESCPRO
            WHERE A.CODAPL = @CodApl
                            AND CAST(FLOOR(CAST(A.DATA AS FLOAT)) AS DATETIME) <= @ParData
                        ORDER BY A.DATA DESC

            IF ISNULL(@APLICACAO, 0) = 0
            BEGIN
                SET @HorasPrevistas = @TEMPOMANUAL
                SET @TEMPOMANUAL    = 0
            END

            IF ISNULL(@APLICACAO, 0) > 0
            BEGIN
                SET @TAMANHO = 0
                SELECT @TAMANHO = COUNT(*)
                FROM [Engeman].[Engeman].[HORESCPRO] HP
                INNER JOIN [Engeman].[Engeman].[APLXESCPRO] AP ON AP.CODESCPRO = HP.CODESCPRO
                WHERE AP.CODAPL = @CodApl
                  AND CAST(FLOOR(CAST(AP.DATA AS FLOAT)) AS DATETIME) = @DATAESCALA

                IF @TAMANHO >= 1
                BEGIN
                    SET @PCODHOR = NULL
                    SELECT @PCODHOR = MIN(HP.CODHOR)
                    FROM [Engeman].[Engeman].[APLXESCPRO] AP
                    INNER JOIN [Engeman].[Engeman].[ESCPRO]      E  ON E.CODESCPRO  = AP.CODESCPRO
                    INNER JOIN [Engeman].[Engeman].[HORESCPRO]   HP ON HP.CODESCPRO = E.CODESCPRO
                    INNER JOIN [Engeman].[Engeman].[HORARIOS]    HO ON HO.CODHOR    = HP.CODHOR
                    INNER JOIN [Engeman].[Engeman].[HORAS]       HA ON HA.CODHOR    = HO.CODHOR
                    WHERE AP.CODAPL = @CodApl
                      AND CAST(FLOOR(CAST(AP.DATA AS FLOAT)) AS DATETIME) = @DATAESCALA
                      AND CAST(FLOOR(CAST(HP.DATA AS FLOAT)) AS DATETIME) =
                          CAST(FLOOR(CAST(E.DATINIESC +
                              (CAST(ABS(CAST(E.DATINIESC AS FLOAT) - CAST(@ParData AS FLOAT)) AS INT) % @TAMANHO)
                          AS FLOAT)) AS DATETIME)

                    SET @I = 0
                    SELECT @I = COUNT(*)
                    FROM [Engeman].[Engeman].[FERIADOS]    FE
                    INNER JOIN [Engeman].[Engeman].[ESCPROXFER] EF ON EF.CODFER     = FE.CODFER
                    INNER JOIN [Engeman].[Engeman].[APLXESCPRO] AP ON AP.CODESCPRO  = EF.CODESCPRO
                    WHERE AP.CODAPL = @CodApl
                      AND CAST(FLOOR(CAST(AP.DATA AS FLOAT)) AS DATETIME) = @DATAESCALA
                      AND ((
                            REPLICATE('0', 2 - LEN(CAST(DATEPART(DD,   @ParData) AS VARCHAR))) + CAST(DATEPART(DD,   @ParData) AS VARCHAR) +
                            REPLICATE('0', 2 - LEN(CAST(DATEPART(MM,   @ParData) AS VARCHAR))) + CAST(DATEPART(MM,   @ParData) AS VARCHAR) +
                            REPLICATE('0', 4 - LEN(CAST(DATEPART(YYYY, @ParData) AS VARCHAR))) + CAST(DATEPART(YYYY, @ParData) AS VARCHAR)
                            LIKE
                            REPLICATE('0', 2 - LEN(CAST(DIA AS VARCHAR))) + CAST(DIA AS VARCHAR) +
                            REPLICATE('0', 2 - LEN(CAST(MES AS VARCHAR))) + CAST(MES AS VARCHAR) +
                            CASE ISNULL(ANO, 0) WHEN 0 THEN '' ELSE CAST(ANO AS VARCHAR) END + '%'
                           )
                           OR (DATEPART(DW, @ParData) = DDS))

                    IF @I = 0
                    BEGIN
                        SET @TP = 0

                        SELECT @TP = ISNULL(ROUND(SUM(X.TEMPO_DATA), 5), 0)
                        FROM (
                            SELECT HOR.CODHOR,
                                SUM(
                                    CASE WHEN HOR.DATHORFIM  < @DiaIni THEN 0
                                    ELSE CASE WHEN HOR.DATHORINI > @DiaFim  THEN 0
                                    ELSE CASE WHEN HOR.DATHORINI <  @DiaIni AND HOR.DATHORFIM >  @DiaFim
                                        THEN DATEDIFF(SS, @DiaIni, @DiaFim) / 3600.0
                                    ELSE CASE WHEN HOR.DATHORINI >= @DiaIni AND HOR.DATHORFIM <= @DiaFim
                                        THEN DATEDIFF(SS, HOR.DATHORINI, HOR.DATHORFIM) / 3600.0
                                    ELSE CASE WHEN HOR.DATHORINI >= @DiaIni OR  HOR.DATHORFIM >  @DiaFim
                                        THEN DATEDIFF(SS, HOR.DATHORINI, @DiaFim) / 3600.0
                                    ELSE CASE WHEN HOR.DATHORINI <  @DiaIni AND HOR.DATHORFIM <= @DiaFim
                                        THEN DATEDIFF(SS, @DiaIni, HOR.DATHORFIM) / 3600.0
                                    ELSE 0
                                    END END END END END END
                                ) AS TEMPO_DATA
                            FROM (
                                SELECT H.CODHOR,
                                    CASE WHEN @DiaAtual = CONVERT(DATETIME, CONVERT(VARCHAR(10), @DiaIni, 103), 103)
                                        THEN CASE WHEN @DiaAtual > CONVERT(DATETIME, CONVERT(VARCHAR(10), H.DATHORINI, 103), 103)
                                            THEN @DiaAtual ELSE H.DATHORINI END
                                        ELSE H.DATHORINI
                                    END AS DATHORINI,
                                    CASE WHEN @DiaAtual = CONVERT(DATETIME, CONVERT(VARCHAR(10), @DiaFim, 103), 103)
                                        THEN CASE WHEN @DiaAtual < CONVERT(DATETIME, CONVERT(VARCHAR(10), H.DATHORFIM, 103), 103)
                                            THEN @DiaAtual + 1 ELSE H.DATHORFIM END
                                        ELSE H.DATHORFIM
                                    END AS DATHORFIM
                                FROM (
                                    SELECT
                                        HORA.CODHOR,
                                        CASE WHEN HORA.HORINI < HORA.MINHORINI
                                            THEN (@DiaAtual + 1) + (HORA.HORINI / 24)
                                            ELSE  @DiaAtual      + (HORA.HORINI / 24)
                                        END AS DATHORINI,
                                        CASE WHEN HORA.HORFIM <= HORA.MINHORINI AND HORA.HORINI <> HORA.HORFIM
                                            THEN (@DiaAtual + 1) + (HORA.HORFIM / 24)
                                            ELSE  @DiaAtual      + (HORA.HORFIM / 24)
                                        END AS DATHORFIM
                                    FROM (
                                        SELECT
                                            HORAS.CODHOR,
                                            CAST(SUBSTRING(HORAS.HORINI, 1, 2) AS FLOAT)
                                                + CAST(SUBSTRING(HORAS.HORINI, 4, 2) AS FLOAT) / 60.0 AS HORINI,
                                            CASE WHEN HORAS.HORFIM = '00:00' AND HORAS.HORINI <> '00:00'
                                                THEN 23.99999
                                                ELSE CAST(SUBSTRING(HORAS.HORFIM, 1, 2) AS FLOAT)
                                                   + CAST(SUBSTRING(HORAS.HORFIM, 4, 2) AS FLOAT) / 60.0
                                            END AS HORFIM,
                                            (SELECT CAST(SUBSTRING(H2.HORINI, 1, 2) AS FLOAT)
                                                    + CAST(SUBSTRING(H2.HORINI, 4, 2) AS FLOAT) / 60.0
                                             FROM [Engeman].[Engeman].[HORAS] H2
                                             WHERE H2.CODHOR = HORAS.CODHOR
                                               AND H2.ORDEM  = (SELECT MIN(ORDEM) FROM [Engeman].[Engeman].[HORAS] H3
                                                                WHERE H3.CODHOR = @PCODHOR)
                                            ) AS MINHORINI
                                        FROM [Engeman].[Engeman].[HORAS]
                                        WHERE HORAS.CODHOR = @PCODHOR
                                    ) HORA
                                ) H
                            ) HOR
                            WHERE ((HOR.DATHORINI BETWEEN @DiaIni AND @DiaFim)
                                OR (HOR.DATHORFIM BETWEEN @DiaIni AND @DiaFim)
                                OR (HOR.DATHORINI < @DiaIni AND HOR.DATHORFIM > @DiaFim))
                              AND HOR.DATHORINI < @DiaFim
                              AND HOR.DATHORFIM > @DiaIni
                            GROUP BY HOR.CODHOR
                        ) X

                        SET @RETORNO = @TP

                        SET @FOLGA = 0
                        SELECT @FOLGA = SUM(CASE WHEN DATINI = DATFIM THEN 1 ELSE 0 END)
                        FROM [Engeman].[Engeman].[APLXESC]
                        WHERE CODAPL = @CodApl AND DATINI = @ParData

                        IF @FOLGA > 0 AND @CONSIDERA <> 'N'
                            SET @RETORNO = 0

                        IF @CONSIDERA = 'N'
                        BEGIN
                            SET @HorasPrevistas = @RETORNO
                            SET @RETORNO        = 0
                        END

                        IF @CONSIDERA = 'S'
                        BEGIN
                            IF ISNULL(@TEMPOMANUAL, 0) > 0
                            BEGIN
                                SET @HorasPrevistas = @TEMPOMANUAL
                                SET @TEMPOMANUAL    = 0
                                SET @RETORNO        = 0
                            END
                            ELSE
                            BEGIN
                                SET @HorasPrevistas = @RETORNO
                                SET @RETORNO        = 0
                            END
                        END

                        IF @CONSIDERA = 'C'
                        BEGIN
                            SET @HorasPrevistas = @RETORNO + ISNULL(@TEMPOMANUAL, 0)
                            SET @TEMPOMANUAL    = 0
                            SET @RETORNO        = 0
                        END
                    END
                    ELSE
                    BEGIN
                        IF @CONSIDERA <> 'N' AND ISNULL(@TEMPOMANUAL, 0) > 0
                        BEGIN
                            SET @HorasPrevistas = @TEMPOMANUAL
                            SET @TEMPOMANUAL    = 0
                        END
                    END
                END
            END

            IF ISNULL(@HorasPrevistas, 0) > 0
            BEGIN
                INSERT INTO @TABELA (Servidor, CodEmpresa, Empresa, Filial, DataRef, Turno,
                                     TagEquipamento, KeyEquipamento, Equipamento, HorasPrevistas)
                VALUES (@Servidor, @CodEmp, @Empresa, @Filial, CAST(@DiaAtual AS DATE), 'TOTAL DO DIA',
                        @TagEquipamento, @KeyEquipamento, @Equipamento, @HorasPrevistas)
            END

            SET @DiaAtual = @DiaAtual + 1
        END

        FETCH NEXT FROM EXECUCAO INTO @Servidor, @CodEmp, @Empresa, @Filial,
                                       @TagEquipamento, @KeyEquipamento, @Equipamento, @CodApl
    END

    CLOSE EXECUCAO
    DEALLOCATE EXECUCAO

    RETURN
END
GO
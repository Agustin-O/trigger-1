CREATE TABLE reservas (
    id SERIAL PRIMARY KEY,
    numero_quarto INT NOT NULL,
    data_checkin DATE NOT NULL,
    data_checkout DATE NOT NULL,
    valor_diaria DECIMAL(10, 2) NOT NULL,
    valor_total DECIMAL(10, 2)
);

CREATE OR REPLACE FUNCTION fn_validar_e_calcular_reserva()
RETURNS TRIGGER AS $$
DECLARE
    quantidade_diarias INT;
BEGIN
    IF NEW.data_checkout <= NEW.data_checkin THEN
        RAISE EXCEPTION 'Erro de Validação: A data de check-out (%) deve ser posterior à data de check-in (%).', 
            NEW.data_checkout, NEW.data_checkin;
    END IF;

    quantidade_diarias := NEW.data_checkout - NEW.data_checkin;
    
    NEW.valor_total := quantidade_diarias * NEW.valor_diaria;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_e_calcular_reserva
BEFORE INSERT OR UPDATE ON reservas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_e_calcular_reserva();

TRUNCATE TABLE reservas RESTART IDENTITY;

INSERT INTO reservas (numero_quarto, data_checkin, data_checkout, valor_diaria)
VALUES (101, '2026-11-01', '2026-11-06', 200.00);

SELECT 'Teste 1 - Reserva efetuada com sucesso (Total deve ser 1000.00)' AS cenario;
SELECT * FROM reservas;

SELECT 'Teste 2 - Tentando inserir data inválida (Esperado: ERRO DA TRIGGER)' AS cenario;
INSERT INTO reservas (numero_quarto, data_checkin, data_checkout, valor_diaria)
VALUES (102, '2026-11-10', '2026-11-05', 200.00); 

SELECT 'Teste 3 - Tentando chocar datas no mesmo quarto (Esperado: ERRO DE OVERBOOKING)' AS cenario;
INSERT INTO reservas (numero_quarto, data_checkin, data_checkout, valor_diaria)
VALUES (101, '2026-11-04', '2026-11-10', 200.00);
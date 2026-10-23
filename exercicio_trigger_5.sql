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

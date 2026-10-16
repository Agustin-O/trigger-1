CREATE TABLE contas(
id SERIAL PRIMARY KEY,
cliente VARCHAR(100) NOT NULL,
saldo NUMERIC(10, 2) NOT NULL
);

CREATE TABLE movimentacoes(
id SERIAL PRIMARY KEY,
conta_id INT REFERENCES contas(id),
tipo VARCHAR(1) CHECK(tipo IN ('C', 'D')),
valor NUMERIC(10, 2) NOT NULL,
data_movimentacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_atualiza_saldo_conta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tipo = 'C' THEN
        UPDATE contas SET saldo = saldo + NEW.valor WHERE id = NEW.conta_id;
    ELSIF NEW.tipo = 'D' THEN
        UPDATE contas SET saldo = saldo - NEW.valor WHERE id = NEW.conta_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualiza_saldo
AFTER INSERT ON movimentacoes
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_saldo_conta();

INSERT INTO contas (cliente, saldo) VALUES ('João Silva', 500.00);

INSERT INTO movimentacoes (conta_id, tipo, valor) VALUES (1, 'D', 150.00);

SELECT * FROM contas WHERE id = 1;
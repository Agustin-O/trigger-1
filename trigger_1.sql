CREATE TABLE produtos(
id SERIAL PRIMARY KEY,
nome VARCHAR(100) NOT NULL,
preco NUMERIC(10, 2) NOT NULL
);

CREATE TABLE historico_precos(
id SERIAL PRIMARY KEY,
produto_id INT NOT NULL,
preco_antigo NUMERIC(10, 2),
preco_novo NUMERIC(10, 2),
data_alteracao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_log_alteracao_preco()
RETURNS TRIGGER AS $$
BEGIN

    if OLD.preco IS DISTINCT FROM NEW.preco THEN
        INSERT INTO historico_precos (produto_id, preco_antigo, preco_novo)
        VALUES (NEW.id, OLD.preco, NEW.preco);

    END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_preco
AFTER UPDATE ON produtos
FOR EACH ROW
EXECUTE FUNCTION fn_log_alteracao_preco();

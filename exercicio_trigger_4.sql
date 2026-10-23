CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE clientes_deletados_log (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    data_remocao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_soft_delete_cliente()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO clientes_deletados_log (cliente_id, nome, email)
    VALUES (OLD.id, OLD.nome, OLD.email);

    UPDATE clientes 
    SET ativo = FALSE 
    WHERE id = OLD.id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_soft_delete_cliente
BEFORE DELETE ON clientes
FOR EACH ROW
EXECUTE FUNCTION fn_soft_delete_cliente();

INSERT INTO clientes (nome, email) VALUES ('Carlos Souza', 'carlos@email.com');

DELETE FROM clientes WHERE id = 1;

SELECT * FROM clientes;

SELECT * FROM clientes_deletados_log;

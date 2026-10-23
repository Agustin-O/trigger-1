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

TRUNCATE TABLE clientes RESTART IDENTITY CASCADE;
TRUNCATE TABLE clientes_deletados_log RESTART IDENTITY;

INSERT INTO vw_clientes (nome, email) VALUES ('Arthur Melzi', 'arthur@email.com');
INSERT INTO vw_clientes (nome, email) VALUES ('Maria Silva', 'maria@email.com');

SELECT 'Validação 1 - View antes do Delete' AS etapa;
SELECT * FROM vw_clientes;

SELECT 'Validação 1 - Tabela antes do Delete' AS etapa;
SELECT * FROM clientes;

DELETE FROM vw_clientes WHERE id = 1;

SELECT 'Validação 2 - View pós-Delete (Apenas Maria deve aparecer)' AS etapa;
SELECT * FROM vw_clientes;

SELECT 'Validação 3 - Tabela física pós-Delete (Arthur modificado para FALSE)' AS etapa;
SELECT * FROM clientes;

SELECT 'Validação 4 - Tabela de Log de Auditoria' AS etapa;
SELECT * FROM clientes_deletados_log;
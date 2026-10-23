CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente VARCHAR(100) NOT NULL,
    valor_total DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_nome VARCHAR(100) NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10, 2) NOT NULL CHECK (preco_unitario >= 0)
);

CREATE OR REPLACE FUNCTION fn_recalcula_valor_total_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id INT;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_pedido_id := OLD.pedido_id;
    ELSE
        v_pedido_id := NEW.pedido_id;
    END IF;

    UPDATE pedidos
    SET valor_total = COALESCE(
        (SELECT SUM(quantidade * preco_unitario) 
         FROM itens_pedido 
         WHERE pedido_id = v_pedido_id), 0
    )
    WHERE id = v_pedido_id;

    IF (TG_OP = 'UPDATE' AND OLD.pedido_id <> NEW.pedido_id) THEN
        UPDATE pedidos
        SET valor_total = COALESCE(
            (SELECT SUM(quantidade * preco_unitario) 
             FROM itens_pedido 
             WHERE pedido_id = OLD.pedido_id), 0
        )
        WHERE id = OLD.pedido_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_itens_pedido_alterados
AFTER INSERT OR UPDATE OR DELETE ON itens_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_recalcula_valor_total_pedido();

UPDATE itens_pedido SET pedido_id = 2 WHERE id = 1;

TRUNCATE TABLE pedidos RESTART IDENTITY CASCADE;

INSERT INTO pedidos (cliente) VALUES ('Ana Souza');
INSERT INTO pedidos (cliente) VALUES ('Carlos Silva');

INSERT INTO itens_pedido (pedido_id, produto_nome, quantidade, preco_unitario) VALUES (1, 'Mouse Gamer', 2, 150.00); -- ID 1 (Total: 300.00)
INSERT INTO itens_pedido (pedido_id, produto_nome, quantidade, preco_unitario) VALUES (1, 'Mousepad', 1, 50.00);    -- ID 2 (Total: 50.00)

SELECT 'Validação 1 - Itens inseridos no Pedido 1 (Total deve ser 350.00)' AS etapa;
SELECT * FROM pedidos;

UPDATE itens_pedido SET pedido_id = 2 WHERE id = 2;

SELECT 'Validação 2 - Após mover item (Pedido 1 deve ir para 300.00 e Pedido 2 para 50.00)' AS etapa;
SELECT * FROM pedidos;

DELETE FROM itens_pedido WHERE id = 1;

SELECT 'Validação 3 - Após deletar item (Pedido 1 deve zerar)' AS etapa;
SELECT * FROM pedidos;

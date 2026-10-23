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

INSERT INTO pedidos (cliente) VALUES ('João Silva');

INSERT INTO itens_pedido (pedido_id, produto_nome, quantidade, preco_unitario) 
VALUES (1, 'Notebook', 1, 3500.00),
       (1, 'Mouse', 2, 50.00);
SELECT * FROM pedidos;

UPDATE itens_pedido SET quantidade = 3 WHERE produto_nome = 'Mouse';
SELECT * FROM pedidos;

DELETE FROM itens_pedido WHERE produto_nome = 'Mouse';
SELECT * FROM pedidos;

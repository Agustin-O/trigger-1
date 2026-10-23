CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    estoque_atual INT NOT NULL DEFAULT 0 CHECK (estoque_atual >= 0)
);

CREATE TABLE itens_venda (
    id SERIAL PRIMARY KEY,
    produto_id INT REFERENCES produtos(id),
    quantidade_vendida INT NOT NULL CHECK (quantidade_vendida > 0)
);

CREATE OR REPLACE FUNCTION fn_valida_e_baixa_estoque()
RETURNS TRIGGER AS $$
DECLARE
    v_estoque_disponivel INT;
BEGIN
    SELECT estoque_atual INTO v_estoque_disponivel
    FROM produtos
    WHERE id = NEW.produto_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado.', NEW.produto_id;
    END IF;

    IF v_estoque_disponivel < NEW.quantidade_vendida THEN
        RAISE EXCEPTION 'Estoque insuficiente para o produto (ID %). Disponível: %, Solicitado: %.', 
            NEW.produto_id, v_estoque_disponivel, NEW.quantidade_vendida;
    END IF;

    UPDATE produtos
    SET estoque_atual = estoque_atual - NEW.quantidade_vendida
    WHERE id = NEW.produto_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_itens_venda_before_insert
BEFORE INSERT ON itens_venda
FOR EACH ROW
EXECUTE FUNCTION fn_valida_e_baixa_estoque();

TRUNCATE TABLE produtos RESTART IDENTITY CASCADE;
TRUNCATE TABLE itens_venda RESTART IDENTITY;

INSERT INTO produtos (nome, estoque_atual) VALUES ('Monitor Ultrawide', 5);

SELECT 'Validação 1 - Estoque Inicial (Deve ser 5)' AS etapa;
SELECT * FROM produtos;


INSERT INTO itens_venda (produto_id, quantidade_vendida) VALUES (1, 2);

SELECT 'Validação 2 - Estoque Pós-Venda (Deve ser 3)' AS etapa;
SELECT * FROM produtos;

SELECT 'Validação 2 - Item Registrado na Tabela de Vendas' AS etapa;
SELECT * FROM itens_venda;

SELECT 'Validação 3 - Tentando vender mais do que o estoque possui (Esperado: ERRO DA TRIGGER)' AS etapa;
INSERT INTO itens_venda (produto_id, quantidade_vendida) VALUES (1, 10);